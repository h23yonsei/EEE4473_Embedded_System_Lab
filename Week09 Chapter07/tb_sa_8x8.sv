`timescale 1ns/1ps
module tb_sa_8x8;
    // control
    reg clk = 1'd0;
    always #5 clk = ~clk;
    reg resetn;
    reg save_weight;
    // data input
    reg signed [7:0] din_in [0:7];
    reg signed [7:0] win_in [0:7];
    // data output
    wire signed [17:0] acc_out [0:7];
    // reg to save input.txt and weight.txt
    reg signed [7:0] inputtxt [0:7][0:7];
    reg signed [7:0] weighttxt [0:7][0:7];
    // uut
    sa_8x8 uut (
        .clk(clk),
        .resetn(resetn),
        .save_weight(save_weight),
        .din_in(din_in),
        .win_in(win_in),
        .acc_out(acc_out)
    );
    initial begin
        // load from txt files
        $readmemh("input.txt", inputtxt);
        $readmemh("weight.txt", weighttxt);
        // initialize registers
        resetn = 1'd1;
        save_weight = 1'd0;
        for (int k = 0; k < 8; k++) begin
            din_in[k] = 8'sd0;
            win_in[k] = 8'sd0;
        end
        @(posedge clk);
        // reset
        resetn = 1'd0;
        @(posedge clk);
        resetn = 1'd1;
        @(posedge clk);
        // load weights
        for (int r = 7; r >= 0; r--) begin
            for (int c = 0; c < 8; c++) begin
                win_in[c] = weighttxt[c][r];
            end
            @(posedge clk);
        end
        // save weights
        save_weight = 1'd1;
        @(posedge clk);
        save_weight = 1'd0;
        @(posedge clk);
        // load data
        for (int cycle = 0; cycle < 24; cycle++) begin
            for (int i = 0; i < 8; i++) begin
                int col_idx = cycle - i;
                if (col_idx >= 0 && col_idx < 8) begin
                    din_in[i] = inputtxt[i][col_idx];
                end
                else begin
                    din_in[i] = 8'h0;
                end
            end
            @(posedge clk);
        end
        $finish;
    end
endmodule