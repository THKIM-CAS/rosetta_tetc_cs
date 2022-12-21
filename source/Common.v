/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: Common.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Common usable modules of ROSETTA (including d-registers, SRAMs, PAM)
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

//------------------------------------------------------------------------------
// Dflipflop array
//------------------------------------------------------------------------------
module Dreg #(
        parameter WIDTH = 1
)(
        input   wire    [WIDTH-1:0]     i,
        output  reg     [WIDTH-1:0]     o,
        input   wire                    clk
);
always @(posedge clk)
        o <=   i;
endmodule

//------------------------------------------------------------------------------
// Dflipflop array with reset
//------------------------------------------------------------------------------
module Dreg_Rst #(
        parameter WIDTH = 1,
        parameter [WIDTH-1:0] RESET_VALUE = {WIDTH{1'b0}}
)(
        input   wire    [WIDTH-1:0]     i,
        output  reg     [WIDTH-1:0]     o,
        input   wire                    clk,
        input   wire                    rst
);
always @(posedge clk) begin
        if(rst) o <=  RESET_VALUE;
        else o <=  i;
end
endmodule

//------------------------------------------------------------------------------
// Dflipflop array with write enable and reset
//------------------------------------------------------------------------------
module Dreg_We_Rst #(
        parameter WIDTH = 1,
        parameter [WIDTH-1:0] RESET_VALUE = {WIDTH{1'b0}}
)(
        input   wire    [WIDTH-1:0]     i,
        output  reg     [WIDTH-1:0]     o,
        input   wire                    we,
        input   wire                    clk,
        input   wire                    rst
);
always @(posedge clk)
        if(rst) o <=   RESET_VALUE;
        else if(we) o <=   i;
endmodule

//------------------------------------------------------------------------------
// Dflipflop array with write enable
//------------------------------------------------------------------------------
module Dreg_We #(
        parameter WIDTH = 1
)(
        input   wire    [WIDTH-1:0]     i,
        output  reg     [WIDTH-1:0]     o,
        input   wire                    we,
        input   wire                    clk
);

always @(posedge clk)
        if(we) o <=   i;
endmodule

//------------------------------------------------------------------------------
// Single-Port SRAM
//------------------------------------------------------------------------------
module Single_Port_SRAM #(
        parameter BYTE = 8,                         //each byte size, by default 8
        parameter NUM_BYTE_IN_WORD = 512/8,         //how many bytes in a word
        parameter DEPTH = 128,                      //how many words in a memory
        parameter ADDR_WIDTH = 7
)(
        input   wire    [ADDR_WIDTH-1:0]                       address,
        input   wire    [NUM_BYTE_IN_WORD-1:0]                 byteena,         //active-high byte enable
        input 	wire                                           clken, 
        input   wire                                           clock,
        input   wire    [BYTE*NUM_BYTE_IN_WORD-1:0]            data,
        input   wire                                           rden,
        input   wire                                           wren,
        output  reg     [BYTE*NUM_BYTE_IN_WORD-1:0]            q
);

reg     [BYTE*NUM_BYTE_IN_WORD-1:0]     mem [0:DEPTH-1];
reg     [ADDR_WIDTH-1:0]                reg_address;

always @(posedge clock)
        if(clken & rden & (~wren)) q <=  mem[address];               //registering read address

wire    [BYTE*NUM_BYTE_IN_WORD-1:0]     biten;

genvar idx;
generate
        for(idx=0; idx<NUM_BYTE_IN_WORD; idx=idx+1) begin: genblk2
                assign  biten[BYTE*(idx+1)-1:BYTE*idx] = {BYTE{byteena[idx]}};
        end
endgenerate

always @(posedge clock)
        if(clken & (~rden) & wren) mem[address] <=   (data & biten) | (mem[address] & ~biten);

endmodule

//------------------------------------------------------------------------------
// Dual-Port SRAM
//------------------------------------------------------------------------------
module Dual_Port_SRAM #(
        parameter BYTE = 8,                     //each byte size, by default 8
        parameter NUM_BYTE_IN_WORD = 1,        //how many bytes in a word
        parameter DEPTH = 7,                  //how many words in a memory
        parameter ADDR_WIDTH = 3
)(
        input   wire    [ADDR_WIDTH-1:0]                       address_a,
        input   wire    [ADDR_WIDTH-1:0]                       address_b,
        input   wire                                           clock,
        input   wire    [BYTE*NUM_BYTE_IN_WORD-1:0]            data_a,
        input   wire    [BYTE*NUM_BYTE_IN_WORD-1:0]            data_b,
        input   wire                                           enable,
        input   wire                                           wren_a,          //write=1, read=0
        input   wire                                           wren_b,          //write=1, read=0
        output  reg     [BYTE*NUM_BYTE_IN_WORD-1:0]            q_a,
        output  reg     [BYTE*NUM_BYTE_IN_WORD-1:0]            q_b
 
);

reg     [BYTE-1:0]     mem     [0:DEPTH-1];

always @(posedge clock)
        if(enable & (~wren_a)) q_a <=  mem[address_a]; //port_a read

always @(posedge clock)
        if(enable & (~wren_b)) q_b <=  mem[address_b]; //port_b read

always @(posedge clock) begin
        if(enable & wren_a) mem[address_a] <= (data_a); //write
        if(enable & wren_b) mem[address_b] <= (data_b);
end

endmodule

// ------------------------------------------------------------------------------
// Register based PAM
// ------------------------------------------------------------------------------
module PAM(
    input wire re0,
    input wire re1,
    input wire re2,
    input wire we,
    input wire [7:0] be,

    input wire [4:0] raddr0,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [4:0] waddr,

    output reg [63:0] rdata0,
    output reg [63:0] rdata1,
    output reg [63:0] rdata2,

    input wire [63:0] wdata,

    input wire clk
);

//64bit x 14
reg [63:0] mem[0:15];

wire [63:0] biten = {{8{be[7]}}, {8{be[6]}}, {8{be[5]}}, {8{be[4]}},
                     {8{be[3]}}, {8{be[2]}}, {8{be[1]}}, {8{be[0]}}};

always @ (posedge clk)
    if(re0) rdata0 <= mem[raddr0];

always @ (posedge clk)
    if(re1) rdata1 <= mem[raddr1];

always @ (posedge clk)
    if(re2) rdata2 <= mem[raddr2];

always @ (posedge clk)
    if(we) mem[waddr] <= (wdata & biten) | (mem[waddr] & ~biten);

endmodule
