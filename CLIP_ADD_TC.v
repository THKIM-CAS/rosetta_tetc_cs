module CLIP_ADD_TC #(
		parameter W = 8
	)(
	input 	wire [31:0]  in1,
	input 	wire [31:0]  in2,
	output 	wire signed [31:0]  out	
	);

	assign out = $signed(in1) + $signed(in2);

endmodule