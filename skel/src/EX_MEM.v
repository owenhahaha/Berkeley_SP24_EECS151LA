module EX_MEM(
    input clk,
    input rst,
    input stall,

    input [31:0] branch_target_X,
    input [31:0] ALU_X,
    input [31:0] rs2_data_X,
    input [4:0] rd_addr_X,
    input [31:0] imm_X,
    input [31:0] PC_4_X,
    input [2:0] funct3_X,
    // input [1:0] last_2bit_X,
    input rd_write_X,
    input d_we_X,
    input [1:0] wb_sel_X,
    input csr_load_X,
    input [31:0] instr_X,
    input d_re_X,

    output [31:0] branch_target_M,
    output [31:0] ALU_M,
    output [31:0] rs2_data_M,
    output [4:0] rd_addr_M,
    output [31:0] imm_M,
    output [31:0] PC_4_M,
    output [2:0] funct3_M,
    output [1:0] last_2bit_M,
    output rd_write_M,
    output d_we_M,
    output [1:0] wb_sel_M,
    output csr_load_M,
    output [31:0] instr_M,
    output d_re_M
);

// always@(posedge clk) begin
//     if(rst) begin
//         branch_target_M <= 0;
//         ALU_M <= 0;
//         rs2_data_M <= 0;
//         rd_addr_M <= 0;
//         imm_M <= 0;
//         PC_4_M <= 0;
//         funct3_M <= 0;
//         last_2bit_M <= 0;
//         rd_write_M <= 0;
//         d_we_M <= 0;
//         wb_sel_M <= 0;
//         csr_load_M <= 0;
//         instr_M <= 32'h0000_0013;
//         d_re_M <= 0;
//     end else begin
//         if(~stall) begin
//             branch_target_M <= branch_target_X;
//             ALU_M <= ALU_X;
//             rs2_data_M <= rs2_data_X;
//             rd_addr_M <= rd_addr_X;
//             imm_M <= imm_X;
//             PC_4_M <= PC_4_X;
//             funct3_M <= funct3_X;
//             last_2bit_M <= ALU_X[1:0];
//             rd_write_M <= rd_write_X;
//             d_we_M <= d_we_X;
//             wb_sel_M <= wb_sel_X;
//             csr_load_M <= csr_load_X;
//             instr_M <= instr_X;
//             d_re_M <= d_re_X;
//         end
//     end
// end


assign branch_target_M = branch_target_X;
assign ALU_M = ALU_X;
assign rs2_data_M = rs2_data_X;
assign rd_addr_M = rd_addr_X;
assign imm_M = imm_X;
assign PC_4_M = PC_4_X;
assign funct3_M = funct3_X;
assign last_2bit_M = ALU_X[1:0];
assign rd_write_M = rd_write_X;
assign d_we_M = d_we_X;
assign wb_sel_M = wb_sel_X;
assign csr_load_M = csr_load_X;
assign instr_M = instr_X;
assign d_re_M = d_re_X;

endmodule