module Vector_Proc_Unit #(
    parameter W  = 8,
    parameter P  = 64
)(
    // Vector 
    input   wire    [P*W-1:0]   in0,
    input   wire    [P*W-1:0]   in1,
    input   wire    [P*W-1:0]   in2,
    input   wire    [P*W-1:0]   bm_rdata,

    input                       first,
    input                       i_end,
    input   wire                mode,           
    input   wire                inv,            // Inversion(GRU)
    input   wire                acc,
    input          [1:0]        fp_dst,
    input          [1:0]        fp_in0,
    input          [1:0]        fp_in1,
    input          [1:0]        th,

    output  wire    [P*W-1:0]   out,
    output  wire    [P-1:0]     out_zero,

    input   wire                clk,
    input   wire                rst
);

wire        [2*P*W-1:0]         COM1_mul;    

wire        [P*W-1:0]           COM2_in2;  
wire        [2*P*W-1:0]         COM2_mul;       
reg         [P*(2*W+4)-1:0]     COM2_mul_tmp;   
wire        [P*(4*W)-1:0]       COM2_add;       
reg         [P*(2*W+4)-1:0]     COM2_add_tmp;   
wire        [P*W-1:0]           COM2_bm_rdata;  

wire                            COM2_i_end;
wire                            COM2_mode;      
wire                            COM2_acc;

wire        [1:0]               COM2_fp_dst;
wire        [1:0]               COM2_fp_in0;
wire        [1:0]               COM2_fp_in1;
wire        [1:0]               COM2_th;

wire                            COM2_first;

wire         [P*(4*W)-1:0]      mvma_acc;

wire                            latch_COM2_first;

wire         [P*W-1:0]          FAU_out;

Dreg_We_Rst #(
        .WIDTH((4*W)*P),
        .RESET_VALUE({((4*W)*P){1'b0}})
) COM2_reg_acc(
        .i(COM2_add),
        .o(mvma_acc),
        .we(COM2_mode),
        .clk(clk),
        .rst(rst | COM2_i_end | !mode)
);

Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
) latched_COM2_first(
        .i(COM2_first),
        .o(latch_COM2_first),
        .clk(clk),
        .rst(rst)
);

//Multiplication
generate
  genvar idx0;
  for(idx0 = 0; idx0 < P; idx0 = idx0+1) begin : mul_blk
          MUL_TC #(
                  .W(W))
          elem_mul(
                  .in0(inv ? ~in0[W*(idx0+1)-1:W*idx0] : in0[W*(idx0+1)-1:W*idx0]),
                  .in1(in1[W*(idx0+1)-1:W*idx0]),
                  .fp_in1(fp_in1),
                  .out(COM1_mul[2*W*(idx0+1)-1:2*W*idx0])
                  );
  end
endgenerate

//Pipeline Register
Dreg#(
        .WIDTH(P*W + P*W + 2*P*W + 1 + 1 + 6 + 1 + 1 + 2)
)COM1COM2_datapath(
        .i({in2     , bm_rdata     , COM1_mul, mode     , acc     , fp_dst     , fp_in0     , fp_in1     , first    , i_end     , th}),
        .o({COM2_in2, COM2_bm_rdata, COM2_mul, COM2_mode,COM2_acc, COM2_fp_dst, COM2_fp_in0, COM2_fp_in1, COM2_first, COM2_i_end, COM2_th}),
        .clk(clk)
);

generate
    genvar idx1;
    for(idx1 = 0; idx1 < P; idx1 = idx1+1) begin : add_blk
        always @*
                case (COM2_fp_in0 ^ COM2_fp_in1)
                        2'b00: COM2_mul_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = COM2_fp_in0[0] ? {{(4){COM2_mul[2*W*(idx1+1)-1]}}, COM2_mul[2*W*(idx1+1)-1:2*W*idx1]} : {COM2_mul[2*W*(idx1+1)-1:2*W*idx1], 4'd0};
                        2'b01: COM2_mul_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(2){COM2_mul[(2*W)*(idx1+1)-1]}}, COM2_mul[(2*W)*(idx1+1)-1:(2*W)*idx1], 2'd0};
                        2'b10: COM2_mul_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(5){COM2_mul[(2*W)*(idx1+1)-1]}}, COM2_mul[(2*W)*(idx1+1)-1:(2*W)*idx1+1]};    
                        2'b11: COM2_mul_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(6){1'b0}}, COM2_mul[(2*W)*(idx1+1)-1-3:(2*W)*idx1], 1'd0};                          
                endcase
        always @*
                casex ({COM2_mode, COM2_fp_dst})
                        3'b000:   COM2_add_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(6){1'd0}}                       , COM2_in2[W*(idx1+1)-1:W*idx1]     , 6'd0};
                        3'b010:   COM2_add_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(5){COM2_in2[W*(idx1+1)-1]}}     , COM2_in2[W*(idx1+1)-1:W*idx1]     , 7'd0};
                        3'b011:   COM2_add_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(3){COM2_in2[W*(idx1+1)-1]}}     , COM2_in2[W*(idx1+1)-1:W*idx1]     , 9'd0};
                        3'b1xx:   COM2_add_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = {{(5){COM2_bm_rdata[W*(idx1+1)-1]}}, COM2_bm_rdata[W*(idx1+1)-1:W*idx1], 7'd0};
                        default:  COM2_add_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1] = 20'd0;
                endcase
        ADD_TC #(
                .W(W)) 
        elem_add(
                .in1({{(2){COM2_mul_tmp[(2*W+4)*(idx1+1)-1]}}, COM2_mul_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1], 10'd0}),
                .in2(!COM2_mode | latch_COM2_first ? {{(2){COM2_add_tmp[(2*W+4)*(idx1+1)-1]}}, COM2_add_tmp[(2*W+4)*(idx1+1)-1:(2*W+4)*idx1], 10'd0} : mvma_acc[(4*W)*(idx1+1)-1:(4*W)*idx1]),
                .out(COM2_add[(4*W)*(idx1+1)-1:(4*W)*idx1])
                );
    end
endgenerate

//FAU & PRU
generate
    genvar idx2;
    for(idx2 = 0; idx2 < P; idx2 = idx2+1) begin : fau_pru_blk
        FAU #(
                .W(W)) 
        elem_fau(
                .in(COM2_mode | COM2_acc ? COM2_add[(4*W)*(idx2+1)-1:(4*W)*idx2] : {{(2){COM2_mul_tmp[(2*W+4)*(idx2+1)-1]}}, COM2_mul_tmp[(2*W+4)*(idx2+1)-1:(2*W+4)*idx2], 10'd0}),
                .fp_dst(COM2_fp_dst),
                .out(FAU_out[W*(idx2+1)-1:W*idx2])
                );
        PRU #(
                .W(W)) 
        elem_pru(
                .in(FAU_out[W*(idx2+1)-1:W*idx2]),
                .fp_dst(COM2_fp_dst),
                .th(COM2_th),
                .out_zero(out_zero[idx2]),
                .out(out[W*(idx2+1)-1:W*idx2])
                );
    end
endgenerate

endmodule