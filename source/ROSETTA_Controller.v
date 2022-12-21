/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: ROSETTA_Controller.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Control signal generation of ROSETTA
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

module ROSETTA_Controller(
        input   wire    [31:0]  inst,
  
        input   wire            nops_cntr_we,                    // first cycle of the instruction
        input   wire            beta_last_bound,
        input   wire            beta_done,                      // 
        input   wire            alp_plus_beta_last_bound,             // end of matrix P_row
        input   wire            alp_plus_beta_done,             // end of matrix P_row
        input   wire            p_done,                         // end of matrix P_row x
        input   wire            p_last_bound,               // one cycle left before p done
        input   wire            nops_done,
        input   wire            all_done,

        output  wire            x_addr_rst, 
        output  wire            r_addr_rst,
        output  wire            x_addr_wen, 
        output  wire            r_addr_wen,

        output  wire            im_ren,                         // stall fetch
        output  wire            pam_x_ren,                      // pam x read enable
        output  wire            pam_y_ren,                      // pam y read enable
        output  wire            pam_r_ren,                      // pam r read enable
        output  wire            pam_r_wen,                      // pam r write enable
        output  wire            wm_ren,                         // wm read enable
        output  wire            bm_ren,                         // bm read enable

        output  wire            inst_done                       // single instruction done signal
);

reg     [11:0]  ctrl_sig; 

assign  {im_ren,
        pam_x_ren, pam_y_ren, pam_r_ren, pam_r_wen,
        wm_ren, bm_ren,
        x_addr_wen, r_addr_wen, 
        x_addr_rst, r_addr_rst, 
        inst_done}
        = ctrl_sig;

always @*
        casex({inst[16], inst[0], beta_last_bound, beta_done, alp_plus_beta_last_bound, alp_plus_beta_done, p_last_bound, p_done, inst[1], nops_cntr_we, nops_done, all_done})

            12'bx0_10_00_11_100_0: ctrl_sig = 12'b0_1000_11_10_00_0;
            12'bx0_xx_01_11_100_0: ctrl_sig = 12'b0_1000_11_10_00_0;
            12'bx0_10_10_11_100_0: ctrl_sig = 12'b0_1001_11_01_10_0;
            12'bx0_01_00_11_100_0: ctrl_sig = 12'b0_1000_11_10_00_0;
            12'bx0_01_10_11_100_0: ctrl_sig = 12'b0_1001_11_00_00_1;

            12'bx0_xx_xx_00_100_0: ctrl_sig = 12'b0_0000_11_00_00_0;
            12'bx0_10_01_10_100_0: ctrl_sig = 12'b0_0001_11_01_00_0;
            12'bx0_10_01_01_100_0: ctrl_sig = 12'b0_1000_11_10_00_0;
            12'bx0_10_10_10_100_0: ctrl_sig = 12'b0_0000_11_00_00_0;
            12'bx0_01_01_10_100_0: ctrl_sig = 12'b0_0001_11_01_00_1;
            12'bx0_01_10_10_100_0: ctrl_sig = 12'b0_0000_11_00_00_0;
            12'bx0_xx_10_01_100_0: ctrl_sig = 12'b0_1000_11_00_10_0;
            12'bx0_01_01_01_100_0: ctrl_sig = 12'b0_1000_11_00_00_0;
            12'bx0_xx_xx_xx_110_0: ctrl_sig = 12'b0_0000_11_00_11_0;
            12'bx0_xx_xx_xx_111_0: ctrl_sig = 12'b1_0000_00_00_11_0;

            12'bx0_10_00_10_100_0: ctrl_sig = 12'b0_0000_11_00_00_0;
            12'bx0_10_00_01_100_0: ctrl_sig = 12'b0_1000_11_10_00_0;

            12'bx0_01_00_10_100_0: ctrl_sig = 12'b0_0000_11_00_00_0;
            12'bx0_01_00_01_100_0: ctrl_sig = 12'b0_1000_11_10_00_0;

            // ENOF w/ nops         
            12'b11_x0_xx_xx_100_0: ctrl_sig = 12'b0_1001_00_11_00_0;
            12'b11_01_xx_xx_100_0: ctrl_sig = 12'b0_1001_00_00_11_1;
            12'b11_xx_xx_xx_110_0: ctrl_sig = 12'b0_0000_00_00_11_0;
            12'b11_xx_xx_xx_111_0: ctrl_sig = 12'b1_0000_00_00_00_0;
            // ENOF w/o nops
            12'b11_x0_xx_xx_0xx_0: ctrl_sig = 12'b0_1001_00_11_00_0;
            12'b11_01_xx_xx_0xx_0: ctrl_sig = 12'b1_1001_00_00_11_1;

            // EMAC w/ nops
            12'b01_x0_xx_xx_100_0: ctrl_sig = 12'b0_1111_00_11_00_0;
            12'b01_01_xx_xx_100_0: ctrl_sig = 12'b0_1111_00_00_11_1;
            12'b01_xx_xx_xx_110_0: ctrl_sig = 12'b0_0000_00_00_11_0;
            12'b01_xx_xx_xx_111_0: ctrl_sig = 12'b1_0000_00_00_00_0;
            // EMAC w/o nops
            12'b01_x0_xx_xx_0xx_0: ctrl_sig = 12'b0_1111_00_11_00_0;
            12'b01_01_xx_xx_0xx_0: ctrl_sig = 12'b1_1111_00_00_11_1;
            
            // all done
            12'bxx_xx_xx_xx_xxx_1: ctrl_sig = 12'b0_0000_00_00_00_0;

            default    : ctrl_sig = 12'd0;       // done of ENOF

        endcase

endmodule 