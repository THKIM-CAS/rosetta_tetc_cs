/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: ROSETTA_State_Machine.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: State machine of ROSETTA
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

/**
*   @Module ROSETTA State Machine
*   @brief  Change ARTEMIS status by start & done signals
*   
**/
module ROSETTA_State_Machine (
        input   wire    start,
        output  reg     state,          // 0:Idle 1:Work
        output  reg     core_rst,
        input   wire    done,
        input   wire    clk,
        input   wire    rst             //sync. active-high
);


localparam ST_IDLE = 1'd0;
localparam ST_WORK = 1'd1;

reg    next_state;

always @ (posedge clk)
        if(rst) state <= ST_IDLE;
        else state <= next_state;

always @*
        casex({state, start, done})
                {ST_IDLE, 1'b0, 1'bx}: {next_state, core_rst} = {ST_IDLE, 1'b0};
                {ST_IDLE, 1'b1, 1'bx}: {next_state, core_rst} = {ST_WORK, 1'b1};
                {ST_WORK, 1'bx, 1'b0}: {next_state, core_rst} = {ST_WORK, 1'b0};
                {ST_WORK, 1'bx, 1'b1}: {next_state, core_rst} = {ST_IDLE, 1'b0};
        endcase

endmodule