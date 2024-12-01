module Control(
    input clk,
    input reset,
    input [31:0] instr,

    output reg rd_write,
    output reg br_type,
    output reg [1:0] taken,
    output reg B_sel,
    output reg d_we,
    output reg dcache_re,
    output icache_re,
    output reg [1:0] wb_sel,
    output reg csr_load
);

wire [6:0] opcode = instr[6:0];
wire [2:0] funct3 = instr[14:12];

assign icache_re = 1;

always @* begin
    case(opcode)
    `OPC_CSR: begin     // csr
        rd_write = 0;
        br_type = 0;
        taken = 0;
        B_sel = 1;
        dcache_re = 0;
        wb_sel = 0;
        d_we = 1;
        csr_load = 1;
    end
    `OPC_LUI: begin     // lui
        rd_write = 1;
        br_type = 0;
        taken = 0;
        B_sel = 1;
        dcache_re = 0;
        wb_sel = 0;
        d_we = 0;
        csr_load = 0;
    end
    `OPC_AUIPC: begin // auipc
        rd_write = 1;
        br_type = 0;
        taken = 0;
        B_sel = 1;
        dcache_re = 0;
        wb_sel = 3;
        d_we = 0;
        csr_load = 0;
    end
    `OPC_BRANCH: begin // B type
        rd_write = 0;
        taken = 1;
        B_sel = 0;
        dcache_re = 0;
        wb_sel = 0;
        case(funct3)
            `FNC_BEQ:  br_type = 0;
            `FNC_BNE:  br_type = 1;
            `FNC_BLT:  br_type = 1;
            `FNC_BGE:  br_type = 0;
            `FNC_BLTU: br_type = 1;
            `FNC_BGEU: br_type = 0;
            default:   br_type = 0;
        endcase
        d_we = 0;
        csr_load = 0;
    end
    `OPC_LOAD: begin  // I type - load
        rd_write = 1;
        br_type = 0;
        taken = 0;
        B_sel = 1;
        dcache_re = 1;
        wb_sel = 1;
        d_we = 0;
        csr_load = 0;
    end
    `OPC_STORE: begin // S type - store
        rd_write = 0;
        br_type = 0;
        taken = 0;
        B_sel = 1;
        dcache_re = 1;
        wb_sel = 0;
        d_we = 1;
        csr_load = 0;
    end
    `OPC_JAL: begin // Jal
        rd_write = 1;
        br_type = 0;
        taken = 2;
        B_sel = 1;
        dcache_re = 0;
        wb_sel = 2;
        d_we = 0;
        csr_load = 0;
    end
    `OPC_JALR: begin // Jalr
        rd_write = 1;
        br_type = 0;
        taken = 3;
        B_sel = 1;
        dcache_re = 0;
        wb_sel = 2;
        d_we = 0;
        csr_load = 0;
    end
    `OPC_ARI_ITYPE: begin  // Arithmetic I-type
        rd_write = 1;
        br_type = 0;
        taken = 0;
        B_sel = 1;
        dcache_re = 0;
        wb_sel = 0;
        d_we = 0;
        csr_load = 0;
    end
    `OPC_ARI_RTYPE: begin  // Arithmetic R-type
        rd_write = 1;
        br_type = 0;
        taken = 0;
        B_sel = 0;
        dcache_re = 0;
        wb_sel = 0;
        d_we = 0; 
        csr_load = 0;                            
    end
    default: begin
        rd_write = 0;
        br_type = 0;
        taken = 0;
        B_sel = 0;
        dcache_re = 0;
        wb_sel = 0;
        d_we = 0; 
        csr_load = 0;
    end
    endcase
end

endmodule