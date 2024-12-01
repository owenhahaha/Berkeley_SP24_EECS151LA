module ImmGen(
    input [31:0] instr,
    output reg [31:0] imm
);

wire [2:0] funct3;
wire [6:0] opcode;

assign funct3 = instr[14:12];
assign opcode = instr[6:0];

always@ * begin
    case(opcode) 
        `OPC_ARI_ITYPE: begin // I-type
            case(funct3)
                3'b001: imm = {27'd0, instr[24:20]};
                3'b101: imm = {27'd0, instr[24:20]};
                default: imm = {{20{instr[31]}}, instr[31:20]};
            endcase
        end
        `OPC_LOAD, `OPC_JALR: begin // I-type load & JALR
            imm[11:0] = instr[31:20];
            imm[31:12] = {20{instr[31]}};
        end
        `OPC_STORE: begin // S-type
            imm[11:0] = {instr[31:25], instr[11:7]};
            imm[31:12] = {20{instr[31]}};
        end
        `OPC_BRANCH: begin // B-type
            imm[12:0] = {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            imm[31:13] = {19{instr[31]}};
        end
        `OPC_JAL: begin // J-type JAL
            imm[20:0] = {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            imm[31:21] = {11{instr[31]}};
        end
        `OPC_AUIPC, `OPC_LUI: begin // U-type
            imm[11:0] = {11{1'b0}};
            imm[31:12] = instr[31:12];
        end
        `OPC_ARI_RTYPE: begin // R-type
            imm = 32'b0;
        end
        `OPC_CSR: begin
            imm = instr[19:15];
        end
        default: begin
            imm = 32'b0;
        end
    endcase
end

endmodule