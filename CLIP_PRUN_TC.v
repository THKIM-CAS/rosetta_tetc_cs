module CLIP_PRUN_TC #(
		parameter W = 8,
        parameter TH = 0// W-TH 0, 1, 2, 3 = zero, 0.25, 0.125, 0.0625
	)(
	input 	wire [31:0]         in,
    input   wire [1:0]          fp_dst,
    input   wire [1:0]          th,
	output 	wire [W-1:0]        out,
    output  wire                out_zero
	);

reg [W-1:0] out_tmp;
reg out_zero_tmp;

always @*
    casex ({fp_dst, in[31]})
        3'b0xx:    out_tmp = |in[31:24] ?  8'hff            : in[23:16];
        3'b100:    out_tmp = |in[31:24] ? {1'b0, 7'h7f}     : {1'b0, in[23:17]};
        3'b101:    out_tmp = &in[31:24] ? {1'b1, in[23:17]} : {1'b1, 7'h0};
        3'b110:    out_tmp = |in[31:26] ? {1'b0, 7'h7f}      : {1'b0, in[25:19]};
        3'b111:    out_tmp = &in[31:26] ? {1'b1, in[25:19]} : {1'b1, 7'h0};
    endcase

always @*
    case (th)
        2'b00:  out_zero_tmp = |out_tmp;
        2'b01:  out_zero_tmp = fp_dst[1] ? !(|out_tmp[7:1]) : !(|out_tmp[7:1]) | &out_tmp[7:1];
        2'b10:  out_zero_tmp = fp_dst[1] ? !(|out_tmp[7:1]) : !(|out_tmp[7:2]) | &out_tmp[7:2];
        2'b11:  out_zero_tmp = fp_dst[1] ? !(|out_tmp[7:1]) : !(|out_tmp[7:3]) | &out_tmp[7:3];
    endcase

    assign out_zero = out_zero_tmp;
    assign out      = out_zero_tmp ? out_tmp : 8'd0;

endmodule
