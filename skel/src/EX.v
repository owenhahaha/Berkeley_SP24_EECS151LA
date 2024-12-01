module EX(
    input [1:0] rs1_sel,
    input [1:0] rs2_sel,

    input [31:0] rd_M,
    input [31:0] rd_W,

    input [31:0] rs1,
    input [31:0] rs2,
    input [31:0] imm,
    input [31:0] PC_4,
    input [3:0] ALUop,
    input B_sel,

    output reg [31:0] rs2_data_sel_X,
    output [31:0] branch_target,
    output [31:0] ALU_out,
    output zero
);

reg [31:0] A;

wire [31:0] B = (B_sel)? imm : rs2_data_sel_X;
assign branch_target = PC_4 - 4 + $signed(imm);
assign zero = (ALU_out == 0);

always@(*) begin
    case(rs1_sel) 
        0: A = rs1;
        1: A = rd_M;
        2: A = rd_W;
        3: A = rs1;
    endcase
    case(rs2_sel) 
        0: rs2_data_sel_X = rs2;
        1: rs2_data_sel_X = rd_M;
        2: rs2_data_sel_X = rd_W;
        3: rs2_data_sel_X = rs2;
    endcase
end

ALU ALU0( 
    .A(A),
    .B(B),
    .ALUop(ALUop),
    .Out(ALU_out)
);

endmodule