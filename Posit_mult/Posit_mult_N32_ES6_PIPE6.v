`timescale 1ns / 1ps

module Posit_mult_N32_ES6_PIPE6(clk, in1, in2, start, out, inf, zero, done);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        	value = value>>1;
      	end
endfunction

parameter N = 32;
parameter Bs = log2(N); 
parameter es = 6;

input clk;
input [N-1:0] in1, in2;
input start; 
output reg [N-1:0] out;
output reg inf, zero;
output reg done;

wire start0= start;
wire s1 = in1[N-1];
wire s2 = in2[N-1];
wire zero_tmp1 = |in1[N-2:0];
wire zero_tmp2 = |in2[N-2:0];
wire inf1 = in1[N-1] & (~zero_tmp1),
	inf2 = in2[N-1] & (~zero_tmp2);
wire zero1 = ~(in1[N-1] | zero_tmp1),
	zero2 = ~(in2[N-1] | zero_tmp2);
wire inf_t = inf1 | inf2,
	zero_t = zero1 & zero2;

//stage1 -- Data Extraction
wire rc1, rc2;
wire [Bs-1:0] regime1, regime2;
wire [es-1:0] e1, e2;
wire [N-es-1:0] mant1, mant2;
wire [N-1:0] xin1 = s1 ? -in1 : in1;
wire [N-1:0] xin2 = s2 ? -in2 : in2;
data_extract_N32_ES6 #(.N(N),.es(es)) uut_de1(.in(xin1), .rc(rc1), .regime(regime1), .exp(e1), .mant(mant1));
data_extract_N32_ES6 #(.N(N),.es(es)) uut_de2(.in(xin2), .rc(rc2), .regime(regime2), .exp(e2), .mant(mant2));

wire [N-es:0] m1 = {zero_tmp1,mant1}, 
	m2 = {zero_tmp2,mant2};

reg start_r00; 
reg s1_r00, s2_r00, inf_r00, zero_r00, rc1_r00, rc2_r00;
reg [Bs-1:0] regime1_r00, regime2_r00;
reg [es-1:0] e1_r00, e2_r00;
reg [N-es:0] m1_r00, m2_r00;
reg start_r0; 
reg s1_r0, s2_r0, inf_r0, zero_r0, rc1_r0, rc2_r0;
reg [Bs-1:0] regime1_r0, regime2_r0;
reg [es-1:0] e1_r0, e2_r0;
reg [N-es:0] m1_r0, m2_r0;
always @(posedge clk) begin
start_r0 <= start0; 
s1_r0 <= s1; 
s2_r0 <= s2; 
inf_r0 <= inf_t; 
zero_r0 <= zero_t; 
rc1_r0 <= rc1; 
rc2_r0 <= rc2;
regime1_r0 <= regime1; 
regime2_r0 <= regime2; 
e1_r0 <= e1; 
e2_r0 <= e2;
m1_r0 <= m1; 
m2_r0 <= m2;
end

//stage2--4: muliplication
wire [53:0] mult_m_r2;
wire [47:0] mult_P;
Mantissa_Multiplier_24x24 m24 (.clk(clk), .a(m1_r0[N-es:3]), .b(m2_r0[N-es:3]), .product(mult_P));
assign mult_m_r2 = {mult_P,6'b0};

reg start_r1; 
reg s1_r1, s2_r1, inf_r1, zero_r1, rc1_r1, rc2_r1;
reg [Bs-1:0] regime1_r1, regime2_r1;
reg [es-1:0] e1_r1, e2_r1;
reg [N-es:0] m1_r1, m2_r1;
reg start_r2; 
reg s1_r2, s2_r2, inf_r2, zero_r2, rc1_r2, rc2_r2;
reg [Bs-1:0] regime1_r2, regime2_r2;
reg [es-1:0] e1_r2, e2_r2;
reg [N-es:0] m1_r2, m2_r2;

always @(posedge clk) begin
start_r1 <= start_r0; 
s1_r1 <= s1_r0; 
s2_r1 <= s2_r0; 
inf_r1 <= inf_r0; 
zero_r1 <= zero_r0; 
rc1_r1 <= rc1_r0; 
rc2_r1 <= rc2_r0;
regime1_r1 <= regime1_r0; 
regime2_r1 <= regime2_r0; 
e1_r1 <= e1_r0; 
e2_r1 <= e2_r0;
m1_r1 <= m1_r0; 
m2_r1 <= m2_r0;

start_r2 <= start_r1; 
s1_r2 <= s1_r1; 
s2_r2 <= s2_r1; 
inf_r2 <= inf_r1; 
zero_r2 <= zero_r1; 
rc1_r2 <= rc1_r1; 
rc2_r2 <= rc2_r1;
regime1_r2 <= regime1_r1; 
regime2_r2 <= regime2_r1; 
e1_r2 <= e1_r1; 
e2_r2 <= e2_r1;
m1_r2 <= m1_r1; 
m2_r2 <= m2_r1;
end

//Sign, Exponent and Mantissa Computation
wire mult_s = s1_r2 ^ s2_r2;

wire mult_m_ovf = mult_m_r2[2*(N-es)+1];
wire [2*(N-es)+1:0] mult_mN = ~mult_m_ovf ? mult_m_r2 << 1'b1 : mult_m_r2;

wire [Bs+1:0] r1 = rc1_r2 ? {2'b0,regime1_r2} : -regime1_r2;
wire [Bs+1:0] r2 = rc2_r2 ? {2'b0,regime2_r2} : -regime2_r2;
wire [Bs+es+1:0] mult_e  =  {r1, e1_r2} + {r2, e2_r2} + mult_m_ovf;

//Exponent and Regime Computation
wire [es+Bs:0] mult_eN = mult_e[es+Bs+1] ? -mult_e : mult_e;
wire [es-1:0] e_o = mult_e[es-1:0];
wire [Bs:0] r_o = (~mult_e[es+Bs+1] || (|mult_e[es-1:0])) + mult_eN[es+Bs:es];

//Exponent and Mantissa Packing
wire [2*N-1+3:0]tmp_o = {{N{~mult_e[es+Bs+1]}},mult_e[es+Bs+1],e_o,mult_mN[2*(N-es):2*(N-es)-(N-es-1)+1], mult_mN[2*(N-es)-(N-es-1):2*(N-es)-(N-es-1)-1], |mult_mN[2*(N-es)-(N-es-1)-2:0] }; 

reg start_r3, mult_s_r3, inf_r3, zero_r3;
reg [2*N-1+3:0] tmp_o_r3;
reg [Bs:0] r_o_r3;
reg [2*(N-es)+1:0] mult_mN_r3;
always @(posedge clk) begin
start_r3 <= start_r2; mult_s_r3 <= mult_s; inf_r3 <= inf_r2; zero_r3 <= zero_r2;
r_o_r3 <= r_o;
tmp_o_r3 <= tmp_o;
mult_mN_r3 <= mult_mN;
end

//Including Regime bits in Exponent-Mantissa Packing
wire [3*N-1+3:0] tmp1_o;
DSR_right_N_S #(.N(3*N+3), .S(Bs+1)) dsr2 (.a({tmp_o_r3,{N{1'b0}}}), .b(r_o_r3[Bs] ? {Bs{1'b1}} : r_o_r3), .c(tmp1_o));


//Rounding RNE : ulp_add = G.(R + S) + L.G.(~(R+S))
wire L = tmp1_o[N+4], G = tmp1_o[N+3], R = tmp1_o[N+2], St = |tmp1_o[N+1:0],
     ulp = ((G & (R | St)) | (L & G & ~(R | St)));
wire [N-1:0] rnd_ulp = {{N-1{1'b0}},ulp};
wire [N-1:0] tmp1_o_rnd = (r_o_r3 < N-es-2) ? tmp1_o[2*N-1+3:N+3] + rnd_ulp : tmp1_o[2*N-1+3:N+3];


//Final Output
wire [N-1:0] tmp1_oN = mult_s_r3 ? -tmp1_o_rnd : tmp1_o_rnd;
wire [N-1:0] out_tmp = inf_r3|zero_r3|(~mult_mN_r3[2*(N-es)+1]) ? {inf_r3,{N-1{1'b0}}} : {mult_s_r3, tmp1_oN[N-1:1]};

always @(posedge clk) begin
out <= out_tmp;
done <= start_r3;
inf <= inf_r3;
zero <= zero_r3;
end

endmodule


/////////////////////////
module data_extract_N32_ES6(in, rc, regime, exp, mant);
function [31:0] log2;
input reg [31:0] value;
	begin
	value = value-1;
	for (log2=0; value>0; log2=log2+1)
        value = value>>1;
    end
endfunction

parameter N=32;
parameter Bs=log2(N);
parameter es = 5;


input [N-1:0] in;
output rc;
output [Bs-1:0] regime;
output [es-1:0] exp;
output [N-es-1:0] mant;

//Data Extraction

wire [N-1:0] xin = in;
assign rc = xin[N-2];

wire [N-1:0] xin_r = rc ? ~xin : xin;

wire [Bs-1:0] k;
LOD_32 uut_lod32_5 (.in({xin_r[N-2:0],rc^1'b0}), .out(k));

assign regime = rc ? k-1 : k;

wire [N-1:0] xin_tmp;
DSR_left_N_S #(.N(N), .S(Bs)) ls (.a({xin[N-3:0],2'b0}),.b(k),.c(xin_tmp));

assign exp= xin_tmp[N-1:N-es];
assign mant= xin_tmp[N-es-1:0];

endmodule


/////////////////////////
module DSR_left_N_S(a,b,c);
        parameter N=16;
        parameter S=4;
        input [N-1:0] a;
        input [S-1:0] b;
        output [N-1:0] c;

wire [N-1:0] tmp [S-1:0];
assign tmp[0]  = b[0] ? a << 7'd1  : a; 
genvar i;
generate
	for (i=1; i<S; i=i+1)begin:loop_blk
		assign tmp[i] = b[i] ? tmp[i-1] << 2**i : tmp[i-1];
	end
endgenerate
assign c = tmp[S-1];

endmodule


/////////////////////////
module DSR_right_N_S(a,b,c);
        parameter N=16;
        parameter S=4;
        input [N-1:0] a;
        input [S-1:0] b;
        output [N-1:0] c;

wire [N-1:0] tmp [S-1:0];
assign tmp[0]  = b[0] ? a >> 7'd1  : a; 
genvar i;
generate
	for (i=1; i<S; i=i+1)begin:loop_blk
		assign tmp[i] = b[i] ? tmp[i-1] >> 2**i : tmp[i-1];
	end
endgenerate
assign c = tmp[S-1];

endmodule

/////////////////////////
module Mantissa_Multiplier_24x24
(
input clk,
input[ 24 - 1 : 0 ] a,
input[ 24 - 1 : 0 ] b,
output[ 48 - 1 : 0 ] product
);

wire [ 24 - 1 : 17 ] a_h = a [ 24 - 1 : 17 ];
wire [ 17 - 1 : 0 ] a_l = a [ 17 - 1 : 0 ];

reg [ 24 + 7 - 1 : 0 ] product_h;
reg [ 24 + 17 - 1 : 0 ] product_l;

//stage1 multiplication
always@( posedge clk ) begin
    product_h <= a_h * b;
    product_l <= a_l * b;
end

wire [ 48 - 1 : 0 ]  product_h_complete = { product_h, 17'd0 };

reg[ 48 - 1 : 0 ] product_reg;

always@( posedge clk ) begin
    product_reg <= product_h_complete + product_l;
end

assign product = product_reg;

endmodule

///////////////////////
module LOD_32(in, out);
input [31:0] in;
output [4:0] out;
wire [3:0] out_l, out_h;
wire out_vl, out_vh;
LOD16_4 pl(.in(in[15:0]), .out(out_l), .out_v(out_vl));
LOD16_4 ph(.in(in[31:16]), .out(out_h), .out_v(out_vh));
assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
endmodule

////////////////////
module LOD16_4(in, out, out_v);
input [15:0] in;
output [3:0] out;
output out_v;
wire [2:0] out_l, out_h;
wire out_vl, out_vh;
LOD8_3 pl(.in(in[7:0]), .out(out_l), .out_v(out_vl));
LOD8_3 ph(.in(in[15:8]), .out(out_h), .out_v(out_vh));
assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
assign out_v = out_vl | out_vh;
endmodule


////////////////////
module LOD8_3(in, out, out_v);
input [7:0] in;
output [2:0] out;
output out_v;

wire [1:0] out_l, out_h;
wire out_vl, out_vh;
LOD4_2 pl(.in(in[3:0]), .out(out_l), .out_v(out_vl));
LOD4_2 ph(.in(in[7:4]), .out(out_h), .out_v(out_vh));
assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
assign out_v = out_vl | out_vh;

endmodule


////////////////////
module LOD4_2(in, out, out_v);
input [3:0] in;
output [1:0] out;
output out_v;

wire out_l, out_h;
wire out_vl, out_vh;
LOD2_1 pl(.in(in[1:0]), .out(out_l), .out_v(out_vl));
LOD2_1 ph(.in(in[3:2]), .out(out_h), .out_v(out_vh));
assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};
assign out_v = out_vl | out_vh;

endmodule


module LOD2_1(in, out, out_v);
input [1:0] in;
output out;
output out_v;

assign out = ~in[1] & in[0];
assign out_v = |in;
endmodule
