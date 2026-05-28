/*
ACC 에서 해당 FP_adder를 instanciation하여 사용한다.

| Port     | Dir | Width | Description |
| -------- | --- | ----- | ----------- |
| i_a      | in  | 9     | 연산 대상       |
| i_b      | in  | 9     | 연산 대상       |
| o_result | out | 9     | 연산 결과       |
*/

`timescale 1ns / 1ps

module ACC_adder (
    input      [8:0] i_a,
    input      [8:0] i_b,
    output reg [8:0] o_result
);

// 0) 필드 분리 / 특수값 감지 / mantissa leading 1 복원
wire sign_a = i_a [8];
wire sign_b = i_b [8];
wire [4:0] exp_a = i_a [7:3];
wire [4:0] exp_b = i_b [7:3];
wire [2:0] mant_a = i_a [2:0];
wire [2:0] mant_b = i_b [2:0];

wire a_is_nan  = (exp_a == 5'b11111) & (mant_a != 3'b000);
wire b_is_nan  = (exp_b == 5'b11111) & (mant_b != 3'b000);
wire a_is_inf  = (exp_a == 5'b11111) & (mant_a == 3'b000);
wire b_is_inf  = (exp_b == 5'b11111) & (mant_b == 3'b000);
wire a_is_zero = (exp_a == 5'b00000) & (mant_a == 3'b000);
wire b_is_zero = (exp_b == 5'b00000) & (mant_b == 3'b000);

wire [3:0] full_mant_a = {1'b1, mant_a};
wire [3:0] full_mant_b = {1'b1, mant_b};

// 1) a와 b의 exp 비교
wire a_is_larger = (exp_a > exp_b) || ((exp_a == exp_b) && (mant_a >= mant_b));
wire [4:0] exp_large = a_is_larger ? exp_a : exp_b;
wire [4:0] exp_diff  = a_is_larger ? (exp_a-exp_b) : (exp_b-exp_a);

// 1.1) exp의 크기에 따라 sign과 mant 구분
wire       sign_large = a_is_larger ? sign_a : sign_b;
wire       sign_small = a_is_larger ? sign_b : sign_a;
wire [3:0] mant_large = a_is_larger ? full_mant_a : full_mant_b;
wire [3:0] mant_small = a_is_larger ? full_mant_b : full_mant_a;

// 2) exp_diff 만큼 mant_small을 right shift
wire [3:0] mant_small_shifted = (exp_diff >= 5'd4) ? 4'd0 : (mant_small >> exp_diff);
// 위 코드는 mant_small_shifted = mant_small >> exp_diff 와 동일
// but barrel shifter 크기 줄일 수 있게 명시적으로 작성함.
// (right shift를 4번 이상 하면 mant는 무조건 000.)

// 3) shift된 mant_small_shifted와 mant_large를 덧셈/뺄센 연산\
// 부호가 같으면 덧셈, 다르면 뺄셈(exp 큰 수-작은 수) 후 부호는 sign_large로 지정
// 연산 결과: XX.XXX (5bit)
wire same_sign = (sign_large == sign_small);
wire [4:0] mant_sum  = {1'b0, mant_large} + {1'b0, mant_small_shifted};
wire [4:0] mant_diff = {1'b0, mant_large} - {1'b0, mant_small_shifted};

wire [4:0] mant_raw = same_sign ? mant_sum : mant_diff;
wire       sign_raw = sign_large;

// 4) Normalization
// mant_raw : XX.XXX
reg signed [5:0] exp_norm; // 음수가 될 수도 있으니 signed로 저장 후 underflow 검사
reg [2:0] mant_norm;

always @(*) begin
    if (mant_raw[4]) begin // 1X.XXX
        exp_norm  = $signed({1'b0, exp_large}) + 6'sd1;
        mant_norm = mant_raw [3:1];
    end else if (mant_raw[3]) begin // 01.XXX
        exp_norm  = exp_large;
        mant_norm = mant_raw [2:0];
    end else if (mant_raw[2]) begin // 00.1XX
        exp_norm  = $signed({1'b0, exp_large}) - 6'sd1;
        mant_norm = {mant_raw[1:0], 1'b0};
    end else if (mant_raw[1]) begin // 00.01X
        exp_norm  = $signed({1'b0, exp_large}) - 6'sd2;
        mant_norm = {mant_raw [0], 2'b00};
    end else if (mant_raw[0]) begin
        exp_norm  = $signed({1'b0, exp_large}) - 6'sd3;
        mant_norm = 3'b000;
    end else begin
        exp_norm = 6'sd0;
        mant_norm = 3'd0;
    end
end

// 5) over/underflow 검사
wire overflow  = (exp_norm >= 6'sd31);
wire underflow = (exp_norm <= 6'sd0);

wire [8:0] inf_val  = {sign_raw, 5'b11111, 3'b000};
wire [8:0] zero_val = {sign_raw, 5'b00000, 3'b000};
wire [8:0] nan_val  = 9'b0_11111_001;
wire [8:0] normal_val = {sign_raw, exp_norm[4:0], mant_norm};

// 6) 결과 출력
always @(*)begin
    if (a_is_nan || b_is_nan) begin
        o_result = nan_val;
    end else if (a_is_inf && b_is_inf && (sign_a != sign_b)) begin
        o_result = nan_val; // +inf + -inf = NaN
    end else if (a_is_inf) begin
        o_result = {sign_a, 5'b11111, 3'b000};
    end else if (b_is_inf) begin
        o_result = {sign_b, 5'b11111, 3'b000};
    end else if (a_is_zero && b_is_zero) begin
        o_result = 9'd0;
    end else if (a_is_zero) begin
        o_result = i_b;
    end else if (b_is_zero) begin
        o_result = i_a;
    end else if (overflow) begin
        o_result = inf_val;
    end else if (underflow) begin
        o_result = zero_val;
    end else begin
      o_result = normal_val;
    end
end

endmodule