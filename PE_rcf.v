module PE_rcf
(
    input clk,
    input rst_n,
    input [1:0] mode,
    
    // data input ports
    input unsigned [16-1:0] mult0,
    input unsigned [16-1:0] mult1,
    input unsigned [64-1:0] add_in,

    output unsigned [64-1:0] result
);

wire [ 32 - 1 : 0 ] product;
HBS hbs ( .clk(clk), .rst_n(rst_n), .mode(mode), .mult0(mult0), .mult1(mult1), .result(product) );

wire [ 64 - 1 : 0 ] sum;
ADD_rcf add_rcf ( .clk(clk), .rst_n(rst_n), .mode(mode), .product(product), .add_in(add_in), .result(sum) );

assign result = sum;

endmodule
