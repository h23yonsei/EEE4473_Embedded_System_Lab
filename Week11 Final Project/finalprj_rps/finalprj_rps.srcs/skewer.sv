`timescale 1ns / 1ps

module skewer #(
    parameter int SIZE = 16
)(
    input  wire clk,
    input  wire resetn,

    input  wire run,                                        // Start diagonal sequencing
    input  wire first_tile,                                 // First tile of layer: assert pe_clear

    input  wire signed [7:0] tile_A [0:SIZE-1][0:SIZE-1],  // Input feature tile
    input  wire signed [7:0] tile_B [0:SIZE-1][0:SIZE-1],  // Weight tile

    output logic signed [7:0] left_out [0:SIZE-1],         // Staggered tile A rows
    output logic signed [7:0] top_out [0:SIZE-1],          // Staggered tile B cols
    output logic pe_en,                                     // Enable PE computation
    (* max_fanout = 256 *) output logic pe_clear,           // Clear accumulators (first tile only); replicated to cut broadcast routing delay

    output logic busy,                                      // Skew in progress 
    output logic done                                       // Skew complete
);

    localparam int TOTAL = 3 * SIZE; // 48
    localparam int TBITS = $clog2(TOTAL + 1);   // 6 bits to count 0-48

    logic [TBITS-1:0] t;                // Diagonal sequence timer (0-47)
    logic [TBITS-1:0] t_next;           // Next value of t for combinational logic
    assign t_next = t + 1'b1;           // Precompute next timer value for combinational logic

    // Sequential logic: timer, control signals, and output staging
    // 1. On reset, initialize every signal.
    // 2. When run is asserted and not busy, start the skew sequence.
    // 3. While busy, increment timer each cycle to move through diagonals.
    // 4. For each PE index, determine if it should receive new data.
    //  - if t_next is between i and i + SIZE, then PE i receives new inputs from tile_A and tile_B
    //  - if not, outputs should be 0 to create skew effect.
    // 5. When timer reaches TOTAL - 1, the last diagonal has been sent, so reset for next run and assert done.
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            t <= '0;            // reset timer
            busy <= 1'b0;       // idle state
            pe_en <= 1'b0;      // disable PEs
            pe_clear <= 1'b0;   // deassert clear
            done <= 1'b0;       // not done

            for (int i = 0; i < SIZE; i++) begin
                left_out[i] <= 8'sd0;   
                top_out[i] <= 8'sd0;    // reset outputs
            end    
        end else begin
            done <= 1'b0;
            pe_clear <= 1'b0;

            if (run && !busy) begin  // Start diagonal sequencing
                t <= '0;
                busy <= 1'b1;
                pe_en <= 1'b1;
                pe_clear <= first_tile;  // Assert clear on first tile of layer only

                for (int i = 0; i < SIZE; i++) begin
                    if (i == 0) begin
                        left_out[i] <= tile_A[i][0];    // only the first element of tile_A
                        top_out[i] <= tile_B[0][i];     // only the first element of tile_B
                    end else begin
                        left_out[i] <= 8'sd0;           // when i > 0, initial outputs are 0 until their turn in the skew sequence
                        top_out[i] <= 8'sd0;            // this creates skew effect: outputs start in top-left corner and move diagonally down-right
                    end
                end

            end else if (busy) begin    // Continue diagonal sequencing
                if (t == TBITS'(TOTAL - 1)) begin   // when timer reaches 47, last diagonal has been sent to PEs -> reset for next run
                    t <= '0;
                    busy <= 1'b0;
                    pe_en <= 1'b0;
                    done <= 1'b1;

                    for (int i = 0; i < SIZE; i++) begin
                        left_out[i] <= 8'sd0;
                        top_out[i] <= 8'sd0;
                    end

                end else begin
                    t <= t + 1'b1;  // Increment timer to move to next diagonal

                    for (int i = 0; i < SIZE; i++) begin    // for each PE index, determine if it should receive new data this cycle
                        if ((t_next >= TBITS'(i)) &&        // if the next timer value is greater than or equal to i AND less than i + SIZE, then PE i receives new inputs
                            (t_next < TBITS'(i + SIZE))) begin
                            left_out[i] <= tile_A[i][t_next - TBITS'(i)];   // tile_A row i, column (t_next - i)
                            top_out[i] <= tile_B[t_next - TBITS'(i)][i];    // tile_B row (t_next - i), column i
                        end else begin  // if not in the current diagonal, outputs should be 0
                            left_out[i] <= 8'sd0;
                            top_out[i] <= 8'sd0;
                        end
                    end
                end

            end else begin
                pe_en <= 1'b0;  // ensure PEs are disabled when not busy

                for (int i = 0; i < SIZE; i++) begin
                    left_out[i] <= 8'sd0;
                    top_out[i] <= 8'sd0;    // outputs should be 0 when not running
                end
            end
        end
    end

endmodule
