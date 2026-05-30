`timescale 1ns / 1ps

module mant_mult_lut (
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output reg [2:0] mant_final,
    output reg       exp_delta
);

    wire [2:0] hi = (mant_a >= mant_b) ? mant_a : mant_b;
    wire [2:0] lo = (mant_a >= mant_b) ? mant_b : mant_a;

    always @(*) begin
        case ({hi, lo})
            // hi=000
            6'b000_000: {exp_delta, mant_final} = 4'b0_000;  // 8*8  =64
            // hi=001
            6'b001_000: {exp_delta, mant_final} = 4'b0_001;  // 9*8  =72
            6'b001_001: {exp_delta, mant_final} = 4'b0_010;  // 9*9  =81
            // hi=010
            6'b010_000: {exp_delta, mant_final} = 4'b0_010;  // 10*8 =80
            6'b010_001: {exp_delta, mant_final} = 4'b0_011;  // 10*9 =90
            6'b010_010: {exp_delta, mant_final} = 4'b0_100;  // 10*10=100
            // hi=011
            6'b011_000: {exp_delta, mant_final} = 4'b0_011;  // 11*8 =88
            6'b011_001: {exp_delta, mant_final} = 4'b0_100;  // 11*9 =99
            6'b011_010: {exp_delta, mant_final} = 4'b0_110;  // 11*10=110
            6'b011_011: {exp_delta, mant_final} = 4'b0_111;  // 11*11=121
            // hi=100
            6'b100_000: {exp_delta, mant_final} = 4'b0_100;  // 12*8 =96
            6'b100_001: {exp_delta, mant_final} = 4'b0_110;  // 12*9 =108
            6'b100_010: {exp_delta, mant_final} = 4'b0_111;  // 12*10=120
            6'b100_011: {exp_delta, mant_final} = 4'b1_000;  // 12*11=132
            6'b100_100: {exp_delta, mant_final} = 4'b1_001;  // 12*12=144
            // hi=101
            6'b101_000: {exp_delta, mant_final} = 4'b0_101;  // 13*8 =104
            6'b101_001: {exp_delta, mant_final} = 4'b0_111;  // 13*9 =117
            6'b101_010: {exp_delta, mant_final} = 4'b1_000;  // 13*10=130
            6'b101_011: {exp_delta, mant_final} = 4'b1_010;  // 13*11=143
            6'b101_100: {exp_delta, mant_final} = 4'b1_010;  // 13*12=156
            6'b101_101: {exp_delta, mant_final} = 4'b1_011;  // 13*13=169
            // hi=110
            6'b110_000: {exp_delta, mant_final} = 4'b0_110;  // 14*8 =112
            6'b110_001: {exp_delta, mant_final} = 4'b1_000;  // 14*9 =126
            6'b110_010: {exp_delta, mant_final} = 4'b1_010;  // 14*10=140
            6'b110_011: {exp_delta, mant_final} = 4'b1_010;  // 14*11=154
            6'b110_100: {exp_delta, mant_final} = 4'b1_010;  // 14*12=168
            6'b110_101: {exp_delta, mant_final} = 4'b1_011;  // 14*13=182
            6'b110_110: {exp_delta, mant_final} = 4'b1_100;  // 14*14=196
            // hi=111
            6'b111_000: {exp_delta, mant_final} = 4'b0_111;  // 15*8 =120
            6'b111_001: {exp_delta, mant_final} = 4'b1_000;  // 15*9 =135
            6'b111_010: {exp_delta, mant_final} = 4'b1_001;  // 15*10=150
            6'b111_011: {exp_delta, mant_final} = 4'b1_010;  // 15*11=165
            6'b111_100: {exp_delta, mant_final} = 4'b1_011;  // 15*12=180
            6'b111_101: {exp_delta, mant_final} = 4'b1_100;  // 15*13=195
            6'b111_110: {exp_delta, mant_final} = 4'b1_101;  // 15*14=210
            6'b111_111: {exp_delta, mant_final} = 4'b1_110;  // 15*15=225
            default:    {exp_delta, mant_final} = 4'bx_xxx;
        endcase
    end

endmodule
