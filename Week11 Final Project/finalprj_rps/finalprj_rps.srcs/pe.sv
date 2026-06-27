`timescale 1ns / 1ps

module pe (
    input  wire clk,
    input  wire resetn,

    input  wire en,                              // Enable computation
    input  wire drain,                           // Shift accumulator down instead of MAC
    input  wire clear,                           // Start fresh accumulation (first k-tile)

    input  wire signed [7:0] left_in,            // From left neighbor (horizontal shift)
    input  wire signed [7:0] top_in,             // From top neighbor (vertical shift)
    input  wire signed [31:0] acc_in,            // From top PE (drain path)

    output wire signed [7:0] right_out,          // To right neighbor
    output wire signed [7:0] bottom_out,         // To bottom neighbor
    output wire signed [31:0] acc_out            // To bottom PE or post-processor
);

    logic signed [7:0] left_reg;       // Pipelined left input for systolic dataflow
    logic signed [7:0] top_reg;        // Pipelined top input for systolic dataflow
    logic signed [15:0] mul_reg;       // Registered product: splits multiply and accumulate timing paths
    logic signed [31:0] acc;           // Accumulator for partial sums

    wire signed [15:0] mul;            // 8x8 multiply result
    wire signed [31:0] signed_mul;     // Sign-extend to 32 bits

    assign mul = left_reg * top_reg;
    assign signed_mul = {{16{mul_reg[15]}}, mul_reg};

    assign right_out = left_reg;
    assign bottom_out = top_reg;
    assign acc_out = acc;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            left_reg <= 8'sd0;
            top_reg <= 8'sd0;
            mul_reg <= 16'sd0;
            acc <= 32'sd0;
        end else if (en) begin
            if (drain)  // Drain mode: propagate accumulator down to next PE
                acc <= acc_in;
            else begin  // Compute mode: MAC operation
                left_reg <= left_in;      // Pipeline inputs for next cycle
                top_reg <= top_in;
                mul_reg <= mul;           // Register product before accumulate
                if (clear)                // First k-tile: start accumulation
                    acc <= signed_mul;
                else                      // Subsequent k-tiles: accumulate products
                    acc <= acc + signed_mul;
            end
        end
    end

endmodule
