module AM_Access_Router #(
    parameter P = 64,
    parameter W = 8
)(
    // Core I/F
    input   wire    [3:0]      am_dst_ptr,
    input   wire    [3:0]      am_src0_ptr,
    input   wire    [3:0]      am_src1_ptr,
    input   wire    [3:0]      am_src2_ptr,

    input   wire    [P*W-1:0]   am_dst_wdata,
    input   wire                am_src0_ren,
    input   wire                am_src1_ren,
    input   wire                am_src2_ren,
    input   wire                am_dst_wen,

    input   wire    [P-1:0]     am_dst_cs,
    input   wire    [P-1:0]     am_src0_cs,
    input   wire    [P-1:0]     am_src1_cs,
    input   wire    [P-1:0]     am_src2_cs,

    output  reg     [P*W-1:0]   am_src2_rdata,
    output  reg     [P*W-1:0]   am_src0_rdata,
    output  reg     [P*W-1:0]   am_src1_rdata,

    // Bank#0 I/F
    output  reg    [2:0]       am0_addr0,
    output  reg                 am0_cs0,            //active-high
    output  reg                 am0_rw0,            //read = 0, write = 1
    output  reg    [P*W-1:0]    am0_wdata0,
    output  reg    [P*W/8-1:0]  am0_byteenable0,    //active-high
    output  reg    [P-1:0]      am0_bank_cs0,
    input   wire   [P*W-1:0]    am0_rdata0,

    output  reg    [2:0]       am0_addr1,
    output  reg                 am0_cs1,            //active-high
    output  reg                 am0_rw1,            //read = 0, write = 1
    output  reg    [P*W-1:0]    am0_wdata1,
    output  reg    [P*W/8-1:0]  am0_byteenable1,    //active-high
    output  reg    [P-1:0]      am0_bank_cs1,
    input   wire   [P*W-1:0]    am0_rdata1,

    // Bank#1 I/F
    output  reg    [2:0]       am1_addr0,
    output  reg                 am1_cs0,            //active-high
    output  reg                 am1_rw0,            //read = 0, write = 1
    output  reg    [P*W-1:0]    am1_wdata0,
    output  reg    [P*W/8-1:0]  am1_byteenable0,    //ative-high
    output  reg    [P-1:0]      am1_bank_cs0,
    input   wire   [P*W-1:0]    am1_rdata0,

    output  reg    [2:0]       am1_addr1,
    output  reg                 am1_cs1,            //active-high
    output  reg                 am1_rw1,            //read = 0, write = 1
    output  reg    [P*W-1:0]    am1_wdata1,
    output  reg    [P*W/8-1:0]  am1_byteenable1,    //active-high
    output  reg    [P-1:0]      am1_bank_cs1,
    input   wire   [P*W-1:0]    am1_rdata1,

    // Clock & Reset
    input   wire                clk,
    input   wire                rst
);

localparam NODATA_PW = {(P*W){1'b0}};
localparam ONE = {(P*W/8){1'b1}};
localparam ZERO = {(P*W/8){1'b0}};

//dst read : 2'd0, dst_write : 2'd1, src0_read = 2'd2, src1_read : 2'd3
reg     [1:0]   am0_access0;
reg     [1:0]   am0_access1;
reg     [1:0]   am1_access0;
reg     [1:0]   am1_access1;

//am0_rdata0 : 2'd1, am0_rdata1 : 2'd1, am1_rdata0 : 2'd2, am1_rdata1 : 2'd3
reg     [1:0]   sel_am_src2_rdata;
reg     [1:0]   sel_am_src0_rdata;
reg     [1:0]   sel_am_src1_rdata;
wire    [1:0]   reg_sel_am_src2_rdata;
wire    [1:0]   reg_sel_am_src0_rdata;
wire    [1:0]   reg_sel_am_src1_rdata;

//dst read : 2'd0, dst_write : 2'd1, src0_read = 2'd2, src1_read : 2'd3
always @*
    casex ({am_src2_ren, am_dst_wen, am_src0_ren, am_src1_ren, am_src2_ptr[3], am_dst_ptr[3], am_src0_ptr[3], am_src1_ptr[3]})
    //MVPA not write
    {4'b0010, 4'bxx0x} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b0, 2'd0, 1'b0, 2'd0, 1'b0, 2'd0, 2'd0, 2'd0, 2'd0};
    {4'b0010, 4'bxx1x} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b0, 2'd0, 1'b0, 2'd0, 1'b1, 2'd2, 1'b0, 2'd0, 2'd0, 2'd2, 2'd0};
    //MVPA , ENOF
    {4'b01x0, 4'bx00x} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd1, am_src0_ren, 2'd2, 1'b0, 2'd0, 1'b0, 2'd0, 2'd0, 2'd1, 2'd0};
    {4'b01x0, 4'bx01x} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd1, 1'b0, 2'd0, am_src0_ren, 2'd2, 1'b0, 2'd0, 2'd0, 2'd2, 2'd0};
    {4'b01x0, 4'bx10x} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {am_src0_ren, 2'd2, 1'b0, 2'd0, 1'b1, 2'd1, 1'b0, 2'd0, 2'd0, 2'd0, 2'd0};
    {4'b01x0, 4'bx11x} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b0, 2'd0, 1'b0, 2'd0, 1'b1, 2'd1, am_src0_ren, 2'd2, 2'd0, 2'd3, 2'd0};
    //EMAC not write
    {4'b1011, 4'b0x01} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd0, 1'b1, 2'd2, 1'b1, 2'd3, 1'b0, 2'd0, 2'd0, 2'd1, 2'd2};
    {4'b1011, 4'b0x10} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd0, 1'b1, 2'd3, 1'b1, 2'd2, 1'b0, 2'd0, 2'd0, 2'd2, 2'd1};
    {4'b1011, 4'b0x11} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd0, 1'b0, 2'd0, 1'b1, 2'd2, 1'b1, 2'd3, 2'd0, 2'd2, 2'd3};
    {4'b1011, 4'b1x00} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1  , 2'd2       , 1'b1   , 2'd3       , 1'b1   , 2'd0       , 1'b0   , 2'd0       , 2'd2             , 2'd0             , 2'd1};
    {4'b1011, 4'b1x01} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b0, 2'd0, 1'b1, 2'd0, 1'b1, 2'd3, 2'd2, 2'd0, 2'd3};
    {4'b1011, 4'b1x10} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd3, 1'b0, 2'd0, 1'b1, 2'd0, 1'b1, 2'd2, 2'd2, 2'd3, 2'd0};
                                           
    //EMAC
    {4'b1111, 4'b0011} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd1, 1'b1, 2'd0, 1'b1, 2'd2, 1'b1, 2'd3, 2'd0, 2'd2, 2'd3};
    {4'b1111, 4'b1100} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b1, 2'd3, 1'b1, 2'd1, 1'b1, 2'd0, 2'd2, 2'd0, 2'd1};
    //EMUL not write
    {4'b0011, 4'bxx00} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b1, 2'd3, 1'b0, 2'd0, 1'b0, 2'd0, 2'd0, 2'd0, 2'd1};
    {4'b0011, 4'bxx01} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b0, 2'd0, 1'b1, 2'd3, 1'b0, 2'd0, 2'd0, 2'd0, 2'd2};
    {4'b0011, 4'bxx10} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd3, 1'b0, 2'd0, 1'b1, 2'd2, 1'b0, 2'd0, 2'd0, 2'd2, 2'd0};
    {4'b0011, 4'bxx11} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b0, 2'd0, 1'b0, 2'd0, 1'b1, 2'd2, 1'b1, 2'd3, 2'd0, 2'd2, 2'd3};                        
    //EMUL
    {4'b0111, 4'bx001} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd1, 1'b1, 2'd2, 1'b1, 2'd3, 1'b0, 2'd0, 2'd0, 2'd1, 2'd2};
    {4'b0111, 4'bx010} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd1, 1'b1, 2'd3, 1'b1, 2'd2, 1'b0, 2'd0, 2'd0, 2'd2, 2'd1};
    {4'b0111, 4'bx100} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b1, 2'd3, 1'b1, 2'd1, 1'b0, 2'd0, 2'd0, 2'd0, 2'd1};
    {4'b0111, 4'bx110} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd3, 1'b0, 2'd0, 1'b1, 2'd1, 1'b1, 2'd2, 2'd0, 2'd3, 2'd0};
    {4'b0111, 4'bx101} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd2, 1'b0, 2'd0, 1'b1, 2'd1, 1'b1, 2'd3, 2'd0, 2'd0, 2'd3};
    {4'b0111, 4'bx011} : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b1, 2'd1, 1'b0, 2'd0, 1'b1, 2'd2, 1'b1, 2'd3, 2'd0, 2'd2, 2'd3};
              default : {am0_cs0, am0_access0, am0_cs1, am0_access1, am1_cs0, am1_access0, am1_cs1, am1_access1, sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata} 
                        = {1'b0, 2'd0, 1'b0, 2'd0, 1'b0, 2'd0, 1'b0, 2'd0, 2'd0, 2'd0, 2'd0};                                                                                       
    endcase

//dst read : 2'd0, dst_write : 2'd1, src0_read = 2'd2, src1_read : 2'd3
always @*
    case (am0_access0)
        2'd0: {am0_addr0, am0_rw0, am0_wdata0, am0_byteenable0, am0_bank_cs0} = {am_src2_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src2_cs};
        2'd1: {am0_addr0, am0_rw0, am0_wdata0, am0_byteenable0, am0_bank_cs0} = {am_dst_ptr[2:0] , 1'b1, am_dst_wdata, ONE , am_dst_cs};
        2'd2: {am0_addr0, am0_rw0, am0_wdata0, am0_byteenable0, am0_bank_cs0} = {am_src0_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src0_cs};
        2'd3: {am0_addr0, am0_rw0, am0_wdata0, am0_byteenable0, am0_bank_cs0} = {am_src1_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src1_cs};
    endcase

always @*
    case (am0_access1)
        2'd0: {am0_addr1, am0_rw1, am0_wdata1, am0_byteenable1, am0_bank_cs1} = {am_src2_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src2_cs};
        2'd1: {am0_addr1, am0_rw1, am0_wdata1, am0_byteenable1, am0_bank_cs1} = {am_dst_ptr[2:0] , 1'b1, am_dst_wdata, ONE , am_dst_cs};
        2'd2: {am0_addr1, am0_rw1, am0_wdata1, am0_byteenable1, am0_bank_cs1} = {am_src0_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src0_cs};
        2'd3: {am0_addr1, am0_rw1, am0_wdata1, am0_byteenable1, am0_bank_cs1} = {am_src1_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src1_cs};
    endcase

always @*
    case (am1_access0)
        2'd0: {am1_addr0, am1_rw0, am1_wdata0, am1_byteenable0, am1_bank_cs0} = {am_src2_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src2_cs};
        2'd1: {am1_addr0, am1_rw0, am1_wdata0, am1_byteenable0, am1_bank_cs0} = {am_dst_ptr[2:0] , 1'b1, am_dst_wdata, ONE , am_dst_cs};
        2'd2: {am1_addr0, am1_rw0, am1_wdata0, am1_byteenable0, am1_bank_cs0} = {am_src0_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src0_cs};
        2'd3: {am1_addr0, am1_rw0, am1_wdata0, am1_byteenable0, am1_bank_cs0} = {am_src1_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src1_cs};
    endcase

always @*
    case (am1_access1)
        2'd0: {am1_addr1, am1_rw1, am1_wdata1, am1_byteenable1, am1_bank_cs1} = {am_src2_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src2_cs};
        2'd1: {am1_addr1, am1_rw1, am1_wdata1, am1_byteenable1, am1_bank_cs1} = {am_dst_ptr[2:0] , 1'b1, am_dst_wdata, ONE , am_dst_cs};
        2'd2: {am1_addr1, am1_rw1, am1_wdata1, am1_byteenable1, am1_bank_cs1} = {am_src0_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src0_cs};
        2'd3: {am1_addr1, am1_rw1, am1_wdata1, am1_byteenable1, am1_bank_cs1} = {am_src1_ptr[2:0], 1'b0, NODATA_PW   , ZERO, am_src1_cs};
    endcase

Dreg_Rst #(
        .WIDTH(6)
) dreg_sel_rdata1(
        .i({sel_am_src2_rdata, sel_am_src0_rdata, sel_am_src1_rdata}),
        .o({reg_sel_am_src2_rdata, reg_sel_am_src0_rdata, reg_sel_am_src1_rdata}),
        .clk(clk),
        .rst(rst)
);

always @*
    case (reg_sel_am_src0_rdata)
        2'd0: am_src0_rdata = am0_rdata0;
        2'd1: am_src0_rdata = am0_rdata1;
        2'd2: am_src0_rdata = am1_rdata0;
        2'd3: am_src0_rdata = am1_rdata1;
    endcase   
always @*
    case (reg_sel_am_src1_rdata)
        2'd0: am_src1_rdata = am0_rdata0;
        2'd1: am_src1_rdata = am0_rdata1;
        2'd2: am_src1_rdata = am1_rdata0;
        2'd3: am_src1_rdata = am1_rdata1;
    endcase
always @*
    case (reg_sel_am_src2_rdata)
        2'd0: am_src2_rdata = am0_rdata0;
        2'd1: am_src2_rdata = am0_rdata1;
        2'd2: am_src2_rdata = am1_rdata0;
        2'd3: am_src2_rdata = am1_rdata1;
    endcase

endmodule