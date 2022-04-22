module MUL_TC #(
		parameter W = 8
	)(
	input 	wire  	[W-1:0]  in0,
	input 	wire 	[W-1:0]  in1,
	output 	wire signed [2*W-1:0]  out,
	input	wire    [1:0]	 fp_in1
	);

	wire signed [16:0]  out_tmp;

	assign out_tmp = $signed(in0) * (|fp_in1 ? $signed(in1) :$signed({1'd0, in1[7:0]}));
	assign out = out_tmp[15:0];

endmodule

