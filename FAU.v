module FAU #(
		parameter W = 8
)(
	input 	wire [31:0]         in,
    input   wire [1:0]          fp_dst,
	output 	reg  [W-1:0]        out
);

always @*
    casex ({fp_dst, in[31]})
        3'b0xx:    out = |in[31:24] ?  8'hff            : in[23:16];
        3'b100:    out = |in[31:24] ? {1'b0, 7'h7f}     : {1'b0, in[23:17]};
        3'b101:    out = &in[31:24] ? {1'b1, in[23:17]} : {1'b1, 7'h0};
        3'b110:    out = |in[31:26] ? {1'b0, 7'h0}      : {1'b0, in[25:19]};
        3'b111:    out = &in[31:26] ? {1'b1, in[25:19]} : {1'b1, 7'h0};
    endcase

endmodule