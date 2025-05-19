`timescale 1ns / 1ps

module posit_div_tb(

    );
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
parameter es = 6;

reg [N-1:0] in1, in2;
reg start; 
wire out_s;
wire [Bs-1:0] out_r;
wire [Bs+es-1:0]out_e;
wire [N-1:0] out_m, out;
wire done;

reg clk;
integer outfile;
parameter length = 9;

// Instantiate the Unit Under Test (UUT)
Posit_div_N32_ES6_PIPE12 #(.N(N), .es(es)) 
uut (
.clk(clk), 
.in1(in1), 
.in2(in2), 
.start(start), 
.out(out), 
.inf(inf), 
.zero(zero), 
.done(done)
);

reg [N-1:0] data1 [1:length];
reg [N-1:0] data2 [1:length];
initial $readmemb("op2.txt",data1);
initial $readmemb("op1.txt",data2);

reg [15:0] i;
	
	initial begin
		// Initialize Inputs
		in1 = 0;
		in2 = 0;
		clk = 0;
		start = 0;
		
		// Wait 100 ns for global reset to finish
		#100 i=0;
		#20 start = 1;
        #655500 start = 0;
		#100;
		
		$fclose(outfile);
		$finish;
	end
	
 always #5 clk=~clk;

  always @(negedge clk) begin			
 	in1=data1[i];	
	in2=data2[i];
	if(i==16'd22)
  	$finish;
	else i = i + 1;
 end

initial outfile = $fopen("error_bit.txt", "wb");

reg [N-1:0] result [1:length];
initial $readmemb("quotient.txt",result);
reg [N-1:0] diff;
always @(negedge clk) begin
	if(start)begin
     	diff = (result[i-13] > out) ? result[i-13]-out : out-result[i-13];
     	//$fwrite(outfile, "%h\t%h\t%h\t%h\t%d\n",in1, in2, out,result[i-1],diff);
     	$fwrite(outfile, "%d\n",diff);
     	end
end
endmodule
