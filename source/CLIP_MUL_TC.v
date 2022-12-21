/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: CLIP_MUL_TC.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Multiplication and clipping module of ROSETTA
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

module CLIP_MUL_TC #(
		parameter W = 8
	)(
	input 	wire  	[W-1:0]  in0,
	input 	wire 	[W-1:0]  in1,
	output 	wire signed [2*W-1:0]  out,
	input	wire    [1:0]	 fp_in1
	);

	wire signed [16:0]  out_tmp;

	assign out_tmp = $signed(in1) * (|fp_in1 ? $signed(in0) :$signed({1'd0, in0[7:0]}));
	assign out = out_tmp[15:0];

endmodule

