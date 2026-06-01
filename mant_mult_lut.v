`timescale 1ns / 1ps

module mant_mult_lut (
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output [7:0] product
);

    assign product = {1'b1, mant_a} * {1'b1, mant_b};

endmodule