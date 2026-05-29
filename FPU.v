/*
| Port       | Dir | Width | Description       
| ---------- | --- | ----- | ----------------- 
| i_start    | in  | 1     | control이 보낸 start 
| i_weight   | in  | 9     |                   
| i_input    | in  | 9     |                   
| o_result   | out | 9     |                         
*/

`timescale 1ns / 1ps

module FPU (
    // input            i_start,
    input  [8:0]     i_weight,
    input  [8:0]     i_input,
    output reg [8:0] o_result
);

wire sign_weight = i_weight [8];
wire sign_input  = i_input  [8];
wire sign_out    = sign_weight ^ sign_input;

// 1. 각 weight와 input의 exp/mant field 분리
// E5M3: S.EEEEE.MMM
//     [8] [7:3] [2:0]
wire [4:0] exp_weight   = i_weight [7:3]; 
wire [4:0] exp_input    = i_input  [7:3]; 
wire [2:0] mant_weight  = i_weight [2:0];
wire [2:0] mant_input   = i_input  [2:0];

// 2. 특수값 사전 감지
// &exp_weight — exponent 전체가 1이면 true (inf 또는 nan)
// ~|exp_weight — exponent 전체가 0이면 true (zero 또는 subnormal)
// 양쪽 입력 중 하나라도 해당되면 특수값

//wire is_nan_or_inf = (&exp_weight) | (&exp_input);
//wire is_zero = (~|exp_weight) & (~|mant_weight) | (~|exp_input) & (~|mant_input);

// inf
wire weight_is_inf  = (exp_weight==5'b11111) & (mant_weight==3'b000);
wire input_is_inf   = (exp_input ==5'b11111) & (mant_input ==3'b000);
//zero
wire weight_is_zero = (exp_weight==5'b00000) & (mant_weight==3'b000);
wire input_is_zero  = (exp_input ==5'b00000) & (mant_input ==3'b000);
//nan
wire weight_is_nan  = (exp_weight==5'b11111) & (mant_weight!=3'b000);
wire input_is_nan   = (exp_input ==5'b11111) & (mant_input !=3'b000);



// 3. Exponent 덧셈
// 5bit+5bit = 6bit --> signed로 표현 위해 7bit
wire signed [6:0] exp_added = $signed({2'd0, exp_weight}) + $signed({2'd0, exp_input}) - 7'sd15;

reg [2:0] mant_final;
reg       exp_adj;

always @(*) begin
    case ({mant_weight, mant_input})
        // mant_w=000
        6'b000_000: {exp_adj, mant_final} = 4'b0_000;
        6'b000_001: {exp_adj, mant_final} = 4'b0_001;
        6'b000_010: {exp_adj, mant_final} = 4'b0_010;
        6'b000_011: {exp_adj, mant_final} = 4'b0_011;
        6'b000_100: {exp_adj, mant_final} = 4'b0_100;
        6'b000_101: {exp_adj, mant_final} = 4'b0_101;
        6'b000_110: {exp_adj, mant_final} = 4'b0_110;
        6'b000_111: {exp_adj, mant_final} = 4'b0_111;
        // mant_w=001
        6'b001_000: {exp_adj, mant_final} = 4'b0_001;
        6'b001_001: {exp_adj, mant_final} = 4'b0_010;
        6'b001_010: {exp_adj, mant_final} = 4'b0_011;
        6'b001_011: {exp_adj, mant_final} = 4'b0_100;
        6'b001_100: {exp_adj, mant_final} = 4'b0_110;
        6'b001_101: {exp_adj, mant_final} = 4'b0_111;
        6'b001_110: {exp_adj, mant_final} = 4'b1_000;
        6'b001_111: {exp_adj, mant_final} = 4'b1_000;
        // mant_w=010
        6'b010_000: {exp_adj, mant_final} = 4'b0_010;
        6'b010_001: {exp_adj, mant_final} = 4'b0_011;
        6'b010_010: {exp_adj, mant_final} = 4'b0_100;
        6'b010_011: {exp_adj, mant_final} = 4'b0_110;
        6'b010_100: {exp_adj, mant_final} = 4'b0_111;
        6'b010_101: {exp_adj, mant_final} = 4'b1_000;
        6'b010_110: {exp_adj, mant_final} = 4'b1_001;
        6'b010_111: {exp_adj, mant_final} = 4'b1_001;
        // mant_w=011
        6'b011_000: {exp_adj, mant_final} = 4'b0_011;
        6'b011_001: {exp_adj, mant_final} = 4'b0_100;
        6'b011_010: {exp_adj, mant_final} = 4'b0_110;
        6'b011_011: {exp_adj, mant_final} = 4'b0_111;
        6'b011_100: {exp_adj, mant_final} = 4'b1_000;
        6'b011_101: {exp_adj, mant_final} = 4'b1_001;
        6'b011_110: {exp_adj, mant_final} = 4'b1_010;
        6'b011_111: {exp_adj, mant_final} = 4'b1_010;
        // mant_w=100
        6'b100_000: {exp_adj, mant_final} = 4'b0_100;
        6'b100_001: {exp_adj, mant_final} = 4'b0_110;
        6'b100_010: {exp_adj, mant_final} = 4'b0_111;
        6'b100_011: {exp_adj, mant_final} = 4'b1_000;
        6'b100_100: {exp_adj, mant_final} = 4'b1_001;
        6'b100_101: {exp_adj, mant_final} = 4'b1_010;
        6'b100_110: {exp_adj, mant_final} = 4'b1_010;
        6'b100_111: {exp_adj, mant_final} = 4'b1_011;
        // mant_w=101
        6'b101_000: {exp_adj, mant_final} = 4'b0_101;
        6'b101_001: {exp_adj, mant_final} = 4'b0_111;
        6'b101_010: {exp_adj, mant_final} = 4'b1_000;
        6'b101_011: {exp_adj, mant_final} = 4'b1_001;
        6'b101_100: {exp_adj, mant_final} = 4'b1_010;
        6'b101_101: {exp_adj, mant_final} = 4'b1_011;
        6'b101_110: {exp_adj, mant_final} = 4'b1_011;
        6'b101_111: {exp_adj, mant_final} = 4'b1_100;
        // mant_w=110
        6'b110_000: {exp_adj, mant_final} = 4'b0_110;
        6'b110_001: {exp_adj, mant_final} = 4'b1_000;
        6'b110_010: {exp_adj, mant_final} = 4'b1_001;
        6'b110_011: {exp_adj, mant_final} = 4'b1_010;
        6'b110_100: {exp_adj, mant_final} = 4'b1_010;
        6'b110_101: {exp_adj, mant_final} = 4'b1_011;
        6'b110_110: {exp_adj, mant_final} = 4'b1_100;
        6'b110_111: {exp_adj, mant_final} = 4'b1_101;
        // mant_w=111
        6'b111_000: {exp_adj, mant_final} = 4'b0_111;
        6'b111_001: {exp_adj, mant_final} = 4'b1_000;
        6'b111_010: {exp_adj, mant_final} = 4'b1_001;
        6'b111_011: {exp_adj, mant_final} = 4'b1_010;
        6'b111_100: {exp_adj, mant_final} = 4'b1_011;
        6'b111_101: {exp_adj, mant_final} = 4'b1_100;
        6'b111_110: {exp_adj, mant_final} = 4'b1_101;
        6'b111_111: {exp_adj, mant_final} = 4'b1_110;
        default:    {exp_adj, mant_final} = 4'b0_000;
    endcase
end

wire signed [6:0] exp_final = exp_added + {6'd0, exp_adj};

// 8. overflow/underflow 처리 (exp)
// E5M3에서 max normal: S.11110.111 --> exp는 최대 30.
wire overflow  = (exp_final >  7'sd30);
wire underflow = (exp_final <= 7'sd0 );

// 9. 출력 값 정의 
wire [8:0] inf_val    = {sign_out, 5'b11111, 3'b000};
wire [8:0] zero_val   = {sign_out, 5'b00000, 3'b000};
wire [8:0] nan_val    = {sign_out, 5'b11111, 3'b001};
wire [8:0] normal_val = {sign_out, exp_final [4:0], mant_final [2:0]};

// 10. 출력
/*
always @(*) begin
    if (i_start) begin
        if (is_nan_or_inf || overflow)
            o_result = nan_val;
        else if (is_zero || underflow)
            o_result = zero_val;
        else
            o_result = normal_val;
    end else begin
        o_result = 9'd0;
    end
end */

always @(*) begin
        if (weight_is_nan || input_is_nan) begin
            o_result = nan_val;
        end else if ((weight_is_inf && input_is_zero) || (weight_is_zero && input_is_inf)) begin
            o_result = nan_val;
        end else if (weight_is_inf || input_is_inf) begin
            o_result = inf_val;
        end else if (weight_is_zero || input_is_zero) begin
            o_result = zero_val;
        end else if (overflow) begin
            o_result = inf_val;
        end else if (underflow) begin
            o_result = zero_val;
        end else begin
          o_result = normal_val;
        end
    end
 
endmodule