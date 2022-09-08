module ROSETTA_Core #(
    parameter P = 64,                            // # of PEs: must be a power of 2
    parameter W = 8                             // word size
)(
  
    output  wire                im_ren,    
    output  wire    [7:0]       im_raddr,
    input   wire    [31:0]      im_rdata,

    output  wire                bm_ren,
    output  wire    [4:0]       bm_raddr,
    input   wire    [P*W-1:0]   bm_rdata,

    output  wire                wm_ren,
    output  wire    [10:0]      wm_raddr,
    input   wire    [P*W-1:0]   wm_rdata,

    output  wire                pam_x_ren,
    output  wire    [3:0]       pam_x_raddr,
    input   wire    [P-1:0]     pam_x_rdata,

    output  wire                pam_y_ren,
    output  wire    [4:0]       pam_y_raddr,
    input   wire    [P-1:0]     pam_y_rdata,

    output  wire                pam_r_ren,    
    output  wire    [4:0]       pam_r_raddr,
    input   wire    [P-1:0]     pam_r_rdata,
 
    output  wire                pam_r_wen,
    output  wire    [4:0]       pam_r_waddr,
    output  wire    [P-1:0]     pam_r_wdata,

    output  wire                am_x_ren,
    output  wire    [4:0]       am_x_raddr,
    output  wire    [P-1:0]     am_x_rcs,
    input   wire    [P*W-1:0]   am_x_rdata,
 
    output  wire                am_y_ren,
    output  wire    [4:0]       am_y_raddr,
    output  wire    [P-1:0]     am_y_rcs,
    input   wire    [P*W-1:0]   am_y_rdata, 

    output  wire                am_r_ren,    
    output  wire    [4:0]       am_r_raddr,
    output  wire    [P-1:0]     am_r_rcs,
    input   wire    [P*W-1:0]   am_r_rdata,

    output  wire                am_r_wen,
    output  wire    [4:0]       am_r_waddr,
    output  wire    [P-1:0]     am_r_wcs,
    output  wire    [P*W-1:0]   am_r_wdata,

    output  wire                done,

    input   wire    [3:0]       alp_plus_beta,
    input   wire    [2:0]       beta,

    // Clock & Reset
    input   wire    clk,
    input   wire    rst     // Sync & Active-high
);

wire    [31:0]  inst, RM_inst, MC_inst;
wire    [12:0]  MC_inst;

wire            all_done;

wire            first_cycle;
wire            beta_done;
wire            alp_plus_beta_done;
wire            p_done;
wire            beta_last_bound;
wire            alp_plus_beta_last_bound;
wire            p_last_bound;

wire    [3:0]   x_addr_cntr_rdata;
wire    [2:0]   r_addr_cntr_rdata;
wire    [2:0]   nops_cntr_rdata;
wire            nops_done;
wire            pam_r_wen_ctrl;

wire    [P-1:0] shfted_pam_x_rdata;

wire            WB_done_wen, RM_done_wen, MC_done_wen, FP_done_wen;
wire            ZB_am_r_wen, WB_am_r_wen, RM_am_r_wen, MC_am_r_wen, FP_am_r_wen;

wire            x_addr_wen;
wire            x_addr_rst;
wire            r_addr_wen;
wire            r_addr_rst;
wire            inst_done;
wire    [2:0]   bias_cntr_inc;

wire    [4:0]   RM_am_r_raddr, MC_am_r_raddr, FP_am_r_raddr, WB_am_r_raddr;

wire            lzcu_in_sel;
wire            ZB_acc_set_bias;
wire            RM_acc_set_bias;
wire            MC_acc_set_bias;
wire            ZB_done_wen;
wire im_ren_first;


wire pam_x_ren_ctrl;

wire nops_cntr_we;

wire RM_first_cycle;
wire [3:0] ZB_pam_x_raddr;


wire    [63:0]  raccess_xy, raccess_z;
wire    [63:0]  RM_raccess_xy, MC_raccess_xy, FP_raccess_xy, WB_raccess_xy;
wire    [63:0]  RM_raccess_z;


wire    [63:0]  lzcu_in;
wire    [6:0]   lzcu_out;
wire    [5:0]   RM_lzcu_out;

wire            im_ren_ctrl, wm_ren_ctrl, bm_ren_ctrl;
wire [6:0] popcnt_l, popcnt_h, popcnt, RM_popcnt;

wire    [6:0]   shamt_acc_reg_in;

wire    [10:0]  wght_addr_cntr_rdata;
wire    [63:0]  lzcu_data_reg_rdata;

wire            shamt_acc_reg_wen;
wire    [5:0]   mvma_x_elem_sel;
wire    [511:0] mvma_x_elem;
wire    [63:0]  VPU_out_nonz_info;

wire    [(64*8)-1:0]  sig_VPU_x, tanh_VPU_x, sig_slope, sig_offset, tanh_slope, tanh_offset;
wire    [(64*8)-1:0]  mvma_x_in;
wire    [(64*8)-1:0] MC_VPU_x, MC_VPU_y, MC_VPU_z, VPU_out_rslt;
reg     [(64*8)-1:0]  RM_VPU_x, RM_VPU_y, RM_VPU_z;

wire [3:0] x_addr_up;
wire [2:0] r_addr_up;
wire DA_acc_set_bias;
wire [63:0] RM_pam_x_rdata;
wire [511:0] masked_am_y_rdata, masked_am_r_rdata, am_x_rdata_final, am_x_rdata_reg;
wire [511:0] masked_am_x_rdata;
wire [63:0]  am_r_wcs_ctrl;
wire [10:0] shamt;

wire    [5:0]   shamt_acc;

wire    [31:0]  ZB_inst;

ROSETTA_Controller controller(
        .inst(inst),

        .nops_cntr_we(nops_cntr_we),
        .beta_last_bound(beta_last_bound),
        .beta_done(beta_done),
        .alp_plus_beta_last_bound(alp_plus_beta_last_bound),
        .alp_plus_beta_done(alp_plus_beta_done),
        .p_done(p_done),
        .p_last_bound(p_last_bound),
        .nops_done(nops_done),
        .all_done(all_done),

        .x_addr_wen(x_addr_wen),
        .r_addr_wen(r_addr_wen),
        .x_addr_rst(x_addr_rst),
        .r_addr_rst(r_addr_rst),

        .im_ren(im_ren_ctrl),
        .pam_x_ren(pam_x_ren_ctrl),
        .pam_y_ren(pam_y_ren),
        .pam_r_ren(pam_r_ren),
        .pam_r_wen(pam_r_wen_ctrl),
        .wm_ren(wm_ren_ctrl),
        .bm_ren(bm_ren_ctrl),

        .inst_done(inst_done)
);

assign pam_x_ren = pam_x_ren_ctrl | first_cycle;

Dreg_We_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
) reg_done(
        .i(1'b1),
        .o(done),
        .we(WB_done_wen),
        .clk(clk),
        .rst(rst)
);

Dreg_We_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
) reg_all_done(
        .i(1'b1),
        .o(all_done),
        .we(inst_done & inst[2]),
        .clk(clk),
        .rst(rst)
);

Dreg #(
        .WIDTH(1) 
)IF_im_ren(
        .i(rst),
        .o(im_ren_first),
        .clk(clk)
);

assign im_ren = im_ren_first | (im_ren_ctrl & !inst[2]) ;

Dreg_We_Rst #(
        .WIDTH(8) 
)IF_pc_reg(
        .i(rst ? 8'd0 : im_raddr + 1'b1),
        .o(im_raddr),
        .we(im_ren),
        .rst(rst),
        .clk(clk)
);

Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE({(1){1'b0}})
)IF_DA_pipeline_reg(
        .i({im_ren}),
        .o({first_cycle}),
        .clk(clk),
        .rst(rst)
);

///////////////////////////////////////////////////////////////////
assign inst = (im_ren_first | all_done) ? 32'd0 : im_rdata;

assign pam_x_raddr = $unsigned(inst[25:22]) + (inst[0] ? r_addr_cntr_rdata : x_addr_cntr_rdata);
assign pam_y_raddr = $unsigned(inst[21:17]) + r_addr_cntr_rdata;
assign pam_r_raddr = $unsigned(inst[31:27]) + r_addr_cntr_rdata;

assign alp_plus_beta_last_bound = inst[0] ? (x_addr_cntr_rdata == (alp_plus_beta - 3'd2)) : (x_addr_up == (alp_plus_beta - 3'd2));
assign alp_plus_beta_done = inst[0] ? (x_addr_cntr_rdata == (alp_plus_beta - 3'd1)) : (x_addr_up == (alp_plus_beta - 3'd1));
assign beta_last_bound    = inst[0] ? (r_addr_cntr_rdata == (beta - 3'd2)) : (r_addr_up == (beta - 3'd2));
assign beta_done          = inst[0] ? (r_addr_cntr_rdata == (beta - 3'd1)) : (r_addr_up == (beta - 3'd1));


Dreg_We_Rst #(
        .WIDTH(4),
        .RESET_VALUE(4'd0)
)DA_x_addr_cntr(
        .i((x_addr_cntr_rdata + 1'b1)),
        .o(x_addr_cntr_rdata),
        .we(x_addr_wen | first_cycle),
        .clk(clk),
        .rst(rst | im_ren | x_addr_rst | nops_cntr_we | all_done)
); 



Dreg_We_Rst #(
        .WIDTH(7),
        .RESET_VALUE(7'd0)
)DA_addr_update(
        .i({x_addr_cntr_rdata, r_addr_cntr_rdata}),
        .o({x_addr_up, r_addr_up}),
        .we(pam_x_ren),
        .clk(clk),
        .rst(rst | im_ren | nops_cntr_we | all_done)
); 

Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE(3'd0)
)DA_r_addr_cntr(
        .i(r_addr_cntr_rdata + 1'b1),
        .o(r_addr_cntr_rdata),
        .we(r_addr_wen),
        .clk(clk),
        .rst(rst | im_ren | r_addr_rst | nops_cntr_we | all_done)
); 

assign nops_done = (nops_cntr_rdata == 3'd4);

Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE(3'd0)
)DA_nops_cntr(
        .i(nops_cntr_rdata + 1'b1),
        .o(nops_cntr_rdata),
        .we(nops_cntr_we),
        .clk(clk),
        .rst(rst | im_ren | all_done)
);

Dreg_We_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'd0)
)DA_nops_we_reg(
        .i(inst[1]),
        .o(nops_cntr_we),
        .we(inst_done),
        .clk(clk),
        .rst(rst | im_ren)
); 

Dreg#(
        .WIDTH(1)
)DA_set_bias_reg(
        .i(r_addr_rst | r_addr_wen),
        .o(DA_acc_set_bias),
        .clk(clk)
); 

Dreg_Rst #(
        .WIDTH(4 + 4 + 5 + 5 + 3 + 2 + 32 + 1 + 1),
        .RESET_VALUE({(4 + 4 + 5 + 5 + 3 + 2 + 32 + 1 + 1){1'b0}})
)DA_ZB_pipeline_reg(
        .i({pam_x_raddr, pam_x_ren, pam_y_ren, pam_r_ren, pam_r_wen_ctrl, pam_y_raddr, pam_r_raddr, r_addr_cntr_rdata, wm_ren_ctrl | first_cycle, bm_ren_ctrl, inst     ,DA_acc_set_bias | first_cycle, inst_done & inst[2]}),
        .o({ZB_pam_x_raddr, am_x_ren , am_y_ren , am_r_ren , ZB_am_r_wen   , am_y_raddr , am_r_raddr , bias_cntr_inc    , wm_ren     , bm_ren     , ZB_inst  , ZB_acc_set_bias              , ZB_done_wen}),
        .clk(clk),
        .rst(rst) 
);

assign lzcu_in_sel = am_x_ren;

assign am_x_raddr = {1'b0, ZB_pam_x_raddr};

assign raccess_xy = ((!ZB_inst[16]) & ZB_inst[0]) ? (pam_x_rdata & pam_y_rdata) : pam_x_rdata;
assign raccess_z  = pam_r_rdata;

assign am_x_rcs = {(64){1'b1}};
assign am_y_rcs = {(64){1'b1}};
assign am_r_rcs = {(64){1'b1}};

assign bm_raddr = ZB_inst[21:17] + bias_cntr_inc; // base_z + bias increment value (DA stage's r_raddr_cntr)
assign wm_raddr = (ZB_inst[16:11] << 3'd6) + ((x_addr_up << 3'd6) + (r_addr_up * 11'd192)) + (((p_done & p_last_bound) ? (wght_addr_cntr_rdata) : lzcu_in_sel ? (wght_addr_cntr_rdata + lzcu_out) : (wght_addr_cntr_rdata + lzcu_out + 1'd1)));

assign lzcu_in = lzcu_in_sel ? pam_x_rdata : lzcu_data_reg_rdata;

LZCU lzcu_64bit( 
        .in(lzcu_in),
        .out(lzcu_out)
);

assign shfted_pam_x_rdata = lzcu_in << (lzcu_out + 1'd1);

Dreg_We #(
        .WIDTH(64)
)ZB_LZCU_data_reg(
        .i(shfted_pam_x_rdata),
        .o(lzcu_data_reg_rdata),
        .we(!ZB_inst[0]),
        .clk(clk)
);  

assign popcnt_l = shfted_pam_x_rdata[ 0] + shfted_pam_x_rdata[ 1] + shfted_pam_x_rdata[ 2] + shfted_pam_x_rdata[ 3] +
                  shfted_pam_x_rdata[ 4] + shfted_pam_x_rdata[ 5] + shfted_pam_x_rdata[ 6] + shfted_pam_x_rdata[ 7] +
                  shfted_pam_x_rdata[ 8] + shfted_pam_x_rdata[ 9] + shfted_pam_x_rdata[10] + shfted_pam_x_rdata[11] +
                  shfted_pam_x_rdata[12] + shfted_pam_x_rdata[13] + shfted_pam_x_rdata[14] + shfted_pam_x_rdata[15] +
                  shfted_pam_x_rdata[16] + shfted_pam_x_rdata[17] + shfted_pam_x_rdata[18] + shfted_pam_x_rdata[19] +
                  shfted_pam_x_rdata[20] + shfted_pam_x_rdata[21] + shfted_pam_x_rdata[22] + shfted_pam_x_rdata[23] +
                  shfted_pam_x_rdata[24] + shfted_pam_x_rdata[25] + shfted_pam_x_rdata[26] + shfted_pam_x_rdata[27] +
                  shfted_pam_x_rdata[28] + shfted_pam_x_rdata[29] + shfted_pam_x_rdata[30] + shfted_pam_x_rdata[31];

assign popcnt_h = shfted_pam_x_rdata[32] + shfted_pam_x_rdata[33] + shfted_pam_x_rdata[34] + shfted_pam_x_rdata[35] +
                  shfted_pam_x_rdata[36] + shfted_pam_x_rdata[37] + shfted_pam_x_rdata[38] + shfted_pam_x_rdata[39] +
                  shfted_pam_x_rdata[40] + shfted_pam_x_rdata[41] + shfted_pam_x_rdata[42] + shfted_pam_x_rdata[43] +
                  shfted_pam_x_rdata[44] + shfted_pam_x_rdata[45] + shfted_pam_x_rdata[46] + shfted_pam_x_rdata[47] +
                  shfted_pam_x_rdata[48] + shfted_pam_x_rdata[49] + shfted_pam_x_rdata[50] + shfted_pam_x_rdata[51] +
                  shfted_pam_x_rdata[52] + shfted_pam_x_rdata[53] + shfted_pam_x_rdata[54] + shfted_pam_x_rdata[55] +
                  shfted_pam_x_rdata[56] + shfted_pam_x_rdata[57] + shfted_pam_x_rdata[58] + shfted_pam_x_rdata[59] +
                  shfted_pam_x_rdata[60] + shfted_pam_x_rdata[61] + shfted_pam_x_rdata[62] + shfted_pam_x_rdata[63];

assign popcnt       = popcnt_l + popcnt_h;

assign p_last_bound = (popcnt == 7'd1) | (lzcu_in_sel & p_done);
assign p_done = !(|popcnt);

Dreg_Rst #(
        .WIDTH(11),
        .RESET_VALUE(11'd0)
)ZB_wght_addr_cntr(
        .i(lzcu_in_sel ? (wght_addr_cntr_rdata + lzcu_out) : (wght_addr_cntr_rdata + lzcu_out + 1'd1)),
        .o(wght_addr_cntr_rdata),
        .clk(clk),
        .rst(rst | first_cycle | all_done | im_ren | p_done)
); 

Dreg_Rst #(
        .WIDTH(64 + 64 + 6 + 32 + 5 + 1 + 1 + 1 + 64 + 1 + 1),
        .RESET_VALUE({(64 + 64 + 6 + 32 + 5 + 1 + 1 + 1 + 64 + 1 + 1){1'b0}})
)ZB_RM_pipeline_reg(
        .i({raccess_xy   , raccess_z   , wm_raddr[5:0]      , ZB_inst, am_r_raddr   , ZB_acc_set_bias, ZB_done_wen, ZB_am_r_wen, pam_x_rdata   , first_cycle  , am_x_ren}),
        .o({RM_raccess_xy, RM_raccess_z, mvma_x_elem_sel   , RM_inst, RM_am_r_raddr, RM_acc_set_bias, RM_done_wen, RM_am_r_wen, RM_pam_x_rdata, RM_first_cycle, reg_am_x_ren}),
        .clk(clk),
        .rst(rst)
);

Dreg_We_Rst #(
        .WIDTH(512),
        .RESET_VALUE(512'd0)
)am_x_rdata_pipeline_reg(
        .i(am_x_rdata),
        .o(am_x_rdata_reg),
        .we(reg_am_x_ren),
        .clk(clk),
        .rst(rst)
); 

assign am_x_rdata_final = reg_am_x_ren ? am_x_rdata : am_x_rdata_reg;
assign am_r_wcs_ctrl = RM_inst[0] ? (RM_inst[16] ? RM_pam_x_rdata : RM_raccess_xy) : 64'hFFFFFFFFFFFFFFFF;

generate
    genvar idx;
    for(idx = 0; idx < P; idx = idx+1) begin : act_mem
        assign masked_am_x_rdata[8*(idx+1)-1:8*idx] = RM_raccess_xy[63-idx] ? am_x_rdata_final[8*(idx+1)-1:8*(idx)] : 8'd0;
        assign masked_am_y_rdata[8*(idx+1)-1:8*idx] = RM_raccess_xy[63-idx] ? am_y_rdata[8*(idx+1)-1:8*(idx)] : 8'd0;
        assign masked_am_r_rdata[8*(idx+1)-1:8*idx] = RM_raccess_z[63-idx] ? am_r_rdata[8*(idx+1)-1:8*(idx)] : 8'd0;
    end        
endgenerate

assign shamt = (mvma_x_elem_sel << 2'd3);
assign mvma_x_elem = masked_am_x_rdata >> shamt;
assign mvma_x_in   = {(64){mvma_x_elem[7:0]}};

ACU acu_16entry(
        .in(masked_am_x_rdata),
        .sig_out(sig_VPU_x),
        .tanh_out(tanh_VPU_x),
        .sig_slope(sig_slope),
        .sig_offset(sig_offset),
        .tanh_slope(tanh_slope),
        .tanh_offset(tanh_offset)
);

always @*
    casex ({RM_inst[13], RM_inst[16], RM_inst[0]})
        3'bxx0 :   {RM_VPU_x, RM_VPU_y, RM_VPU_z} = {mvma_x_in , wm_rdata  , bm_rdata};
        3'b011 :   {RM_VPU_x, RM_VPU_y, RM_VPU_z} = {sig_VPU_x , sig_slope , sig_offset};
        3'b111 :   {RM_VPU_x, RM_VPU_y, RM_VPU_z} = {tanh_VPU_x, tanh_slope, tanh_offset};
        default:   {RM_VPU_x, RM_VPU_y, RM_VPU_z} = {masked_am_x_rdata, masked_am_y_rdata, masked_am_r_rdata};
    endcase

Dreg_Rst #(
        .WIDTH(64 + 5 + 13 + 64*8*3 + 1 + 1 + 1),
        .RESET_VALUE({(64 + 5 + 13 + 64*8*3 + 1 + 1 + 1){1'b0}})
)RM_MC_pipeline_reg(
        .i({am_r_wcs_ctrl, RM_am_r_raddr, RM_inst[12:0], RM_VPU_x, RM_VPU_y, RM_VPU_z, RM_acc_set_bias, RM_done_wen, RM_am_r_wen}),
        .o({MC_raccess_xy, MC_am_r_raddr, MC_inst      , MC_VPU_x, MC_VPU_y, MC_VPU_z, MC_acc_set_bias, MC_done_wen, MC_am_r_wen}),
        .clk(clk),
        .rst(rst)
);

//////////////////////////////////////////////////////////////////////////////

VPU vpu(
        .VPU_in_x(MC_VPU_x),
        .VPU_in_y(MC_VPU_y),
        .VPU_in_z(MC_VPU_z),

        .first(MC_acc_set_bias),
        .mode(!MC_inst[0]),
        .inv(MC_inst[11] & MC_inst[0]),
        .acc(MC_inst[12]),
        .fp_dst(MC_inst[8:7]),
        .fp_in0(MC_inst[6:5]),
        .fp_in1(MC_inst[4:3]),
        .th(MC_inst[10:9]),

        .VPU_out_rslt(VPU_out_rslt),
        .VPU_out_nonz_info(VPU_out_nonz_info),

        .clk(clk),
        .rst(rst)
);

Dreg_Rst #(
        .WIDTH(64 + 5 + 1 + 1),
        .RESET_VALUE({(64 + 5 + 1 + 1){1'b0}})
)MC_FP_pipeline_reg(
        .i({MC_raccess_xy, MC_am_r_raddr, MC_done_wen, MC_am_r_wen}),
        .o({FP_raccess_xy, FP_am_r_raddr, FP_done_wen, FP_am_r_wen}),
        .clk(clk),
        .rst(rst)
);

Dreg_Rst #(
        .WIDTH(64 + 5 + 512 + 64 + 1 + 1),
        .RESET_VALUE({(64 + 5 + 512 + 64 + 1 + 1){1'b0}})
)FP_WB_pipeline_reg(
        .i({FP_raccess_xy, FP_am_r_raddr, VPU_out_rslt  , VPU_out_nonz_info, FP_done_wen, FP_am_r_wen}),
        .o({WB_raccess_xy, WB_am_r_raddr, am_r_wdata    , pam_r_wdata      , WB_done_wen, WB_am_r_wen}),
        .clk(clk),
        .rst(rst)
);

assign am_r_wen    = WB_am_r_wen;
assign am_r_wcs    = {(64){(1'b1)}};
assign am_r_waddr  = WB_am_r_raddr;

assign pam_r_wen   = WB_am_r_wen;
assign pam_r_waddr = WB_am_r_raddr;
endmodule