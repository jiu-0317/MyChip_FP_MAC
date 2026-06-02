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

// ================================================================
//  SPI master tasks
// ================================================================
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

reg [15:0] rx_dummy;

task spi_cmd;
    input [2:0]  cmd;
    input [7:0]  data;
    input [3:0]  addr;
    input        mode;
    begin
        spi_transfer({cmd, data, addr, mode}, rx_dummy);
    end
endtask

// ================================================================
//  FP8 -> real conversion
// ================================================================
function real e4m3_to_real;
    input [7:0] val;
    real mantissa;
    integer exp_int;
    begin
        if (val[6:3] == 0 && val[2:0] == 0)
            e4m3_to_real = 0.0;
        else begin
            mantissa = 1.0 + val[2:0] / 8.0;
            exp_int  = val[6:3] - 7;
            e4m3_to_real = (val[7] ? -1.0 : 1.0) * mantissa * (2.0 ** exp_int);
        end
    end
endfunction

function real e5m2_to_real;
    input [7:0] val;
    real mantissa;
    integer exp_int;
    begin
        if (val[6:2] == 0 && val[1:0] == 0)
            e5m2_to_real = 0.0;
        else begin
            mantissa = 1.0 + val[1:0] / 4.0;
            exp_int  = val[6:2] - 15;
            e5m2_to_real = (val[7] ? -1.0 : 1.0) * mantissa * (2.0 ** exp_int);
        end
    end
endfunction

// ================================================================
//  Test infrastructure
// ================================================================
parameter NUM_TESTS = 16;

reg        read_mode [0:NUM_TESTS-1];
reg  [7:0] tw        [0:NUM_TESTS-1][0:8];  // weight values
reg        twm       [0:NUM_TESTS-1][0:8];  // weight modes
reg  [7:0] ti        [0:NUM_TESTS-1][0:8];  // input values
reg        tim       [0:NUM_TESTS-1][0:8];  // input modes
real       expected  [0:NUM_TESTS-1];

integer pass_count, fail_count;
integer t, j;
reg [15:0] result;
real actual, error_val, w_real, i_real;

// ================================================================
//  Test case definitions
// ================================================================
task define_tests;
    integer k;
    begin
        // ---- Test01: All 1.0 x 1.0 (E4M3), expect=9.0 ----
        read_mode[0] = 0;
        expected[0]  = 9.0;
        for (k=0; k<9; k=k+1) begin twm[0][k]=0; tw[0][k]=8'h38; tim[0][k]=0; ti[0][k]=8'h38; end

        // ---- Test02: Single 2.0 x 3.0 (E4M3), rest=0, expect=6.0 ----
        read_mode[1] = 0;
        expected[1]  = 6.0;
        for (k=0; k<9; k=k+1) begin twm[1][k]=0; tw[1][k]=8'h00; tim[1][k]=0; ti[1][k]=8'h00; end
        tw[1][0] = 8'h40; ti[1][0] = 8'h44;

        // ---- Test03: All 2.0 x 2.0 (E4M3), expect=36.0 ----
        read_mode[2] = 0;
        expected[2]  = 36.0;
        for (k=0; k<9; k=k+1) begin twm[2][k]=0; tw[2][k]=8'h40; tim[2][k]=0; ti[2][k]=8'h40; end

        // ---- Test04: All 1.0 x (-1.0) (E4M3), expect=-9.0 ----
        read_mode[3] = 0;
        expected[3]  = -9.0;
        for (k=0; k<9; k=k+1) begin twm[3][k]=0; tw[3][k]=8'h38; tim[3][k]=0; ti[3][k]=8'hB8; end

        // ---- Test05: All 1.0 x 1.0 (E5M2), expect=9.0 ----
        read_mode[4] = 1;
        expected[4]  = 9.0;
        for (k=0; k<9; k=k+1) begin twm[4][k]=1; tw[4][k]=8'h3C; tim[4][k]=1; ti[4][k]=8'h3C; end

        // ---- Test06: All 0.5 x 0.5 (E4M3), expect=2.25 ----
        read_mode[5] = 0;
        expected[5]  = 2.25;
        for (k=0; k<9; k=k+1) begin twm[5][k]=0; tw[5][k]=8'h30; tim[5][k]=0; ti[5][k]=8'h30; end

        // ---- Test07: All 4.0 x 4.0 (E4M3), expect=144.0 ----
        read_mode[6] = 0;
        expected[6]  = 144.0;
        for (k=0; k<9; k=k+1) begin twm[6][k]=0; tw[6][k]=8'h48; tim[6][k]=0; ti[6][k]=8'h48; end

        // ---- Test08: +1/-1 cancel (E4M3), expect=0.0 ----
        read_mode[7] = 0;
        expected[7]  = 0.0;
        for (k=0; k<9; k=k+1) begin twm[7][k]=0; tw[7][k]=8'h38; tim[7][k]=0; end
        ti[7][0]=8'h38; ti[7][1]=8'hB8; ti[7][2]=8'h38; ti[7][3]=8'hB8;
        ti[7][4]=8'h38; ti[7][5]=8'hB8; ti[7][6]=8'h38; ti[7][7]=8'hB8;
        ti[7][8]=8'h00;

        // ---- Test09: All zero (E4M3), expect=0.0 ----
        read_mode[8] = 0;
        expected[8]  = 0.0;
        for (k=0; k<9; k=k+1) begin twm[8][k]=0; tw[8][k]=8'h00; tim[8][k]=0; ti[8][k]=8'h00; end

        // ---- Test10: Mixed mode, read=E4M3, expect=20.0 ----
        read_mode[9] = 0;
        expected[9]  = 20.0;
        twm[9][0]=0; tw[9][0]=8'h38; tim[9][0]=1; ti[9][0]=8'h42;
        twm[9][1]=1; tw[9][1]=8'h40; tim[9][1]=0; ti[9][1]=8'h30;
        twm[9][2]=0; tw[9][2]=8'h30; tim[9][2]=1; ti[9][2]=8'h40;
        twm[9][3]=1; tw[9][3]=8'h3E; tim[9][3]=0; ti[9][3]=8'h40;
        twm[9][4]=0; tw[9][4]=8'h48; tim[9][4]=1; ti[9][4]=8'h3C;
        twm[9][5]=1; tw[9][5]=8'hBC; tim[9][5]=0; ti[9][5]=8'h38;
        twm[9][6]=0; tw[9][6]=8'h3C; tim[9][6]=1; ti[9][6]=8'hC0;
        twm[9][7]=1; tw[9][7]=8'h42; tim[9][7]=0; ti[9][7]=8'h44;
        twm[9][8]=0; tw[9][8]=8'h40; tim[9][8]=1; ti[9][8]=8'h3E;

        // ---- Test11: Mixed mode, read=E5M2, expect=20.0 ----
        read_mode[10] = 1;
        expected[10]  = 20.0;
        twm[10][0]=0; tw[10][0]=8'h38; tim[10][0]=1; ti[10][0]=8'h42;
        twm[10][1]=1; tw[10][1]=8'h40; tim[10][1]=0; ti[10][1]=8'h30;
        twm[10][2]=0; tw[10][2]=8'h30; tim[10][2]=1; ti[10][2]=8'h40;
        twm[10][3]=1; tw[10][3]=8'h3E; tim[10][3]=0; ti[10][3]=8'h40;
        twm[10][4]=0; tw[10][4]=8'h48; tim[10][4]=1; ti[10][4]=8'h3C;
        twm[10][5]=1; tw[10][5]=8'hBC; tim[10][5]=0; ti[10][5]=8'h38;
        twm[10][6]=0; tw[10][6]=8'h3C; tim[10][6]=1; ti[10][6]=8'hC0;
        twm[10][7]=1; tw[10][7]=8'h42; tim[10][7]=0; ti[10][7]=8'h44;
        twm[10][8]=0; tw[10][8]=8'h40; tim[10][8]=1; ti[10][8]=8'h3E;

        // ---- Test12: All 1.5 x 1.5 (E4M3), expect=20.25 ----
        read_mode[11] = 0;
        expected[11]  = 20.25;
        for (k=0; k<9; k=k+1) begin twm[11][k]=0; tw[11][k]=8'h3C; tim[11][k]=0; ti[11][k]=8'h3C; end

        // ---- Test13: All 4.0 x 3.0 (E4M3), expect=108.0 ----
        read_mode[12] = 0;
        expected[12]  = 108.0;
        for (k=0; k<9; k=k+1) begin twm[12][k]=0; tw[12][k]=8'h48; tim[12][k]=0; ti[12][k]=8'h44; end

        // ---- Test14: All 1.0 x 2.0 (E4M3), expect=18.0 ----
        read_mode[13] = 0;
        expected[13]  = 18.0;
        for (k=0; k<9; k=k+1) begin twm[13][k]=0; tw[13][k]=8'h38; tim[13][k]=0; ti[13][k]=8'h40; end

        // ---- Test15: All 1.0 x 2.0 (E5M2), read=E4M3, expect=18.0 ----
        read_mode[14] = 0;
        expected[14]  = 18.0;
        for (k=0; k<9; k=k+1) begin twm[14][k]=1; tw[14][k]=8'h3C; tim[14][k]=1; ti[14][k]=8'h40; end

        // ---- Test16: Single 3.0 x 3.0 (E4M3), read=E5M2, expect=9.0 ----
        read_mode[15] = 1;
        expected[15]  = 9.0;
        for (k=0; k<9; k=k+1) begin twm[15][k]=0; tw[15][k]=8'h00; tim[15][k]=0; ti[15][k]=8'h00; end
        tw[15][0] = 8'h44; ti[15][0] = 8'h44;
    end
endtask

// ================================================================
//  Run one test: reset -> load W -> load I -> compute -> acc -> read
// ================================================================
task run_test;
    input integer idx;
    begin
        // Reset DUT
        rstn = 0;
        ssn = 1; mosi = 0; sclk_reg = 0;
        #(CLK_PERIOD * 10);
        rstn = 1;
        #(CLK_PERIOD * 10);

        // LOAD_W x9 (cmd=000)
        for (j = 0; j < 9; j = j + 1)
            spi_cmd(3'b000, tw[idx][j], j[3:0], twm[idx][j]);

        // LOAD_I x9 (cmd=001)
        for (j = 0; j < 9; j = j + 1)
            spi_cmd(3'b001, ti[idx][j], j[3:0], tim[idx][j]);

        // COMPUTE (cmd=010)
        spi_cmd(3'b010, 8'h00, 4'h0, 1'b0);
        #500;

        // ACC (cmd=011)
        spi_cmd(3'b011, 8'h00, 4'h0, 1'b0);
        #3000;

        // READ_RESULT (cmd=100)
        spi_cmd(3'b100, 8'h00, 4'h0, read_mode[idx]);
        #500;

        // Dummy SPI read to get result via MISO
        spi_transfer(16'h0000, result);

        // Evaluate
        if (read_mode[idx])
            actual = e5m2_to_real(result[7:0]);
        else
            actual = e4m3_to_real(result[7:0]);

        error_val = actual - expected[idx];

        if (error_val < 0.0) error_val = -error_val;

        if (error_val < 0.001) begin
            $display("[PASS] Test%02d | Expected=%f  Actual=%f  Error=%f",
                     idx+1, expected[idx], actual, actual - expected[idx]);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Test%02d | Expected=%f  Actual=%f  Error=%f",
                     idx+1, expected[idx], actual, actual - expected[idx]);
            fail_count = fail_count + 1;
        end
    end
endtask

// ================================================================
//  Main
// ================================================================
initial begin
    $dumpfile("tb_TOP.vcd");
    $dumpvars(0, tb_TOP);

    clk = 0;
    pass_count = 0;
    fail_count = 0;

    define_tests;

    $display("");
    $display("================================================================");
    $display("  FP MAC Testbench — %0d tests", NUM_TESTS);
    $display("================================================================");

    for (t = 0; t < NUM_TESTS; t = t + 1)
        run_test(t);

    $display("");
    $display("================================================================");
    $display("  SUMMARY: %0d PASS / %0d FAIL / %0d TOTAL",
             pass_count, fail_count, pass_count + fail_count);
    $display("================================================================");

    #200;
    $finish;
end

endmodule
