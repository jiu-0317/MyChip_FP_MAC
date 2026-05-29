`timescale 1ns / 1ps

module TOP (
    input        i_clk,
    input        i_rstn,
    // SPI physical pins
    input        i_ssn,
    input        i_mosi,
    input        i_sclk,
    output       o_miso
);

// ===== Internal wires =====

// SPI_slave
wire [15:0] spi_o_dat;
wire        spi_rx_done;

// IR
wire [2:0]  ir_cmd;
wire        ir_cmd_valid_one_pulse;
wire        ir_mode;
wire [8:0]  ir_data;
wire [3:0]  ir_addr;

// CONTROL
wire        ctrl_tx_load;
// wire        ctrl_clear_valid;
wire        ctrl_w_wen;
wire        ctrl_i_wen;
//wire        ctrl_fpu_start;
//wire        ctrl_fpu_rf_wen;
wire        ctrl_fpu_rf_send_start;
wire        ctrl_acc_start;
wire        ctrl_acc_r_wen;
wire        ctrl_mode;

// W_I_RF
// wire        w_all_valid;
// wire        i_all_valid;
wire [8:0]  w_data   [8:0];
wire [8:0]  i_data_rf [8:0];

// FPU
wire [8:0]  fpu_result [8:0];

// FPU_RF
// 변경
wire [8:0]  router_out;
//wire        fpu_rf_all_valid;

// ACC
wire [8:0]  acc_result;
wire        acc_done;

// ACC_R
wire [7:0]  acc_r_data;

// ===== SPI TX data: ACC_R 8bit -> 16bit padding =====
wire [15:0] spi_tx_data = {8'h00, acc_r_data};

// ===== rx_done 1-cycle delay =====
// SPI o_dat가 NBA로 갱신되므로, 1사이클 지연해야 IR이 올바른 o_dat를 봄
reg rx_done_d;
always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) rx_done_d <= 1'b0;
    else         rx_done_d <= spi_rx_done;
end

// ===== SPI_slave =====
SPI_slave u_spi (
    .i_rstn    (i_rstn),
    .i_clk     (i_clk),
    .i_ssn     (i_ssn),
    .i_mosi    (i_mosi),
    .i_sclk    (i_sclk),
    .i_tx_load (ctrl_tx_load),
    .o_miso    (o_miso),
    .i_dat     (spi_tx_data),
    .o_dat     (spi_o_dat),
    .o_rx_done (spi_rx_done)
);

// ===== IR =====
IR u_ir (
    .i_rx_data            (spi_o_dat),
    .i_rx_done            (rx_done_d),
    .o_cmd                (ir_cmd),
    .o_cmd_valid_one_pulse(ir_cmd_valid_one_pulse),
    .o_mode               (ir_mode),
    .o_data               (ir_data),
    .o_addr               (ir_addr)
);

// ===== CONTROL =====
CONTROL u_ctrl (
    .i_clk                (i_clk),
    .i_rstn               (i_rstn),
    .o_tx_load            (ctrl_tx_load),
    .i_cmd                (ir_cmd),
    .i_cmd_valid_one_pulse(ir_cmd_valid_one_pulse),
    .i_mode               (ir_mode),
    //.o_clear_valid        (ctrl_clear_valid),
    .o_w_wen              (ctrl_w_wen),
    .o_i_wen              (ctrl_i_wen),
    //.i_w_all_valid        (w_all_valid),
    //.i_i_all_valid        (i_all_valid),
    //.o_fpu_start          (ctrl_fpu_start),
    //.o_fpu_rf_wen         (ctrl_fpu_rf_wen),
    .o_fpu_rf_send_start  (ctrl_fpu_rf_send_start),
    //.i_fpu_rf_all_valid   (fpu_rf_all_valid),
    .o_acc_start          (ctrl_acc_start),
    .i_acc_done           (acc_done),
    .o_acc_r_wen          (ctrl_acc_r_wen),
    .o_mode               (ctrl_mode)
);

// ===== W_I_RF =====
W_I_RF u_w_i_rf (
    .i_clk        (i_clk),
    .i_rstn       (i_rstn),
    //.i_clear_valid(ctrl_clear_valid),
    .i_w_wen      (ctrl_w_wen),
    .i_i_wen      (ctrl_i_wen),
    .i_addr       (ir_addr),
    .i_data       (ir_data),
    //.o_w_all_valid(w_all_valid),
    //.o_i_all_valid(i_all_valid),
    .o_w_data     (w_data),
    .o_i_data     (i_data_rf)
);

// ===== FPU x9 =====
genvar g;
generate
    for (g = 0; g < 9; g = g + 1) begin : fpu_gen
        FPU u_fpu (
            //.i_start  (ctrl_fpu_start),
            .i_weight (w_data[g]),
            .i_input  (i_data_rf[g]),
            .o_result (fpu_result[g])
        );
    end
endgenerate

// ===== FPU_RF =====
/*FPU_RF u_fpu_rf (
    .i_clk       (i_clk),
    .i_rstn      (i_rstn),
    .i_wen       (ctrl_fpu_rf_wen),
    .i_send_start(ctrl_fpu_rf_send_start),
    .i_data      (fpu_result),
    .o_data      (fpu_rf_out),
    .o_all_valid (fpu_rf_all_valid)
);*/

// 변경
FPU_router u_router (
    .i_clk       (i_clk),
    .i_rstn      (i_rstn),
    .i_send_start(ctrl_fpu_rf_send_start),
    .i_data      (fpu_result),
    .o_data      (router_out)
);

// ===== ACC =====
ACC u_acc (
    .i_clk    (i_clk),
    .i_rstn   (i_rstn),
    .i_start  (ctrl_acc_start),
    .i_data   (router_out),
    .o_result (acc_result),
    .o_done   (acc_done)
);

// ===== ACC_R =====
ACC_R u_acc_r (
    .i_clk   (i_clk),
    .i_rstn  (i_rstn),
    .i_wen   (ctrl_acc_r_wen),
    .i_mode  (ctrl_mode),
    .i_data  (acc_result),
    .o_data  (acc_r_data)
);

endmodule
