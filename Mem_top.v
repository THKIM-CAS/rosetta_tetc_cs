module Act_mem #(
        parameter WIDTH = 512,
        parameter ADDR_WIDTH = 3,
        parameter P = 64
)(
        input   wire    [ADDR_WIDTH-1:0]    address_a, address_b, 
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
            Dual_Port_SRAM8b7 act_mem(
                  .address_a(address_a),
                  .address_b(address_b),
                  .clock(clock),
                  .data_a(data_a[8*(idx+1)-1:8*idx]),
                  .data_b(data_b[8*(idx+1)-1:8*idx]),
                  .wren_a(wren_a & i_be_a[idx]),
                  .wren_b(wren_b & i_be_b[idx]),
                  .q_a(q_a[8*(idx+1)-1:8*idx]),
                  .q_b(q_b[8*(idx+1)-1:8*idx])
            );
        end        
    endgenerate

endmodule
