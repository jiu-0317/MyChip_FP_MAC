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


//zero
wire weight_is_zero = (exp_weight==5'b00000) & (mant_weight==3'b000);
wire input_is_zero  = (exp_input ==5'b00000) & (mant_input ==3'b000);
//nan or inf
wire weight_is_nan_or_inf  = (exp_weight==5'b11111);
wire input_is_nan_or_inf   = (exp_input ==5'b11111);



// 3. Exponent 덧셈
wire signed [6:0] exp_added = $signed({2'd0, exp_weight}) + $signed({2'd0, exp_input}) - 7'sd15;

// 4. Mantissa LUT (곱셈 + 정규화 + 라운딩 + 오버플로우 처리 통합)
wire [2:0] mant_final;
wire       exp_delta;

mant_mult_lut u_mant_lut (
    .mant_a     (mant_weight),
    .mant_b     (mant_input),
    .mant_final (mant_final),
    .exp_delta  (exp_delta)
);

// 5. Exponent 최종 계산
wire signed [6:0] exp_final = exp_added + (exp_delta ? 7'sd1 : 7'sd0);

// 6. overflow/underflow 처리
wire overflow  = (exp_final >  7'sd30);
wire underflow = (exp_final <= 7'sd0 );

// 7. 출력 값 정의
wire [8:0] zero_val   = {sign_out, 5'b00000, 3'b000};
wire [8:0] nan_val    = {sign_out, 5'b11111, 3'b001};
wire [8:0] normal_val = {sign_out, exp_final [4:0], mant_final [2:0]};

// 8. 출력
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
        if (weight_is_nan_or_inf || input_is_nan_or_inf) begin
            o_result = nan_val;
        end else if (weight_is_zero || input_is_zero) begin
            o_result = zero_val;
        end else if (overflow) begin
            o_result = nan_val;
        end else if (underflow) begin
            o_result = zero_val;
        end else begin
          o_result = normal_val;
        end
    end
 
endmodule