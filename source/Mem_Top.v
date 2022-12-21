/* ****************************************************************************
SPDX-FileCopyrightText: 2022 Jiho Kim <jhkim_ms@kau.kr>
SPDX-License-Identifier: CERN-OHL-S-2.0 or any later version

-- (C) Copyright 2022 Jiho Kim - All rights reserved.
-- Source file: Mem_Top.v           
-- Date:        December 2022
-- Author:      Jiho Kim
-- Description: Top modules of memory of ROSETTA
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

module Act_mem #(
        parameter WIDTH = 512,
        parameter ADDR_WIDTH = 3,
        parameter P = 64
)( 
        input   wire                        enable,
        input   wire    [ADDR_WIDTH-1:0]    addr_a, addr_b, 
        input   wire    [WIDTH/8-1:0]       i_be_a,   i_be_b,
        input   wire    [P-1:0]             i_cs_a, i_cs_b,
        input   wire    [WIDTH-1:0]         data_a, data_b,
        input   wire                        wren_a, wren_b,
        output  wire    [WIDTH-1:0]         q_a, q_b,
        input   wire                        clock
);

    generate 
        genvar idx;
        for(idx = 0; idx < P; idx = idx+1) begin : act_mem

        `ifdef _QUARTUS
            Dual_Port_SRAM8b7 act_mem(
                .address_a(addr_a),
                .address_b(addr_b),
                .clock(clock),
                .data_a(data_a[8*(idx+1)-1:8*idx]),
                .data_b(data_b[8*(idx+1)-1:8*idx]),
                .wren_a(wren_a & i_be_a[idx]),
                .wren_b(wren_b & i_be_b[idx]),
                .q_a(q_a[8*(idx+1)-1:8*idx]),
                .q_b(q_b[8*(idx+1)-1:8*idx])
            );

        `elsif _RTLSIM
            Dual_Port_SRAM act_mem(
                .address_a(addr_a),
                .address_b(addr_b),
                .clock(clock),
                .enable((i_cs_a[63-idx] | i_cs_b[63-idx]) & enable),
                .data_a(data_a[8*(idx+1)-1:8*idx]),
                .data_b(data_b[8*(idx+1)-1:8*idx]),
                .wren_a(wren_a & i_be_a[idx]),
                .wren_b(wren_b & i_be_b[idx]),
                .q_a(q_a[8*(idx+1)-1:8*idx]),
                .q_b(q_b[8*(idx+1)-1:8*idx])
            );

        `else   
            AM8x16 act_mem (
                .clka(clock),                      
                .ena(i_cs_a[idx] & enable),       
                .wea(wren_a & i_be_a[idx]),       
                .addra(addr_a),                
                .dina(data_a[8*(idx+1)-1:8*idx]), 
                .douta(q_a[8*(idx+1)-1:8*idx]),   
                .clkb(clock),                     
                .enb(i_cs_b[idx] & enable),       
                .web(wren_b & i_be_b[idx]),       
                .addrb(addr_b),                
                .dinb(data_b[8*(idx+1)-1:8*idx]), 
                .doutb(q_b[8*(idx+1)-1:8*idx])    
            );
        `endif

        end        
    endgenerate

endmodule

module Wght_mem #(
        parameter WIDTH = 512,
        parameter ADDR_WIDTH = 11,
        parameter P = 64
)( 
        input   wire                        ena,
        input   wire    [ADDR_WIDTH-1:0]    addr, 
        input   wire    [WIDTH/8-1:0]       be, 
        input   wire    [P-1:0]             wea, 
        input   wire    [WIDTH-1:0]         data, 
        input   wire                        wren, 
        input   wire                        rden, 
        output  wire    [WIDTH-1:0]         q,
        input   wire                        clk
);

    `ifdef _QUARTUS
        Single_Port_SRAM512b1536 weight_mem(
                .address(addr),
                .byteena(be),
                .clock(clk),
                .clken(ena),
                .data(data),
                .rden(rden),
                .wren(wren),
                .q(q)
        );

    `elsif _RTLSIM
        Single_Port_SRAM #(
                .BYTE(8),
                .NUM_BYTE_IN_WORD(P*8/8),
                .DEPTH(1556),
                .ADDR_WIDTH(11)
        ) weight_mem(
                .address(addr),
                .byteena(be),
                .clock(clk),
                .clken(ena),
                .data(data),
                .rden(rden),
                .wren(wren),
                .q(q)
        );

    `else       
        WM512x1536 weight_mem (
                .clka(clk),
                .ena(ena),
                .wea(wea),
                .addra(addr),
                .dina(data),
                .douta(q)
        );

    `endif

endmodule

module Bias_mem #(
        parameter WIDTH = 512,
        parameter ADDR_WIDTH = 5,
        parameter P = 64
)( 
        input   wire                        ena,
        input   wire    [ADDR_WIDTH-1:0]    addr, 
        input   wire    [WIDTH/8-1:0]       be, 
        input   wire    [P-1:0]             wea, 
        input   wire    [WIDTH-1:0]         data, 
        input   wire                        wren, 
        input   wire                        rden, 
        output  wire    [WIDTH-1:0]         q,
        input   wire                        clk
);

    `ifdef _QUARTUS
        Single_Port_SRAM512b8 bias_mem(
                .address(addr),
                .byteena(be),
                .clock(clk),
                .clken(ena),
                .data(data),
                .rden(rden),        
                .wren(wren),
                .q(q)
        );
 
    `elsif _RTLSIM
        Single_Port_SRAM #(
                .BYTE(8),
                .NUM_BYTE_IN_WORD(P*8/8),
                .DEPTH(8),
                .ADDR_WIDTH(5)
        ) bias_mem(
                .address(addr),
                .byteena(be),
                .clock(clk),
                .clken(ena),
                .data(data),
                .rden(rden),        
                .wren(wren),
                .q(q)
        );

    `else       
        BM512x8 bias_mem (
                .clka(clk),
                .ena(ena),
                .wea(wea),
                .addra(addr[2:0]),
                .dina(data),
                .douta(q)
        );

    `endif

endmodule

module Inst_mem #(
        parameter WIDTH = 32,
        parameter ADDR_WIDTH = 8
)( 
        input   wire                        ena,
        input   wire    [ADDR_WIDTH-1:0]    addr, 
        input   wire    [WIDTH/8-1:0]       be, 
        input   wire    [3:0]               wea, 
        input   wire    [WIDTH-1:0]         data, 
        input   wire                        wren, 
        input   wire                        rden, 
        output  wire    [WIDTH-1:0]         q,
        input   wire                        clk
);

    `ifdef _QUARTUS
        Single_Port_SRAM32b50 inst_mem(
                .address(addr),
                .byteena(be),
                .clock(clk),
                .clken(ena),
                .data(data),
                .rden(rden),        
                .wren(wren),
                .q(q)
        );

    `elsif _RTLSIM
        Single_Port_SRAM #(
                .BYTE(8),
                .NUM_BYTE_IN_WORD(32/8),
                .DEPTH(50),
                .ADDR_WIDTH(8)
        ) inst_mem(
                .address(addr),
                .byteena(be),
                .clock(clk),
                .clken(ena),
                .data(data),
                .rden(rden),        
                .wren(wren),
                .q(q)
        );

    `else       
        IM32x50 inst_mem (
                .clka(clk),
                .ena(ena),
                .wea(wea),
                .addra(addr),
                .dina(data),
                .douta(q)
        );

    `endif


endmodule