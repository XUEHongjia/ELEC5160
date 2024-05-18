module ADD_rcf
(
input clk,
input rst_n,
input [1:0] mode,

input [ 32 - 1 : 0 ] product,
input [ 64 - 1 : 0 ] add_in,

output reg [ 64 - 1 : 0 ] result
);

localparam MODE4 = 2'b00;
localparam MODE8 = 2'b01;
localparam MODE16 = 2'b10;

// mode 8
wire [ 16 - 1 : 0 ] product_mode8[ 1 : 0 ];
assign product_mode8[0] = { product [16-1:0] };
assign product_mode8[1] = { product [32-1:16] };

wire [ 32 - 1 : 0 ] add_in_mode8 [ 1 : 0 ];
assign add_in_mode8[0] = { add_in[ 32 - 1 : 0 ] };
assign add_in_mode8[1] = { add_in[ 64 - 1 : 32 ] };

wire [ 32 - 1 : 0 ] sum_mode8 [ 1 : 0 ];
assign sum_mode8[0] = product_mode8[0] + add_in_mode8[0];
assign sum_mode8[1] = product_mode8[1] + add_in_mode8[1];

//mode4
wire [ 8 - 1 : 0 ] product_mode4[ 4 - 1 : 0 ];
assign product_mode4[0] = { product [8-1:0] };
assign product_mode4[1] = { product [16-1:8] };
assign product_mode4[2] = { product [24-1:16] };
assign product_mode4[3] = { product [32-1:24] };

wire [ 16 - 1 : 0 ] add_in_mode4 [ 4 - 1 : 0 ];
assign add_in_mode4[0] = { add_in[ 16 - 1 : 0 ] };
assign add_in_mode4[1] = { add_in[ 32 - 1 : 16 ] };
assign add_in_mode4[2] = { add_in[ 48 - 1 : 32 ] };
assign add_in_mode4[3] = { add_in[ 64 - 1 : 48 ] };

wire [ 16 - 1 : 0 ] sum_mode4 [ 4 - 1 : 0 ];
assign sum_mode4[0] = product_mode4[0] + add_in_mode4[0];
assign sum_mode4[1] = product_mode4[1] + add_in_mode4[1];
assign sum_mode4[2] = product_mode4[2] + add_in_mode4[2];
assign sum_mode4[3] = product_mode4[3] + add_in_mode4[3];

always@( posedge clk or negedge rst_n ) begin

if ( !rst_n ) begin
result <= 0;
end

else if ( mode == MODE16 ) begin
result <= add_in + product;
end

else if ( mode == MODE4 ) begin
result <= { sum_mode4[3], sum_mode4[2], sum_mode4[1], sum_mode4[0] };
end

else if ( mode == MODE8 ) begin
result <= { sum_mode8[1], sum_mode8[0] };
end

end

endmodule
