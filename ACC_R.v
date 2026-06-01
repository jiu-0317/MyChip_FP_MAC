/*
ACC에서 받아온 E5M3를 mode에 맞게 E4M3 / E5M2로 변환한다.

| Port          | Dir | Width | Description        
| ------------- | --- | ----- | ------------------ 
| i_clk, i_rstn | in  | 1     |                    
| i_wen         | in  | 1     | control에서 보낸 wen   
| i_mode        | in  | 1     | 0: E4M3 | 1: E5M2 
| i_data        | in  | 9     | ACC 결과             
| o_data        | out | 8     | 축소된 포맷                         
*/

module ACC_R(
    input            i_clk,
    input            i_rstn,
    input            i_wen,
    input            i_mode,
    input      [8:0] i_data,
    output reg [7:0] o_data
);

wire [4:0] exp_raw;
wire signed [4:0] exp_e4m3; // actual exp --> [3:0], signed for underflow

assign exp_raw = i_data[7:3]; // i_data에서 exp 추출
assign exp_e4m3 = exp_raw - 5'sd8; // bias 수정 (15-->7, -8)

reg  [7:0] e4m3;
wire [7:0] e5m2;

// E4M3 변환, underflow는 NaN으로 처리
always @(*) begin
    if (exp_e4m3<=0) begin
        e4m3 = {i_data[8], 4'b0000, 3'b000}; // 극소값 및 0 --> zero saturation
    end else begin
        e4m3 = {i_data[8], exp_e4m3[3:0], i_data[2:0]}; // normal
    end
end

// E5M2 변환
assign e5m2 = i_data[8:1]; // mantissa lsb 버림

always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
        o_data  <= 8'd0;
    end else if (i_wen && (i_mode == 0)) begin // mode : E4M3
        o_data  <= e4m3;
    end else if (i_wen && (i_mode == 1)) begin // mode : E5M2
        o_data  <= e5m2;
    end else begin 
        o_data  <= 8'd0;
    end
end

endmodule 