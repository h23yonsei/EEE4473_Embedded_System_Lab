`timescale 1ns / 1ns

module finalprj_tb_mod;

logic clk, resetn, proc_start, proc_done;

// clock: 10 ns period
initial clk = 0;
always #5 clk = ~clk;

// internal probe taps into each PE accumulator
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

// instantiate finalprj top module
finalprj_top u_dut (
    .i_CLK (clk),
    .i_RST_n (resetn),

    .i_PROC_START (proc_start),
    .o_PROC_DONE (proc_done),

    // AXI bus tied idle (do not modify)
    .S_AXI_ARESETN (resetn),
    .S_AXI_AWADDR (32'd0),
    .S_AXI_AWVALID (1'b0),
    .S_AXI_AWREADY (),
    .S_AXI_WDATA (32'd0),
    .S_AXI_WSTRB (4'd0),
    .S_AXI_WVALID (1'b0),
    .S_AXI_WREADY (),
    .S_AXI_BRESP (),
    .S_AXI_BVALID (),
    .S_AXI_BREADY (1'b1),
    .S_AXI_ARADDR (32'd0),
    .S_AXI_ARVALID (1'b0),
    .S_AXI_ARREADY (),
    .S_AXI_RDATA (),
    .S_AXI_RRESP (),
    .S_AXI_RVALID (),
    .S_AXI_RREADY (1'b1)
);

// golden reference from numpy_reference.py (X5_int8): 16 clips x 16 cols, only cols 0..8 are valid logits
localparam int OUT_BASE = 14'h2880;

localparam logic signed [7:0] GOLDEN [0:15][0:15] = '{
    '{ 1, 1, 1, 1, 3, 1, 3, 1, 3, 0, 0, 0, 0, 0, 0, 0},
    '{ 9, 2, 1, 0,11, 0, 9, 0,20, 0, 0, 0, 0, 0, 0, 0},
    '{ 2, 0, 0, 6,18, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 2, 2, 0, 0, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 8,15, 0, 0, 8, 0,27, 7, 0, 0, 0, 0, 0, 0, 0},
    '{ 0,12, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    '{ 6, 1, 0, 0, 6, 0, 4, 0,11, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 0, 0, 1, 6, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    '{11, 1, 0, 0, 9, 0, 5, 0,19, 0, 0, 0, 0, 0, 0, 0},
    '{ 7, 0, 7, 7,21, 3, 9, 7,17, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 4, 5, 0, 0, 4, 0,21, 1, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 8, 5, 0, 0, 1, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0},
    '{ 0, 0, 0, 0, 0,16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    '{ 7, 1, 0, 0, 7, 0, 5, 0,14, 0, 0, 0, 0, 0, 0, 0}
};

// model's argmax predictions over valid logits (cols 0..8)
localparam int EXP_PRED [0:15] =
    '{4, 8, 4, 5, 7, 1, 8, 2, 4, 8, 4, 7, 0, 1, 5, 8};

string CLASS_NAME [0:8] =
    '{"one","two","three","four","five","six","seven","eight","nine"};

// read the hardware output for one clip row (byte lane c = column c)
function automatic logic signed [7:0] hw_out(input int row, input int col);
    logic [127:0] w;
    w = u_dut.u_bram.mem[OUT_BASE + row];
    return signed'(w[col*8 +: 8]);
endfunction

// argmax over valid logits (cols 0..8); ties take the lowest index (matches numpy)
function automatic int argmax9(input int row);
    int best_idx;
    logic signed [7:0] best_val;
    best_idx = 0;
    best_val = hw_out(row, 0);
    for (int c = 1; c < 9; c++)
        if (hw_out(row, c) > best_val) begin
            best_val = hw_out(row, c);
            best_idx = c;
        end
    return best_idx;
endfunction

// dump a 16x16 region for visual inspection
task automatic dump_region(input [13:0] base, input string label);
    logic [127:0] w;
    $display("--- %s  (base 0x%04h) ---", label, base);
    for (int row = 0; row < 16; row++) begin
        w = u_dut.u_bram.mem[base + row];
        $write("  row %2d:", row);
        for (int c = 0; c < 16; c++)
            $write(" %4d", $signed(w[c*8 +: 8]));
        $write("\n");
    end
endtask

// dump every layer's output region (each writes a distinct base, so all survive to end-of-run)
task automatic dump_output;
    dump_region(14'h2700, "Layer 0 output");
    dump_region(14'h2780, "Layer 1 output");
    dump_region(14'h2800, "Layer 2 output");
    dump_region(14'h2880, "Layer 3 output (final)");
endtask

// full-byte check vs golden + argmax prediction check
task automatic check_output;
    int byte_errs = 0;
    int pred_errs = 0;
    $display("--- Full-output byte check vs numpy golden ---");
    for (int row = 0; row < 16; row++)
        for (int c = 0; c < 16; c++)
            if (hw_out(row, c) !== GOLDEN[row][c]) begin
                $display("  BYTE MISMATCH clip %0d col %0d: hw=%0d golden=%0d",
                         row+1, c, hw_out(row, c), GOLDEN[row][c]);
                byte_errs++;
            end
    if (byte_errs == 0) $display("  byte check: PASS (all 256 bytes match)");
    else                $display("  byte check: FAIL (%0d mismatches)", byte_errs);

    $display("--- Prediction check (argmax over cols 0..8) ---");
    for (int row = 0; row < 16; row++) begin
        automatic int p = argmax9(row);
        if (p !== EXP_PRED[row]) begin
            $display("  PRED MISMATCH clip %0d: hw=%0d(%s) exp=%0d(%s)",
                     row+1, p, CLASS_NAME[p], EXP_PRED[row], CLASS_NAME[EXP_PRED[row]]);
            pred_errs++;
        end else begin
            $display("  clip %2d: %-6s (class %0d) OK", row+1, CLASS_NAME[p], p);
        end
    end

    $display("========================================");
    if (byte_errs == 0 && pred_errs == 0)
        $display(" INTEGRATION TEST: PASS");
    else
        $display(" INTEGRATION TEST: FAIL (%0d byte, %0d pred errors)",
                 byte_errs, pred_errs);
    $display("========================================");
endtask

// instrumentation: pe_en_cycles (array was clocked), wr_count (~400 write-backs), first write/drain samples show real values reached requant
int pe_en_cycles = 0;
int wr_count = 0;
int pp_seen = 0;

always @(posedge clk) begin
    if (resetn) begin
        if (u_dut.pe_en) pe_en_cycles++;

        if (u_dut.pa_wr) begin
            wr_count++;
            if (wr_count <= 20)
                $display("[WR %3d] addr=0x%04h data[0..3]= %0d %0d %0d %0d",
                    wr_count, u_dut.pa_addr,
                    $signed(u_dut.pa_wdata[7:0]), $signed(u_dut.pa_wdata[15:8]),
                    $signed(u_dut.pa_wdata[23:16]), $signed(u_dut.pa_wdata[31:24]));
        end

        if (u_dut.pp_valid_out && pp_seen < 4) begin
            pp_seen++;
            $display("[PP %0d] acc_out[0..3]= %0d %0d %0d %0d   pp_data[0..3]= %0d %0d %0d %0d",
                pp_seen,
                u_dut.acc_out_bus[0], u_dut.acc_out_bus[1],
                u_dut.acc_out_bus[2], u_dut.acc_out_bus[3],
                u_dut.pp_data[0], u_dut.pp_data[1],
                u_dut.pp_data[2], u_dut.pp_data[3]);
        end
    end
end

// watchdog: full 4-layer run is ~35k cycles; fail loudly if DONE never asserts instead of hanging
initial begin
    #2_000_000; // 2 ms @ 1ns timescale = 200k cycles
    $display("TIMEOUT: o_PROC_DONE never asserted -- CONTROL FSM stalled");
    $finish;
end

initial begin
    resetn = 1'b0;
    proc_start = 1'b0;

    repeat (32) @(posedge clk);
    resetn = 1'b1;

    @(posedge clk);
    proc_start = 1'b1;
    @(posedge clk);
    proc_start = 1'b0;

    wait (proc_done); // auto-stop when DONE asserts
    $display("========================================");
    $display(" o_PROC_DONE asserted -- run complete");
    $display("========================================");
    repeat (16) @(posedge clk);

    $display("--- Instrumentation summary ---");
    $display("  pe_en cycles : %0d (expect thousands)", pe_en_cycles);
    $display("  RTL writes   : %0d (expect ~400)", wr_count);

    dump_output;
    check_output;

    $finish;
end

endmodule
