/**
*   @Module    ROSETTA_Core
*   @brief     datapath of ROSETTA Core
*
**/

module ROSETTA_Core #(
    parameter P = 64,                            // # of PEs: must be a power of 2
    parameter W = 8,                             // word size
    parameter LOG_P = 6
)(
  
    // Inst. Memory I/F
    output  wire                im_ren,    
    output  wire    [7:0]       im_ptr,
    input   wire    [27:0]      im_rdata,

    // Bias Memory I/F
    output  wire                bm_ren,
    output  wire    [2:0]       bm_ptr,
    input   wire    [P*W-1:0]   bm_rdata,

    // Weight Memory I/F
    output  wire                wm_ren,
    output  wire    [10:0]      wm_ptr,
    input   wire    [P*W-1:0]   wm_rdata,

    output  wire                pam_src0_ren,
    output  wire    [3:0]       pam_src0_ptr,
    input   wire    [P-1:0]     pam_src0_rdata,

    output  wire                pam_src1_ren,
    output  wire    [3:0]       pam_src1_ptr,
    input   wire    [P-1:0]     pam_src1_rdata,

    output  wire                pam_src2_ren,    
    output  wire    [3:0]       pam_src2_ptr,
    input   wire    [P-1:0]     pam_src2_rdata,

    output  wire                pam_dst_wen,
    output  wire    [3:0]       pam_dst_ptr,
    output  wire    [P-1:0]     pam_dst_wdata,

    // Vector Memory I/F
    output  wire                am_src0_ren,
    output  wire    [3:0]       am_src0_ptr,
    output  wire    [P-1:0]     am_src0_cs,
    input   wire    [P*W-1:0]   am_src0_rdata,

    output  wire                am_src1_ren,
    output  wire    [3:0]       am_src1_ptr,
    output  wire    [P-1:0]     am_src1_cs,
    input   wire    [P*W-1:0]   am_src1_rdata,

    output  wire                am_src2_ren,    
    output  wire    [3:0]       am_src2_ptr,
    input   wire    [P*W-1:0]   am_src2_rdata,
    output  wire    [P-1:0]     am_src2_cs,

    output  wire                am_dst_wen,
    output  wire    [3:0]       am_dst_ptr,
    output  wire    [P-1:0]     am_dst_cs,
    output  wire    [P*W-1:0]   am_dst_wdata,

    output  wire                done,

    input   wire    [6:0]       bound_info,

    // Clock & Reset
    input   wire    clk,
    input   wire    rst     //async. active-high
);

localparam add_p = 24'd1 << LOG_P;
localparam add_wp = 24'd3 << LOG_P;
localparam NOP   = 28'd0;

function integer ceil_log2;
  input integer value;
  integer tmp;
  begin
    tmp = value - 1;
    for (ceil_log2=0; tmp>0; ceil_log2=ceil_log2+1)
      tmp = tmp >> 1;
  end
endfunction

// Core Control signal
wire    [3:0]   i_bound;
wire    [2:0]   j_bound;

// IF stage data-path signal
wire    [27:0]  IF_inst_rdata;
wire            IF_first_inst;
wire            latched_IF_first_inst;
wire            final_IF_first_inst;

// DEC stage data-path signal
wire    [3:0]   DEC_pam_dst_ptr;
wire    [3:0]   DEC_pam_dst_ptr_e;
wire    [3:0]   DEC_pam_dst_ptr_m;
wire    [10:0]  DEC_wm_ptr;

wire DEC_i_end;
wire [2:0] DEC_i_end_cntr;
wire DEC_k_end;
wire [2:0] DEC_k_end_cntr;
wire DEC_j_end;
wire DEC_j_end_reg;


// DEC stage control-path signal
wire    [27:0]  DEC_inst;
wire            DEC_first_inst;
wire            DEC_im_ren;
wire            DEC_stall_fetch;
wire            DEC_stall_done;
wire            latched_DEC_stall_done;

wire            DEC_nop_signal;
wire            DEC_nops_inst;

wire    [1:0]   DEC_oprnd1_sel;
wire            DEC_oprnd2_sel;
wire            DEC_mvma_bias_acc;

wire            DEC_last_cycle;
wire            DEC_done_wen;

wire            DEC_inv;
wire            DEC_acc;
wire            DEC_act_type;
wire    [1:0]   DEC_fp_out;
wire    [1:0]   DEC_fp_in0;
wire    [1:0]   DEC_fp_in1;
wire            DEC_all_done;

wire    [2:0]   DEC_nops_cntr;
wire            DEC_last_inst;

wire            DEC_am_src0_ren;
wire            DEC_am_src1_ren;
wire            DEC_am_src2_ren;
wire            DEC_wm_ren;
wire            DEC_bm_ren;
wire            DEC_am_dst_wen;

wire    [2:0]   DEC_e_cntr;
wire            DEC_e_state;
wire            DEC_e_done;
wire            DEC_mvma_first;

// ZD stage data-path signal
wire    [3:0]   ZD_am_src0_ptr;
wire    [3:0]   ZD_am_src1_ptr;
wire    [3:0]   ZD_am_dst_ptr;
wire    [10:0]  ZD_wm_ptr;
wire    [10:0]  ZD_wm_ptr_base;
wire    [2:0]   ZD_bm_ptr;

wire    [6:0]   ZD_shamt;
wire    [8:0]   ZD_acc_shamt;
wire    [8:0]   ZD_addr_handler;
wire    [8:0]   ZD_all_in_one;
wire    [P-1:0] ZD_shfted_pam0_rdata;
wire    [P-1:0] ZD_pam0_rdata;
wire    [P-1:0] latched_pam_src0_rdata;
wire    [P-1:0] ZD_pam1_rdata;
wire    [P-1:0] ZD_pam2_rdata;

wire            ZD_pam_src0_ren;
wire            ZD_pam_src1_ren;
wire            ZD_pam_src2_ren;
wire            ZD_am_src0_ren;
wire            ZD_am_src1_ren;

wire            ZD_wm_ren;
wire            ZD_bm_ren;

wire    [63:0]  ZD_am_cs;
wire    [P-1:0] ZD_am_dst_cs;

wire            ZD_am_dst_wen;

// ZD stage control-path signal
wire    [27:0]  ZD_inst;

wire            ZD_k_end;
wire            ZD_i_end;
wire            ZD_j_end;
wire            ZD_j_end_reg;
wire            ZD_e_end;

wire            ZD_mvma_bias_acc;
wire            ZD_am_dst_wen_ctrl;
wire    [1:0]   ZD_oprnd1_sel;
wire            ZD_oprnd2_sel;
wire            ZD_done_wen;
wire            ZD_inv;
wire            ZD_acc;
wire            ZD_act_type;
wire    [1:0]   ZD_fp_out;
wire    [1:0]   ZD_fp_in0;
wire    [1:0]   ZD_fp_in1;


// RM stage data-path signal

wire [6:0]      RM_acc_shamt;

wire [P-1:0]    RM_pam0_rdata;
wire [P-1:0]    RM_pam1_rdata;

wire [P*W-1:0]  RM_wm_rdata;
wire [P*W-1:0]  RM_bm_rdata;
wire [P*W-1:0]  RM_am_src0_rdata;
wire [P*W-1:0]  RM_am_src1_rdata;
wire [P*W-1:0]  RM_am_src2_rdata;

wire [P*W-1:0]  RM_enof_src0;

wire [P*W-1:0]  RM_offset_sig;
wire [P*W-1:0]  RM_offset_tanh;
wire [P*W-1:0]  RM_slope_sig;
wire [P*W-1:0]  RM_slope_tanh;

reg  [P*W-1:0]  RM_in0;
reg  [P*W-1:0]  RM_in1;
wire [P*W-1:0]  RM_in2;

wire [P*W-1:0]  scale;
wire [P*W-1:0]  scale_shft_reg;
wire [P*W-1:0]  RM_am_src0_rdata_dupl;

wire [P-1:0]    RM_am_dst_cs;
wire [3:0]      RM_am_dst_ptr;

// RM stage control-path signal
wire            RM_i_end;

wire            RM_mvma_bias_acc;
wire            RM_am_dst_wen;
wire [1:0]      RM_oprnd1_sel;
wire            RM_oprnd2_sel;
wire            RM_done_wen;
wire            RM_inv;
wire            RM_acc;
wire            RM_act_type;
wire [1:0]      RM_fp_out;
wire [1:0]      RM_fp_in0;
wire [1:0]      RM_fp_in1;
wire [1:0]      RM_th;

// COM1 stage data-path signal
wire [P-1:0]    COM1_am_dst_cs;

wire [P*W-1:0]  COM1_in0;
wire [P*W-1:0]  COM1_in1;
wire [P*W-1:0]  COM1_in2;

wire [3:0]      COM1_am_dst_ptr;
wire [P*W-1:0]  COM1_bm_rdata;

// COM1 stage control-path signal
wire            COM1_mvma_bias_acc;
wire            COM1_i_end;

wire            COM1_am_dst_wen;
wire [1:0]      COM1_oprnd1_sel;
wire            COM1_done_wen;
wire            COM1_inv;
wire            COM1_acc;
wire [1:0]      COM1_fp_out;
wire [1:0]      COM1_fp_in0;
wire [1:0]      COM1_fp_in1;
wire [1:0]      COM1_th;

// COM2 stage data-path signal
wire [P-1:0]    COM2_am_dst_cs;
wire [3:0]      COM2_am_dst_ptr;
wire [P*W-1:0]  COM2_am_dst_wdata;
wire [P-1:0]    COM2_pam_dst_wdata;

// COM2 stage control-path signal
wire            COM2_am_dst_wen;
wire            COM2_done_wen;

// WM stage data-path signal
wire [P-1:0]    WM_am_dst_cs;
wire [3:0]      WM_am_dst_ptr;
wire [P*W-1:0]  WM_am_dst_wdata;
wire [P-1:0]    WM_pam_dst_wdata;

// WM stage control-path signal
wire            WM_done_wen;
wire            WM_am_dst_wen;

// Core signal
wire core_state;
wire latched_rst;
assign core_state = latched_rst & !WM_done_wen;

Dreg #(
        .WIDTH(1)
) reg_rst(
        .i(~rst),
        .o(latched_rst),
        .clk(clk)
);

assign i_bound = bound_info[6:3];
assign j_bound = bound_info[2:0];

assign im_ren              = (!DEC_last_inst) & (!DEC_stall_fetch) | (DEC_e_state & !(|DEC_e_cntr) & !DEC_nops_inst) & !DEC_last_inst;

Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
) reg_done(
        .i(WM_done_wen),
        .o(done),
        .clk(clk),
        .rst(rst)
);

Dreg_We_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'd0)
) reg_DEC_all_done(
        .i(1'b1),
        .o(DEC_all_done),
        .we(DEC_done_wen),
        .clk(clk),
        .rst(rst)
); 

ROSETTA_Controller controller(
        .inst(DEC_inst),

        .all_done(DEC_all_done),

        .nop(DEC_nop_signal),
        .nops_encod(DEC_nops_inst),
        .k_end(ZD_k_end),
        .i_end(ZD_i_end),            
        .j_end(ZD_j_end),   
        .j_end_reg(ZD_j_end_reg|ZD_done_wen),
        .k_end_out(DEC_k_end),
        .i_end_out(DEC_i_end),
        .j_end_out(DEC_j_end),
        .e_end_out(ZD_e_end),
        .e_end(DEC_e_cntr == 3'b1),      
        .e_state(DEC_e_state),

        .stall_done(DEC_stall_done),

        .stall_fetch(DEC_stall_fetch),   
   

        .am_src0_ren(DEC_am_src0_ren),        
        .am_src1_ren(DEC_am_src1_ren),        
        .am_dst_ren(DEC_am_src2_ren),         
        .am_dst_wen(DEC_am_dst_wen),         
        .wm_ren(DEC_wm_ren),             
        .bm_ren(DEC_bm_ren),     

        .oprnd1_sel(DEC_oprnd1_sel),         
        .oprnd2_sel(DEC_oprnd2_sel),     
        .mvma_first(DEC_mvma_bias_acc),
        
        .done_wen(DEC_last_cycle),          
        
        .inv(DEC_inv),                  
        .acc(DEC_acc),                  
        .act_type(DEC_act_type),             
        .fp_out(DEC_fp_out),
        .fp_in0(DEC_fp_in0),
        .fp_in1(DEC_fp_in1),

        .last_inst(DEC_last_inst)
);

// ------------------------------------------------------------------
// IF Stage
// ------------------------------------------------------------------
assign IF_inst_rdata       = im_rdata;
assign final_IF_first_inst = latched_IF_first_inst & IF_first_inst;

Dreg_We #(
        .WIDTH(8)
)IF_pc_reg(
        .i(rst ? 8'd0 : im_ptr + 1'b1),
        .o(im_ptr),
        .we(rst | im_ren),
        .clk(clk)
);
 
Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'b0)
)IF_first_inst_reg(
        .i(1'b1),
        .o(IF_first_inst),
        .clk(clk),
        .rst(rst)
);

Dreg #(
        .WIDTH(1)
)IF_flipped_first_inst_reg(
        .i(!IF_first_inst),
        .o(latched_IF_first_inst),
        .clk(clk)
);
 
Dreg_Rst #(
        .WIDTH(28 + 1 + 1),
        .RESET_VALUE({(28 + 1 + 1){1'b0}})
)IFDEC_datapath(
        .i({IF_inst_rdata, final_IF_first_inst, im_ren}),
        .o({DEC_inst     , DEC_first_inst     , DEC_im_ren}),
        .clk(clk),
        .rst(rst)
);

// ------------------------------------------------------------------
// DEC Stage
// ------------------------------------------------------------------
assign DEC_stall_done = (DEC_nops_cntr >= (DEC_nops_inst ? 3'd2 : 3'b0)) & (|DEC_nops_cntr);
assign DEC_done_wen   =  DEC_last_cycle & DEC_last_inst;
assign DEC_nop_signal     = (core_state == 1'b0 | (DEC_j_end_reg) & (!DEC_last_inst));

assign DEC_pam_dst_ptr_m = DEC_inst[27:24] + (DEC_i_end + DEC_i_end_cntr);

assign DEC_pam_dst_ptr_e = DEC_inst[27:24] + DEC_e_cntr;
assign DEC_pam_dst_ptr   = DEC_inst[0] ? DEC_pam_dst_ptr_e : DEC_pam_dst_ptr_m;

assign pam_src0_ptr   = DEC_inst[23:20] + ((DEC_inst[0] | DEC_mvma_first) ? DEC_e_cntr : DEC_k_end_cntr);
assign pam_src1_ptr   = DEC_inst[19:16] + ((DEC_inst[0] | DEC_mvma_first) ? DEC_e_cntr : DEC_k_end_cntr);
assign pam_src2_ptr   = DEC_pam_dst_ptr;

assign pam_src0_ren   = DEC_am_src0_ren;
assign pam_src1_ren   = DEC_am_src1_ren;
assign pam_src2_ren   = DEC_am_src2_ren;

assign DEC_wm_ptr     = {DEC_inst[15:11], {(6){1'd0}}};

Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE(3'd0)
) DEC_i_end_cntr_reg(
        .i(DEC_i_end_cntr + 1'b1),
        .o(DEC_i_end_cntr),
        .clk(clk),
        .we(ZD_i_end),
        .rst(rst | IF_inst_rdata[0] )
); 
 
Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE(3'd0)
) DEC_k_end_cntr_reg(
        .i(DEC_k_end_cntr + 1'b1),
        .o(DEC_k_end_cntr),
        .clk(clk),
        .we(ZD_k_end | DEC_mvma_first),
        .rst(rst | IF_inst_rdata[0] | (DEC_k_end_cntr[1] & !DEC_k_end_cntr[0]))
); 

Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE({(1){1'b0}})
) DEC_j_end_regreg(
        .i(ZD_j_end),
        .o(DEC_j_end_reg),
        .clk(clk),
        .rst(rst | im_ren)
);


Dreg_We_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'd0)
) DEC_mvma_first_reg(
        .i(DEC_im_ren),
        .o(DEC_mvma_first),
        .clk(clk),
        .we(DEC_im_ren),
        .rst(rst | IF_inst_rdata[0] | !DEC_im_ren)
); 

Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE(1'd0)
) DEC_stall_done_reg(
        .i(DEC_stall_done),
        .o(latched_DEC_stall_done),
        .clk(clk),
        .rst(rst)
); 

Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE(3'd0)
) DEC_nops_cntr_reg(
        .i(DEC_nops_cntr + 1'b1),
        .o(DEC_nops_cntr),
        .we((DEC_nops_inst) & (((!DEC_inst[0]) & DEC_j_end_reg) | (DEC_inst[0] & (DEC_e_cntr >= 3'b10)))),
        .clk(clk),
        .rst(rst | DEC_first_inst | (DEC_stall_done))
);

Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE({(3){1'b0}})
) DEC_e_cntr_reg(
        .i(DEC_e_cntr + 1'b1),
        .o(DEC_e_cntr),
        .we(DEC_im_ren | DEC_inst[0] & DEC_e_cntr < j_bound),
        .clk(clk),
        .rst(rst | !DEC_inst[0] | latched_DEC_stall_done | DEC_im_ren)
);

// --------------DEC --> ZD Pipeline Register-----------------
Dreg_Rst #(
        .WIDTH(26 + 22 + 4*3 + 11),
        .RESET_VALUE({(26 + 22 + 4*3 + 11){1'b0}})
)DECZD_datapath(
        .i({{DEC_inst, DEC_oprnd1_sel, DEC_oprnd2_sel, DEC_mvma_bias_acc | DEC_first_inst, DEC_done_wen, DEC_inv, DEC_acc, DEC_act_type, DEC_fp_out, DEC_fp_in0, DEC_fp_in1, DEC_wm_ren, DEC_bm_ren, pam_src0_ren   , pam_src1_ren   , pam_src2_ren   , DEC_am_dst_wen}, {pam_src0_ptr  , pam_src1_ptr  , DEC_pam_dst_ptr   , DEC_wm_ptr}}),
        .o({{ZD_inst,  ZD_oprnd1_sel , ZD_oprnd2_sel , ZD_mvma_bias_acc                  , ZD_done_wen , ZD_inv , ZD_acc , ZD_act_type , ZD_fp_out , ZD_fp_in0 , ZD_fp_in1 , ZD_wm_ren , ZD_bm_ren , ZD_pam_src0_ren, ZD_pam_src1_ren, ZD_pam_src2_ren, ZD_am_dst_wen_ctrl} , {ZD_am_src0_ptr, ZD_am_src1_ptr, ZD_am_dst_ptr, ZD_wm_ptr_base}}),
        .clk(clk),
        .rst(rst)
); 

// ------------------------------------------------------------------
// ZD Stage
// ------------------------------------------------------------------
assign ZD_am_dst_wen = (ZD_i_end & (!(|DEC_nops_cntr)) & (!latched_DEC_stall_done)) ? 1'b1 : (ZD_am_dst_wen_ctrl) & (!(|DEC_nops_cntr));

assign ZD_k_end = (ZD_shamt == 7'd64) & (|ZD_acc_shamt); 
assign ZD_i_end = (ZD_acc_shamt == 9'd192) | (ZD_acc_shamt == 9'd384);
assign ZD_j_end = (ZD_acc_shamt == 9'd384); 

assign ZD_pam0_rdata        = pam_src0_rdata;
assign ZD_shfted_pam0_rdata = ZD_pam0_rdata << ZD_acc_shamt;
assign ZD_pam1_rdata        = pam_src1_rdata;
assign ZD_pam2_rdata        = pam_src2_rdata;

assign ZD_am_cs     = (ZD_inst[15] & ZD_inst[0]) ? ZD_pam0_rdata : (ZD_pam0_rdata & ZD_pam1_rdata);
assign ZD_am_dst_cs = ZD_am_cs;

assign am_src0_cs   = ZD_am_cs;
assign am_src1_cs   = ZD_am_cs;
assign am_src2_cs   = (ZD_inst[15] & ZD_inst[0]) ? ZD_pam2_rdata : (ZD_pam0_rdata & ZD_pam1_rdata & ZD_pam2_rdata);

assign am_src0_ren  = ZD_pam_src0_ren;
assign am_src1_ren  = ZD_pam_src1_ren;
assign am_src2_ren  = ZD_pam_src2_ren;

assign am_src0_ptr  = ZD_am_src0_ptr;
assign am_src1_ptr  = ZD_am_src1_ptr;
assign am_src2_ptr  = ZD_am_dst_ptr;

assign wm_ren       = ZD_wm_ren;
assign bm_ren       = ZD_bm_ren;
assign wm_ptr       = ZD_wm_ptr;
assign bm_ptr       = ZD_bm_ptr;

Dreg_Rst #(
        .WIDTH(1),
        .RESET_VALUE({(1){1'b0}})
) ZD_j_end_regreg(
        .i(ZD_j_end),
        .o(ZD_j_end_reg),
        .clk(clk),
        .rst(rst | ZD_inst[0])
);

LZCU ZD_zero_detect_unit(
        .pam_rdata((|ZD_acc_shamt[5:0]) ? ZD_shfted_pam0_rdata : ZD_pam0_rdata),
        .shamt(ZD_shamt)
);

Dreg_We_Rst #(
        .WIDTH(9),
        .RESET_VALUE({(9){1'b0}})
) ZD_acc_shamt_reg(
        .i(ZD_acc_shamt + ZD_shamt),
        .o(ZD_acc_shamt),
        .we(|ZD_inst),
        .clk(clk),
        .rst(rst | ZD_e_end | ZD_inst[0])
);

Dreg_We_Rst #(
        .WIDTH(11),
        .RESET_VALUE({(11){1'b0}})
) ZD_wm_ptr_reg(
        .i((|ZD_acc_shamt) ? (ZD_shamt + ZD_wm_ptr) : (ZD_wm_ptr_base)),
        .o(ZD_wm_ptr),
        .we(|ZD_inst),
        .clk(clk),
        .rst(rst | ZD_e_end | ZD_inst[0])
);

reg [2:0] bm_ptr_tmp;

always @*
    case (ZD_acc_shamt[6]&ZD_acc_shamt[7])
        1'd0:    bm_ptr_tmp = ZD_acc_shamt[8] ? ZD_bm_ptr : ZD_inst[18:16];
        1'd1:    bm_ptr_tmp = ZD_bm_ptr + 1'b1;
    endcase

Dreg_We_Rst #(
        .WIDTH(3),
        .RESET_VALUE({(3){1'b0}})
) ZD_bm_ptr_reg(
        .i(bm_ptr_tmp),
        .o(ZD_bm_ptr),
        .we(|ZD_inst),
        .clk(clk),
        .rst(rst | ZD_e_end | ZD_inst[0])
);

// --------------ZD --> RM Pipeline Register-----------------
Dreg_Rst #(
        .WIDTH(15 + 10 + (4 + 64)),
        .RESET_VALUE({(15 + 10 + (4 + 64)){1'b0}})
)ZDRM_datapath(
        .i({{ZD_mvma_bias_acc, ZD_i_end, ZD_am_dst_wen, ZD_oprnd1_sel, ZD_oprnd2_sel,  ZD_done_wen, ZD_inv, ZD_acc, ZD_act_type, ZD_fp_out, ZD_fp_in0, ZD_fp_in1, ZD_inst[10:9], ZD_acc_shamt[6:0]}, {ZD_am_dst_ptr, ZD_am_dst_cs}}),
        .o({{RM_mvma_bias_acc, RM_i_end, RM_am_dst_wen, RM_oprnd1_sel, RM_oprnd2_sel,  RM_done_wen, RM_inv, RM_acc, RM_act_type, RM_fp_out, RM_fp_in0, RM_fp_in1, RM_th        , RM_acc_shamt}, {RM_am_dst_ptr, RM_am_dst_cs}}),
        .clk(clk),
        .rst(rst)
); 

// ------------------------------------------------------------------
// RM Stage 
// ------------------------------------------------------------------
assign RM_wm_rdata      = wm_rdata;
assign RM_bm_rdata      = bm_rdata;

assign RM_am_src0_rdata = am_src0_rdata;
assign RM_am_src1_rdata = am_src1_rdata;
assign RM_am_src2_rdata = am_src2_rdata;
assign scale            = RM_am_src0_rdata;

// sigmoid -> act_type = 0, tanh -> act_type : 1
generate
    genvar idx;
        for(idx = 0; idx < P; idx = idx+1) begin : actblk
            sig_slope u0_sig_slope(
                .in_data(scale[W*(idx+1)-1:W*idx]),
                .enof_type(RM_act_type),
                .slope(RM_slope_sig[W*(idx+1)-1:W*idx])
            );        
            sig_offset u0_sig_offset(
                .in_data(scale[W*(idx+1)-1:W*idx]),
                .enof_type(RM_act_type),
                .offset(RM_offset_sig[W*(idx+1)-1:W*idx])
            );
            assign RM_enof_src0[W*(idx+1)-1:W*idx] = RM_act_type ? {{(W-6){1'b0}}, {scale[W*idx+3:W*idx], 2'b0}}  : {{(3){1'b0}}, scale[W*idx+4:W*idx]};
            assign RM_offset_tanh[W*(idx+1)-1:W*idx] = {{{(3){~RM_offset_sig[W*idx+4]}}, RM_offset_sig[W*idx+3:W*idx]}, 1'd0};
        end
endgenerate

assign scale_shft_reg        = scale >> (RM_acc_shamt << 2'd3);
assign RM_am_src0_rdata_dupl = {(P){scale_shft_reg[W-1:0]}};
assign RM_in2                = RM_oprnd2_sel ? (RM_act_type ? RM_offset_tanh : RM_offset_sig) : RM_am_src2_rdata;

always @*
    case (RM_oprnd1_sel)
        2'd0:    {RM_in0, RM_in1} = {RM_wm_rdata, RM_am_src0_rdata_dupl};
        2'd1:    {RM_in0, RM_in1} = {scale, RM_am_src1_rdata};
        default: {RM_in0, RM_in1} = {RM_enof_src0, RM_act_type ? RM_slope_tanh : RM_slope_sig};
    endcase

// -------------- RM --> COM1 Pipeline Register-----------------
Dreg_Rst #(
        .WIDTH(16 + (4+4*P*W + 64)),
        .RESET_VALUE({(16 + (4+4*P*W + 64)){1'b0}})
)RMCOM1_datapath(
        .i({{RM_mvma_bias_acc  , RM_i_end  , RM_am_dst_wen  , RM_oprnd1_sel  , RM_done_wen  , RM_inv  , RM_acc  , RM_fp_out  , RM_fp_in0  , RM_fp_in1  , RM_th}  , {RM_am_dst_ptr  , RM_in0  , RM_in1  , RM_in2  , RM_bm_rdata , RM_am_dst_cs}}),
        .o({{COM1_mvma_bias_acc, COM1_i_end, COM1_am_dst_wen, COM1_oprnd1_sel, COM1_done_wen, COM1_inv, COM1_acc, COM1_fp_out, COM1_fp_in0, COM1_fp_in1, COM1_th}, {COM1_am_dst_ptr, COM1_in0, COM1_in1, COM1_in2, COM1_bm_rdata, COM1_am_dst_cs}}),
        .clk(clk),
        .rst(rst)
);

// ------------------------------------------------------------------
// COM Stage (COM1 --> COM2)
// ------------------------------------------------------------------

Vector_Proc_Unit #(
    .P(P),
    .W(W)
) COM1_vector_proc_unit(
        .in0(COM1_in0),
        .in1(COM1_in1),
        .in2(COM1_in2),
        .bm_rdata(COM1_bm_rdata),

        .i_end(COM1_i_end),
        .first(COM1_mvma_bias_acc | (!(|COM1_oprnd1_sel))),
        .mode(~|COM1_oprnd1_sel),
        .inv(COM1_inv),
        .acc(COM1_acc),
        .fp_dst(COM1_fp_out),
        .fp_in0(COM1_fp_in0),
        .fp_in1(COM1_fp_in1),
        .th(COM1_th),

        .out(COM2_am_dst_wdata),
        .out_zero(COM2_pam_dst_wdata),

        .clk(clk),
        .rst(rst)
);

// -------------- COM1 --> COM2 Pipeline Register-----------------
Dreg_Rst #(
        .WIDTH(2 + 4 + 64),
        .RESET_VALUE({(2 + 4 + 64){1'b0}})
)COM1COM2_datapath(
        .i({{COM1_am_dst_wen, COM1_done_wen}, {COM1_am_dst_ptr, COM1_am_dst_cs}}),
        .o({{COM2_am_dst_wen, COM2_done_wen}, {COM2_am_dst_ptr, COM2_am_dst_cs}}),
        .clk(clk),
        .rst(rst)
);

// -------------- COM2 --> WM Pipeline Register-----------------
Dreg_Rst #(
        .WIDTH(2 + (4+P*W + P) + 64),
        .RESET_VALUE({(2 + (4+P*W + P + 64)){1'b0}})
)COM2WM_datapath(
        .i({{COM2_am_dst_wen, COM2_done_wen}, {COM2_am_dst_ptr, COM2_am_dst_wdata, COM2_pam_dst_wdata, COM2_am_dst_cs}}),
        .o({{WM_am_dst_wen  , WM_done_wen}  , {WM_am_dst_ptr  , WM_am_dst_wdata    , WM_pam_dst_wdata, WM_am_dst_cs}}),
        .clk(clk),
        .rst(rst)
);

// ------------------------------------------------------------------
// WM Stage (COM1 --> COM2)
// ------------------------------------------------------------------

assign am_dst_wen = (WM_am_dst_wen | (WM_done_wen)); 
assign pam_dst_wen = am_dst_wen;

assign am_dst_ptr = WM_am_dst_ptr;
assign pam_dst_ptr = WM_am_dst_ptr;

assign am_dst_cs = WM_am_dst_cs & {(64){am_dst_wen}};

assign am_dst_wdata = WM_am_dst_wdata;
assign pam_dst_wdata = WM_pam_dst_wdata;

endmodule