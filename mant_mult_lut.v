`timescale 1ns / 1ps

module mant_mult_lut (
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output reg [7:0] product
);

    always @(*) begin
        case ({mant_a, mant_b})
            // mant_a=000 (1.000=8)
            6'b000_000: product = 8'd64;   // 8*8
            6'b000_001: product = 8'd72;   // 8*9
            6'b000_010: product = 8'd80;   // 8*10
            6'b000_011: product = 8'd88;   // 8*11
            6'b000_100: product = 8'd96;   // 8*12
            6'b000_101: product = 8'd104;  // 8*13
            6'b000_110: product = 8'd112;  // 8*14
            6'b000_111: product = 8'd120;  // 8*15
            // mant_a=001 (1.001=9)
            6'b001_000: product = 8'd72;   // 9*8
            6'b001_001: product = 8'd81;   // 9*9
            6'b001_010: product = 8'd90;   // 9*10
            6'b001_011: product = 8'd99;   // 9*11
            6'b001_100: product = 8'd108;  // 9*12
            6'b001_101: product = 8'd117;  // 9*13
            6'b001_110: product = 8'd126;  // 9*14
            6'b001_111: product = 8'd135;  // 9*15
            // mant_a=010 (1.010=10)
            6'b010_000: product = 8'd80;   // 10*8
            6'b010_001: product = 8'd90;   // 10*9
            6'b010_010: product = 8'd100;  // 10*10
            6'b010_011: product = 8'd110;  // 10*11
            6'b010_100: product = 8'd120;  // 10*12
            6'b010_101: product = 8'd130;  // 10*13
            6'b010_110: product = 8'd140;  // 10*14
            6'b010_111: product = 8'd150;  // 10*15
            // mant_a=011 (1.011=11)
            6'b011_000: product = 8'd88;   // 11*8
            6'b011_001: product = 8'd99;   // 11*9
            6'b011_010: product = 8'd110;  // 11*10
            6'b011_011: product = 8'd121;  // 11*11
            6'b011_100: product = 8'd132;  // 11*12
            6'b011_101: product = 8'd143;  // 11*13
            6'b011_110: product = 8'd154;  // 11*14
            6'b011_111: product = 8'd165;  // 11*15
            // mant_a=100 (1.100=12)
            6'b100_000: product = 8'd96;   // 12*8
            6'b100_001: product = 8'd108;  // 12*9
            6'b100_010: product = 8'd120;  // 12*10
            6'b100_011: product = 8'd132;  // 12*11
            6'b100_100: product = 8'd144;  // 12*12
            6'b100_101: product = 8'd156;  // 12*13
            6'b100_110: product = 8'd168;  // 12*14
            6'b100_111: product = 8'd180;  // 12*15
            // mant_a=101 (1.101=13)
            6'b101_000: product = 8'd104;  // 13*8
            6'b101_001: product = 8'd117;  // 13*9
            6'b101_010: product = 8'd130;  // 13*10
            6'b101_011: product = 8'd143;  // 13*11
            6'b101_100: product = 8'd156;  // 13*12
            6'b101_101: product = 8'd169;  // 13*13
            6'b101_110: product = 8'd182;  // 13*14
            6'b101_111: product = 8'd195;  // 13*15
            // mant_a=110 (1.110=14)
            6'b110_000: product = 8'd112;  // 14*8
            6'b110_001: product = 8'd126;  // 14*9
            6'b110_010: product = 8'd140;  // 14*10
            6'b110_011: product = 8'd154;  // 14*11
            6'b110_100: product = 8'd168;  // 14*12
            6'b110_101: product = 8'd182;  // 14*13
            6'b110_110: product = 8'd196;  // 14*14
            6'b110_111: product = 8'd210;  // 14*15
            // mant_a=111 (1.111=15)
            6'b111_000: product = 8'd120;  // 15*8
            6'b111_001: product = 8'd135;  // 15*9
            6'b111_010: product = 8'd150;  // 15*10
            6'b111_011: product = 8'd165;  // 15*11
            6'b111_100: product = 8'd180;  // 15*12
            6'b111_101: product = 8'd195;  // 15*13
            6'b111_110: product = 8'd210;  // 15*14
            6'b111_111: product = 8'd225;  // 15*15
            default:    product = 8'd0;
        endcase
    end

endmodule
