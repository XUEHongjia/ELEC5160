module polar(
  input clk,
  input reset,
  
  input [1:0]polar_in,
  output reg [1:0]polar_out
);

reg even = 1;

always @( posedge clk or posedge reset ) begin

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