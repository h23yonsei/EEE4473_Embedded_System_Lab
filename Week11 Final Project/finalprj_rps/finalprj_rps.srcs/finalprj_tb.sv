`timescale 1ns / 1ns

module finalprj_tb;

logic clk, resetn, proc_start, proc_done;

initial clk = 0;
always #1 clk = ~clk;

// Tap all PE accumulators for debugging/verification
wire signed [31:0] pe_acc_tap [0:15][0:15];

genvar gr, gc;
generate
    for (gr = 0; gr < 16; gr++) begin : g_tap_row
        for (gc = 0; gc < 16; gc++) begin : g_tap_col
            assign pe_acc_tap[gr][gc] =
                u_dut.u_systolic.u_pe_arr.g_row[gr].g_col[gc].u_pe.acc;
        end
    end
endgenerate

finalprj_top u_dut (
    .i_CLK           (clk),
    .i_RST_n         (resetn),

    .i_PROC_START    (proc_start),
    .o_PROC_DONE     (proc_done),

    .S_AXI_ARESETN  (resetn),
    .S_AXI_AWADDR   (32'd0),   // AXI bus idle (no external reads/writes)
    .S_AXI_AWVALID  (1'b0),
    .S_AXI_AWREADY  (),
    .S_AXI_WDATA    (32'd0),
    .S_AXI_WSTRB    (4'd0),
    .S_AXI_WVALID   (1'b0),
    .S_AXI_WREADY   (),
    .S_AXI_BRESP    (),
    .S_AXI_BVALID   (),
    .S_AXI_BREADY   (1'b1),
    .S_AXI_ARADDR   (32'd0),
    .S_AXI_ARVALID  (1'b0),
    .S_AXI_ARREADY  (),
    .S_AXI_RDATA    (),
    .S_AXI_RRESP    (),
    .S_AXI_RVALID   (),
    .S_AXI_RREADY   (1'b1)
);

initial begin
    resetn     = 1'b0;
    proc_start = 1'b0;

    repeat (32) @(posedge clk);
    resetn = 1'b1;

    @(posedge clk);
    proc_start = 1'b1;
    @(posedge clk);
    proc_start = 1'b0;

    // Wait for completion
    wait (proc_done);           // uncommented
    repeat (16) @(posedge clk); // uncommented
    $finish;                    // new to stop sim

end

endmodule