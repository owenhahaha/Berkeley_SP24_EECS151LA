// Module: ALUdecoder
// Desc:   Sets the ALU operation
// Inputs: opcode: the top 6 bits of the instruction
//         funct: the funct, in the case of r-type instructions
//         add_rshift_type: selects whether an ADD vs SUB, or an SRA vs SRL
// Outputs: ALUop: Selects the ALU's operation
//

`include "Opcode.vh"
`include "ALUop.vh"

module ALUdec(
  input [6:0]       opcode,
  input [2:0]       funct,
  input             add_rshift_type,
  output reg [3:0]  ALUop
);

always @* begin
  if(opcode == `OPC_CSR)         // csr
    case(funct)
      `FNC_CSRRW: ALUop = `ALU_COPY_A;
      `FNC_CSRRWI: ALUop = `ALU_COPY_B;
      default: ALUop = `ALU_XXX;
    endcase
  else if(opcode == `OPC_LUI)    // lui
    ALUop = `ALU_COPY_B;
  else if(opcode == `OPC_AUIPC)  // auipc
    ALUop = `ALU_ADD;
  else if(opcode == `OPC_BRANCH) // B type
    case(funct)
      `FNC_BEQ:  ALUop = `ALU_SUB;
      `FNC_BNE:  ALUop = `ALU_SUB;
      `FNC_BLT:  ALUop = `ALU_SLT;
      `FNC_BGE:  ALUop = `ALU_SLT;
      `FNC_BLTU: ALUop = `ALU_SLTU;
      `FNC_BGEU: ALUop = `ALU_SLTU;
      default:   ALUop = `ALU_SUB;
    endcase
  else if(opcode == `OPC_LOAD)   // I type - load
    ALUop = `ALU_ADD;
  else if(opcode == `OPC_STORE)  // S type - store
    ALUop = `ALU_ADD;
  else if(opcode == `OPC_JAL || opcode == `OPC_JALR)  // J type
    ALUop = `ALU_ADD;
  else if(opcode == `OPC_ARI_ITYPE)   // Arithmetic I-type
    case(funct)
      `FNC_ADD_SUB: ALUop = `ALU_ADD;
      `FNC_SLL:     ALUop = `ALU_SLL;
      `FNC_SLT:     ALUop = `ALU_SLT;
      `FNC_SLTU:    ALUop = `ALU_SLTU;
      `FNC_XOR:     ALUop = `ALU_XOR;
      `FNC_OR:      ALUop = `ALU_OR;
      `FNC_AND:     ALUop = `ALU_AND;
      `FNC_SRL_SRA: ALUop = (add_rshift_type)? `ALU_SRL: `ALU_SRA;
      default:      ALUop = `ALU_ADD;
    endcase
  else                                // Arithmetic R-type
    case(funct)
      `FNC_ADD_SUB: ALUop = (add_rshift_type)? `ALU_ADD: `ALU_SUB;
      `FNC_SLL:     ALUop = `ALU_SLL;
      `FNC_SLT:     ALUop = `ALU_SLT;
      `FNC_SLTU:    ALUop = `ALU_SLTU;
      `FNC_XOR:     ALUop = `ALU_XOR;
      `FNC_OR:      ALUop = `ALU_OR;
      `FNC_AND:     ALUop = `ALU_AND;
      `FNC_SRL_SRA: ALUop = (add_rshift_type)? `ALU_SRL: `ALU_SRA;
      default:      ALUop = `ALU_ADD;
    endcase
end


  // Implement your ALU decoder here, then delete this comment

endmodule
