`timescale 1ns / 1ps

module post_proc #(
    parameter int SIZE = 16
)(
    input  wire clk,
    input  wire resetn,

    input  wire valid_in,
    input  wire signed [31:0] acc_in [0:SIZE-1],  // PE array bottom-row accumulators
    input  wire [31:0] scaler,                     // M*2^32 quantization factor per layer

    output logic valid_out,                        // Result valid (3 cycles after valid_in)
    output logic signed [7:0] data_out [0:SIZE-1] // Quantized int8 logits
);

    logic s1_valid;                      // Stage 1 valid (ReLU)
    logic [31:0] s1_relu [0:SIZE-1];     // ReLU output (zero negatives)

    logic s2_valid;                      // Stage 2 valid (scale)
    logic [63:0] s2_prod [0:SIZE-1];     // 32*32 multiply result

    logic [31:0] scaler_lane [0:SIZE-1]; // Cached scaler per lane

    // Sequential logic: pipeline registers and computations
    // 1. ReLU
    // 2. Scale
    // 3. Round and saturate to int8
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin  // reset all pipeline registers and outputs
            s1_valid <= 1'b0;
            s2_valid <= 1'b0;
            valid_out <= 1'b0;

            for (int i = 0; i < SIZE; i++) begin
                scaler_lane[i] <= 32'd0;
                s1_relu[i] <= 32'd0;
                s2_prod[i] <= 64'd0;
                data_out[i] <= 8'sd0;
            end
        end else begin
            if (scaler_lane[0] != scaler) begin // update scaler cache if it changes (by layer)
                for (int i = 0; i < SIZE; i++) begin
                    scaler_lane[i] <= scaler;   // cache the scaler
                end
            end

            // Stage 1: ReLU
            s1_valid <= valid_in;
            if (valid_in) begin
                for (int i = 0; i < SIZE; i++) begin
                    s1_relu[i] <= acc_in[i][31] ? 32'd0 : acc_in[i];  // if signed bit is 1(negative), ReLU outputs 0; else pass through signed value
                end
            end

            // Stage 2: Scale
            s2_valid <= s1_valid;
            if (s1_valid) begin
                for (int i = 0; i < SIZE; i++) begin
                    s2_prod[i] <= s1_relu[i] * scaler_lane[i];  // multiply ReLU output by scaler; result is 64-bit
                end
            end

            // Stage 3: Round
            valid_out <= s2_valid;
            if (s2_valid) begin
                for (int i = 0; i < SIZE; i++) begin
                    logic [32:0] rounded;
                    rounded = {1'b0, s2_prod[i][63:32]} + s2_prod[i][31];  // add the 31st bit for rounding, and keep 33 bits for saturation check
                    if (|rounded[32:7]) // if any of the upper bits beyond 7 are set, it means the value exceeds the int8 range
                        data_out[i] <= 8'sd127;                            // Saturate to 127
                    else
                        data_out[i] <= signed'({1'b0, rounded[6:0]});      // otherwise, take the lower 7 bits as the int8 result (with sign bit)
                end
            end
        end
    end

endmodule
