`timescale 1ns / 1ps

module adder4(
    input clk,
    input rst_n,
    
    input unsigned [8-1:0] c00,
    input unsigned [8-1:0] c01,
    input unsigned [8-1:0] c10,
    input unsigned [8-1:0] c11,

    output reg unsigned [16-1:0] result
    );

wire unsigned [ 16 - 1 : 0 ] c_concat;
assign c_concat = { c11[8-1:0], c00[8-1:0] };
wire unsigned [ 12 - 1 : 0 ] c01_left;
wire unsigned [ 12 - 1 : 0 ] c10_left;
    assign c01_left = { c01[8-1:0], 4'h0 };
    assign c10_left = { c10[8-1:0], 4'h0 };

always@( posedge clk or negedge rst_n ) begin

if ( !rst_n ) begin
    result <= 0;
end

else begin
    result <= c_concat + c01_left + c10_left;
end

end

endmodule
