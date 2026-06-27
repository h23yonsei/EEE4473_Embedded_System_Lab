module finalprj_top (
    //ports : DO NOT MODIFY
    input   wire                    i_CLK,
    input   wire                    i_RST_n,

    input   wire                    i_PROC_START,
    output  logic                   o_PROC_DONE,

    input   wire                    S_AXI_ARESETN,
    input   wire    [31:0]          S_AXI_AWADDR,
    input   wire                    S_AXI_AWVALID,
    output  logic                   S_AXI_AWREADY,
    input   wire    [31:0]          S_AXI_WDATA,
    input   wire    [3:0]           S_AXI_WSTRB,
    input   wire                    S_AXI_WVALID,
    output  logic                   S_AXI_WREADY,
    output  wire    [1:0]           S_AXI_BRESP,
    output  logic                   S_AXI_BVALID,
    input   wire                    S_AXI_BREADY,
    input   wire    [31:0]          S_AXI_ARADDR,
    input   wire                    S_AXI_ARVALID,
    output  logic                   S_AXI_ARREADY,
    output  logic   [31:0]          S_AXI_RDATA,
    output  wire    [1:0]           S_AXI_RRESP,
    output  logic                   S_AXI_RVALID,
    input   wire                    S_AXI_RREADY
);

// new: internal wires for sequencer-to-PE/BRAM connections
logic [13:0] pa_addr;
logic pa_wr;
logic [127:0] pa_wdata;
logic [127:0] pa_rdata;
logic pa_busy;

logic [13:0] pb_addr;
logic [127:0] pb_rdata;

logic pe_en;
logic pe_clear;
logic pe_drain;

logic signed [7:0] left_bus [0:15];
logic signed [7:0] top_bus [0:15];

logic pp_valid_in;
logic [31:0] pp_scaler;
logic pp_valid_out;
logic signed [7:0] pp_data [0:15];

wire signed [31:0] acc_out_bus [0:15];

//=========================================================================
// BRAM instance : You can freely configure ports A and B
//=========================================================================

BRAM_TDP #(
    .INIT_FILE          ("bram_init.txt"            )
) u_bram (
    //Port A - I/O path  (read input matrix, write output matrix) + AXI
    .i_PA_ADDR          (pa_addr                    ),  // new, was 14'd0
    .i_PA_WR            (pa_wr                      ),  // new, was 1'b0
    .i_PA_WDATA         (pa_wdata                   ),  // new, was 128'd0
    .o_PA_RDATA         (pa_rdata                   ),  // new
    .o_PA_BUSY          (pa_busy                    ),  // new

    //Port B - weight path  (read only from RTL side)
    // ADDITIONS: Changed from hardcoded 14'd0 to use sequencer output
    .i_PB_ADDR          (pb_addr                    ),  // new, was 14'd0
    .i_PB_WR            (1'b0                       ),  // new, was 1'b0
    .i_PB_WDATA         (128'd0                     ),  // new, was 128'd0
    .o_PB_RDATA         (pb_rdata                   ),

    //AXI4-Lite pass-through : DO NOT MODIFY FROM HERE
    .i_CLK              (i_CLK                      ),
    .i_RST_n            (S_AXI_ARESETN              ),

    .S_AXI_AWADDR       (S_AXI_AWADDR               ),
    .S_AXI_AWVALID      (S_AXI_AWVALID              ),
    .S_AXI_AWREADY      (S_AXI_AWREADY              ),
    .S_AXI_WDATA        (S_AXI_WDATA                ),
    .S_AXI_WSTRB        (S_AXI_WSTRB                ),
    .S_AXI_WVALID       (S_AXI_WVALID               ),
    .S_AXI_WREADY       (S_AXI_WREADY               ),
    .S_AXI_BRESP        (S_AXI_BRESP                ),
    .S_AXI_BVALID       (S_AXI_BVALID               ),
    .S_AXI_BREADY       (S_AXI_BREADY               ),
    .S_AXI_ARADDR       (S_AXI_ARADDR               ),
    .S_AXI_ARVALID      (S_AXI_ARVALID              ),
    .S_AXI_ARREADY      (S_AXI_ARREADY              ),
    .S_AXI_RDATA        (S_AXI_RDATA                ),
    .S_AXI_RRESP        (S_AXI_RRESP                ),
    .S_AXI_RVALID       (S_AXI_RVALID               ),
    .S_AXI_RREADY       (S_AXI_RREADY               )
);

//=========================================================================
// ADDITIONS: Systolic core instance
//=========================================================================

systolic_core u_systolic (
    .clk (i_CLK),
    .resetn (i_RST_n),
    .pe_en (pe_en),
    .pe_clear (pe_clear),
    .pe_drain (pe_drain),
    .left_in (left_bus),
    .top_in (top_bus),
    .pp_valid_in (pp_valid_in),
    .pp_scaler (pp_scaler),
    .acc_out (acc_out_bus),
    .pp_valid_out (pp_valid_out),
    .pp_data (pp_data)
);

//=========================================================================
// CONTROL instance : Write your own control module
//=========================================================================

//=========================================================================
// CONTROLLER: You can save it as a separate file
//=========================================================================

// new: instead of writing CONTROL module here, wrote a new sequencer module
sequencer u_sequencer (
    .i_CLK              (i_CLK                      ),
    .i_RST_n            (i_RST_n                    ),

    .i_PROC_START       (i_PROC_START               ),
    .o_PROC_DONE        (o_PROC_DONE                ),

    // new: BRAM Port A connections
    .o_PA_ADDR          (pa_addr                    ),
    .o_PA_WR            (pa_wr                      ),
    .o_PA_WDATA         (pa_wdata                   ),
    .i_PA_RDATA         (pa_rdata                   ),
    .i_PA_BUSY          (pa_busy                    ),

    // new: BRAM Port B connections
    .o_PB_ADDR          (pb_addr                    ),
    .i_PB_RDATA         (pb_rdata                   ),

    // new: PE array control
    .o_PE_EN            (pe_en                      ),
    .o_PE_CLEAR         (pe_clear                   ),
    .o_PE_DRAIN         (pe_drain                   ),
    .o_LEFT             (left_bus                   ),
    .o_TOP              (top_bus                    ),

    // new: Post-processor control
    .o_PP_VALID         (pp_valid_in                ),
    .o_PP_SCALER        (pp_scaler                  ),
    .i_PP_VALID         (pp_valid_out               ),
    .i_PP_DATA          (pp_data                    )
);

endmodule

//=========================================================================
// AXI BRAM MODULE : DO NOT MODIFY
//=========================================================================

module BRAM_TDP #(
    parameter INIT_FILE = "bram_init.txt"
)(
    input   wire                i_CLK,
    input   wire                i_RST_n,

    //---- Port A : RTL read / write ----
    input   wire    [13:0]      i_PA_ADDR,
    input   wire                i_PA_WR,
    input   wire    [127:0]     i_PA_WDATA,
    output  logic   [127:0]     o_PA_RDATA,
    output  wire                o_PA_BUSY,      //AXI owns port A this cycle

    //---- Port B : RTL read / write ----
    input   wire    [13:0]      i_PB_ADDR,
    input   wire                i_PB_WR,
    input   wire    [127:0]     i_PB_WDATA,
    output  logic   [127:0]     o_PB_RDATA,

    //---- AXI4-Lite Slave (32-bit data) ----
    input   wire    [31:0]      S_AXI_AWADDR,
    input   wire                S_AXI_AWVALID,
    output  logic               S_AXI_AWREADY,
    input   wire    [31:0]      S_AXI_WDATA,
    input   wire    [3:0]       S_AXI_WSTRB,
    input   wire                S_AXI_WVALID,
    output  logic               S_AXI_WREADY,
    output  wire    [1:0]       S_AXI_BRESP,
    output  logic               S_AXI_BVALID,
    input   wire                S_AXI_BREADY,
    input   wire    [31:0]      S_AXI_ARADDR,
    input   wire                S_AXI_ARVALID,
    output  logic               S_AXI_ARREADY,
    output  logic   [31:0]      S_AXI_RDATA,
    output  wire    [1:0]       S_AXI_RRESP,
    output  logic               S_AXI_RVALID,
    input   wire                S_AXI_RREADY
);

assign S_AXI_BRESP = 2'b00;   //OKAY
assign S_AXI_RRESP = 2'b00;


//=========================================================================
// Memory array  (Vivado byte-write-enable inference pattern)
//=========================================================================

(* ram_style = "block" *)
logic [127:0] mem [0:(1<<14)-1];

initial $readmemh(INIT_FILE, mem);


//=========================================================================
// AXI4-Lite write channel FSM
//=========================================================================

logic        aw_fire, w_fire;
logic [13:0] axi_waddr;
logic [1:0]  axi_wlane;
logic        axi_wr_pending;     //write data captured, issue to port A
logic [15:0] axi_wbe;            //byte-write-enable (16 bytes)
logic [127:0] axi_wdata_128;     //write data spread to 128-bit

assign aw_fire = S_AXI_AWVALID & S_AXI_AWREADY;
assign w_fire  = S_AXI_WVALID  & S_AXI_WREADY;

always_ff @(posedge i_CLK) begin
    if (!i_RST_n) begin
        S_AXI_AWREADY  <= 1'b1;
        S_AXI_WREADY   <= 1'b1;
        S_AXI_BVALID   <= 1'b0;
        axi_wr_pending  <= 1'b0;
    end
    else begin
        //Accept AW
        if (aw_fire) begin
            axi_waddr     <= S_AXI_AWADDR[17:4];
            axi_wlane     <= S_AXI_AWADDR[3:2];
            S_AXI_AWREADY <= 1'b0;
        end

        //Accept W
        if (w_fire) begin
            S_AXI_WREADY <= 1'b0;
        end

        //Both AW and W received -> issue write next cycle
        if ((!S_AXI_AWREADY || aw_fire) && (!S_AXI_WREADY || w_fire)
            && !axi_wr_pending && !S_AXI_BVALID) begin

            logic [1:0] lane;
            lane = aw_fire ? S_AXI_AWADDR[3:2] : axi_wlane;

            //Build byte-enable and data vectors
            axi_wbe       <= '0;
            axi_wdata_128 <= '0;
            for (int i = 0; i < 4; i++) begin
                axi_wbe      [lane*4 + i] <= S_AXI_WSTRB[i];
                axi_wdata_128[(lane*4 + i)*8 +: 8] <= S_AXI_WDATA[i*8 +: 8];
            end
            axi_wr_pending <= 1'b1;
        end

        //Write has been issued to BRAM -> respond
        if (axi_wr_pending) begin
            axi_wr_pending <= 1'b0;
            S_AXI_BVALID   <= 1'b1;
        end

        //B handshake complete
        if (S_AXI_BVALID && S_AXI_BREADY) begin
            S_AXI_BVALID  <= 1'b0;
            S_AXI_AWREADY <= 1'b1;
            S_AXI_WREADY  <= 1'b1;
        end
    end
end


//=========================================================================
// AXI4-Lite read channel FSM
//=========================================================================

logic        axi_rd_pending;
logic        axi_rd_wait;    // extra pipeline stage: holds address while waiting for BRAM registered output
logic [13:0] axi_raddr;
logic [1:0]  axi_rlane;

always_ff @(posedge i_CLK) begin
    if (!i_RST_n) begin
        S_AXI_ARREADY  <= 1'b1;
        S_AXI_RVALID   <= 1'b0;
        axi_rd_pending <= 1'b0;
        axi_rd_wait    <= 1'b0;
    end
    else begin
        //Accept AR
        if (S_AXI_ARVALID && S_AXI_ARREADY) begin
            axi_raddr      <= S_AXI_ARADDR[17:4];
            axi_rlane      <= S_AXI_ARADDR[3:2];
            S_AXI_ARREADY  <= 1'b0;
            axi_rd_pending <= 1'b1;
        end

        // Stage 1 ?†’ axi_rd_pending: axi_raddr is now driving pa_addr.
        // The BRAM address input is stable; its registered output (o_PA_RDATA)
        // will reflect this address only AFTER the next rising edge.
        // Do NOT capture o_PA_RDATA here ?? it still holds the previous address's data.
        if (axi_rd_pending) begin
            axi_rd_pending <= 1'b0;
            axi_rd_wait    <= 1'b1;   // wait one more cycle for BRAM latency
        end

        // Stage 2 ?†’ axi_rd_wait: o_PA_RDATA now holds valid data for axi_raddr.
        // Capture it and assert RVALID.
        if (axi_rd_wait) begin
            axi_rd_wait    <= 1'b0;
            S_AXI_RVALID   <= 1'b1;
            case (axi_rlane)
                2'd0: S_AXI_RDATA <= o_PA_RDATA[ 31:  0];
                2'd1: S_AXI_RDATA <= o_PA_RDATA[ 63: 32];
                2'd2: S_AXI_RDATA <= o_PA_RDATA[ 95: 64];
                2'd3: S_AXI_RDATA <= o_PA_RDATA[127: 96];
            endcase
        end

        //R handshake complete
        if (S_AXI_RVALID && S_AXI_RREADY) begin
            S_AXI_RVALID  <= 1'b0;
            S_AXI_ARREADY <= 1'b1;
        end
    end
end


//=========================================================================
// Port A mux : AXI has absolute priority over RTL read
//=========================================================================

wire        pa_axi_active = axi_wr_pending | axi_rd_pending | axi_rd_wait;
assign      o_PA_BUSY     = pa_axi_active;

wire [13:0] pa_addr = pa_axi_active ? (axi_wr_pending ? axi_waddr : axi_raddr)
                                    : i_PA_ADDR;

//=========================================================================
// Port A : BRAM read + byte-write  (Vivado inference pattern)
//=========================================================================

always_ff @(posedge i_CLK) begin
    //Byte-granularity write (AXI - absolute priority)
    if (axi_wr_pending) begin
        for (int i = 0; i < 16; i++) begin
            if (axi_wbe[i])
                mem[pa_addr][i*8 +: 8] <= axi_wdata_128[i*8 +: 8];
        end
    end
    //Full-width write (RTL - only when AXI is idle)
    else if (i_PA_WR && !pa_axi_active) begin
        mem[pa_addr] <= i_PA_WDATA;
    end
    //Synchronous read (always - read-first mode)
    o_PA_RDATA <= mem[pa_addr];
end


//=========================================================================
// Port B : BRAM read / write  (RTL only)
//=========================================================================

always_ff @(posedge i_CLK) begin
    if (i_PB_WR) begin
        mem[i_PB_ADDR] <= i_PB_WDATA;
    end
    o_PB_RDATA <= mem[i_PB_ADDR];
end


endmodule
