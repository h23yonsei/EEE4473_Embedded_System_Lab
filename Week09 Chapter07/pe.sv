module pe (
    // control
    input clk,
    input resetn,
    input save_weight,
    // data in
    input signed [7:0] data_in,
    input signed [7:0] weight_in,
    input signed [17:0] acc_in,
    // data out
    output reg signed [7:0] data_out,
    output reg signed [7:0] weight_out,
    output reg signed [17:0] acc_out
);
    reg has_weight;
    reg signed [7:0] internal_weight;

    always @(posedge clk or negedge resetn) begin
        // reseting case
        if (!resetn) begin
            // data out
            data_out <= 8'd0;
            weight_out <= 8'd0;
            acc_out <= 18'd0;
            // internal reg
            internal_weight <= 8'd0;
            has_weight <= 1'd0;
        end
        // working case
        else begin
            data_out <= data_in;
            weight_out <= weight_in;
            // lock weight
            if (save_weight && !has_weight) begin
                internal_weight <= weight_in;
                has_weight <= 1'd1;
                acc_out <= acc_in;
            end
            // post-locking weight
            if(has_weight) begin
                acc_out <= acc_in + (data_in * internal_weight);
            end
            // pre-locking weight
            else begin
                acc_out <= acc_in;
            end
        end
    end
endmodule