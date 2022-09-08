module VPU #(
    parameter P  = 64
)( 
    // Vector  
    input   wire   [(P*8)-1:0]  VPU_in_x,   
    input   wire   [(P*8)-1:0]  VPU_in_y,
    input   wire   [(P*8)-1:0]  VPU_in_z,

    input   wire                first,
    input   wire                mode,           // 0:Mul 1:MAC 2:Inner_Product
    input   wire                inv,            // Inversion(GRU)
    input   wire                acc,
    input   wire   [1:0]        fp_dst,
    input   wire   [1:0]        fp_in0,
    input   wire   [1:0]        fp_in1,
    input   wire   [1:0]        th,

    output  wire    [P*8-1:0]   VPU_out_rslt,
    output  wire    [P-1:0]     VPU_out_nonz_info,
 
    input   wire                clk,
    input   wire                rst
);

wire        [2*P*8-1:0]         FP_mul;       

wire        [P*8-1:0]           MC_in2;    
wire        [2*P*8-1:0]         MC_mul;      
reg         [P*(2*8+4)-1:0]     MC_mul_tmp;   
wire        [P*(4*8)-1:0]       MC_add;       
reg         [P*(2*8+4)-1:0]     MC_add_tmp;   

wire                            MC_mode;      
wire                            MC_acc;

wire        [1:0]               MC_fp_dst;
wire        [1:0]               MC_fp_in0;
wire        [1:0]               MC_fp_in1;
wire        [1:0]               MC_th;

wire                            MC_first;

wire         [P*(4*8)-1:0]      mvma_acc;

Dreg_We_Rst #(
        .WIDTH((4*8)*P),
        .RESET_VALUE({((4*8)*P){1'b0}})
) MC_reg_acc(
        .i(MC_add),
        .o(mvma_acc),
        .we(MC_mode),
        .clk(clk),
        .rst(rst | !mode)
);

//Multiplication
generate
  genvar idx0;
  for(idx0 = 0; idx0 < P; idx0 = idx0+1) begin : mul_blk 
          CLIP_MUL_TC #(
                  .W(8))
          elem_mul(
                  .in0(inv ? (~VPU_in_y[8*(idx0+1)-1:8*idx0]) : VPU_in_y[8*(idx0+1)-1:8*idx0]),
                  .in1(VPU_in_x[8*(idx0+1)-1:8*idx0]),
                  .fp_in1(fp_in1),
                  .out(FP_mul[2*8*(idx0+1)-1:2*8*idx0])
          );
  end
endgenerate

//Pipeline Register
Dreg#(
        .WIDTH(P*8 + 2*P*8 + 1 + 1 + 6 + 1 + 2)
)FPMC_datapath(
        .i({VPU_in_z, FP_mul, mode     , acc     , fp_dst     , fp_in0     , fp_in1     , first    , th}),
        .o({MC_in2, MC_mul, MC_mode, MC_acc, MC_fp_dst, MC_fp_in0, MC_fp_in1, MC_first, MC_th}),
        .clk(clk)
);

//Addition
generate
    genvar idx1;
    for(idx1 = 0; idx1 < P; idx1 = idx1+1) begin : add_blk
        always @*
                case ({(MC_fp_in0[1] ^ MC_fp_in1[1]), MC_fp_in0[0] ^ MC_fp_in1[0]})
                        2'b00: MC_mul_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = MC_mode ? {{(4){MC_mul[2*8*(idx1+1)-1]}}, MC_mul[2*8*(idx1+1)-1:2*8*idx1]} : {MC_mul[2*8*(idx1+1)-1:2*8*idx1], 4'd0}; // <<0 : <<4
                        2'b01: MC_mul_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(2){MC_mul[(2*8)*(idx1+1)-1]}}, MC_mul[(2*8)*(idx1+1)-1:(2*8)*idx1], 2'd0}; // <<2
                        2'b10: MC_mul_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(5){MC_mul[(2*8)*(idx1+1)-1]}}, MC_mul[(2*8)*(idx1+1)-1:(2*8)*idx1+1]};     // >>1
                        2'b11: MC_mul_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(3){MC_mul[(2*8)*(idx1+1)-1]}}, MC_mul[(2*8)*(idx1+1)-1:(2*8)*idx1], 1'd0};                    // <<1      
                endcase
        always @*
                casex ({MC_mode, MC_fp_dst})
                        3'b000:   MC_add_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(6){1'd0}}                       , MC_in2[8*(idx1+1)-1:8*idx1]     , 6'd0};
                        3'b010:   MC_add_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(5){MC_in2[8*(idx1+1)-1]}}     , MC_in2[8*(idx1+1)-1:8*idx1]     , 7'd0};
                        3'b011:   MC_add_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(3){MC_in2[8*(idx1+1)-1]}}     , MC_in2[8*(idx1+1)-1:8*idx1]     , 9'd0};
                        3'b1xx:   MC_add_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = {{(5){MC_in2[8*(idx1+1)-1]}}     , MC_in2[8*(idx1+1)-1:8*idx1], 7'd0};
                        default:  MC_add_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1] = 20'd0;
                endcase
        CLIP_ADD_TC #(
                .W(8)) 
        elem_add(
                .in1({{(2){MC_mul_tmp[(2*8+4)*(idx1+1)-1]}}, MC_mul_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1], 10'd0}),
                .in2(!MC_mode | MC_first ? {{(2){MC_add_tmp[(2*8+4)*(idx1+1)-1]}}, MC_add_tmp[(2*8+4)*(idx1+1)-1:(2*8+4)*idx1], 10'd0} : mvma_acc[(4*8)*(idx1+1)-1:(4*8)*idx1]),
                .out(MC_add[(4*8)*(idx1+1)-1:(4*8)*idx1])
                );
    end
endgenerate

//Clipping & Pruning
generate
    genvar idx2;
    for(idx2 = 0; idx2 < P; idx2 = idx2+1) begin : clip_blk
        FAU_PRU #(
                .W(8)) 
        elem_clip_prun(
                .in(MC_mode | MC_acc ? MC_add[(4*8)*(idx2+1)-1:(4*8)*idx2] : {{(2){MC_mul_tmp[(2*8+4)*(idx2+1)-1]}}, MC_mul_tmp[(2*8+4)*(idx2+1)-1:(2*8+4)*idx2], 10'd0}),
                .fp_dst(MC_fp_dst),
                .th(MC_th),
                .FAU_out(VPU_out_rslt[8*(idx2+1)-1:8*(idx2)]),
                .PRU_out(VPU_out_nonz_info[63-idx2])
                );
    end
endgenerate

endmodule