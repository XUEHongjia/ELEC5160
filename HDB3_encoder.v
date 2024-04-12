`timescale 1ns / 1ps

module HDB3_encoder(
input clk,
input reset,
input data_in,
output HDB3_encode_P,
output HDB3_encode_N
);

wire [1:0] data_v;
add_v add_v_u1(
  .clk(clk),
  .reset(reset),
  .data_in(data_in),
  .data_v(data_v)
);

wire [1:0]data_b;
add_b add_b_u1(
  .clk(clk),
  .reset(reset),
  .add_b_in(data_v),
  .add_b_out(data_b)
);

wire [1:0]hdb3_code;
polar polar_u1(
  .clk(clk),
  .reset(reset),
  .polar_in(data_b),
  .polar_out(hdb3_code)
);

assign HDB3_encode_P = hdb3_code[1];
assign HDB3_encode_N = hdb3_code[0];

endmodule
