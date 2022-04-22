/**
*   @Module    ROSETTA_Controller
*   @brief     Generating control signals of ROSETTA_Core
*
**/
module ROSETTA_Controller(
        input   wire    [27:0]  inst,

        input   wire            all_done,

        input   wire            nop,
        output  wire            nops_encod,

        input   wire            k_end,
        input   wire            i_end,                          // end of matrix P_row x P_col
        input   wire            j_end,                          // end of matrix P_row x all_col
        input   wire            j_end_reg,                      

        input   wire            e_end,                          // end of EMAC or ENOF
        output  wire            k_end_out,
        output  wire            i_end_out,                      
        output  wire            j_end_out,
        output  wire            e_state,
        output  wire            e_end_out,

        input   wire            stall_done,                     // done bubble
        output  wire            stall_fetch,                    

        output  wire            am_src0_ren,                    // am src0 read enable
        output  wire            am_src1_ren,                    // am src1 read enable
        output  wire            am_dst_ren,                     // am src2 read enable
        output  wire            am_dst_wen,                     // am dst  write enable
        output  wire            wm_ren,                         // wm read enable
        output  wire            bm_ren,                         // bm read enable

        output  wire    [1:0]   oprnd1_sel,                     
        output  wire            oprnd2_sel,                     
        output  wire            mvma_first,                     // mvma first signal

        output  wire            done_wen,                       // Done signal write enable

        output  wire            inv,                            // Implementing (1-x) of GRU (if x<0, invert fraction bits)
        output  wire            acc,                            // MAC operation Accumulation enable (y = x + ( acc ? a : 0 ))
        output  wire            act_type,                       // activation type (0-sigmoid, 1-tanh)
        output  wire    [1:0]   fp_out,
        output  wire    [1:0]   fp_in0,
        output  wire    [1:0]   fp_in1,
        output  wire            last_inst

);

/*
* Instruction based Control signals
*
* inv:      inversion       (0-off    , 1-on)           // for GRU (1-x)
* acc:      accumulate      (0-off    , 1-on)
* act_type: activation type (0-sigmoid, 1-tanh)
*/
assign nops_encod       = inst[1]; //2'd3 : 3'b0
assign last_inst        = inst[2];
assign fp_in1           = inst[4:3];
assign fp_in0           = inst[6:5];
assign fp_out           = inst[8:7];
assign inv              = inst[11];
assign acc              = inst[12];
assign act_type         = inst[13];
assign k_end_out        = k_end;
assign i_end_out        = i_end;
assign j_end_out        = j_end;
assign e_end_out        = e_end;

reg     [12:0]  ctrl_sig;
/*
* Control signals
* 
* Total 12bit control signals
* 
*/

assign  {stall_fetch,
        e_state,
        am_src0_ren, am_src1_ren, am_dst_ren, am_dst_wen, wm_ren, bm_ren, 
        oprnd1_sel, oprnd2_sel, mvma_first,
        done_wen}
        = ctrl_sig;

always @*
        casex({all_done, nop, stall_done, inst[15], inst[0], j_end, j_end_reg, i_end, e_end})

                9'b0_10_x0_x1x_x: ctrl_sig = 13'b1_0_000000_0000_0;                                         // NOP (delayed slot)
                9'b0_11_00_x1x_x: ctrl_sig = 13'b0_0_000000_0000_1;                                         // NOP + stall done

                9'b0_00_x0_0x0_x: ctrl_sig = 13'b1_0_100011_0000_0;                                         // mvma k_done
                9'b0_00_x0_0x1_x: ctrl_sig = 13'b1_0_100011_0001_0;                                         // mvma i_done
                9'b0_00_x0_1xx_x: ctrl_sig = 13'b1_0_000000_0000_1;                                         // mvma j_done

                9'b0_00_11_xxx_0: ctrl_sig = 13'b1_1_100100_1010_0;                                         // enof start
                9'b0_00_11_xxx_1: ctrl_sig = 13'b1_0_100100_1010_1;                                         // enof done

                9'b0_0x_01_xxx_0: ctrl_sig = acc ? 13'b1_1_111100_0100_0 : 13'b1_1_110100_0100_0;             // emac start
                9'b0_0x_01_xxx_1: ctrl_sig = acc ? 13'b1_0_111100_0100_1 : 13'b1_0_110100_0100_1;             // emac done

                9'b1_xx_xx_xxx_x: ctrl_sig = 13'b1_0_000000_0000_0;

                default:    ctrl_sig = 13'd0;
        endcase
endmodule