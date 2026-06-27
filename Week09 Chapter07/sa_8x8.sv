module sa_8x8 (
    // control
    input clk,
    input resetn,
    input save_weight,
    // data input
    input reg signed [7:0] din_in  [0:7], 
    input reg signed [7:0] win_in  [0:7],
    // data output 
    output reg signed [17:0] acc_out [0:7]  
);
    // wires to connect PEs
    wire signed [7:0] data_flow [0:7][0:8]; 
    wire signed [7:0] weight_flow [0:8][0:7]; 
    wire signed [17:0] acc_flow [0:8][0:7]; 
    // generate 64 PEs
    genvar i, j;
    generate
        for (i = 0; i < 8; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                pe u_pe (
                    // control
                    .clk(clk),
                    .resetn(resetn),
                    .save_weight(save_weight),
                    // data input
                    .data_in(data_flow[i][j]),
                    .weight_in(weight_flow[i][j]),
                    .acc_in(acc_flow[i][j]),
                    // data output
                    .data_out(data_flow[i][j+1]),
                    .weight_out(weight_flow[i+1][j]),
                    .acc_out(acc_flow[i+1][j])
                );
            end
        end
    endgenerate
    // setup boundary PEs
    generate
        for (i = 0; i < 8; i = i + 1) begin
            assign data_flow[i][0] = din_in[i];      
            assign weight_flow[0][i] = win_in[i];      
            assign acc_flow[0][i] = 18'sd0;
            assign acc_out[i] = acc_flow[8][i]; 
        end
    endgenerate
endmodule