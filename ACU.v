/**
*   @Module ACU: Activation Coefficient Unit
*   @brief  Activation Coefficient Unit based on the reduced table
*  
**/
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
        casex(in_data[7:4])
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