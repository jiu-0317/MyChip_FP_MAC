`timescale 1ns / 1ps

module mant_mult_lut (
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output reg [2:0] mant_final,
    output reg       exp_delta
);

    always @(*) begin
        case ({mant_a, mant_b})
            // mant_a=000 (1.000 * 1.xxx)
            6'b000_000: {exp_delta, mant_final} = 4'b0_000;  // 8*8  =64
            6'b000_001: {exp_delta, mant_final} = 4'b0_001;  // 8*9  =72
            6'b000_010: {exp_delta, mant_final} = 4'b0_010;  // 8*10 =80
            6'b000_011: {exp_delta, mant_final} = 4'b0_011;  // 8*11 =88
            6'b000_100: {exp_delta, mant_final} = 4'b0_100;  // 8*12 =96
            6'b000_101: {exp_delta, mant_final} = 4'b0_101;  // 8*13 =104
            6'b000_110: {exp_delta, mant_final} = 4'b0_110;  // 8*14 =112
            6'b000_111: {exp_delta, mant_final} = 4'b0_111;  // 8*15 =120
            // mant_a=001 (1.001 * 1.xxx)
            6'b001_000: {exp_delta, mant_final} = 4'b0_001;  // 9*8  =72
            6'b001_001: {exp_delta, mant_final} = 4'b0_010;  // 9*9  =81
            6'b001_010: {exp_delta, mant_final} = 4'b0_011;  // 9*10 =90
            6'b001_011: {exp_delta, mant_final} = 4'b0_100;  // 9*11 =99
            6'b001_100: {exp_delta, mant_final} = 4'b0_110;  // 9*12 =108
            6'b001_101: {exp_delta, mant_final} = 4'b0_111;  // 9*13 =117
            6'b001_110: {exp_delta, mant_final} = 4'b1_000;  // 9*14 =126
            6'b001_111: {exp_delta, mant_final} = 4'b1_000;  // 9*15 =135
            // mant_a=010 (1.010 * 1.xxx)
            6'b010_000: {exp_delta, mant_final} = 4'b0_010;  // 10*8 =80
            6'b010_001: {exp_delta, mant_final} = 4'b0_011;  // 10*9 =90
            6'b010_010: {exp_delta, mant_final} = 4'b0_100;  // 10*10=100
            6'b010_011: {exp_delta, mant_final} = 4'b0_110;  // 10*11=110
            6'b010_100: {exp_delta, mant_final} = 4'b0_111;  // 10*12=120
            6'b010_101: {exp_delta, mant_final} = 4'b1_000;  // 10*13=130
            6'b010_110: {exp_delta, mant_final} = 4'b1_010;  // 10*14=140
            6'b010_111: {exp_delta, mant_final} = 4'b1_001;  // 10*15=150
            // mant_a=011 (1.011 * 1.xxx)
            6'b011_000: {exp_delta, mant_final} = 4'b0_011;  // 11*8 =88
            6'b011_001: {exp_delta, mant_final} = 4'b0_100;  // 11*9 =99
            6'b011_010: {exp_delta, mant_final} = 4'b0_110;  // 11*10=110
            6'b011_011: {exp_delta, mant_final} = 4'b0_111;  // 11*11=121
            6'b011_100: {exp_delta, mant_final} = 4'b1_000;  // 11*12=132
            6'b011_101: {exp_delta, mant_final} = 4'b1_010;  // 11*13=143
            6'b011_110: {exp_delta, mant_final} = 4'b1_010;  // 11*14=154
            6'b011_111: {exp_delta, mant_final} = 4'b1_010;  // 11*15=165
            // mant_a=100 (1.100 * 1.xxx)
            6'b100_000: {exp_delta, mant_final} = 4'b0_100;  // 12*8 =96
            6'b100_001: {exp_delta, mant_final} = 4'b0_110;  // 12*9 =108
            6'b100_010: {exp_delta, mant_final} = 4'b0_111;  // 12*10=120
            6'b100_011: {exp_delta, mant_final} = 4'b1_000;  // 12*11=132
            6'b100_100: {exp_delta, mant_final} = 4'b1_001;  // 12*12=144
            6'b100_101: {exp_delta, mant_final} = 4'b1_010;  // 12*13=156
            6'b100_110: {exp_delta, mant_final} = 4'b1_010;  // 12*14=168
            6'b100_111: {exp_delta, mant_final} = 4'b1_011;  // 12*15=180
            // mant_a=101 (1.101 * 1.xxx)
            6'b101_000: {exp_delta, mant_final} = 4'b0_101;  // 13*8 =104
            6'b101_001: {exp_delta, mant_final} = 4'b0_111;  // 13*9 =117
            6'b101_010: {exp_delta, mant_final} = 4'b1_000;  // 13*10=130
            6'b101_011: {exp_delta, mant_final} = 4'b1_010;  // 13*11=143
            6'b101_100: {exp_delta, mant_final} = 4'b1_010;  // 13*12=156
            6'b101_101: {exp_delta, mant_final} = 4'b1_011;  // 13*13=169
            6'b101_110: {exp_delta, mant_final} = 4'b1_011;  // 13*14=182
            6'b101_111: {exp_delta, mant_final} = 4'b1_100;  // 13*15=195
            // mant_a=110 (1.110 * 1.xxx)
            6'b110_000: {exp_delta, mant_final} = 4'b0_110;  // 14*8 =112
            6'b110_001: {exp_delta, mant_final} = 4'b1_000;  // 14*9 =126
            6'b110_010: {exp_delta, mant_final} = 4'b1_010;  // 14*10=140
            6'b110_011: {exp_delta, mant_final} = 4'b1_010;  // 14*11=154
            6'b110_100: {exp_delta, mant_final} = 4'b1_010;  // 14*12=168
            6'b110_101: {exp_delta, mant_final} = 4'b1_011;  // 14*13=182
            6'b110_110: {exp_delta, mant_final} = 4'b1_100;  // 14*14=196
            6'b110_111: {exp_delta, mant_final} = 4'b1_101;  // 14*15=210
            // mant_a=111 (1.111 * 1.xxx)
            6'b111_000: {exp_delta, mant_final} = 4'b0_111;  // 15*8 =120
            6'b111_001: {exp_delta, mant_final} = 4'b1_000;  // 15*9 =135
            6'b111_010: {exp_delta, mant_final} = 4'b1_001;  // 15*10=150
            6'b111_011: {exp_delta, mant_final} = 4'b1_010;  // 15*11=165
            6'b111_100: {exp_delta, mant_final} = 4'b1_011;  // 15*12=180
            6'b111_101: {exp_delta, mant_final} = 4'b1_100;  // 15*13=195
            6'b111_110: {exp_delta, mant_final} = 4'b1_101;  // 15*14=210
            6'b111_111: {exp_delta, mant_final} = 4'b1_110;  // 15*15=225
            default:    {exp_delta, mant_final} = 4'b0_000;
        endcase
    end

endmodule
