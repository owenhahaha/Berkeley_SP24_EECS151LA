module MEM(
    input clk,
    input [31:0] ALU_M,
    input [31:0] rs2_data_M,
    input [2:0] funct3,
    input d_we,

    input [1:0] wb_sel,
    input [31:0] branch_target,
    input [31:0] PC_4,

    output reg [31:0] rd_data,

    output [31:0] dcache_addr,
    output reg [31:0] dcache_din,
    output reg [3:0] dcache_we
);
wire [1:0] last_2bit;
assign last_2bit = ALU_M[1:0];
assign dcache_addr = {ALU_M[31:2], 2'd0};


always@* begin
    case(wb_sel)
        2'd0: rd_data = ALU_M;           // write back memory
        2'd1: rd_data = 0;                // write back branch_target
        2'd2: rd_data = PC_4;             // jal/jalr
        2'd3: rd_data = branch_target;    // auipc
    endcase
end     


always@* begin
    if(d_we) begin
        case(funct3)
            3'h0:   case(last_2bit)
                        2'b00: dcache_we = 4'b0001;
                        2'b01: dcache_we = 4'b0010;
                        2'b10: dcache_we = 4'b0100;
                        2'b11: dcache_we = 4'b1000;
                    endcase
            3'h1:   if(last_2bit == 2'b00) dcache_we = 4'b0011;
                    else if(last_2bit == 2'b10) dcache_we = 4'b1100;
                    else dcache_we = 4'b0000;
            3'h2:   dcache_we = 4'b1111;
            default: dcache_we = 4'b0000;
        endcase
    end else
        dcache_we = 4'b0000;
end
always@* begin
    if(d_we) begin
        case(funct3)
            3'h0:   case(last_2bit)
                        2'b00: dcache_din = {24'd0, rs2_data_M[7:0]};
                        2'b01: dcache_din = {16'd0, rs2_data_M[7:0],  8'd0};
                        2'b10: dcache_din = { 8'd0, rs2_data_M[7:0], 16'd0};
                        2'b11: dcache_din = {rs2_data_M[7:0], 24'd0};
                    endcase
            3'h1:   if(last_2bit == 2'b00) dcache_din = {16'd0, rs2_data_M[15:0]};
                    else if(last_2bit == 2'b10) dcache_din = {rs2_data_M[15:0], 16'd0};
                    else dcache_din = 24'd0;
            3'h2:   dcache_din = rs2_data_M;
            default: dcache_din = 24'd0;
        endcase
    end else
        dcache_din = 24'd0;
end

endmodule