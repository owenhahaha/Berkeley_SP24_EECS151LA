module DE_EX(
    input clk,
    input rst,
    input interlock,
    input taken,
    input stall,

    input [3:0] ALUop_D,
    input [31:0] rs1_data_D,
    input [31:0] rs2_data_D,
    input [4:0] rd_addr_D,
    input [31:0] imm_D,
    input [31:0] PC_4_D,
    input rd_write_D,
    input br_type_D,
    input [1:0] taken_D,
    input B_sel_D,
    input d_we_D,
    input [1:0] wb_sel_D,
    input csr_load_D,
    input [31:0] instr_D,
    input d_re_D,

    output reg [3:0] ALUop_X,
    output reg [31:0] rs1_data_X,
    output reg [31:0] rs2_data_X,
    output reg [4:0] rd_addr_X,
    output reg [31:0] imm_X,
    output reg [31:0] PC_4_X,
    output reg [2:0] funct3_X,
    output reg rd_write_X,
    output reg br_type_X,
    output reg [1:0] taken_X,
    output reg B_sel_X,
    output reg d_we_X,
    output reg [1:0] wb_sel_X,
    output reg csr_load_X,
    output reg [31:0] instr_X,
    output reg d_re_X
);

reg [3:0] ALUop_X_n;
reg [31:0] rs1_data_X_n;
reg [31:0] rs2_data_X_n;
reg [4:0] rd_addr_X_n;
reg [31:0] imm_X_n;
reg [31:0] PC_4_X_n;
reg [2:0] funct3_X_n;
reg rd_write_X_n;
reg br_type_X_n;
reg [1:0] taken_X_n;
reg B_sel_X_n;
reg d_we_X_n;
reg [1:0] wb_sel_X_n;
reg csr_load_X_n;
reg [31:0] instr_X_n;
reg d_re_X_n;

REGISTER_R #(.N(4)) R0(.q(ALUop_X), .d(ALUop_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(32)) R1(.q(rs1_data_X), .d(rs1_data_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(32)) R2(.q(rs2_data_X), .d(rs2_data_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(5)) R3(.q(rd_addr_X), .d(rd_addr_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(32)) R4(.q(imm_X), .d(imm_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(32)) R5(.q(PC_4_X), .d(PC_4_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(3)) R6(.q(funct3_X), .d(funct3_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(1)) R7(.q(rd_write_X), .d(rd_write_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(1)) R8(.q(br_type_X), .d(br_type_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(2)) R9(.q(taken_X), .d(taken_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(1)) R10(.q(B_sel_X), .d(B_sel_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(1)) R11(.q(d_we_X), .d(d_we_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(2)) R12(.q(wb_sel_X), .d(wb_sel_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(1)) R13(.q(csr_load_X), .d(csr_load_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(32), .INIT(32'h0000_0013)) R14(.q(instr_X), .d(instr_X_n), .rst(rst), .clk(clk));
REGISTER_R #(.N(1)) R15(.q(d_re_X), .d(d_re_X_n), .rst(rst), .clk(clk));

always@* begin
    if((interlock|taken)&(~stall)) begin
        funct3_X_n = 0;
        ALUop_X_n = 0;
        rs1_data_X_n = 0;
        rs2_data_X_n = 0;
        rd_addr_X_n = 0;
        imm_X_n = 0;
        PC_4_X_n = 0;
        rd_write_X_n = 0;
        br_type_X_n = 0;
        taken_X_n = 0;
        B_sel_X_n = 0;
        d_we_X_n = 0;
        wb_sel_X_n = 0;
        csr_load_X_n = 0;
        instr_X_n = 32'h0000_0013;
        d_re_X_n = 0;
    end 
    else begin
        if(~stall) begin
            funct3_X_n = instr_D[14:12];
            ALUop_X_n = ALUop_D;
            rs1_data_X_n = rs1_data_D;
            rs2_data_X_n = rs2_data_D;
            rd_addr_X_n = rd_addr_D;
            imm_X_n = imm_D;
            PC_4_X_n = PC_4_D;
            rd_write_X_n = rd_write_D;
            br_type_X_n = br_type_D;
            taken_X_n = taken_D;
            B_sel_X_n = B_sel_D;
            d_we_X_n = d_we_D;
            wb_sel_X_n = wb_sel_D;
            csr_load_X_n = csr_load_D;
            instr_X_n = instr_D;
            d_re_X_n = d_re_D;
        end
        else begin
            funct3_X_n = funct3_X;
            ALUop_X_n = ALUop_X;
            rs1_data_X_n = rs1_data_X;
            rs2_data_X_n = rs2_data_X;
            rd_addr_X_n = rd_addr_X;
            imm_X_n = imm_X;
            PC_4_X_n = PC_4_X;
            rd_write_X_n = rd_write_X;
            br_type_X_n = br_type_X;
            taken_X_n = taken_X;
            B_sel_X_n = B_sel_X;
            d_we_X_n = d_we_X;
            wb_sel_X_n = wb_sel_X;
            csr_load_X_n = csr_load_X;
            instr_X_n = instr_X;
            d_re_X_n = d_re_X;
        end
    end
end



// assign funct3_X = instr_D[14:12];

// assign ALUop_X = ALUop_D;
// assign rs1_data_X = rs1_data_D;
// assign rs2_data_X = rs2_data_D;
// assign rd_addr_X = rd_addr_D;
// assign imm_X = imm_D;
// assign PC_4_X = PC_4_D;
// assign rd_write_X = rd_write_D;
// assign br_type_X = br_type_D;
// assign taken_X = taken_D;
// assign B_sel_X = B_sel_D;
// assign d_we_X = d_we_D;
// assign wb_sel_X = wb_sel_D;
// assign csr_load_X = csr_load_D;

// assign instr_X = instr_D;



endmodule