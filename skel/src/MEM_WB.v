module MEM_WB(
    input clk,
    input reset,
    input stall,
    input interlock,
    output reg [31:0] ALU_W,
    output reg [31:0] PC_4_W,
    output reg [31:0] branch_target_W,
    output reg [31:0] imm_W,
    output reg [2:0] funct3_W,
    output reg [1:0] last_2bit_W,
    output reg [1:0] wb_sel_W,
    output reg [31:0] instr_W,
    output reg [4:0] rd_addr_W,
    output reg rd_write_W,
    output reg csr_load_W,
    output reg [31:0] dcache_dout_W,

    input [31:0] dcache_dout,
    input [31:0] ALU_M,
    input [31:0] PC_4_M,
    input [31:0] branch_target_M,
    input [31:0] imm_M,
    input [2:0] funct3_M,
    input [1:0] last_2bit_M,
    input [1:0] wb_sel_M,
    input [31:0] instr_M,
    input [4:0] rd_addr_M,
    input rd_write_M,
    input csr_load_M
);

// wire csr_load_M_ = (interlock)? 0: csr_load_M;
// wire rd_write_M_ = (interlock)? 0: rd_write_M;

// REGISTER_R  #(.N(1)) R1 (
//     .clk(clk),
//     .rst(reset | ~stall),
//     .d(rd_write_M),
//     .q(rd_write_W)
// );

wire stall_delay;
wire [31:0] dcache_dout_delay;

REGISTER_R_CE #(.N(174)) R0 (
    .clk(clk),
    .rst(reset),
    .d({ALU_M, PC_4_M, branch_target_M, imm_M, funct3_M, last_2bit_M, wb_sel_M, instr_M, rd_addr_M, csr_load_M, rd_write_M}),
    .q({ALU_W, PC_4_W, branch_target_W, imm_W, funct3_W, last_2bit_W, wb_sel_W, instr_W, rd_addr_W, csr_load_W, rd_write_W}),
    .ce(~stall)
);

REGISTER_R #(.N(1)) R1 (
    .clk(clk),
    .rst(reset),
    .d(stall),
    .q(stall_delay)
);

REGISTER_R #(.N(32)) R2 (
    .clk(clk),
    .rst(reset),
    .d(dcache_dout_W),
    .q(dcache_dout_delay)
);

always@*
    if(stall_delay)
        dcache_dout_W = dcache_dout_delay;
    else
        dcache_dout_W = dcache_dout;

// always@(posedge clk) begin
//   if(reset) begin
//     ALU_W <= 0;
//     rd_addr_W <= 0;
//     rd_write_W <= 0;
//     PC_4_W <= 0;
//     branch_target_W <= 0;
//     imm_W <= 0;
//     funct3_W <= 0;
//     last_2bit_W <= 0;
//     wb_sel_W <= 0;
//     csr_load_W <= 0;
//     instr_W <= 0;
//   end 
//   else if(stall) begin
//     ALU_W <= ALU_W;
//     rd_addr_W <= rd_addr_W;
//     PC_4_W <= PC_4_W;
//     branch_target_W <= branch_target_W;
//     imm_W <= imm_W;
//     funct3_W <= funct3_W;
//     last_2bit_W <= last_2bit_W;
//     wb_sel_W <= wb_sel_W;
    
//     csr_load_W <= csr_load_W;
//     rd_write_W <= rd_write_W;
//     instr_W <= instr_M;
//   end
//   else begin
//     ALU_W <= ALU_M;
//     rd_addr_W <= rd_addr_M;
//     PC_4_W <= PC_4_M;
//     branch_target_W <= branch_target_M;
//     imm_W <= imm_M;
//     funct3_W <= funct3_M;
//     last_2bit_W <= last_2bit_M;
//     wb_sel_W <= wb_sel_M;
    
//     csr_load_W <= (interlock)? 0: csr_load_M;
//     rd_write_W <= (interlock)? 0: rd_write_M;
//     instr_W <= instr_M;
//   end
// end

endmodule