/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: ROSETTA_Wrapper.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Wrapper of ROSETTA for Xilinx simulation
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

module ROSETTA_Wrapper(

        input   wire    [11:0]          ext_addr_32b,
        output  reg     [31:0]          ext_rdata_32b,
        input   wire    [31:0]          ext_wdata_32b,
        input   wire    [3:0]           ext_we_32b,
        input   wire                    ext_en_32b,
 
        input   wire    [12:0]          ext_addr_64b,
        output  wire     [63:0]         ext_rdata_64b,
        input   wire    [63:0]          ext_wdata_64b,
        input   wire    [7:0]           ext_we_64b,
        input   wire                    ext_en_64b,

        input   wire    [18:0]          ext_addr_512b,
        output  reg     [511:0]         ext_rdata_512b,
        input   wire    [511:0]         ext_wdata_512b,
        input   wire    [63:0]          ext_we_512b,
        input   wire                    ext_en_512b,

        input   wire                    ext_clk,    // Active high
        input   wire                    ext_rst     // Sync & Active-high
);

reg     [1:0]   ext_cs_32b;
reg     [3:0]   ext_cs_512b;

wire            avmm_csr_cs;
wire            avmm_am0_cs;
wire            avmm_am1_cs;
wire            avmm_pam_cs;
wire            avmm_wm_cs;
wire            avmm_bm_cs;
wire            avmm_im_cs;

wire            avmm_r_32b;
wire            avmm_w_32b;
wire    [3:0]   avmm_be_32b;
wire    [31:0]  avmm_csr_rdata;
wire    [31:0]  avmm_im_rdata;

wire            avmm_r_64b;
wire            avmm_w_64b;
wire    [7:0]   avmm_be_64b;
wire    [63:0]  avmm_pam_rdata;

wire            avmm_r_512b;
wire            avmm_w_512b;
wire    [63:0]  avmm_be_512b;
wire    [511:0] avmm_am0_rdata;
wire    [511:0] avmm_am1_rdata;
wire    [511:0] avmm_wm_rdata;
wire    [511:0] avmm_bm_rdata;

// Address decoder
assign {avmm_csr_cs, avmm_im_cs} = ext_cs_32b;
always @* begin
        casex({ext_en_32b, ext_addr_32b[11]})
                {1'b1, 1'b0} : ext_cs_32b = 2'b10;
                {1'b1, 1'b1} : ext_cs_32b = 2'b01;
                default      : ext_cs_32b = 2'b00;
        endcase
end

assign {avmm_am0_cs, avmm_am1_cs, avmm_wm_cs, avmm_bm_cs} = ext_cs_512b;
always @* begin
        casex({ext_en_512b, ext_addr_512b[18:17]})
                {1'b1, 2'b00} : ext_cs_512b = 4'b1000;
                {1'b1, 2'b01} : ext_cs_512b = 4'b0100;
                {1'b1, 2'b10} : ext_cs_512b = 4'b0010;
                {1'b1, 2'b11} : ext_cs_512b = 4'b0001;
                default       : ext_cs_512b = 4'b0000;
        endcase
end

always @* begin
        casex (ext_addr_32b[11])
                1'b0: ext_rdata_32b = avmm_csr_rdata;
                1'b1: ext_rdata_32b = avmm_im_rdata;
        endcase
end

always @* begin
        casex (ext_addr_512b[18:17])
                2'b00: ext_rdata_512b = avmm_am0_rdata;
                2'b01: ext_rdata_512b = avmm_am1_rdata;
                2'b10: ext_rdata_512b = avmm_wm_rdata;
                2'b11: ext_rdata_512b = avmm_bm_rdata;
        endcase     
end


// ext --> AVMM interface wrapper
assign avmm_w_32b = |ext_we_32b;
assign avmm_r_32b = ~avmm_w_32b;
assign avmm_be_32b = (avmm_w_32b) ? ext_we_32b : {(4){1'b1}};

assign avmm_w_64b = |ext_we_64b;
assign avmm_r_64b = ~avmm_w_64b;
assign avmm_be_64b = (avmm_w_64b) ? ext_we_64b : {(8){1'b1}};

assign avmm_w_512b = |ext_we_512b;
assign avmm_r_512b = ~avmm_w_512b;
assign avmm_be_512b = (avmm_w_512b) ? ext_we_512b : {(64){1'b1}};

ROSETTA ROSETTA_Top(
        .avmm_csr_addr(ext_addr_32b[2]),
        .avmm_csr_rdata(avmm_csr_rdata),
        .avmm_csr_wdata(ext_wdata_32b),
        .avmm_csr_be(avmm_be_32b),
        .avmm_csr_cs(avmm_csr_cs),
        .avmm_csr_r(avmm_r_32b),
        .avmm_csr_w(avmm_w_32b),
 
        .avmm_am0_addr(ext_addr_512b[8:6]),
        .avmm_am0_rdata(avmm_am0_rdata),
        .avmm_am0_wdata(ext_wdata_512b),
        .avmm_am0_be(avmm_be_512b),
        .avmm_am0_cs(avmm_am0_cs),
        .avmm_am0_r(avmm_r_512b),
        .avmm_am0_w(avmm_w_512b),

        .avmm_am1_addr(ext_addr_512b[8:6]),
        .avmm_am1_rdata(avmm_am1_rdata),
        .avmm_am1_wdata(ext_wdata_512b),
        .avmm_am1_be(avmm_be_512b),
        .avmm_am1_cs(avmm_am1_cs),
        .avmm_am1_r(avmm_r_512b),
        .avmm_am1_w(avmm_w_512b),

        .avmm_pam_addr(ext_addr_64b[6:3]),
        .avmm_pam_rdata(ext_rdata_64b),
        .avmm_pam_wdata(ext_wdata_64b),
        .avmm_pam_be(avmm_be_64b),
        .avmm_pam_cs(ext_en_64b),
        .avmm_pam_r(avmm_r_64b),
        .avmm_pam_w(avmm_w_64b),

        .avmm_wm_addr(ext_addr_512b[16:6]),
        .avmm_wm_rdata(avmm_wm_rdata),
        .avmm_wm_wdata(ext_wdata_512b),
        .avmm_wm_be(avmm_be_512b),
        .avmm_wm_cs(avmm_wm_cs),
        .avmm_wm_r(avmm_r_512b),
        .avmm_wm_w(avmm_w_512b),

        .avmm_bm_addr(ext_addr_512b[10:6]),
        .avmm_bm_rdata(avmm_bm_rdata),
        .avmm_bm_wdata(ext_wdata_512b),
        .avmm_bm_be(avmm_be_512b),
        .avmm_bm_cs(avmm_bm_cs),
        .avmm_bm_r(avmm_r_512b),
        .avmm_bm_w(avmm_w_512b),

        .avmm_im_addr(ext_addr_32b[7:2]),
        .avmm_im_rdata(avmm_im_rdata),
        .avmm_im_wdata(ext_wdata_32b),
        .avmm_im_be(avmm_be_32b),
        .avmm_im_cs(avmm_im_cs),
        .avmm_im_r(avmm_r_32b),
        .avmm_im_w(avmm_w_32b),

        .clk(ext_clk),    // Active high
        .rst(ext_rst)     // Sync & Active-high
);

endmodule
