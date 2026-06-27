`timescale 1ns / 1ps

module top # (
    parameter TOGGLE_MAX = 32'd50_000       // To adjust frequency
) (
    input wire clk_in,                      
    input wire resetn,                      // unused
    output reg [7:0] segout,                // a, b, c, d, e, f, g, dp
    output reg [7:0] segcom                 // com
);
    reg [31:0] cnt = 32'd0;                 // counter  
    reg [2:0] i = 3'd0;                     // index: 0 ~ 7 
   
    // Sequential logic: Counter
    always @(posedge clk_in) begin
        if (cnt ==  TOGGLE_MAX - 1) begin   // counter: 0 ~ 50000
            cnt <= 32'd0;
            i <= i + 3'd1;                  // next index
        end else begin
            cnt <= cnt + 32'd1;
        end
    end
   
    // Sequential logic: segment signals mapping 
    always @(posedge clk_in) begin
        case (i)
            3'd0: begin segcom <= 8'b0000_0001;     // only display 0 on
                        segout <= 8'b00000001; end  // 8 
            3'd1: begin segcom <= 8'b0000_0010;     // only display 1 on
                        segout <= 8'b01000001; end  // 6
            3'd2: begin segcom <= 8'b0000_0100;     // only display 2 on
                        segout <= 8'b10011001; end  // 4
            3'd3: begin segcom <= 8'b0000_1000;     // only display 3 on
                        segout <= 8'b00100101; end  // 2
            3'd4: begin segcom <= 8'b0001_0000;     // only display 4 on
                        segout <= 8'b00011111; end  // 7
            3'd5: begin segcom <= 8'b0010_0000;     // only display 5 on
                        segout <= 8'b01001001; end  // 5
            3'd6: begin segcom <= 8'b0100_0000;     // only display 6 on
                        segout <= 8'b00001101; end  // 3
            3'd7: begin segcom <= 8'b1000_0000;     // only display 7 on
                        segout <= 8'b10011111; end  // 1
            default: begin segcom <= 8'b0000_0000;  
                        segout <= 8'b1111_1111; end // off
        endcase
    end
endmodule