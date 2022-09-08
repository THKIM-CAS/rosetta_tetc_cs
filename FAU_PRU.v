module FAU_PRU #(
		parameter W = 8,
        parameter TH = 0// W-TH 0, 1, 2, 3 = zero, 0.25, 0.125, 0.0625
	)(
	input 	wire [31:0]         in,
    input   wire [1:0]          fp_dst,
    input   wire [1:0]          th,
	output 	reg  [W-1:0]        FAU_out,
    output  reg                 PRU_out
	);

always @*
    casex ({fp_dst, in[31]})
        3'b0xx:    FAU_out = |in[31:24] ?  8'hff            : in[23:16];
        3'b100:    FAU_out = |in[31:24] ? {1'b0, 7'h7f}     : {1'b0, in[23:17]};
        3'b101:    FAU_out = &in[31:24] ? {1'b1, in[23:17]} : {1'b1, 7'h0};
        3'b110:    FAU_out = |in[31:26] ? {1'b0, 7'h7f}      : {1'b0, in[25:19]};
        3'b111:    FAU_out = &in[31:26] ? {1'b1, in[25:19]} : {1'b1, 7'h0};
    endcase

always @*
    case (th)
        2'b00:  PRU_out = |FAU_out;
        2'b01:  PRU_out = fp_dst[1] ? !(|FAU_out[7:1]) : !(|FAU_out[7:1]) | &FAU_out[7:1];
        2'b10:  PRU_out = fp_dst[1] ? !(|FAU_out[7:1]) : !(|FAU_out[7:2]) | &FAU_out[7:2];
        2'b11:  PRU_out = fp_dst[1] ? !(|FAU_out[7:1]) : !(|FAU_out[7:3]) | &FAU_out[7:3];
    endcase

endmodule
