`timescale 1ns / 1ps

module PE_tb;

   //============== (1) ==================
   //signals declaration
reg clk = 0;
reg rst_n = 0;
reg [1:0] mode = 2'b00;

reg unsigned [16-1:0] mult0;
reg unsigned [16-1:0] mult1;

wire unsigned [32-1 : 0] result;

    //============== (2) ==================
    //clock generating
real         CYCLE_100MHz = 10 ; //
always begin
    clk = 0 ; #(CYCLE_100MHz/2) ;
    clk = 1 ; #(CYCLE_100MHz/2) ;
end
    //============== (3) ==================
    //rst/rstn generating
initial begin
#100;
rst_n <= 1;
# 1200;
end

    //============== (4) ==================
    //motivation
always@( negedge clk or negedge rst_n ) begin
if ( !rst_n ) begin
mode <= 2'b11;
mult0 <= 0;
mult1 <= 0;
end

else begin
mode <= 2'b01;
mult0 <= 16'h0111;
mult1 <= 16'h0202;
end

end

    //============== (5) ==================
    //module instantiation
PE_rcf uut ( .clk( clk ), .rst_n( rst_n ), .mode( mode ), .mult0( mult0 ), .mult1( mult1 ), .result( result ) );
    
    //============== (6) ==================
    //auto check


    //============== (7) ==================
    //simulation finish
    
    
endmodule
