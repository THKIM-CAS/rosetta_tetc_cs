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