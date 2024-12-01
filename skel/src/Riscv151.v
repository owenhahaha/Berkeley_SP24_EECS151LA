`include "const.vh"

module Riscv151(
    input clk,
    input reset,

    // Memory system ports
    output [31:0] dcache_addr,
    output [31:0] icache_addr,
    output [3:0] dcache_we,
    output dcache_re,
    output icache_re,
    output [31:0] dcache_din,
    input [31:0] dcache_dout,
    input [31:0] icache_dout,
    input stall,
    output [31:0] csr

);

wire interlock;
wire [1:0] rs1_sel;
wire [1:0] rs2_sel;
wire [31:0] rd_data_M;


wire [31:0] PC_4_F;
wire br_type_X;
wire [1:0] taken_X;
wire zero;
wire [31:0] branch_target_X;
wire PC_sel_F;
wire [31:0] ALU_X;

IF IF(
  .clk(clk),
  .reset(reset),
  .icache_re(icache_re),
  .branch_target(branch_target_X),
  .jalr_target(ALU_X),
  .interlock(interlock),
  .stall(stall),

  .zero(zero),
  .taken(taken_X),
  .br_type(br_type_X),
  .PC_sel(PC_sel_F),

  .PC_4(PC_4_F),
  .icache_addr(icache_addr)
);


// IF->DE reg
wire [31:0] PC_4_D;
wire PC_sel_D;
wire [31:0] instr_D;

IF_DE IFDE(
  .clk(clk),
  .reset(reset),
  .stall(stall|PC_sel_F|interlock),
  .icache_re(icache_re),
  .icache_dout(icache_dout),
  .PC_4_F(PC_4_F),
  .PC_sel_F(PC_sel_F),
  .interlock(interlock),
  .instr_D(instr_D),
  .PC_4_D(PC_4_D),
  .PC_sel_D(PC_sel_D)
);

wire [4:0] rd_addr_W;
wire [31:0] rd_data_W;
wire [31:0] rd_data_X;
wire rd_write_W;
wire csr_load_W;

wire [3:0] ALUop_D;
wire [31:0] rs1_data_D;
wire [31:0] rs2_data_D;
wire [4:0] rd_addr_D;
wire [31:0] imm_D;
// wire [31:0] instr_D = PC_sel_D? 32'h0000_0000 : icache_dout;
wire [4:0] rs1_addr_D = instr_D[19:15];
wire [4:0] rs2_addr_D = instr_D[24:20];

wire [31:0] A_out_D;
wire [31:0] B_out_D;

// DE DE(
//   .clk(clk),
//   .reset(reset),
//   .instr(instr_D),
//   .waddr(rd_addr_W),
//   .wdata(rd_data_W),
// 	.wen(rd_write_W),
//   .csr_load(csr_load_W),

// 	.ALUop(ALUop_D),
// 	.rs1_data(rs1_data_D),
// 	.rs2_data(rs2_data_D),
// 	.rd_addr(rd_addr_D),
// 	.imm(imm_D),
//  .csr(csr)
// );

wire B_sel_D;

DEE DEE(
  .clk(clk),
  .reset(reset),
  .instr(instr_D),
  .waddr(rd_addr_W),
  .wdata(rd_data_W),
	.wen(rd_write_W),
  .csr_load(csr_load_W),

  .rs1_sel(rs1_sel),
  .rs2_sel(rs2_sel),
  .B_sel(B_sel_D),
  
  .rd_X(rd_data_X),
  .rd_W(rd_data_W),

	.ALUop(ALUop_D),
	.rs2_data_sel(rs2_data_D),
	.rd_addr(rd_addr_D),
	.imm(imm_D),
  .csr(csr),

  .A_out(A_out_D),
  .B_out(B_out_D)
);

wire d_re_M;
wire rd_write_D;
wire br_type_D;
wire [1:0] taken_D;
wire d_we_D;
wire [1:0] wb_sel_D;
wire csr_load_D;
wire dcache_re_D;
assign dcache_re = d_re_M;

Control Control(
    .clk(clk),
    .reset(reset),
    .instr(instr_D),

    .rd_write(rd_write_D),
    .br_type(br_type_D),
    .taken(taken_D),
    .B_sel(B_sel_D),
    .d_we(d_we_D),
    .dcache_re(dcache_re_D),
    .icache_re(icache_re),
    .wb_sel(wb_sel_D),
    .csr_load(csr_load_D)
);

wire [3:0] ALUop_X;
wire [31:0] rs1_data_X;
wire [31:0] rs2_data_X;
wire [31:0] rs2_data_sel_X;
wire [4:0] rd_addr_X;
wire [31:0] imm_X;
wire [31:0] PC_4_X;
wire [2:0] funct3_X;
wire rd_write_X;
wire B_sel_X;
wire d_we_X;
wire [1:0] wb_sel_X;
wire csr_load_X;
wire [31:0] instr_X;
wire d_re_X;

wire [31:0] A_out_X;
wire [31:0] B_out_X;


// DE_EX DEEX(
//   .clk(clk),
//   .rst(reset),
//   .interlock(interlock),
//   .taken(PC_sel_F|PC_sel_D),
//   .stall(stall),

//   .ALUop_D(ALUop_D),
//   .rs1_data_D(rs1_data_D),
//   .rs2_data_D(rs2_data_D),
//   .rd_addr_D(rd_addr_D),
//   .imm_D(imm_D),
//   .PC_4_D(PC_4_D),
//   .rd_write_D(rd_write_D),
//   .br_type_D(br_type_D),
//   .taken_D(taken_D),
//   .B_sel_D(B_sel_D),
//   .d_we_D(d_we_D),
//   .wb_sel_D(wb_sel_D),
//   .csr_load_D(csr_load_D),
//   .instr_D(instr_D),
//   .d_re_D(dcache_re_D),

//   .ALUop_X(ALUop_X),
//   .rs1_data_X(rs1_data_X),
//   .rs2_data_X(rs2_data_X),
//   .rd_addr_X(rd_addr_X),
//   .imm_X(imm_X),
//   .PC_4_X(PC_4_X),
//   .funct3_X(funct3_X),
//   .rd_write_X(rd_write_X),
//   .br_type_X(br_type_X),
//   .taken_X(taken_X),
//   .B_sel_X(B_sel_X),
//   .d_we_X(d_we_X),
//   .wb_sel_X(wb_sel_X),
//   .csr_load_X(csr_load_X),
//   .instr_X(instr_X),
//   .d_re_X(d_re_X)
// );

DEE_XM DEEXM(
  .clk(clk),
  .rst(reset),
  .interlock(interlock),
  .taken(PC_sel_F|PC_sel_D),
  .stall(stall),

  .ALUop_D(ALUop_D),
  .rs1_data_D(rs1_data_D),
  .rs2_data_D(rs2_data_D),
  .rd_addr_D(rd_addr_D),
  .imm_D(imm_D),
  .PC_4_D(PC_4_D),
  .rd_write_D(rd_write_D),
  .br_type_D(br_type_D),
  .taken_D(taken_D),
  .B_sel_D(B_sel_D),
  .d_we_D(d_we_D),
  .wb_sel_D(wb_sel_D),
  .csr_load_D(csr_load_D),
  .instr_D(instr_D),
  .d_re_D(dcache_re_D),

  .A_out_D(A_out_D),
  .B_out_D(B_out_D),

  .ALUop_X(ALUop_X),
  .rs1_data_X(rs1_data_X),
  .rs2_data_X(rs2_data_X),
  .rd_addr_X(rd_addr_X),
  .imm_X(imm_X),
  .PC_4_X(PC_4_X),
  .funct3_X(funct3_X),
  .rd_write_X(rd_write_X),
  .br_type_X(br_type_X),
  .taken_X(taken_X),
  .B_sel_X(B_sel_X),
  .d_we_X(d_we_X),
  .wb_sel_X(wb_sel_X),
  .csr_load_X(csr_load_X),
  .instr_X(instr_X),
  .d_re_X(d_re_X),

  .A_out_X(A_out_X),
  .B_out_X(B_out_X)
);

wire [31:0] ALU_M;

// EX EX(
//   .rs1_sel(rs1_sel),
//   .rs2_sel(rs2_sel),

//   .rd_M(rd_data_M),
//   .rd_W(rd_data_W),

//   .rs1(rs1_data_X),
//   .rs2(rs2_data_X),
//   .imm(imm_X),
//   .PC_4(PC_4_X),
//   .ALUop(ALUop_X),
//   .B_sel(B_sel_X),

//   .rs2_data_sel_X(rs2_data_sel_X),
//   .branch_target(branch_target_X),
//   .ALU_out(ALU_X),
//   .zero(zero)
// );

XM XM(
  .A(A_out_X),
  .B(B_out_X),
  .imm(imm_X),
  .PC_4(PC_4_X),
  .ALUop(ALUop_X),

  .rs2_data(rs2_data_X),
  .funct3(funct3_X),
  .d_we(d_we_X),
  .wb_sel(wb_sel_X),

  .rd_data(rd_data_X),
  
  .dcache_addr(dcache_addr),
  .dcache_din(dcache_din),
  .dcache_we(dcache_we),

  .branch_target(branch_target_X),
  .ALU_out(ALU_X),
  .zero(zero)
);

wire [31:0] branch_target_M;
wire [31:0] rs2_data_M;
wire [4:0] rd_addr_M;
wire [31:0] imm_M;
wire [31:0] PC_4_M;
wire [2:0] funct3_M;
wire [1:0] last_2bit_M;
wire rd_write_M;
wire d_we_M;
wire [1:0] wb_sel_M;
wire csr_load_M;
wire [31:0] instr_M;

EX_MEM EXMEM(
    .clk(clk),
    .rst(reset),
    .stall(stall),

    .branch_target_X(branch_target_X),
    .ALU_X(ALU_X),
    .rs2_data_X(rs2_data_sel_X),
    .rd_addr_X(rd_addr_X),
    .imm_X(imm_X),
    .PC_4_X(PC_4_X),
    .funct3_X(funct3_X),
    .rd_write_X(rd_write_X),
    .d_we_X(d_we_X),
    .wb_sel_X(wb_sel_X),
    .csr_load_X(csr_load_X),
    .instr_X(instr_X),
    .d_re_X(d_re_X),

    .branch_target_M(branch_target_M),
    .ALU_M(ALU_M),
    .rs2_data_M(rs2_data_M),
    .rd_addr_M(rd_addr_M),
    .imm_M(imm_M),
    .PC_4_M(PC_4_M),
    .funct3_M(funct3_M),
    .last_2bit_M(last_2bit_M),
    .rd_write_M(rd_write_M),
    .d_we_M(d_we_M),
    .wb_sel_M(wb_sel_M),
    .csr_load_M(csr_load_M),
    .instr_M(instr_M),
    .d_re_M(d_re_M)
);

// MEM MEM(
//     .clk(clk),
//     .ALU_M(ALU_M),
//     .rs2_data_M(rs2_data_M),
//     .funct3(funct3_M),
//     .d_we(d_we_M),

//     .wb_sel(wb_sel_M),
//     .branch_target(branch_target_M),
//     .PC_4(PC_4_M),

//     .rd_data(rd_data_M),

//     .dcache_addr(dcache_addr),
//     .dcache_din(dcache_din),
//     .dcache_we(dcache_we)
// );

// MEM->WB reg
wire [31:0] ALU_W;
wire [31:0] PC_4_W;
wire [31:0] branch_target_W;
wire [31:0] imm_W;
wire [2:0] funct3_W;
wire [1:0] last_2bit_W;
wire [1:0] wb_sel_W;
wire [31:0] instr_W;
wire [31:0] dcache_dout_W;

MEM_WB MEMWB (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .interlock(interlock),

    .ALU_W(ALU_W),
    .PC_4_W(PC_4_W),
    .branch_target_W(branch_target_W),
    .imm_W(imm_W),
    .funct3_W(funct3_W),
    .last_2bit_W(last_2bit_W),
    .wb_sel_W(wb_sel_W),
    .instr_W(instr_W),
    .rd_addr_W(rd_addr_W),
    .rd_write_W(rd_write_W),
    .csr_load_W(csr_load_W),
    .dcache_dout_W(dcache_dout_W),
    .dcache_dout(dcache_dout),
    .ALU_M(ALU_M),
    .PC_4_M(PC_4_M),
    .branch_target_M(branch_target_M),
    .imm_M(imm_M),
    .funct3_M(funct3_M),
    .last_2bit_M(last_2bit_M),
    .wb_sel_M(wb_sel_M),
    .instr_M(instr_M),
    .rd_addr_M(rd_addr_M),
    .rd_write_M(rd_write_M),
    .csr_load_M(csr_load_M)
);

WB WB(
    .clk(clk),
    .wb_sel(wb_sel_W),
    .funct3(funct3_W),
    .last_2bit(last_2bit_W),
    .branch_target(branch_target_W),
    .PC_4(PC_4_W),
    .ALUout(ALU_W),
    .dcache_dout(dcache_dout_W),

    .wdata(rd_data_W)
);

stall_unit SU(
    .instr_D(instr_D),
    .instr_X(instr_X),

    .interlock(interlock)
);

bypass_unit BU(
    // .instr_X(instr_X),
    .instr_X(instr_D),
    .instr_M(instr_M),
    .instr_W(instr_W),
    .rs1_sel(rs1_sel),
    .rs2_sel(rs2_sel)
);

endmodule
