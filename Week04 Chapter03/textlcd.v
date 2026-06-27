`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2014/07/28 14:57:38
// Design Name: 
// Module Name: textlcd
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define lcd_blank 8'b00100000
`define lcd_dash 8'b00101101
`define lcd_colon 8'b00111010
`define lcd_comma 8'b00101100
`define lcd_Dot 8'b00101110
`define lcd_0 8'b00110000
`define lcd_1 8'b00110001
`define lcd_2 8'b00110010
`define lcd_3 8'b00110011
`define lcd_4 8'b00110100
`define lcd_5 8'b00110101
`define lcd_6 8'b00110110
`define lcd_7 8'b00110111
`define lcd_8 8'b00111000
`define lcd_9 8'b00111001
`define lcd_a 8'b01000001
`define lcd_b 8'b01000010
`define lcd_c 8'b01000011
`define lcd_d 8'b01000100
`define lcd_e 8'b01000101
`define lcd_f 8'b01000110
`define lcd_g 8'b01000111
`define lcd_h 8'b01001000
`define lcd_i 8'b01001001
`define lcd_j 8'b01001010
`define lcd_k 8'b01001011
`define lcd_l 8'b01001100
`define lcd_m 8'b01001101
`define lcd_n 8'b01001110
`define lcd_o 8'b01001111
`define lcd_p 8'b01010000
`define lcd_q 8'b01010001
`define lcd_r 8'b01010010
`define lcd_s 8'b01010011
`define lcd_t 8'b01010100
`define lcd_u 8'b01010101
`define lcd_v 8'b01010110
`define lcd_w 8'b01010111
`define lcd_x 8'b01011000
`define lcd_y 8'b01011001
`define lcd_z 8'b01011010
`define lcd_under 8'b01011111
`define lcd_s_a 8'b01100001
`define lcd_s_b 8'b01100010
`define lcd_s_c 8'b01100011
`define lcd_s_d 8'b01100100
`define lcd_s_e 8'b01100101
`define lcd_s_f 8'b01100110
`define lcd_s_g 8'b01100111
`define lcd_s_h 8'b01101000
`define lcd_s_i 8'b01101001
`define lcd_s_j 8'b01101010
`define lcd_s_k 8'b01101011
`define lcd_s_l 8'b01101100
`define lcd_s_m 8'b01101101
`define lcd_s_n 8'b01101110
`define lcd_s_o 8'b01101111
`define lcd_s_p 8'b01110000
`define lcd_s_q 8'b01110001
`define lcd_s_r 8'b01110010
`define lcd_s_s 8'b01110011
`define lcd_s_t 8'b01110100
`define lcd_s_u 8'b01110101
`define lcd_s_v 8'b01110110
`define lcd_s_w 8'b01110111
`define lcd_s_x 8'b01111000
`define lcd_s_y 8'b01111001
`define lcd_s_z 8'b01111010
`define add_line_1 8'b10000000
`define add_line_2 8'b11000000
`define add_line_3 8'b10010100
`define add_line_4 8'b11010100


module textlcd(
	resetn,
	
    bram_read_data_p0,
    bram_read_addr_p0,
    bram_read_data_p1,
    bram_read_addr_p1,

	lcdclk,
	lcd_rs,
	lcd_rw,
	lcd_en,
	lcd_data);

input  resetn;

input [31:0] bram_read_data_p0;
output reg [12:0] bram_read_addr_p0;
input [31:0] bram_read_data_p1;
output reg [12:0] bram_read_addr_p1;

input  lcdclk;
output lcd_rs;
output lcd_rw;
output reg lcd_en;
output [7:0] lcd_data;

wire [31:0] reg_a;
wire [31:0] reg_b;
wire [31:0] reg_c;
wire [31:0] reg_d;
wire [31:0] reg_e;
wire [31:0] reg_f;
wire [31:0] reg_g;
wire [31:0] reg_h;
reg [23:0] delay_lcdclk; //clock
reg [15:0] count_lcd;
// lcd_en is declared as an output reg above
reg  [4:0] lcd_mode = 0;
wire [4:0] mode_pwron = 1 ;  // power on
wire [4:0] mode_fnset = 2 ;  // function set
wire [4:0] mode_onoff = 3 ;  // display on/off Control
wire [4:0] mode_entr1 = 4 ;  // 
wire [4:0] mode_entr2 = 5 ;  // 
wire [4:0] mode_entr3 = 6 ;  // 
wire [4:0] mode_seta1 = 7 ;  // set addr 1st line
wire [4:0] mode_wr1st = 8 ;  // Write 1st line
wire [4:0] mode_seta2 = 9 ;  // set addr 2nd line
wire [4:0] mode_wr2nd = 10;  // Write 2nd line
wire [4:0] mode_delay = 11;  // dealy
wire [4:0] mode_actcm = 12;  // user command
reg [9:0] set_data;

// Data read from the BRAM
reg [31:0] local_data[0:7];

// NOTE: For a 32-bit-wide ROM, each read returns 4 ASCII characters.
// If your COE packs bytes as 32'h596F6E73 for "Yons", then the first character
// should be taken from [31:24], matching the write logic below.
assign reg_a = local_data[0];
assign reg_b = local_data[1];
assign reg_c = local_data[2];
assign reg_d = local_data[3];
assign reg_e = local_data[4];
assign reg_f = local_data[5];
assign reg_g = local_data[6];
assign reg_h = local_data[7];

// ------------------------------------------------------------
// BRAM addressing for 32-bit-wide ROM
//   - One address returns 32 bits = 4 ASCII characters.
//   - This design reads 4 words for line 1 and 4 words for line 2.
//   - If you want the 0th word to be "empty", keep LINE1_BASE=1.
//     (i.e., put blanks at word address 0 in your COE).
// ------------------------------------------------------------
localparam integer LINE_CHARS  = 16;
localparam integer WORD_BYTES  = 4;
localparam integer LINE_WORDS  = LINE_CHARS / WORD_BYTES; // 4

localparam [12:0] LINE1_BASE   = 13'd1;
localparam [12:0] LINE2_BASE   = LINE1_BASE + LINE_WORDS; // 5

// Read 8 words total (4 per port) into local_data[] once during init.
// We sample the BRAM data a few cycles after entering each init state
// to avoid any ambiguity about BRAM read latency.
always @(posedge lcdclk) begin
    if (resetn == 0) begin
        bram_read_addr_p0 <= LINE1_BASE;
        bram_read_addr_p1 <= LINE2_BASE;
        local_data[0] <= 32'b0;
        local_data[1] <= 32'b0;
        local_data[2] <= 32'b0;
        local_data[3] <= 32'b0;
        local_data[4] <= 32'b0;
        local_data[5] <= 32'b0;
        local_data[6] <= 32'b0;
        local_data[7] <= 32'b0;
    end else begin
        // Ensure base addresses are applied during the initial power-on state
        if (lcd_mode == mode_pwron && delay_lcdclk == 24'd0) begin
            bram_read_addr_p0 <= LINE1_BASE;
            bram_read_addr_p1 <= LINE2_BASE;
        end

        // Line 1 word 0
        if (lcd_mode == mode_fnset) begin
            if (delay_lcdclk == 24'd10) begin
                local_data[0] <= bram_read_data_p0;
                local_data[4] <= bram_read_data_p1;
            end
            if (delay_lcdclk == 24'd11) begin
                bram_read_addr_p0 <= bram_read_addr_p0 + 13'd1;
                bram_read_addr_p1 <= bram_read_addr_p1 + 13'd1;
            end
        end

        // Line 1 word 1
        if (lcd_mode == mode_onoff) begin
            if (delay_lcdclk == 24'd10) begin
                local_data[1] <= bram_read_data_p0;
                local_data[5] <= bram_read_data_p1;
            end
            if (delay_lcdclk == 24'd11) begin
                bram_read_addr_p0 <= bram_read_addr_p0 + 13'd1;
                bram_read_addr_p1 <= bram_read_addr_p1 + 13'd1;
            end
        end

        // Line 1 word 2
        if (lcd_mode == mode_entr1) begin
            if (delay_lcdclk == 24'd10) begin
                local_data[2] <= bram_read_data_p0;
                local_data[6] <= bram_read_data_p1;
            end
            if (delay_lcdclk == 24'd11) begin
                bram_read_addr_p0 <= bram_read_addr_p0 + 13'd1;
                bram_read_addr_p1 <= bram_read_addr_p1 + 13'd1;
            end
        end

        // Line 1 word 3
        if (lcd_mode == mode_entr2) begin
            if (delay_lcdclk == 24'd10) begin
                local_data[3] <= bram_read_data_p0;
                local_data[7] <= bram_read_data_p1;
            end
            // No need to increment further after the last read for each line.
        end
    end
end


// Counterx2000 & //Counterx40
always @(posedge lcdclk)
begin
	if (resetn == 0)
	begin
        delay_lcdclk <= 0;
        count_lcd <= 0;
        lcd_en <= 1'b0;
    end
    else begin
        // Counterx2000
        if (delay_lcdclk < 1999)
            delay_lcdclk <=  delay_lcdclk + 1;
        else
            delay_lcdclk <= 0;

        // Counterx40
        if (delay_lcdclk == 0) 
        begin
            if (count_lcd < 40)
                count_lcd <= count_lcd + 1;
            else
                count_lcd <= 6;
        end
    
        if (delay_lcdclk == 200)
            lcd_en <= 1'b1;
        else if (delay_lcdclk == 1800)
            lcd_en <= 1'b0;
        end
    end
    
    // decoder switch
    always @(posedge lcdclk)
    begin
        if (resetn == 0)
            lcd_mode <= mode_pwron;
        else 
            begin
                case (count_lcd)
                    0  : lcd_mode <= mode_pwron ;
                    1  : lcd_mode <= mode_fnset ;
                    2  : lcd_mode <= mode_onoff ;
                    3  : lcd_mode <= mode_entr1 ;
                    4  : lcd_mode <= mode_entr2 ;
                    5  : lcd_mode <= mode_entr3 ;
                    6  : lcd_mode <= mode_seta1 ;
                    7  : lcd_mode <= mode_wr1st ;
                    23 : lcd_mode <= mode_seta2 ;
                    24 : lcd_mode <= mode_wr2nd ;
                    40 : lcd_mode <= mode_delay ;
                    41 : lcd_mode <= mode_actcm ;
                    default : begin end 
                endcase    
            end
    end
    assign lcd_rs = set_data[9];
    assign lcd_rw = set_data[8];
    assign lcd_data = set_data[7:0];
    
    // decoder output (combinational): drives lcd_rs/lcd_rw/lcd_data via set_data
    // IMPORTANT: Do NOT increment BRAM addresses or latch BRAM data here.
    //            Those are done synchronously in the BRAM reader block above.
    always @* begin
        if (resetn == 0) begin
            set_data = 10'b0000000000;
        end else begin
            // Default: harmless command (Return Home). Also avoids latch inference.
            set_data = {2'b00, 8'h02};
            case (lcd_mode)
                mode_pwron : set_data = {2'b00, 8'h38};
                mode_fnset : set_data = {2'b00, 8'h38};
                mode_onoff : set_data = {2'b00, 8'h0e};
                mode_entr1 : set_data = {2'b00, 8'h06};
                mode_entr2 : set_data = {2'b00, 8'h02};
                mode_entr3 : set_data = {2'b00, 8'h01};
                mode_seta1 : set_data = {2'b00, 8'h80};

                mode_wr1st : begin
                    // default character: space
                    set_data = {1'b1, 1'b0, 8'h20};
                    case (count_lcd)
                        7  : set_data = {1'b1, 1'b0, reg_a[31:24]};
                        8  : set_data = {1'b1, 1'b0, reg_a[23:16]};
                        9  : set_data = {1'b1, 1'b0, reg_a[15: 8]};
                        10 : set_data = {1'b1, 1'b0, reg_a[7 : 0]};
                        11 : set_data = {1'b1, 1'b0, reg_b[31:24]};
                        12 : set_data = {1'b1, 1'b0, reg_b[23:16]};
                        13 : set_data = {1'b1, 1'b0, reg_b[15: 8]};
                        14 : set_data = {1'b1, 1'b0, reg_b[7 : 0]};
                        15 : set_data = {1'b1, 1'b0, reg_c[31:24]};
                        16 : set_data = {1'b1, 1'b0, reg_c[23:16]};
                        17 : set_data = {1'b1, 1'b0, reg_c[15: 8]};
                        18 : set_data = {1'b1, 1'b0, reg_c[7 : 0]};
                        19 : set_data = {1'b1, 1'b0, reg_d[31:24]};
                        20 : set_data = {1'b1, 1'b0, reg_d[23:16]};
                        21 : set_data = {1'b1, 1'b0, reg_d[15: 8]};
                        22 : set_data = {1'b1, 1'b0, reg_d[7 : 0]};
                        default: begin end
                    endcase
                end

                mode_seta2 : set_data = {2'b00, 8'hc0};
                mode_wr2nd : begin
                    set_data = {1'b1, 1'b0, 8'h20};
                    case (count_lcd)
                        24 : set_data = {1'b1, 1'b0, reg_e[31:24]};
                        25 : set_data = {1'b1, 1'b0, reg_e[23:16]};
                        26 : set_data = {1'b1, 1'b0, reg_e[15: 8]};
                        27 : set_data = {1'b1, 1'b0, reg_e[7 : 0]};
                        28 : set_data = {1'b1, 1'b0, reg_f[31:24]};
                        29 : set_data = {1'b1, 1'b0, reg_f[23:16]};
                        30 : set_data = {1'b1, 1'b0, reg_f[15: 8]};
                        31 : set_data = {1'b1, 1'b0, reg_f[7 : 0]};
                        32 : set_data = {1'b1, 1'b0, reg_g[31:24]};
                        33 : set_data = {1'b1, 1'b0, reg_g[23:16]};
                        34 : set_data = {1'b1, 1'b0, reg_g[15: 8]};
                        35 : set_data = {1'b1, 1'b0, reg_g[7 : 0]};
                        36 : set_data = {1'b1, 1'b0, reg_h[31:24]};
                        37 : set_data = {1'b1, 1'b0, reg_h[23:16]};
                        38 : set_data = {1'b1, 1'b0, reg_h[15: 8]};
                        39 : set_data = {1'b1, 1'b0, reg_h[7 : 0]};
                        default: begin end
                    endcase
                end

                mode_delay : set_data = {2'b00, 8'h02};
                mode_actcm : set_data = {2'b00, 8'h02};
                default : begin end
            endcase
        end
    end

endmodule
