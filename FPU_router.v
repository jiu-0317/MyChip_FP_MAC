`timescale 1ns / 1ps

module FPU_router(
    input            i_clk,
    input            i_rstn,
    input            i_send_start,
    input      [8:0] i_data [8:0],
    output reg [8:0] o_data
);

reg [3:0] send_cnt;
reg       sending;

always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
        send_cnt <= 4'd0;
        sending  <= 1'b0;
    end else if (i_send_start) begin
        send_cnt <= 4'd0;
        sending  <= 1'b1;
    end else if (sending) begin
        if (send_cnt == 4'd8) begin
            sending <= 1'b0;
        end else begin
            send_cnt <= send_cnt + 4'd1;
        end
    end
end

always @(posedge i_clk) begin
    if (sending) begin
        case (send_cnt)
            4'd0: o_data <= i_data[0];
            4'd1: o_data <= i_data[1];
            4'd2: o_data <= i_data[2];
            4'd3: o_data <= i_data[3];
            4'd4: o_data <= i_data[4];
            4'd5: o_data <= i_data[5];
            4'd6: o_data <= i_data[6];
            4'd7: o_data <= i_data[7];
            4'd8: o_data <= i_data[8];
            default: o_data <= 9'd0;
        endcase
    end else begin
        o_data <= 9'd0;
    end
end

endmodule