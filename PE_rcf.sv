`timescale 1ns / 1ps

module PE_rcf
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

//  left shift
reg unsigned [ 32 - 1 : 0 ] product_shift [ 16 - 1 : 0 ];

always@ ( posedge clk or negedge rst_n ) begin

if ( !rst_n ) begin
    for ( row = 0; row < NUM; row = row + 1 ) begin
        for ( col = 0; col < NUM; col = col + 1 ) begin
            product_shift[row*4 + col] <= 0;
        end
    end
end

else begin
    for ( row = 0; row < NUM; row = row + 1 ) begin
        for ( col = 0; col < NUM; col = col + 1 ) begin;
            product_shift[ row*4 + col ] <= c[row][col] << (4*( row + col ));
        end
    end
end

end

//log2n sum tree
reg unsigned [32-1 : 0] add1 [ 8-1 : 0 ];
reg unsigned [32-1 : 0] add2 [ 4-1 : 0 ];
reg unsigned [32-1 : 0] add3 [ 2-1 : 0 ];

integer j;
integer k;
integer l;
always @ ( posedge clk or negedge rst_n ) begin
if ( !rst_n ) begin
    for ( j = 0; j < 8; j = j + 1 ) begin
        add1[j] <= 0;
    end
    
    for ( k = 0; k < 4; k = k + 1 ) begin
        add2[k] <= 0;
    end
    
    for ( l = 0; l < 2; l = l + 1 ) begin
        add3[l] <= 0;
    end
end

else begin
    for ( j = 0; j < 8; j = j + 1 ) begin
        add1[j] <= product_shift[j] + product_shift[16-1-j];
    end
    for ( k = 0; k < 4; k = k + 1 ) begin
        add2[k] <= add1[k] + add1[8-1-k];
    end
    
    for ( l = 0; l < 2; l = l + 1 ) begin
        add3[l] <= add2[l] + add2[4-1-l];
    end
end

end

always @ ( posedge clk or negedge rst_n ) begin

if ( !rst_n ) begin
result <= 0;
end

else begin
result <= add3[0] + add3[1];
end
end

endmodule
