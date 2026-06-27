`timescale 1ns / 1ps
module tb_mystery_module();
    // Declare wires and registers for the DUT
    reg clk; reg rst;
    wire [7:0] out;

    // Instantiate the DUT
    mystery_module mystery_module_inst ( 
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    // Generate a clock signal
    initial begin           
        clk <= 0;
        forever begin
            #5 clk <= ~clk; // 10ns period, 100MHz frequency
        end
    end

    // Simulation sequence
    initial begin
        clk = 0; rst = 1;
        #10 rst = 0;       // assert a reset signal for 1 clock cycle
        #1000;           // for 1000ns
        $finish;
    end
endmodule
