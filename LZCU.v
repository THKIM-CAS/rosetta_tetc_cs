module LZCU #(
        parameter LZC_WIDTH = 7,
        parameter I_WIDTH = 2**(LZC_WIDTH-1)
)(
        output reg [LZC_WIDTH-1:0] out,
        input wire [I_WIDTH-1:0] in
);

generate
        if(I_WIDTH == 2) begin: blk_end
                always @*
                        case(in)
                                2'b00: out = 2'd2;
                                2'b01: out = 2'd1;
                                2'b10: out = 2'd0;
                                2'b11: out = 2'd0;
                        endcase
        end
        else begin: blk_nonend
                wire [LZC_WIDTH-2:0] o0, o1;
                LZCU #(.LZC_WIDTH(LZC_WIDTH-1)) u0(.in(in[I_WIDTH-1:I_WIDTH/2]), .out(o0));
                LZCU #(.LZC_WIDTH(LZC_WIDTH-1)) u1(.in(in[I_WIDTH/2-1:0]), .out(o1));
                always @*
                        casex({o0[LZC_WIDTH-2], o1[LZC_WIDTH-2]})
                                {1'b1, 1'b1}: out = {1'b1, {(LZC_WIDTH-1){1'b0}}};
                                {1'b1, 1'b0}: out = {2'b01, o1[LZC_WIDTH-3:0]};
                                {1'b0, 1'bx}: out = {2'b00, o0[LZC_WIDTH-3:0]};
                        endcase
        end
endgenerate
endmodule