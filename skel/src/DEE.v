module DEE(
    input clk,
    input reset,
    input [31:0] instr,
    input [4:0] waddr,
    input [31:0] wdata,
	input wen,
	input csr_load,

    input [1:0] rs1_sel,
    input [1:0] rs2_sel,
    input B_sel,

    input [31:0] rd_X,
    input [31:0] rd_W,

	output [3:0] ALUop,
	output [4:0] rd_addr,
	output [31:0] imm,
	output [31:0] csr,

    output reg [31:0] rs2_data_sel,
    output reg [31:0] A_out,
    output [31:0] B_out
);

wire [31:0] rs1_data;
wire [31:0] rs2_data;

wire [4:0] rs1_addr;
wire [4:0] rs2_addr;

wire [2:0] funct3;
wire [6:0] opcode;
wire add_rshift_type;

assign rd_addr = instr[11:7];
assign rs1_addr = instr[19:15];
assign rs2_addr = instr[24:20];

assign funct3 = instr[14:12];
assign opcode = instr[6:0];
assign add_rshift_type = ~instr[30];

regfile R0(
    .clk(clk),
	.reset(reset),
	.raddr1(rs1_addr),
	.raddr2(rs2_addr),
	.wen(wen),
	.waddr(waddr),
	.wdata(wdata),
	.csr_load(csr_load),

	.rdata1(rs1_data),
	.rdata2(rs2_data),
	.csr(csr)
);

ALUdec A0(
  .opcode(opcode),
  .funct(funct3),
  .add_rshift_type(add_rshift_type),
  .ALUop(ALUop)
);

ImmGen I0(
	.instr(instr),
	.imm(imm)
);

assign B_out = (B_sel)? imm : rs2_data_sel;

always@(*) begin
    case(rs1_sel) 
        0: A_out = rs1_data;
        1: A_out = rd_X;
        2: A_out = rd_W;
        3: A_out = rs1_data;
    endcase
    case(rs2_sel) 
        0: rs2_data_sel = rs2_data;
        1: rs2_data_sel = rd_X;
        2: rs2_data_sel = rd_W;
        3: rs2_data_sel = rs2_data;
    endcase
end



endmodule