`include "EECS151.v"

module regfile(
	input clk,
	input reset,
	input [4:0] raddr1,
	input [4:0] raddr2,
	input wen,
	input [4:0]  waddr,
	input [31:0] wdata,
	input csr_load,

	output [31:0] rdata1,
	output [31:0] rdata2,
	output [31:0] csr
);

wire [31:0] gpr   [0:31];
reg  [31:0] gpr_n [0:31];

reg  [31:0] csr_n;

integer i;

assign rdata1 = gpr[raddr1];
assign rdata2 = gpr[raddr2];

// assign sw_data = gpr[raddr2];

REGISTER_R #(.N(32)) CSR0(.q(csr), .d(csr_n), .rst(reset), .clk(clk));

REGISTER_R #(.N(32)) REG0(.q(gpr[0]), .d(gpr_n[0]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG1(.q(gpr[1]), .d(gpr_n[1]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG2(.q(gpr[2]), .d(gpr_n[2]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG3(.q(gpr[3]), .d(gpr_n[3]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG4(.q(gpr[4]), .d(gpr_n[4]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG5(.q(gpr[5]), .d(gpr_n[5]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG6(.q(gpr[6]), .d(gpr_n[6]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG7(.q(gpr[7]), .d(gpr_n[7]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG8(.q(gpr[8]), .d(gpr_n[8]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG9(.q(gpr[9]), .d(gpr_n[9]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG10(.q(gpr[10]), .d(gpr_n[10]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG11(.q(gpr[11]), .d(gpr_n[11]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG12(.q(gpr[12]), .d(gpr_n[12]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG13(.q(gpr[13]), .d(gpr_n[13]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG14(.q(gpr[14]), .d(gpr_n[14]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG15(.q(gpr[15]), .d(gpr_n[15]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG16(.q(gpr[16]), .d(gpr_n[16]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG17(.q(gpr[17]), .d(gpr_n[17]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG18(.q(gpr[18]), .d(gpr_n[18]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG19(.q(gpr[19]), .d(gpr_n[19]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG20(.q(gpr[20]), .d(gpr_n[20]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG21(.q(gpr[21]), .d(gpr_n[21]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG22(.q(gpr[22]), .d(gpr_n[22]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG23(.q(gpr[23]), .d(gpr_n[23]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG24(.q(gpr[24]), .d(gpr_n[24]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG25(.q(gpr[25]), .d(gpr_n[25]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG26(.q(gpr[26]), .d(gpr_n[26]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG27(.q(gpr[27]), .d(gpr_n[27]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG28(.q(gpr[28]), .d(gpr_n[28]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG29(.q(gpr[29]), .d(gpr_n[29]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG30(.q(gpr[30]), .d(gpr_n[30]), .rst(reset), .clk(clk));
REGISTER_R #(.N(32)) REG31(.q(gpr[31]), .d(gpr_n[31]), .rst(reset), .clk(clk));

always @(*) begin
	// x0
	gpr_n[0] = 32'd0;
	// x1~x31
	for(i = 1; i < 32; i = i + 1) begin
		gpr_n[i] = (wen && (i == waddr)) ? wdata : gpr[i];
	end
	// csr
	if(csr_load) csr_n = wdata;
	else csr_n = csr;
end

endmodule