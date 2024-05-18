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

module HBS
#(
parameter BITWIDTH_MIN = 4,
parameter NUM = 4
)
(
    input clk,
    input rst_n,
    input [1:0] mode,
    
    // data input ports
    input unsigned [16-1:0] mult0,
    input unsigned [16-1:0] mult1,
    //input unsigned [32-1:0] add,

    output reg unsigned [32-1:0] result
);

localparam MODE4 = 2'b00;
localparam MODE8 = 2'b01;
localparam MODE16 = 2'b10;

wire unsigned [ BITWIDTH_MIN - 1 : 0 ] a [ NUM - 1 : 0 ];
assign a[0] = mult0[ 4- 1 : 0 ];
assign a[1] = mult0[ 8- 1 : 4 ];
assign a[2] = mult0[ 12- 1 : 8 ];
assign a[3] = mult0[ 16- 1 : 12 ];

wire unsigned [ BITWIDTH_MIN - 1 : 0 ] b [ NUM - 1 : 0 ];
assign b[0] = mult1[ 4- 1 : 0 ];
assign b[1] = mult1[ 8- 1 : 4 ];
assign b[2] = mult1[ 12- 1 : 8 ];
assign b[3] = mult1[ 16- 1 : 12 ];

// mulplication product array
reg unsigned [ 8 - 1 : 0 ] c [ NUM - 1 : 0 ][ NUM - 1 : 0 ];
integer col;
integer row;

//multiplier array
always@( posedge clk or negedge rst_n ) begin

if ( !rst_n ) begin
    for ( row = 0; row < NUM; row = row + 1 ) begin
        for ( col = 0; col < NUM; col = col + 1 ) begin
            c[row][col] <= 0;
        end
    end
end

//16 bit mode
else if ( mode == MODE16 ) begin
    for ( row = 0; row < NUM; row = row + 1 ) begin
        for ( col = 0; col < NUM; col = col + 1 ) begin
            c[row][col] <= a[row]*b[col];
        end
    end
end

//8 bit mode
else if ( mode == MODE8 ) begin
    for ( row = 0; row < NUM; row = row + 1 ) begin
        for ( col = 0; col < NUM; col = col + 1 ) begin
            if ( ( row < 2 && col < 2 ) || ( row >= 2 && col >= 2 ) ) begin
                c[row][col] <= a[row]*b[col];
            end
            else begin
                c[row][col] <= 0;
            end
        end
    end
end

//4 bit mode
else if ( mode == MODE4 ) begin
    for ( row = 0; row < NUM; row = row + 1 ) begin
        for ( col = 0; col < NUM; col = col + 1 ) begin
            if ( row == col ) begin
                c[row][col] <= a[row]*b[col];
            end
            else begin
                c[row][col] <= 0;
            end
        end
    end
end

end

//
wire unsigned [16-1:0] sum[4-1:0]; 
adder4 adder4_( .clk(clk), .rst_n(rst_n), .c00( c[0][0] ), .c01( c[0][1] ), .c10( c[1][0] ), .c11( c[1][1] ), .result( sum[0] ) ); 
adder4 adder4_0( .clk(clk), .rst_n(rst_n), .c00( c[0][2] ), .c01( c[0][3] ), .c10( c[1][2] ), .c11( c[1][3] ), .result( sum[1] ) ); 
adder4 adder4_1( .clk(clk), .rst_n(rst_n), .c00( c[2][0] ), .c01( c[2][1] ), .c10( c[3][0] ), .c11( c[3][1] ), .result( sum[2] ) ); 
adder4 adder4_2( .clk(clk), .rst_n(rst_n), .c00( c[2][2] ), .c01( c[2][3] ), .c10( c[3][2] ), .c11( c[3][3] ), .result( sum[3] ) ); 

wire unsigned [ 32 - 1 : 0 ] sum_concat; 
assign sum_concat = { sum[3][16-1:0], sum[0][16-1:0] }; 
wire unsigned [ 24 - 1 : 0 ] sum2_left;  
assign sum2_left = { sum[2][16-1:0], 8'h00 }; 
wire unsigned [ 24 - 1 : 0 ] sum1_left; 
assign sum1_left = { sum[1][16-1:0], 8'h00 }; 

always@( posedge clk or negedge rst_n )begin 

if ( !rst_n ) begin 
result <= 0; 
end 

else begin 
result <= sum_concat + sum2_left + sum1_left; 
end
end

endmodule
