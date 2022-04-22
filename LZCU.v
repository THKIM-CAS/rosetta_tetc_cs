module LZCU #(
        parameter LZC_WIDTH = 7,
        parameter I_WIDTH = 2**(LZC_WIDTH-1)
)(
        output reg [LZC_WIDTH-1:0] shamt,
        input wire [I_WIDTH-1:0] pam_rdata
);

generate
        if(I_WIDTH == 2) begin: blk_end
                reg [1:0] out;
                always @*
                        case(pam_rdata)
                                2'b00: shamt = 2'd2;
                                2'b01: shamt = 2'd1;
                                2'b10: shamt = 2'd0;
                                2'b11: shamt = 2'd0;
                        endcase
        end
        else begin: blk_nonend
                wire [LZC_WIDTH-2:0] o0, o1;
                LZCU #(.LZC_WIDTH(LZC_WIDTH-1)) u0(.pam_rdata(pam_rdata[I_WIDTH-1:I_WIDTH/2]), .shamt(o0));
                LZCU #(.LZC_WIDTH(LZC_WIDTH-1)) u1(.pam_rdata(pam_rdata[I_WIDTH/2-1:0]), .shamt(o1));
                always @*
                        casex({o0[LZC_WIDTH-2], o1[LZC_WIDTH-2]})
                                {1'b1, 1'b1}: shamt = {1'b1, {(LZC_WIDTH-1){1'b0}}};
                                {1'b1, 1'b0}: shamt = {2'b01, o1[LZC_WIDTH-3:0]};
                                {1'b0, 1'bx}: shamt = {2'b00, o0[LZC_WIDTH-3:0]};
                        endcase
        end
endgenerate
endmodule