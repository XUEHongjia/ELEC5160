`timescale 1ns / 1ps

module HDB3_encoder_tb(
    );
reg clk = 0;
reg reset = 1;
integer count = 130;

parameter SEQ = 65'b11_0000_1_0000_0000_11_0000_111_0000_1111_00_1_0_1_000_11_0000_0000_0000_111_0000_11_0_1;
parameter SEQ2 = 130'b1100_0010_0000_0001_1000_0111_0000_1111_0010_1000_1100_0000_0000_0011_1000_0110_1_1100_0010_0000_0001_1000_0111_0000_1111_0010_1000_1100_0000_0000_0011_1000_0110_1;
//parameter SEQ2 = { SEQ, SEQ };

reg data_in = 0;
wire HDB3_encode_P;
wire HDB3_encode_N;

HDB3_encoder uut ( .clk( clk ), .reset( reset ), .data_in( data_in ), .HDB3_encode_P( HDB3_encode_P ), .HDB3_encode_N( HDB3_encode_N ) );

always@( negedge clk or posedge reset ) begin
if ( reset ) begin
count <= 130;
data_in <= SEQ2[ count - 1 ];
end

else begin
count <= count - 1;
data_in <= SEQ2[count-1];
end

end

initial begin

#100;
reset <= 0;

forever begin
    #10;
    clk <= ~clk;
end

# 1200;

end

endmodule
