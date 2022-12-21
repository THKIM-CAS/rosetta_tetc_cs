/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: ACU.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Activation Coefficient Unit of ROSETTA
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


module ACU (
    input    wire [(64*8)-1:0]     in,
    output   wire [(64*8)-1:0]     sig_out,
    output   wire [(64*8)-1:0]     tanh_out,
    output   wire [(64*8)-1:0]     sig_slope,
    output   wire [(64*8)-1:0]     sig_offset,
    output   wire [(64*8)-1:0]     tanh_slope,
    output   wire [(64*8)-1:0]     tanh_offset
	);

generate
    genvar idx;
        for(idx = 0; idx < 64; idx = idx+1) begin : actblk
            sig_slope u0_sig_slope(
                .in_data(in[8*(idx+1)-1:8*idx]),
                .slope(sig_slope[8*(idx+1)-1:8*idx])
            );        
            sig_offset u0_sig_offset(
                .in_data(in[8*(idx+1)-1:8*idx]),
                .offset(sig_offset[8*(idx+1)-1:8*idx]) 
            );
            assign tanh_slope[8*(idx+1)-1:8*idx] = sig_slope[8*(idx+1)-1:8*idx];
            assign tanh_offset[8*(idx+1)-1:8*idx] = {{{(3){~sig_offset[8*idx+4]}}, sig_offset[8*idx+3:8*idx]}, 1'd0};
            assign sig_out[8*(idx+1)-1:8*idx]  = {{(3){1'b0}}, in[8*idx+4:8*idx]};
            assign tanh_out[8*(idx+1)-1:8*idx] = {{(2){1'b0}}, {in[8*idx+3:8*idx], 2'b0}};
        end 
endgenerate

endmodule

module sig_slope (
    input   wire    [7:0]  in_data,
    input   wire           enof_type,
    output  reg     [7:0]  slope
);

    wire [2:0] knot_symm;
    wire [3:0] knot;
    assign knot = enof_type ? ^in_data[7:6] ? {in_data[7],{(3){in_data[6]}}} : in_data[6:3]
                                            : in_data[7:4];
    assign knot_symm = knot[3] ? ~knot[2:0] : knot[2:0];

    always @*
        casex(knot_symm)
            3'b000 : slope = 8'h3E;
            3'b001 : slope = 8'h37;
            3'b010 : slope = 8'h2C;
            3'b011 : slope = 8'h20;
            3'b100 : slope = 8'h16;
            3'b101 : slope = 8'h0E;
            3'b110 : slope = 8'h09;
            3'b111 : slope = 8'h05;
        endcase               
endmodule

module sig_offset (
    input   wire    [7:0]  in_data,
    input   wire           enof_type,
    output  reg     [7:0]  offset
);

    wire [3:0] knot;
    assign knot = enof_type ? ^in_data[7:6] ? {in_data[7],{(3){in_data[6]}}} : in_data[6:3]
                                            : in_data[7:4];

    always @*
        casex(knot)
            4'b0000 : offset = 8'h80;
            4'b0001 : offset = 8'h9F;
            4'b0010 : offset = 8'hBB;
            4'b0011 : offset = 8'hD1;
            4'b0100 : offset = 8'hE1;
            4'b0101 : offset = 8'hEC;
            4'b0110 : offset = 8'hF3;
            4'b0111 : offset = 8'hF8;
            4'b1000 : offset = 8'h04;
            4'b1001 : offset = 8'h07;
            4'b1010 : offset = 8'h0C;
            4'b1011 : offset = 8'h13;
            4'b1100 : offset = 8'h1E;
            4'b1101 : offset = 8'h2E;
            4'b1110 : offset = 8'h44;
            4'b1111 : offset = 8'h60;
        endcase               
endmodule