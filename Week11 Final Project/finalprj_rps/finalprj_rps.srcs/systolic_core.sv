`timescale 1ns / 1ps

module systolic_core (
    input  wire clk,
    input  wire resetn,

    input  wire pe_en,                           // Enable PE computation
    input  wire pe_clear,                        // Reset accumulators for new tile
    input  wire pe_drain,                        // Shift accumulators to post-processor

    input  wire signed [7:0] left_in [0:15],     // Tile A rows
    input  wire signed [7:0] top_in [0:15],      // Tile B cols

    input  wire pp_valid_in,                     // Latch bottom row accumulators
    input  wire [31:0] pp_scaler,                // Quantization scale factor

    output logic signed [31:0] acc_out [0:15],   // Raw accumulator outputs (debug)
    output logic pp_valid_out,                   // Quantized result ready (3 cycles)
    output logic signed [7:0] pp_data [0:15]     // Quantized int8 logits
);

    // 16x16 PE array: computes tile_A * tile_B, accumulates across k-tiles
    pe_array u_pe_arr (
        .clk (clk),
        .resetn (resetn),
        .en (pe_en),
        .drain (pe_drain),
        .clear (pe_clear),
        .left_array (left_in),
        .top_array (top_in),
        .acc_out_array (acc_out)
    );

    // 3-stage pipeline: ReLU -> scale -> round/saturate to int8
    post_proc u_post_proc (
        .clk (clk),
        .resetn (resetn),
        .valid_in (pp_valid_in),
        .acc_in (acc_out),
        .scaler (pp_scaler),
        .valid_out (pp_valid_out),
        .data_out (pp_data)
    );

endmodule
