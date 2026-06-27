`timescale 1ns / 1ps

module sequencer (
    input  wire i_CLK,
    input  wire i_RST_n,

    input  wire i_PROC_START,
    output logic o_PROC_DONE,

    output logic [13:0] o_PA_ADDR,                   // BRAM Port A: load inputs, store outputs
    output logic o_PA_WR,
    output logic [127:0] o_PA_WDATA,
    input  wire [127:0] i_PA_RDATA,
    input  wire i_PA_BUSY,

    output logic [13:0] o_PB_ADDR,                   // BRAM Port B: read weights
    input  wire [127:0] i_PB_RDATA,

    (* max_fanout = 256 *) output logic o_PE_EN,     // Gated with skewer for tile computation; replicated to cut broadcast routing delay
    output logic o_PE_CLEAR,                         // Reset PE accumulators at first tile
    (* max_fanout = 256 *) output logic o_PE_DRAIN,  // Shift accumulators to post-processor; replicated to cut broadcast routing delay
    output logic signed [7:0] o_LEFT [0:15],         // Tile A rows to systolic array
    output logic signed [7:0] o_TOP [0:15],          // Tile B cols to systolic array

    output logic o_PP_VALID,                         // Latch post-processor samples
    output logic [31:0] o_PP_SCALER,                 // Per-layer quantization scale factor
    input  wire i_PP_VALID,                          // Post-processor result ready (3 cycles later)
    input  wire signed [7:0] i_PP_DATA [0:15]        // Quantized output logits
);

    localparam int unsigned TOTAL_LAYERS = 4;       // Total layers to process (3 GEMMs + 1 output write)
    localparam int unsigned BATCH_SIZE = 16;        // Number of input samples (fixed at 16 for tile size)
    localparam int unsigned SYSTOLIC_SIZE = 16;     // Systolic array dimensions (16x16 PEs)

    localparam int unsigned W_DIMS [TOTAL_LAYERS][2] = '{
    //   ROWS  COLS
        '{128,  768},   // Layer 0: 128x768 weight matrix
        '{128,  128},   // Layer 1: 128x128 weight matrix
        '{128,  128},   // Layer 2: 128x128 weight matrix
        '{16,   128}    // Layer 3: 16x128 weight matrix (output writeback)
    };

    // Helper function: calculate input dimensions based on layer and tile type
    function automatic int unsigned calc_idim(int unsigned layer, dim);
        if(dim == 0)       return BATCH_SIZE;         // input rows = batch size for all layers
        else begin
            if(layer == 0) return W_DIMS[0][1];       // fetch from localparam W_DIMS for layer 0 input cols
            else           return W_DIMS[layer-1][0]; // input rows = previous layer's weight rows
        end
    endfunction

    localparam int unsigned I_DIMS [TOTAL_LAYERS+1][2] = '{
    //   ROWS            COLS
        '{calc_idim(0,0), calc_idim(0,1)},
        '{calc_idim(1,0), calc_idim(1,1)},
        '{calc_idim(2,0), calc_idim(2,1)},
        '{calc_idim(3,0), calc_idim(3,1)},
        '{calc_idim(4,0), calc_idim(4,1)}   // Extra entry for layer 3 input dimensions (output of layer 2)
    };

    localparam int unsigned W_BADDR [TOTAL_LAYERS] = '{32'h0000_0000, 32'h0000_1800, 32'h0000_1C00, 32'h0000_2000}; // weight base addresses
    localparam int unsigned I_BADDR [TOTAL_LAYERS] = '{32'h0000_2400, 32'h0000_2700, 32'h0000_2780, 32'h0000_2800}; // input base addresses
    localparam int unsigned O_BADDR [TOTAL_LAYERS] = '{I_BADDR[1], I_BADDR[2], I_BADDR[3], 32'h0000_2880};          // output base addresses

    // Predetermined scaling factors: for post-processing quantization
    localparam int unsigned PP_SCALER [TOTAL_LAYERS] = '{32'h0017_B92F, 32'h005E_4B3A, 32'h0502_1F6A, 32'hFFFF_FFFF}; 

    logic signed [7:0] tile_A [0:15][0:15];  // Input feature tile (16x16)
    logic signed [7:0] tile_B [0:15][0:15];  // Weight tile (16x16)

    logic skew_run;         // Trigger skewer to start diagonal sequence
    logic skew_first_tile;  // Assert pe_clear on first tile of layer
    logic skew_pe_en;       // Skewer-driven PE enable
    logic skew_pe_clear;    // Skewer-driven PE clear
    logic skew_busy;        // Skewer still processing (47 cycles)
    logic skew_done;        // Skewer finished sending tile pair

    // Instantiation: skewer module handles diagonal sequencing
    skewer #(.SIZE(SYSTOLIC_SIZE)) u_skewer (
        .clk (i_CLK),
        .resetn (i_RST_n),
        .run (skew_run),
        .first_tile (skew_first_tile),
        .tile_A (tile_A),
        .tile_B (tile_B),
        .left_out (o_LEFT),
        .top_out (o_TOP),
        .pe_en (skew_pe_en),
        .pe_clear (skew_pe_clear),
        .busy (skew_busy),
        .done (skew_done)
    );

    logic ctrl_drain_en;                          // Enable PEs during drain phase
    assign o_PE_EN = skew_pe_en | ctrl_drain_en;  // Enable during compute or drain phase
    assign o_PE_CLEAR = skew_pe_clear;            // Clear at start of layer

    localparam logic [3:0] S_IDLE = 4'd0, 
                         S_L_INIT = 4'd1,   // Initialize layer parameters and addresses
                         S_W_INIT = 4'd2,   // Initialize weight tile parameters and addresses
                         S_LOAD = 4'd3,     // Load tile pair from BRAM (16 cycles)
                         S_SKEW = 4'd4,     // Skewer sends tile data to PEs
                         S_FLUSH = 4'd5,    // Wait 1 cycle after skew
                         S_DRAIN = 4'd6,    // Drain row by row
                         S_W_NEXT = 4'd7,   // Next weight tile (same layer)
                         S_L_NEXT = 4'd8,   // Next layer 
                         S_DONE = 4'd9;     // All layers done

    logic [3:0] state, next_state;

    // State variables to track progress through layers, tiles, and drain cycles
    logic [1:0] layer;  // Current layer index (0 to 3)
    logic [3:0] w_tile; 
    logic [5:0] k_tile; // Current tile indices
    logic [4:0] cnt;    // Counter for load, skew, and drain

    // Derived parameters based on layer and tile indices
    logic [5:0] n_k;         // Number of k-tiles (weight cols / 16) for current layer
    logic [3:0] n_w;         // Number of weight tile rows for current layer
    logic [13:0] b_w_stride; // Stride to jump to next weight tile row in BRAM

    // Current BRAM addresses (shared across states for loading and writing)
    logic [13:0] cur_a_base;
    logic [13:0] cur_a_addr;
    logic [13:0] cur_b_w_base;
    logic [13:0] cur_b_addr;
    logic [13:0] cur_o_addr;

    logic [4:0] drain_cnt;  // Count drain cycles to write output to BRAM
    logic [4:0] write_row;  // Current output row being written

    logic [127:0] pp_word;  // Pack 16 post-processor int8 outputs into 128-bit word

    // Combination logic: pack post-processor outputs into 128-bit word for BRAM write
    always @(*) begin
        for (int c = 0; c < 16; c++)
            pp_word[c*8 +: 8] = i_PP_DATA[c];
    end

    // Combination logic: next state logic for FSM
    always @(*) begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (i_PROC_START)
                    next_state = S_L_INIT;  // start processing
            end

            S_L_INIT: begin
                next_state = S_W_INIT;      // after 1 cycle, start first weight tile
            end

            S_W_INIT: begin
                next_state = S_LOAD;        // after 1 cycle, start loading tile pair from BRAM
            end

            S_LOAD: begin
                if (cnt == 5'd16)           // after 16 cycles, full tile loaded
                    next_state = S_SKEW;    // start diagonal sequencing to PEs
            end

            S_SKEW: begin
                if (skew_done)              // after skewing, move to flush
                    next_state = S_FLUSH;   // 1 cycle gap to ensure all PEs have finished before draining
            end

            S_FLUSH: begin
                if (cnt == 5'd1) begin      // after 2 cycle, either drain or load next tile
                    if (k_tile == n_k - 6'd1)
                        next_state = S_DRAIN;   // last k-tile: drain to post-processor
                    else
                        next_state = S_LOAD;    // more k-tiles are needed: load next tile pair
                end
            end

            S_DRAIN: begin
                if (drain_cnt == 5'd18)     // after 16 cycles (drain) + 2 cycles (write to BRAM), move to next tile or layer
                    next_state = S_W_NEXT;      
            end

            S_W_NEXT: begin                 // process more weight tiles
                if (w_tile == n_w - 4'd1)   
                    next_state = S_L_NEXT;      // last w-tile: move to next layer
                else
                    next_state = S_W_INIT;      // more w-tiles in the same layer: initialize next tile
            end

            S_L_NEXT: begin
                if (layer == 2'd3)          // after last layer, go to done state
                    next_state = S_DONE;
                else
                    next_state = S_L_INIT;
            end

            S_DONE: begin                   // go to idle after done pulse
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // Sequential logic: state transitions
    always @(posedge i_CLK or negedge i_RST_n) begin
        if (!i_RST_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Sequential logic: signal updates
    always @(posedge i_CLK or negedge i_RST_n) begin
        if (!i_RST_n) begin
            layer <= '0;
            w_tile <= '0;
            k_tile <= '0;
            cnt <= '0;
            drain_cnt <= '0;
            write_row <= '0;

            cur_a_base <= '0;
            cur_a_addr <= '0;
            cur_b_w_base <= '0;
            cur_b_addr <= '0;
            cur_o_addr <= '0;

            o_PROC_DONE <= 1'b0;
            o_PA_ADDR <= '0;
            o_PA_WR <= 1'b0;
            o_PA_WDATA <= '0;
            o_PB_ADDR <= '0;
            o_PE_DRAIN <= 1'b0;
            o_PP_VALID <= 1'b0;
            o_PP_SCALER <= '0;

            ctrl_drain_en <= 1'b0;
            skew_run <= 1'b0;
            skew_first_tile <= 1'b0;

            n_k <= '0;
            n_w <= '0;
            b_w_stride <= '0;       // reset all variables and signals

        end else begin
            o_PROC_DONE <= 1'b0;
            o_PA_WR <= 1'b0;
            skew_run <= 1'b0;       // these are for default, and specific states will overwrite

            case (state)

                S_IDLE: begin   // Wait for start, and hold signals low
                    o_PE_DRAIN <= 1'b0;
                    o_PP_VALID <= 1'b0;
                    ctrl_drain_en <= 1'b0;

                    if (i_PROC_START) begin
                        layer <= 2'd0;
                    end
                end

                S_L_INIT: begin  // Initialize per-layer BRAM addresses and parameters
                    cur_a_base <= 14'(I_BADDR[layer]);      // Input feature base address
                    cur_a_addr <= 14'(I_BADDR[layer]);
                    cur_b_w_base <= 14'(W_BADDR[layer]);    // Weight tile base address
                    cur_b_addr <= 14'(W_BADDR[layer]);
                    cur_o_addr <= 14'(O_BADDR[layer]);      // Output base address
                    o_PP_SCALER <= PP_SCALER[layer];        // Layer-specific quantization scale

                    w_tile <= '0;
                    n_k <= 6'(W_DIMS[layer][1] >> 4);       // Number of k-tiles (weight cols / 16)
                    n_w <= 4'(W_DIMS[layer][0] >> 4);       // Number of weight tile rows
                    b_w_stride <= 14'(W_DIMS[layer][1]);    // Weight matrix stride
                end

                S_W_INIT: begin // Initialize and prepare tile parameters
                    k_tile <= '0;
                    cur_a_addr <= cur_a_base;   // port A address for input tile
                    cur_b_addr <= cur_b_w_base; // port B address for weight tile
                    cnt <= '0;                  // counter is for loading tile pairs and skew cycles

                    o_PA_ADDR <= cur_a_base;    
                    o_PB_ADDR <= cur_b_w_base;  // assert addresses for first tile pair load in the next state 
                end

                S_LOAD: begin  // Load 16x16 tile pair from BRAM
                    if (cnt < 5'd15) begin  // Prefetch next word
                        o_PA_ADDR <= cur_a_addr + 14'(cnt + 1);
                        o_PB_ADDR <= cur_b_addr + 14'(cnt + 1); // assert next addresses for pipelined loading
                    end

                    if (cnt >= 5'd1) begin  // Capture with 1-cycle pipeline delay (considering BRAM read latency)
                        for (int k = 0; k < 16; k++) begin
                            tile_A[cnt-1][k] <= signed'(i_PA_RDATA[k*8 +: 8]);
                            tile_B[k][cnt-1] <= signed'(i_PB_RDATA[k*8 +: 8]);  // load data from BRAM into tile buffers
                        end
                    end

                    cnt <= cnt + 1'b1;  // increment load counter

                    if (cnt == 5'd16) begin  // Capture the 16th row and trigger the skewer for the next cycle
                        cnt <= '0;
                        skew_run <= 1'b1;    // Start diagonal sequencing
                        skew_first_tile <= (k_tile == '0);
                    end
                end

                S_SKEW: begin  // Diagonal sequencing (~47 cycles)
                    if (skew_done) begin
                        cnt <= '0;
                    end
                end

                S_FLUSH: begin  // 2-cycle gap between skew and drain
                    cnt <= cnt + 1'b1;

                    if (cnt == 5'd1) begin
                        cnt <= '0;

                        if (k_tile == n_k - 1) begin  // Last k-tile: drain accumulators
                            o_PE_DRAIN <= 1'b1;
                            ctrl_drain_en <= 1'b1;
                            o_PP_VALID <= 1'b1;
                            drain_cnt <= '0;
                            write_row <= 5'd15;

                        end else begin  // More k-tiles: load next batch
                            k_tile <= k_tile + 1'b1;
                            cur_a_addr <= cur_a_addr + 14'd16;
                            cur_b_addr <= cur_b_addr + 14'd16;  // increment addresses for next tile pair

                            o_PA_ADDR <= cur_a_addr + 14'd16;
                            o_PB_ADDR <= cur_b_addr + 14'd16;   // assert addresses for next tile pair
                        end
                    end
                end

                S_DRAIN: begin  // Shift accumulators down, collect 16 outputs, write BRAM
                    drain_cnt <= drain_cnt + 1'b1;

                    if (drain_cnt < 5'd15) begin    // Drain cycles 0-14
                        o_PE_DRAIN <= 1'b1;
                        ctrl_drain_en <= 1'b1;    
                        o_PP_VALID <= 1'b1;         // enable PEs and latch post-processor outputs for 16 cycles
                    end else if (drain_cnt == 5'd15) begin  // Cycle 15: deassert signals
                        o_PE_DRAIN <= 1'b0;
                        ctrl_drain_en <= 1'b0;      // disable PEs after draining all rows
                        o_PP_VALID <= 1'b0;         // deassert valid after capturing last row of outputs
                    end

                    if (i_PP_VALID && !i_PA_BUSY) begin  // Post-processor result ready
                        o_PA_ADDR <= cur_o_addr + 14'(write_row);   // Write output row
                        o_PA_WR <= 1'b1;
                        o_PA_WDATA <= pp_word;                      // assert write with packed post-processor outputs

                        if (write_row != 5'd0)
                            write_row <= write_row - 1'b1;          // Systolic array drains the bottom row (row 15) first; count down to row 0
                    end
                end

                S_W_NEXT: begin // Move to next weight tile or next layer
                    if (w_tile != n_w - 1) begin
                        w_tile <= w_tile + 1'b1;
                        cur_b_w_base <= cur_b_w_base + b_w_stride;  // move to next weight tile row
                        cur_o_addr <= cur_o_addr + 14'd16;          // move output address for next tile's results
                    end
                end

                S_L_NEXT: begin // Move to next layer or done
                    if (layer != 2'd3) begin    // according to current layer index
                        layer <= layer + 1'b1;  // move to next layer, by increasing layer index
                    end
                end

                S_DONE: begin   // Assert done signal
                    o_PROC_DONE <= 1'b1;
                end

                default: begin
                end

            endcase
        end
    end

endmodule
