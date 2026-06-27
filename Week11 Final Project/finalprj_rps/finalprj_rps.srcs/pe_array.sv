`timescale 1ns / 1ps

module pe_array (
    input  wire clk,
    input  wire resetn,

    input  wire en,                                  // Enable all PEs
    input  wire drain,                               // Drain accumulators to post-processor
    input  wire clear,                               // Reset accumulators for new tile

    input  wire signed [7:0] left_array [0:15],      // Tile A rows (left edge)
    input  wire signed [7:0] top_array [0:15],       // Tile B cols (top edge)

    output logic signed [31:0] acc_out_array [0:15]  // Bottom row accumulators
);

    wire signed [7:0] left_wire [0:15][0:15];        // Horizontal dataflow (left to right)
    wire signed [7:0] top_wire [0:15][0:15];         // Vertical dataflow (top to bottom)
    wire signed [31:0] acc_wire [0:15][0:15];        // Accumulator routing

    genvar r, c;
    generate
        for (r = 0; r < 16; r = r + 1) begin : g_row
            for (c = 0; c < 16; c = c + 1) begin : g_col
                // Boundary: external inputs on edges, neighbor outputs internally
                wire signed [7:0] pe_left_in = (c == 0) ? left_array[r] : left_wire[r][c-1];
                wire signed [7:0] pe_top_in = (r == 0) ? top_array[c] : top_wire[r-1][c];
                wire signed [31:0] pe_acc_in = (r == 0) ? 32'sd0 : acc_wire[r-1][c];   // Top PE accumulator on drain

                pe u_pe (
                    .clk (clk),
                    .resetn (resetn),
                    .en (en),
                    .drain (drain),
                    .clear (clear),
                    .left_in (pe_left_in),
                    .top_in (pe_top_in),
                    .acc_in (pe_acc_in),
                    .right_out (left_wire[r][c]),
                    .bottom_out (top_wire[r][c]),
                    .acc_out (acc_wire[r][c])
                );

                if (r == 15) begin : g_out
                    assign acc_out_array[c] = acc_wire[15][c];
                end

            end
        end
    endgenerate

endmodule
