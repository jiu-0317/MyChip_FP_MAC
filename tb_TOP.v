`timescale 1ns / 1ps

module tb_TOP;

reg clk, rstn;
reg ssn, mosi, sclk_reg;
wire miso;

TOP u_top (
    .i_clk  (clk),
    .i_rstn (rstn),
    .i_ssn  (ssn),
    .i_mosi (mosi),
    .i_sclk (sclk_reg),
    .o_miso (miso)
);

// System clock: 100MHz (10ns)
parameter CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk = ~clk;

// SPI clock half period: 50ns (10MHz)
parameter SCLK_HALF = 50;

// ----- SPI master task -----
task spi_transfer;
    input  [15:0] tx_data;
    output [15:0] rx_data;
    integer i;
    begin
        ssn = 1'b0;
        #(SCLK_HALF);
        for (i = 15; i >= 0; i = i - 1) begin
            mosi = tx_data[i];
            #(SCLK_HALF);
            sclk_reg = 1'b1;
            #1;
            rx_data[i] = miso;
            #(SCLK_HALF - 1);
            sclk_reg = 1'b0;
        end
        mosi = 1'b0;
        #(SCLK_HALF);
        ssn = 1'b1;
        #(CLK_PERIOD * 20);
    end
endtask

// ----- SPI command helper -----
// Format: {cmd[2:0], data[7:0], addr[3:0], mode[0]}
reg [15:0] rx_dummy;

task spi_cmd;
    input [2:0]  cmd;
    input [7:0]  data;
    input [3:0]  addr;
    input        mode;
    begin
        spi_transfer({cmd, data, addr, mode}, rx_dummy);
        $display("[%0t] SPI TX: cmd=%b data=%02h addr=%0d mode=%b", $time, cmd, data, addr, mode);
    end
endtask

// ----- E4M3 -> real 변환 (S1 E4 M3, bias=7) -----
function real e4m3_to_real;
    input [7:0] val;
    real mantissa;
    integer exp_int;
    begin
        if (val[6:3] == 0 && val[2:0] == 0) begin
            e4m3_to_real = 0.0;
        end else begin
            mantissa = 1.0 + val[2:0] / 8.0;
            exp_int  = val[6:3] - 7;
            e4m3_to_real = (val[7] ? -1.0 : 1.0) * mantissa * (2.0 ** exp_int);
        end
    end
endfunction

// ----- E5M2 -> real 변환 (S1 E5 M2, bias=15) -----
function real e5m2_to_real;
    input [7:0] val;
    real mantissa;
    integer exp_int;
    begin
        if (val[6:2] == 0 && val[1:0] == 0) begin
            e5m2_to_real = 0.0;
        end else begin
            mantissa = 1.0 + val[1:0] / 4.0;
            exp_int  = val[6:2] - 15;
            e5m2_to_real = (val[7] ? -1.0 : 1.0) * mantissa * (2.0 ** exp_int);
        end
    end
endfunction

// ----- Test -----
integer i;
reg [15:0] result;
real expected, actual, w_real, i_real, product;

// ============================================================
//  USER CONFIG: 여기만 수정하면 됩니다!
//
//  MODE 설정: 0 = E4M3, 1 = E5M2
//    LOAD_MODE : Weight/Input 데이터 포맷
//    READ_MODE : 결과 읽기 포맷
//
//  E4M3 (mode=0): S(1) E(4) M(3), bias=7
//    0.5  = 8'h30   (0_0110_000)
//    1.0  = 8'h38   (0_0111_000)
//    1.5  = 8'h3C   (0_0111_100)
//    2.0  = 8'h40   (0_1000_000)
//    3.0  = 8'h44   (0_1000_100)
//    4.0  = 8'h48   (0_1001_000)
//   -1.0  = 8'hB8   (1_0111_000)
//   -2.0  = 8'hC0   (1_1000_000)
//
//  E5M2 (mode=1): S(1) E(5) M(2), bias=15
//    0.5  = 8'h38   (0_01110_00)
//    1.0  = 8'h3C   (0_01111_00)
//    1.5  = 8'h3E   (0_01111_10)
//    2.0  = 8'h40   (0_10000_00)
//    3.0  = 8'h42   (0_10000_10)
//    4.0  = 8'h44   (0_10001_00)
//   -1.0  = 8'hBC   (1_01111_00)
//   -2.0  = 8'hC0   (1_10000_00)
// ============================================================
reg       WM [0:8];   // Weight mode (값마다 개별 지정, 0: E4M3, 1: E5M2)
reg       IM [0:8];   // Input  mode (값마다 개별 지정, 0: E4M3, 1: E5M2)
reg       READ_MODE;  // 결과 읽기 포맷 (0: E4M3, 1: E5M2)
reg [7:0] W  [0:8];   // Weight values (9개)
reg [7:0] I  [0:8];   // Input  values (9개)

initial begin
    // --- READ mode 설정 ---
    READ_MODE = 1'b0;  // 0: E4M3, 1: E5M2

    // --- Weight 값 설정 (WM: 해당 값의 mode) ---
    WM[0] = 0;  W[0] = 8'h38;  // E4M3  1.0
    WM[1] = 1;  W[1] = 8'h40;  // E5M2  2.0
    WM[2] = 0;  W[2] = 8'h30;  // E4M3  0.5
    WM[3] = 1;  W[3] = 8'h3E;  // E5M2  1.5
    WM[4] = 0;  W[4] = 8'h48;  // E4M3  4.0
    WM[5] = 1;  W[5] = 8'hBC;  // E5M2 -1.0
    WM[6] = 0;  W[6] = 8'h3C;  // E4M3  1.5
    WM[7] = 1;  W[7] = 8'h42;  // E5M2  3.0
    WM[8] = 0;  W[8] = 8'h40;  // E4M3  2.0

    // --- Input 값 설정 (IM: 해당 값의 mode) ---
    IM[0] = 1;  I[0] = 8'h42;  // E5M2  3.0
    IM[1] = 0;  I[1] = 8'h30;  // E4M3  0.5
    IM[2] = 1;  I[2] = 8'h40;  // E5M2  2.0
    IM[3] = 0;  I[3] = 8'h40;  // E4M3  2.0
    IM[4] = 1;  I[4] = 8'h3C;  // E5M2  1.0
    IM[5] = 0;  I[5] = 8'h38;  // E4M3  1.0
    IM[6] = 1;  I[6] = 8'hC0;  // E5M2 -2.0
    IM[7] = 0;  I[7] = 8'h44;  // E4M3  3.0
    IM[8] = 1;  I[8] = 8'h3E;  // E5M2  1.5
end

initial begin
    $dumpfile("tb_TOP.vcd");
    $dumpvars(0, tb_TOP);

    clk = 0; rstn = 0;
    ssn = 1; mosi = 0; sclk_reg = 0;

    // Reset
    #100;
    rstn = 1;
    #100;

    // ----- LOAD_W x9 (cmd=000) -----
    $display("\n========== LOAD WEIGHT x9 ==========");
    for (i = 0; i < 9; i = i + 1) begin
        spi_cmd(3'b000, W[i], i[3:0], WM[i]);
    end

    // Check w_all_valid
    #100;
    $display("[%0t] w_all_valid=%b, i_all_valid=%b",
        $time,
        u_top.w_all_valid,
        u_top.i_all_valid);

    // ----- LOAD_I x9 (cmd=001) -----
    $display("\n========== LOAD INPUT x9 ==========");
    for (i = 0; i < 9; i = i + 1) begin
        spi_cmd(3'b001, I[i], i[3:0], IM[i]);
    end

    // Check i_all_valid
    #100;
    $display("[%0t] w_all_valid=%b, i_all_valid=%b",
        $time,
        u_top.w_all_valid,
        u_top.i_all_valid);

    // ----- COMPUTE (cmd=010) -----
    $display("\n========== COMPUTE ==========");
    spi_cmd(3'b010, 8'h00, 4'h0, 1'b0);
    #500;

    // Check FPU results & FPU_RF
    $display("[%0t] fpu_rf_all_valid=%b, CONTROL state=%b",
        $time,
        u_top.fpu_rf_all_valid,
        u_top.u_ctrl.state);

    // ----- ACC (cmd=011) -----
    $display("\n========== ACC ==========");
    spi_cmd(3'b011, 8'h00, 4'h0, 1'b0);
    #3000;

    // Check ACC result
    $display("[%0t] acc_done_flag=%b, acc_result=%b (%0d)",
        $time,
        u_top.u_ctrl.acc_done_flag,
        u_top.acc_result,
        u_top.acc_result);

    // ----- READ_RESULT (cmd=100) -----
    $display("\n========== READ RESULT (mode=%0b, %s) ==========", READ_MODE, READ_MODE ? "E5M2" : "E4M3");
    spi_cmd(3'b100, 8'h00, 4'h0, READ_MODE);
    #500;

    // Check ACC_R output and SPI tx data
    $display("[%0t] acc_r_data=%02h, spi_tx_data=%04h",
        $time,
        u_top.acc_r_data,
        u_top.spi_tx_data);

    // ----- Dummy read to get result from MISO -----
    $display("\n========== DUMMY READ ==========");
    spi_transfer(16'h0000, result);
    $display("[%0t] SPI RX = %04h", $time, result);

    // ----- Result -----
    $display("\n========== RESULT (READ=%s) ==========",
        READ_MODE ? "E5M2" : "E4M3");

    expected = 0.0;
    for (i = 0; i < 9; i = i + 1) begin
        w_real  = WM[i] ? e5m2_to_real(W[i]) : e4m3_to_real(W[i]);
        i_real  = IM[i] ? e5m2_to_real(I[i]) : e4m3_to_real(I[i]);
        product = w_real * i_real;
        $display("  [%0d] W=0x%02h[%s](%6.3f) * I=0x%02h[%s](%6.3f) = %8.4f",
            i, W[i], WM[i] ? "E5M2" : "E4M3", w_real,
               I[i], IM[i] ? "E5M2" : "E4M3", i_real, product);
        expected = expected + product;
    end

    actual = READ_MODE ? e5m2_to_real(result[7:0]) : e4m3_to_real(result[7:0]);

    $display("");
    $display("  Expected (real)  : %f", expected);
    $display("  Actual   (%s)  : 0x%02h = %f", READ_MODE ? "E5M2" : "E4M3", result[7:0], actual);
    $display("  Error            : %f", actual - expected);

    #200;
    $finish;
end

endmodule
