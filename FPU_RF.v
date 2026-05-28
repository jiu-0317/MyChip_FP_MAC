/*
fpu의 연산 결과를 저장하는 RF.

| Port          | Dir | Width | Description               
| ------------- | --- | ----- | ------------------------- 
| i_clk, i_rstn | in  | 1     |                           
| i_wen         | in  | 1     | control에서 보낸 write enable 
| i_data        | in  | 9x9   |                           
| o_data        | out | 9x9   |                           
| o_all_valid   | out | 1     | control로 보내는 valid        
*/

`timescale 1ns / 1ps

module FPU_RF(
    input            i_clk,
    input            i_rstn,
    input            i_wen,
    input            i_send_start, // 값 전송 시작 신호
    input      [8:0] i_data [8:0],
    output reg [8:0] o_data, // 순차적으로 값 전송
    output reg       o_all_valid
);

reg [8:0] data_reg [8:0];
always @(i_clk) begin
    /*if (!i_rstn) begin
        data_reg[0] <= 9'd0;
        data_reg[1] <= 9'd0;
        data_reg[2] <= 9'd0;
        data_reg[3] <= 9'd0;
        data_reg[4] <= 9'd0;
        data_reg[5] <= 9'd0;
        data_reg[6] <= 9'd0;
        data_reg[7] <= 9'd0;
        data_reg[8] <= 9'd0;
        o_all_valid <= 1'b0;
    end else */begin
        o_all_valid <= 1'b0;
        if (i_wen) begin // 값 저장하는건 병렬로
            data_reg[0] <= i_data[0];
            data_reg[1] <= i_data[1];
            data_reg[2] <= i_data[2];
            data_reg[3] <= i_data[3];
            data_reg[4] <= i_data[4];
            data_reg[5] <= i_data[5];
            data_reg[6] <= i_data[6];
            data_reg[7] <= i_data[7];
            data_reg[8] <= i_data[8];
            o_all_valid <= 1'b1;
        end
    end
end


reg [3:0] send_cnt; // 몇개 보냈는지 (0~8)
reg       sending;

always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
        send_cnt    <= 4'd0;
        sending     <= 1'b0;
    end else if (i_send_start) begin // i_send_start는 1 clock pulse
        send_cnt <= 4'd0;
        sending  <= 1'b1;
    end else if (sending) begin
        if (send_cnt == 4'd8) begin
            sending     <= 1'b0;
        end else begin
            send_cnt <= send_cnt + 4'd1;
        end
    end
end

always @(posedge i_clk) begin
    if (sending) begin
        case (send_cnt)
            4'd0: o_data <= data_reg [0];
            4'd1: o_data <= data_reg [1];
            4'd2: o_data <= data_reg [2];
            4'd3: o_data <= data_reg [3];
            4'd4: o_data <= data_reg [4];
            4'd5: o_data <= data_reg [5];
            4'd6: o_data <= data_reg [6];
            4'd7: o_data <= data_reg [7];
            4'd8: o_data <= data_reg [8];
            default: o_data <= 9'd0;
        endcase
    end else begin
      o_data <= 9'd0;
    end
end

endmodule