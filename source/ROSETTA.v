/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: ROSETTA.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Top module of ROSETTA
-- Language:    Verilog-2001
-- Simulation:  Synopsys - VCS
-- Synthesis:   Xilinst-Vivado 
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
-- ***************************************************************************/

module ROSETTA(

        input   wire                    avmm_csr_addr,
        output  reg     [31:0]          avmm_csr_rdata,
        input   wire    [31:0]          avmm_csr_wdata,
        input   wire    [3:0]           avmm_csr_be,
        input   wire                    avmm_csr_cs,
        input   wire                    avmm_csr_r,
        input   wire                    avmm_csr_w,
  
        input   wire    [2:0]           avmm_am0_addr,
        output  wire    [511:0]         avmm_am0_rdata,
        input   wire    [511:0]         avmm_am0_wdata,
        input   wire    [63:0]          avmm_am0_be,
        input   wire                    avmm_am0_cs,
        input   wire                    avmm_am0_r,
        input   wire                    avmm_am0_w,

        input   wire    [2:0]           avmm_am1_addr,
        output  wire    [511:0]         avmm_am1_rdata,
        input   wire    [511:0]         avmm_am1_wdata,
        input   wire    [63:0]          avmm_am1_be,
        input   wire                    avmm_am1_cs,
        input   wire                    avmm_am1_r,
        input   wire                    avmm_am1_w,

        input   wire    [3:0]           avmm_pam_addr,
        output  wire    [63:0]          avmm_pam_rdata,
        input   wire    [63:0]          avmm_pam_wdata,
        input   wire    [7:0]           avmm_pam_be,
        input   wire                    avmm_pam_cs,
        input   wire                    avmm_pam_r,
        input   wire                    avmm_pam_w,

        input   wire    [10:0]          avmm_wm_addr,
        output  wire    [511:0]         avmm_wm_rdata,
        input   wire    [511:0]         avmm_wm_wdata,
        input   wire    [63:0]          avmm_wm_be,
        input   wire                    avmm_wm_cs,
        input   wire                    avmm_wm_r,
        input   wire                    avmm_wm_w,

        input   wire    [4:0]           avmm_bm_addr,
        output  wire    [511:0]         avmm_bm_rdata,
        input   wire    [511:0]         avmm_bm_wdata,
        input   wire    [63:0]          avmm_bm_be,
        input   wire                    avmm_bm_cs,
        input   wire                    avmm_bm_r,
        input   wire                    avmm_bm_w,

        input   wire    [5:0]           avmm_im_addr,
        output  wire    [31:0]          avmm_im_rdata,
        input   wire    [31:0]          avmm_im_wdata,
        input   wire    [3:0]           avmm_im_be,
        input   wire                    avmm_im_cs,
        input   wire                    avmm_im_r,
        input   wire                    avmm_im_w,

        input   wire                    clk,    // Active high
        input   wire                    rst     // Sync & Active-high
);

/*
* Hyperparameters
* P: Parallelism (# of PEs: must be a power of 2 & bigger than 64)
* W: Word size
* D: input Dimension
* H: State size
*/
localparam P = 64;
localparam W = 8;

//State Machine Signals
wire                state;                      // 0:Idle 1:Work
wire                core_rst;                   // Core start signal
wire                done;       

// Signals
wire                am_src2_ren;
wire                am_src0_ren;
wire                am_src1_ren;
wire                am_dst_wen;

wire    [4:0]       am_dst_addr;
wire    [4:0]       am_src0_addr;
wire    [4:0]       am_src1_addr;
wire    [4:0]       am_src2_addr;

wire    [P-1:0]     am_dst_cs;
wire    [P-1:0]     am_src0_cs;
wire    [P-1:0]     am_src1_cs;
wire    [P-1:0]     am_src2_cs;

wire    [P*8-1:0]   am_dst_wdata;
wire    [P*8-1:0]   am_src2_rdata;
wire    [P*8-1:0]   am_src0_rdata;
wire    [P*8-1:0]   am_src1_rdata;

wire                pam_src2_ren;
wire                pam_src0_ren;
wire                pam_src1_ren;
wire                pam_dst_wen;

wire    [4:0]       pam_dst_addr;
wire    [4:0]       pam_src0_addr;
wire    [4:0]       pam_src1_addr;
wire    [4:0]       pam_src2_addr;

wire    [P-1:0]     pam_dst_wdata;
wire    [P-1:0]     pam_src2_rdata;
wire    [P-1:0]     pam_src0_rdata;
wire    [P-1:0]     pam_src1_rdata;

wire                wm_ren;
wire    [10:0]      wm_addr;
wire    [P*8-1:0]   wm_rdata;

wire                bm_ren;
wire    [4:0]       bm_addr;
wire    [P*8-1:0]   bm_rdata;

wire                im_ren;
wire    [7:0]       im_addr;
wire    [31:0]      im_rdata;

wire    [4:0]       am0_addr0;
wire                am0_cs0; 
wire                am0_rw0;
wire    [P*8-1:0]   am0_wdata0;
wire    [P*8/8-1:0] am0_byteenable0;
wire    [P-1:0]     am0_bank_cs0;

wire    [4:0]       am0_addr1;
wire                am0_cs1;
wire                am0_rw1;
wire    [P*8-1:0]   am0_wdata1;
wire    [P*8/8-1:0] am0_byteenable1;
wire    [P-1:0]     am0_bank_cs1;

wire    [4:0]       am1_addr0;
wire                am1_cs0; 
wire                am1_rw0;
wire    [P*8-1:0]   am1_wdata0;
wire    [P*8/8-1:0] am1_byteenable0;
wire    [P-1:0]     am1_bank_cs0;

wire    [4:0]       am1_addr1;
wire                am1_cs1;
wire                am1_rw1;
wire    [P*8-1:0]   am1_wdata1;
wire    [P*8/8-1:0] am1_byteenable1;
wire    [P-1:0]     am1_bank_cs1;

wire    [P*8-1:0]   am0_rdata0;
wire    [P*8-1:0]   am0_rdata1;
wire    [P*8-1:0]   am1_rdata0;
wire    [P*8-1:0]   am1_rdata1;

wire                pam_cs;
wire    [P-1:0]     pam_rdata;

wire    [3:0]       alp_plus_beta;
wire    [2:0]       beta;

reg     [0:0]       latched_avmm_csr_addr;

// read & write signals
wire    csr_write  = avmm_csr_w  & (~avmm_csr_r);
wire    csr_read   = avmm_csr_r  & (~avmm_csr_w);
 
wire    am0_write  = avmm_am0_w  & (~avmm_am0_r);
wire    am0_read   = avmm_am0_r  & (~avmm_am0_w);
 
wire    am1_write  = avmm_am1_w  & (~avmm_am1_r);
wire    am1_read   = avmm_am1_r  & (~avmm_am1_w);

wire    pam_write  = avmm_pam_w  & (~avmm_pam_r);
wire    pam_read   = avmm_pam_r  & (~avmm_pam_w);
 
wire    wm_write   = avmm_wm_w   & (~avmm_wm_r);
wire    wm_read    = avmm_wm_r   & (~avmm_wm_w);

wire    bm_write   = avmm_bm_w   & (~avmm_bm_r);
wire    bm_read    = avmm_bm_r   & (~avmm_bm_w);

wire    im_write   = avmm_im_w   & (~avmm_im_r);
wire    im_read    = avmm_im_r   & (~avmm_im_w);

assign  avmm_am0_rdata  = am0_rdata1;
assign  avmm_am1_rdata  = am1_rdata1;
assign  avmm_pam_rdata  = pam_src0_rdata;
assign  avmm_wm_rdata   = wm_rdata;
assign  avmm_bm_rdata   = bm_rdata;
assign  avmm_im_rdata   = im_rdata;

always @(posedge clk)
        if(avmm_csr_cs & csr_read) latched_avmm_csr_addr <= avmm_csr_addr;

always @*
    case(latched_avmm_csr_addr)
            1'b0 : avmm_csr_rdata = {30'd0,  done, state};
            1'b1 : avmm_csr_rdata = {25'd0,  alp_plus_beta, beta};
    endcase

ROSETTA_Core#(
        .P(P),
        .W(W)
) core(
        .im_ren(im_ren),
        .im_raddr(im_addr),
        .im_rdata(im_rdata),

        .bm_ren(bm_ren),
        .bm_raddr(bm_addr),
        .bm_rdata(bm_rdata),

        .wm_ren(wm_ren),
        .wm_raddr(wm_addr),
        .wm_rdata(wm_rdata),

        .pam_r_ren(pam_src2_ren),
        .pam_r_rdata(pam_src2_rdata),
        .pam_r_raddr(pam_src2_addr),

        .pam_r_wen(pam_dst_wen),
        .pam_r_waddr(pam_dst_addr),
        .pam_r_wdata(pam_dst_wdata),

        .pam_x_ren(pam_src0_ren),
        .pam_x_raddr(pam_src0_addr[3:0]),
        .pam_x_rdata(pam_src0_rdata),

        .pam_y_ren(pam_src1_ren),
        .pam_y_raddr(pam_src1_addr),
        .pam_y_rdata(pam_src1_rdata),

        .am_r_ren(am_src2_ren),
        .am_r_rdata(am_src2_rdata),
        .am_r_raddr(am_src2_addr),
        .am_r_rcs(am_src2_cs),

        .am_r_wen(am_dst_wen),
        .am_r_waddr(am_dst_addr),
        .am_r_wcs(am_dst_cs),
        .am_r_wdata(am_dst_wdata),

        .am_x_ren(am_src0_ren),
        .am_x_raddr(am_src0_addr),
        .am_x_rcs(am_src0_cs),
        .am_x_rdata(am_src0_rdata),

        .am_y_ren(am_src1_ren),
        .am_y_raddr(am_src1_addr),
        .am_y_rcs(am_src1_cs),
        .am_y_rdata(am_src1_rdata),

        .alp_plus_beta(alp_plus_beta),
        .beta(beta),

        .done(done),

        .clk(clk),
        .rst(core_rst)
);

AM_Access_Router#(
        .P(P),
        .W(W)
) am_access_router(
        .am_dst_addr(am_dst_addr),
        .am_src0_addr(am_src0_addr),
        .am_src1_addr(am_src1_addr),
        .am_src2_addr(am_src2_addr),

        .am_dst_wdata(am_dst_wdata),
        .am_src2_ren(am_src2_ren),
        .am_src0_ren(am_src0_ren),
        .am_src1_ren(am_src1_ren),
        .am_dst_wen(am_dst_wen),

        .am_src2_rdata(am_src2_rdata),
        .am_src0_rdata(am_src0_rdata),
        .am_src1_rdata(am_src1_rdata),

        .am_src0_cs(am_src0_cs),
        .am_src1_cs(am_src1_cs),
        .am_dst_cs(am_dst_cs),
        .am_src2_cs(am_src2_cs),

        .am0_addr0(am0_addr0),
        .am0_cs0(am0_cs0),
        .am0_rw0(am0_rw0),
        .am0_wdata0(am0_wdata0),
        .am0_byteenable0(am0_byteenable0),
        .am0_rdata0(am0_rdata0),
        .am0_bank_cs0(am0_bank_cs0),

        .am0_addr1(am0_addr1),
        .am0_cs1(am0_cs1),
        .am0_rw1(am0_rw1),
        .am0_wdata1(am0_wdata1),
        .am0_byteenable1(am0_byteenable1),
        .am0_rdata1(am0_rdata1),
        .am0_bank_cs1(am0_bank_cs1),

        .am1_addr0(am1_addr0),
        .am1_cs0(am1_cs0),
        .am1_rw0(am1_rw0),
        .am1_wdata0(am1_wdata0),
        .am1_byteenable0(am1_byteenable0),
        .am1_rdata0(am1_rdata0),
        .am1_bank_cs0(am1_bank_cs0),

        .am1_addr1(am1_addr1),
        .am1_cs1(am1_cs1),
        .am1_rw1(am1_rw1),
        .am1_wdata1(am1_wdata1),
        .am1_byteenable1(am1_byteenable1),
        .am1_rdata1(am1_rdata1),
        .am1_bank_cs1(am1_bank_cs1),

        .clk(clk),
        .rst(rst)
);

    Act_mem am0(
            .addr_a(state ? am0_addr0[2:0] : avmm_am0_addr),
            .addr_b(state ? am0_addr1[2:0] : avmm_am0_addr),
            .data_a(state ? am0_wdata0 : avmm_am0_wdata),
            .data_b(am0_wdata1),
            .i_be_a(state ? am0_byteenable0 : avmm_am0_be),
            .i_be_b(am0_byteenable1),
            .i_cs_a(state ? am0_bank_cs0 : avmm_am0_be),
            .i_cs_b(am0_bank_cs1),
            .wren_a(state ? (am0_cs0 & am0_rw0) : (avmm_am0_cs & am0_write)),
            .wren_b(am0_cs1 & am0_rw1 & state),
            .q_a(am0_rdata0),
            .q_b(am0_rdata1),
            .enable(avmm_am0_cs | (am0_cs0 & state) | (am0_cs1 & state)),
            .clock(clk)  
    );

    Act_mem am1(    
            .addr_a(state ? am1_addr0[2:0] : avmm_am1_addr),
            .addr_b(state ? am1_addr1[2:0] : avmm_am1_addr),
            .data_a(state ? am1_wdata0 : avmm_am1_wdata),
            .data_b(am1_wdata1),
            .i_be_a(state ? am1_byteenable0 : avmm_am1_be),
            .i_be_b(am1_byteenable1),
            .i_cs_a(state ? am1_bank_cs0 : avmm_am1_be),
            .i_cs_b(am1_bank_cs1),
            .wren_a(state ? (am1_cs0 & am1_rw0) : (avmm_am1_cs & am1_write)),
            .wren_b(am1_cs1 & am1_rw1 & state),
            .q_a(am1_rdata0),
            .q_b(am1_rdata1),
            .enable(avmm_am1_cs | (am1_cs0 & state) | (am1_cs1 & state)),          
            .clock(clk)            
    );

    Wght_mem wm(
            .addr(state ? wm_addr[10:0] : avmm_wm_addr),
            .data(avmm_wm_wdata),
            .be(state ? {(64){1'b1}} : avmm_wm_be),
            .wren(avmm_wm_cs & wm_write),
            .rden(state ? wm_ren : (avmm_wm_cs & wm_read)),
            .wea(state ? {(64){(!wm_ren)}} : ((avmm_wm_cs & wm_write) ? avmm_wm_be : {(64){(1'b0)}})),
            .q(wm_rdata),
            .ena(avmm_wm_cs | (wm_ren & state)),
            .clk(clk)  
    );

    Bias_mem bm(
            .addr(state ? bm_addr[4:0] : avmm_bm_addr),
            .data(avmm_bm_wdata),
            .be(state ? {(64){1'b1}} : avmm_bm_be),
            .wren(avmm_bm_cs & bm_write),
            .rden(state ? bm_ren : (avmm_bm_cs & bm_read)),
            .wea(state ? {(64){(!bm_ren)}} : ((avmm_bm_cs & bm_write) ? avmm_bm_be : {(64){(1'b0)}})),
            .q(bm_rdata),
            .ena(avmm_bm_cs | (bm_ren & state)),
            .clk(clk)  
    );

    Inst_mem im(
            .addr(state ? im_addr : avmm_im_addr),
            .data(avmm_im_wdata),
            .be(state ? {(32/8){1'b1}} : avmm_im_be),
            .wren(avmm_im_cs & im_write),
            .rden(state ? im_ren : (avmm_im_cs & im_read)),
            .wea(state ? {(4){(!im_ren)}} : ((avmm_im_cs & im_write) ? avmm_im_be : {(4){(1'b0)}})),
            .q(im_rdata),
            .ena(avmm_im_cs | (im_ren & state)),
            .clk(clk)  
    );

    PAM pam(
            .re0(state ? pam_src0_ren : (pam_read & avmm_pam_cs)),
            .re1(pam_src1_ren),
            .re2(pam_src2_ren),
            .we(state ? pam_dst_wen : (avmm_pam_cs & pam_write)),
            .be(state ? {(64/8){1'b1}} : avmm_pam_be),
    
            .raddr0(state ? {1'b0, pam_src0_addr[3:0]} : avmm_pam_addr),
            .raddr1(pam_src1_addr),
            .raddr2(pam_src2_addr),
            .waddr(state ? pam_dst_addr : avmm_pam_addr),
    
            .rdata0(pam_src0_rdata),
            .rdata1(pam_src1_rdata),
            .rdata2(pam_src2_rdata),
    
            .wdata(state ? pam_dst_wdata : avmm_pam_wdata),
            .clk(clk)
    );

    Dreg_We_Rst #(
            .WIDTH(7),
            .RESET_VALUE(7'h7f)
    ) bound_info_reg(
            .i(avmm_csr_wdata[6:0]),  
            .o({alp_plus_beta, beta}),
            .we(avmm_csr_cs & csr_write & avmm_csr_addr),
            .clk(clk),
            .rst(rst)
    );

//-----------------------------------------------------------------------------
// State Machine
//-----------------------------------------------------------------------------
ROSETTA_State_Machine ROSETTA_sm(
        .start(avmm_csr_cs & csr_write & avmm_csr_wdata[0] & !avmm_csr_addr),
        .state(state),
        .core_rst(core_rst),
        .done(done),
        .clk(clk),
        .rst(rst)
);

endmodule