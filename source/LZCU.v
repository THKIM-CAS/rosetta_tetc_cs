/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: LZCU.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Leading zero counting unit of ROSETTA
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

module LZCU #(
        parameter LZC_WIDTH = 7,
        parameter I_WIDTH = 2**(LZC_WIDTH-1)
)(
        output reg [LZC_WIDTH-1:0] out,
        input wire [I_WIDTH-1:0] in
);

generate
        if(I_WIDTH == 2) begin: blk_end
                always @*
                        case(in)
                                2'b00: out = 2'd2;
                                2'b01: out = 2'd1;
                                2'b10: out = 2'd0;
                                2'b11: out = 2'd0;
                        endcase
        end
        else begin: blk_nonend
                wire [LZC_WIDTH-2:0] o0, o1;
                LZCU #(.LZC_WIDTH(LZC_WIDTH-1)) u0(.in(in[I_WIDTH-1:I_WIDTH/2]), .out(o0));
                LZCU #(.LZC_WIDTH(LZC_WIDTH-1)) u1(.in(in[I_WIDTH/2-1:0]), .out(o1));
                always @*
                        casex({o0[LZC_WIDTH-2], o1[LZC_WIDTH-2]})
                                {1'b1, 1'b1}: out = {1'b1, {(LZC_WIDTH-1){1'b0}}};
                                {1'b1, 1'b0}: out = {2'b01, o1[LZC_WIDTH-3:0]};
                                {1'b0, 1'bx}: out = {2'b00, o0[LZC_WIDTH-3:0]};
                        endcase
        end
endgenerate
endmodule