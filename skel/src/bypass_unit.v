module bypass_unit (
    input [31:0] instr_X,
    input [31:0] instr_M,
    input [31:0] instr_W,

    output reg [1:0] rs1_sel,
    output reg [1:0] rs2_sel
);

reg rd_present_M;
reg rd_present_W;

reg rs1_present_X;
reg rs2_present_X;

wire [4:0] rs1_X = rs1_present_X? instr_X[19:15]: 5'd0;
wire [4:0] rs2_X = rs2_present_X? instr_X[24:20]: 5'd0;
wire [6:0] opcode_X = instr_X[6:0];
wire [2:0] funct3_X = instr_X[14:12];

wire [4:0] rd_M = rd_present_M? instr_M[11:7]: 5'd0;
wire [6:0] opcode_M = instr_M[6:0];

wire [4:0] rd_W = rd_present_W? instr_W[11:7]: 5'd0;
wire [6:0] opcode_W = instr_W[6:0];

always @(*) begin
    if(rs1_X == 0) rs1_sel = 0;
    else if(rs1_X == rd_M) rs1_sel = 1;
    else if(rs1_X == rd_W) rs1_sel = 2;
    else rs1_sel = 0;

    if(rs2_X == 0) rs2_sel = 0;
    else if(rs2_X == rd_M) rs2_sel = 1;
    else if(rs2_X == rd_W) rs2_sel = 2;
    else rs2_sel = 0;
end

always @(*) begin
    case(opcode_M) 
    `OPC_CSR: rd_present_M = 0;
    `OPC_LUI: rd_present_M = 1;
    `OPC_AUIPC: rd_present_M = 1;
    `OPC_BRANCH: rd_present_M = 0;
    `OPC_LOAD: rd_present_M = 1;
    `OPC_STORE: rd_present_M = 0;
    `OPC_JAL: rd_present_M = 1;
    `OPC_JALR: rd_present_M = 1;
    `OPC_ARI_ITYPE: rd_present_M = 1;
    `OPC_ARI_RTYPE: rd_present_M = 1;
    default: rd_present_M = 0;
    endcase

    case(opcode_W) 
    `OPC_CSR: rd_present_W = 0;
    `OPC_LUI: rd_present_W = 1;
    `OPC_AUIPC: rd_present_W = 1;
    `OPC_BRANCH: rd_present_W = 0;
    `OPC_LOAD: rd_present_W = 1;
    `OPC_STORE: rd_present_W = 0;
    `OPC_JAL: rd_present_W = 1;
    `OPC_JALR: rd_present_W = 1;
    `OPC_ARI_ITYPE: rd_present_W = 1;
    `OPC_ARI_RTYPE: rd_present_W = 1;
    default: rd_present_W = 0;
    endcase

    case(opcode_X) 
    `OPC_CSR: rs1_present_X = (funct3_X == `FNC_CSRRW)? 1: 0;
    `OPC_LUI: rs1_present_X = 0;
    `OPC_AUIPC: rs1_present_X = 0;
    `OPC_BRANCH: rs1_present_X = 1;
    `OPC_LOAD: rs1_present_X = 1;
    `OPC_STORE: rs1_present_X = 1;
    `OPC_JAL: rs1_present_X = 0;
    `OPC_JALR: rs1_present_X = 1;
    `OPC_ARI_ITYPE: rs1_present_X = 1;
    `OPC_ARI_RTYPE: rs1_present_X = 1;
    default: rs1_present_X = 0;
    endcase

    case(opcode_X) 
    `OPC_CSR: rs2_present_X = 0;
    `OPC_LUI: rs2_present_X = 0;
    `OPC_AUIPC: rs2_present_X = 0;
    `OPC_BRANCH: rs2_present_X = 1;
    `OPC_LOAD: rs2_present_X = 0;
    `OPC_STORE: rs2_present_X = 1;
    `OPC_JAL: rs2_present_X = 0;
    `OPC_JALR: rs2_present_X = 0;
    `OPC_ARI_ITYPE: rs2_present_X = 0;
    `OPC_ARI_RTYPE: rs2_present_X = 1;
    default: rs2_present_X = 0;
    endcase
end



endmodule