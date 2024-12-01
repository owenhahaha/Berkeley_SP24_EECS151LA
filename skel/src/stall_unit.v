module stall_unit(
    input [31:0] instr_D,
    input [31:0] instr_X,

    output reg   interlock
);

reg rs1_present_D;
reg rs2_present_D;

wire [4:0] rs1_D = rs1_present_D? instr_D[19:15]: 5'd0;
wire [4:0] rs2_D = rs2_present_D? instr_D[24:20]: 5'd0;
wire [6:0] opcode_D = instr_D[6:0];
wire [2:0] funct3_D = instr_D[14:12];

wire [6:0] opcode_X = instr_X[6:0];
wire [4:0] rd_X = (opcode_X == `OPC_LOAD)? instr_X[11:7]: 5'd0;

always @(*) begin
    if(opcode_X == `OPC_LOAD) begin
        if(rs1_D == 0 & rs2_D == 0) interlock = 0;
        else if (rs1_D == 0 & rs2_D == rd_X) interlock = 1;
        else if (rs2_D == 0 & rs1_D == rd_X) interlock = 1;
        else if (rs2_D == rd_X | rs1_D == rd_X) interlock = 1;
        else interlock = 0;
    end else begin
        interlock = 0;
    end
end

always@* begin
    case(opcode_D) 
    `OPC_CSR: rs1_present_D = (funct3_D == `FNC_CSRRW)? 1: 0;
    `OPC_LUI: rs1_present_D = 0;
    `OPC_AUIPC: rs1_present_D = 0;
    `OPC_BRANCH: rs1_present_D = 1;
    `OPC_LOAD: rs1_present_D = 1;
    `OPC_STORE: rs1_present_D = 1;
    `OPC_JAL: rs1_present_D = 0;
    `OPC_JALR: rs1_present_D = 1;
    `OPC_ARI_ITYPE: rs1_present_D = 1;
    `OPC_ARI_RTYPE: rs1_present_D = 1;
    default: rs1_present_D = 0;
    endcase

    case(opcode_D) 
    `OPC_CSR: rs2_present_D = 0;
    `OPC_LUI: rs2_present_D = 0;
    `OPC_AUIPC: rs2_present_D = 0;
    `OPC_BRANCH: rs2_present_D = 1;
    `OPC_LOAD: rs2_present_D = 0;
    `OPC_STORE: rs2_present_D = 1;
    `OPC_JAL: rs2_present_D = 0;
    `OPC_JALR: rs2_present_D = 0;
    `OPC_ARI_ITYPE: rs2_present_D = 0;
    `OPC_ARI_RTYPE: rs2_present_D = 1;
    default: rs2_present_D = 0;
    endcase
end
endmodule
