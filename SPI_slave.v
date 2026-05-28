`timescale 1ns / 1ps

module SPI_slave(
    input i_rstn,
    input i_clk,
    input i_ssn,
    input i_mosi,
    input i_sclk,
    input i_tx_load,
    output o_miso,
    input [15:0] i_dat,
    output reg [15:0] o_dat,
    output o_rx_done // SSn 0→1 순간 1-cycle 펄스
    );

  reg [15:0] RBUF, TBUF;
  reg [15:0] r_dat;
  reg d_SSn;
  wire w_rstn;

  assign o_miso = TBUF[15];

  always @ (posedge i_sclk or negedge i_rstn) begin
    if (i_rstn == 1'b0) begin
      RBUF <= 16'h00;
    end
    else begin
      RBUF <= {RBUF[14:00], i_mosi};
    end
  end

  always @ (posedge i_clk or negedge i_rstn) begin
    if (i_rstn == 1'b0) begin
      d_SSn <= 1'b1;
    end
    else begin
      d_SSn <= i_ssn;
    end
  end

  assign w_rstn = ((i_ssn == 1'b0) && (d_SSn == 1'b1)) ? 1'b0 : 1'b1;

  always @ (negedge i_sclk or negedge w_rstn) begin
    if (w_rstn == 1'b0) begin
      TBUF <= r_dat;
    end
    else begin
      TBUF <= {TBUF[14:00], 1'b0};
    end
  end

  always @ (posedge i_clk or negedge i_rstn) begin
    if (i_rstn == 1'b0) begin
      r_dat <= 16'h00;
      o_dat <= 16'h00;
    end
    else begin
      if (i_ssn == 1'b1) begin
        if (i_tx_load) begin
          r_dat <= i_dat;
        end
        o_dat <= RBUF;
      end
    end
  end

  reg d_SSn_r;
  always @(posedge i_clk) d_SSn_r <= i_ssn;

  wire o_rx_done = i_ssn & ~d_SSn_r;  // SSn 0→1 순간 1-cycle 펄스

endmodule
