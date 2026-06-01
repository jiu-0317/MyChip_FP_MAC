`timescale 1ns / 1ps

module mant_mult_lut (
    input  [2:0] mant_a,
    input  [2:0] mant_b,
    output reg [7:0] product
);

    always @(*) begin
        assign mant_product = {1'b1, mant_weight} * {1'b1, mant_input};
    end

endmodule
