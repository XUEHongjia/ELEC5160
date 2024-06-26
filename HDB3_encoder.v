`timescale 1ns / 1ps

module add_v(
    input clk,
    input reset,
    
    input data_in,
    output reg [1:0] data_v
);

parameter HDB3_0 = 2'B00; //0
parameter HDB3_1 = 2'B01; //+1
parameter HDB3_B = 2'B11; //-1
parameter HDB3_V = 2'B10; //V code,-2

reg [1:0]count = 0;

always @( posedge clk ) begin

if ( reset ) begin
count <= 0;
data_v <= 0;
end

else begin
  if(data_in == 1'b1) begin
    count <= 0; 
    data_v <= 2'b01;
  end
  
  else begin
    count <= count + 1;
    
    if(count == 2'd3) begin
      data_v <= 2'b11;
      count <= 0;
    end
    
    else
      data_v <= 0;
    end
end
    
end

endmodule

module add_b(
  input clk,
  input reset, 
  
  input [1:0]add_b_in,
  output [1:0]add_b_out
);

reg firstv = 0;
reg enen = 1;
reg [1:0] d[3:0];

always @( posedge clk ) begin

if ( reset ) begin
firstv <= 0;
enen <= 1;
d[0] <= 0;
d[1] <= 0;
d[2] <= 0;
d[3] <= 0;
end

else begin
  d[3] <= d[2];
  d[2] <= d[1];
  d[1] <= d[0];
  d[0] <= add_b_in;

  if(d[0] == 2'b11) begin//if times of V is even 
    enen <= 1;
    firstv <= 0;
  end
  
  else if(d[0] == 2'b01) begin
    enen <= ~enen;
    firstv <= 1;
  end
  
  else
    firstv <= 1;
  end
end

assign add_b_out = enen && (firstv == 1) && (d[0] == 2'b11) ? 2'b10 : d[3];

endmodule

module polar(
  input clk,
  input reset,
  
  input [1:0]polar_in,
  output reg [1:0]polar_out
);

reg even = 1;

always @( posedge clk ) begin

if (reset) begin
even <= 1;
polar_out <= 0;
end

else begin

  if(polar_in == 2'b11) begin//if the polar code is V
    polar_out <= even ? 2'b01 : 2'b10;
    //even <= ~even;
  end
  
  else if(polar_in == 2'b01 || polar_in == 2'b10) begin
    polar_out <= even ? 2'b10 : 2'b01;
    even <= ~even;
  end
  
  else begin//if the polar code is 0
    polar_out <= 2'b00;
  end 
end 
end

endmodule // polar

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
