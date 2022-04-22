module PRU #(
		parameter W = 8,
        parameter TH = 0// W-TH 0, 1, 2, 3 = zero, 0.25, 0.125, 0.0625
	)(
	input 	wire [7:0]          in,
    input   wire [1:0]          fp_dst,
    input   wire [1:0]          th,
    output 	wire [W-1:0]        out,
    output  reg                 out_zero
	);

always @*
    case (th)
        2'b00:  out_zero = |in;
        2'b01:  out_zero = fp_dst[1] ? !(|in[7:1]) : !(|in[7:1]) | &in[7:1];
        2'b10:  out_zero = fp_dst[1] ? !(|in[7:1]) : !(|in[7:2]) | &in[7:2];
        2'b11:  out_zero = fp_dst[1] ? !(|in[7:1]) : !(|in[7:3]) | &in[7:3];
    endcase

    assign out      = out_zero ? in : 8'd0;

endmodule
