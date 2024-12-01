`include "util.vh"
`include "const.vh"

module Icache #
(
	parameter LINES = 64,
	parameter CPU_WIDTH = `CPU_INST_BITS,
	parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8)
)
(
	input clk,
	input reset,

	input                       cpu_req_valid,   // re
	output reg                  cpu_req_ready,   // stall
	input [WORD_ADDR_BITS-1:0]  cpu_req_addr,    // cache_addr[31:2]
	input [CPU_WIDTH-1:0]       cpu_req_data,    // cache_din
	input [3:0]                 cpu_req_write,   // cache_we

	output                      cpu_resp_valid,  // undefined
	output reg [CPU_WIDTH-1:0]  cpu_resp_data,   // cache_dout

	output reg                  mem_req_valid,
	input                       mem_req_ready,
	output reg [WORD_ADDR_BITS-1-`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH):0] mem_req_addr,
	output reg                       mem_req_rw,
	output reg                       mem_req_data_valid,
	input                            mem_req_data_ready,
	output reg [`MEM_DATA_BITS-1:0]  mem_req_data_bits,
	// byte level masking
	output reg [(`MEM_DATA_BITS/8)-1:0] mem_req_data_mask,

	input                       mem_resp_valid,
	input [`MEM_DATA_BITS-1:0]  mem_resp_data
);

reg [WORD_ADDR_BITS-1:0] cpu_req_addr_d;
reg [CPU_WIDTH-1:0]      cpu_req_data_d;
reg [3:0]                cpu_req_write_d;
reg [WORD_ADDR_BITS-1:0] cpu_req_addr_delay;
reg [CPU_WIDTH-1:0]      cpu_req_data_delay;
reg [3:0]                cpu_req_write_delay;
reg                      cpu_req_valid_delay;
reg hit0, hit1;
wire miss0, miss1;
assign miss0 = ~hit0;
assign miss1 = ~hit1;
reg valid0, valid1;
reg dirty0, dirty1;
reg last_d;
reg [7:0] cache_addr;

localparam READY = 2'd0, SAVE = 2'd1, LOAD = 2'd2, WRITE = 2'd3;
reg [1:0] state;
reg [2:0] cnt;

reg we_cache0_00, we_cache0_01, we_cache0_10, we_cache0_11;
reg we_cache1_00, we_cache1_01, we_cache1_10, we_cache1_11;
// reg we_cache0_00_, we_cache0_01_, we_cache0_10_, we_cache0_11_;
// reg we_cache1_00_, we_cache1_01_, we_cache1_10_, we_cache1_11_;
reg [3:0] wmask0_00, wmask0_01, wmask0_10, wmask0_11;
reg [3:0] wmask1_00, wmask1_01, wmask1_10, wmask1_11;
// reg [3:0] wmask0_00_, wmask0_01_, wmask0_10_, wmask0_11_;
// reg [3:0] wmask1_00_, wmask1_01_, wmask1_10_, wmask1_11_;
reg [31:0] din0_00, din0_01, din0_10, din0_11;
reg [31:0] din1_00, din1_01, din1_10, din1_11;
wire [31:0] dout0_00, dout0_01, dout0_10, dout0_11;
wire [31:0] dout1_00, dout1_01, dout1_10, dout1_11;
reg we_cache0_tag, we_cache1_tag;
reg [22-1:0] din_tag;
reg set;
reg [22-1:0] dout_tag0, dout_tag1;
reg [6-1:0] tag_addr;

sram22_256x32m4w8 sram0_00 (
  .clk(clk),
  .we(we_cache0_00),
  .wmask(wmask0_00),
  .addr(cache_addr),
  .din(din0_00),
  .dout(dout0_00)
);
sram22_256x32m4w8 sram0_01 (
  .clk(clk),
  .we(we_cache0_01),
  .wmask(wmask0_01),
  .addr(cache_addr),
  .din(din0_01),
  .dout(dout0_01)
);
sram22_256x32m4w8 sram0_10 (
  .clk(clk),
  .we(we_cache0_10),
  .wmask(wmask0_10),
  .addr(cache_addr),
  .din(din0_10),
  .dout(dout0_10)
);
sram22_256x32m4w8 sram0_11 (
  .clk(clk),
  .we(we_cache0_11),
  .wmask(wmask0_11),
  .addr(cache_addr),
  .din(din0_11),
  .dout(dout0_11)
);

sram22_256x32m4w8 sram1_00 (
  .clk(clk),
  .we(we_cache1_00),
  .wmask(wmask1_00),
  .addr(cache_addr),
  .din(din1_00),
  .dout(dout1_00)
);
sram22_256x32m4w8 sram1_01 (
  .clk(clk),
  .we(we_cache1_01),
  .wmask(wmask1_01),
  .addr(cache_addr),
  .din(din1_01),
  .dout(dout1_01)
);
sram22_256x32m4w8 sram1_10 (
  .clk(clk),
  .we(we_cache1_10),
  .wmask(wmask1_10),
  .addr(cache_addr),
  .din(din1_10),
  .dout(dout1_10)
);
sram22_256x32m4w8 sram1_11 (
  .clk(clk),
  .we(we_cache1_11),
  .wmask(wmask1_11),
  .addr(cache_addr),
  .din(din1_11),
  .dout(dout1_11)
);

reg [22-1:0] tag0_n [0:63];
reg [22-1:0] tag1_n [0:63];
wire [22-1:0] tag0 [0:63];
wire [22-1:0] tag1 [0:63];
integer i;

always @(*) begin
	for(i = 0; i < 64; i = i + 1) begin
		tag0_n[i] = (we_cache0_tag && (i == tag_addr)) ? din_tag : tag0[i];
		tag1_n[i] = (we_cache1_tag && (i == tag_addr)) ? din_tag : tag1[i];
	end
end

REGISTER_R #(.N(22)) REG0_0(.q(tag0[0]), .d(tag0_n[0]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_1(.q(tag0[1]), .d(tag0_n[1]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_2(.q(tag0[2]), .d(tag0_n[2]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_3(.q(tag0[3]), .d(tag0_n[3]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_4(.q(tag0[4]), .d(tag0_n[4]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_5(.q(tag0[5]), .d(tag0_n[5]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_6(.q(tag0[6]), .d(tag0_n[6]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_7(.q(tag0[7]), .d(tag0_n[7]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_8(.q(tag0[8]), .d(tag0_n[8]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_9(.q(tag0[9]), .d(tag0_n[9]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_10(.q(tag0[10]), .d(tag0_n[10]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_11(.q(tag0[11]), .d(tag0_n[11]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_12(.q(tag0[12]), .d(tag0_n[12]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_13(.q(tag0[13]), .d(tag0_n[13]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_14(.q(tag0[14]), .d(tag0_n[14]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_15(.q(tag0[15]), .d(tag0_n[15]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_16(.q(tag0[16]), .d(tag0_n[16]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_17(.q(tag0[17]), .d(tag0_n[17]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_18(.q(tag0[18]), .d(tag0_n[18]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_19(.q(tag0[19]), .d(tag0_n[19]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_20(.q(tag0[20]), .d(tag0_n[20]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_21(.q(tag0[21]), .d(tag0_n[21]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_22(.q(tag0[22]), .d(tag0_n[22]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_23(.q(tag0[23]), .d(tag0_n[23]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_24(.q(tag0[24]), .d(tag0_n[24]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_25(.q(tag0[25]), .d(tag0_n[25]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_26(.q(tag0[26]), .d(tag0_n[26]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_27(.q(tag0[27]), .d(tag0_n[27]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_28(.q(tag0[28]), .d(tag0_n[28]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_29(.q(tag0[29]), .d(tag0_n[29]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_30(.q(tag0[30]), .d(tag0_n[30]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_31(.q(tag0[31]), .d(tag0_n[31]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_32(.q(tag0[32]), .d(tag0_n[32]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_33(.q(tag0[33]), .d(tag0_n[33]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_34(.q(tag0[34]), .d(tag0_n[34]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_35(.q(tag0[35]), .d(tag0_n[35]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_36(.q(tag0[36]), .d(tag0_n[36]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_37(.q(tag0[37]), .d(tag0_n[37]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_38(.q(tag0[38]), .d(tag0_n[38]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_39(.q(tag0[39]), .d(tag0_n[39]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_40(.q(tag0[40]), .d(tag0_n[40]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_41(.q(tag0[41]), .d(tag0_n[41]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_42(.q(tag0[42]), .d(tag0_n[42]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_43(.q(tag0[43]), .d(tag0_n[43]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_44(.q(tag0[44]), .d(tag0_n[44]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_45(.q(tag0[45]), .d(tag0_n[45]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_46(.q(tag0[46]), .d(tag0_n[46]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_47(.q(tag0[47]), .d(tag0_n[47]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_48(.q(tag0[48]), .d(tag0_n[48]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_49(.q(tag0[49]), .d(tag0_n[49]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_50(.q(tag0[50]), .d(tag0_n[50]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_51(.q(tag0[51]), .d(tag0_n[51]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_52(.q(tag0[52]), .d(tag0_n[52]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_53(.q(tag0[53]), .d(tag0_n[53]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_54(.q(tag0[54]), .d(tag0_n[54]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_55(.q(tag0[55]), .d(tag0_n[55]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_56(.q(tag0[56]), .d(tag0_n[56]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_57(.q(tag0[57]), .d(tag0_n[57]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_58(.q(tag0[58]), .d(tag0_n[58]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_59(.q(tag0[59]), .d(tag0_n[59]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_60(.q(tag0[60]), .d(tag0_n[60]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_61(.q(tag0[61]), .d(tag0_n[61]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_62(.q(tag0[62]), .d(tag0_n[62]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_63(.q(tag0[63]), .d(tag0_n[63]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_0(.q(tag1[0]), .d(tag1_n[0]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_1(.q(tag1[1]), .d(tag1_n[1]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_2(.q(tag1[2]), .d(tag1_n[2]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_3(.q(tag1[3]), .d(tag1_n[3]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_4(.q(tag1[4]), .d(tag1_n[4]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_5(.q(tag1[5]), .d(tag1_n[5]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_6(.q(tag1[6]), .d(tag1_n[6]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_7(.q(tag1[7]), .d(tag1_n[7]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_8(.q(tag1[8]), .d(tag1_n[8]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_9(.q(tag1[9]), .d(tag1_n[9]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_10(.q(tag1[10]), .d(tag1_n[10]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_11(.q(tag1[11]), .d(tag1_n[11]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_12(.q(tag1[12]), .d(tag1_n[12]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_13(.q(tag1[13]), .d(tag1_n[13]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_14(.q(tag1[14]), .d(tag1_n[14]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_15(.q(tag1[15]), .d(tag1_n[15]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_16(.q(tag1[16]), .d(tag1_n[16]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_17(.q(tag1[17]), .d(tag1_n[17]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_18(.q(tag1[18]), .d(tag1_n[18]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_19(.q(tag1[19]), .d(tag1_n[19]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_20(.q(tag1[20]), .d(tag1_n[20]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_21(.q(tag1[21]), .d(tag1_n[21]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_22(.q(tag1[22]), .d(tag1_n[22]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_23(.q(tag1[23]), .d(tag1_n[23]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_24(.q(tag1[24]), .d(tag1_n[24]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_25(.q(tag1[25]), .d(tag1_n[25]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_26(.q(tag1[26]), .d(tag1_n[26]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_27(.q(tag1[27]), .d(tag1_n[27]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_28(.q(tag1[28]), .d(tag1_n[28]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_29(.q(tag1[29]), .d(tag1_n[29]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_30(.q(tag1[30]), .d(tag1_n[30]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_31(.q(tag1[31]), .d(tag1_n[31]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_32(.q(tag1[32]), .d(tag1_n[32]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_33(.q(tag1[33]), .d(tag1_n[33]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_34(.q(tag1[34]), .d(tag1_n[34]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_35(.q(tag1[35]), .d(tag1_n[35]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_36(.q(tag1[36]), .d(tag1_n[36]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_37(.q(tag1[37]), .d(tag1_n[37]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_38(.q(tag1[38]), .d(tag1_n[38]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_39(.q(tag1[39]), .d(tag1_n[39]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_40(.q(tag1[40]), .d(tag1_n[40]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_41(.q(tag1[41]), .d(tag1_n[41]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_42(.q(tag1[42]), .d(tag1_n[42]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_43(.q(tag1[43]), .d(tag1_n[43]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_44(.q(tag1[44]), .d(tag1_n[44]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_45(.q(tag1[45]), .d(tag1_n[45]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_46(.q(tag1[46]), .d(tag1_n[46]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_47(.q(tag1[47]), .d(tag1_n[47]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_48(.q(tag1[48]), .d(tag1_n[48]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_49(.q(tag1[49]), .d(tag1_n[49]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_50(.q(tag1[50]), .d(tag1_n[50]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_51(.q(tag1[51]), .d(tag1_n[51]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_52(.q(tag1[52]), .d(tag1_n[52]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_53(.q(tag1[53]), .d(tag1_n[53]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_54(.q(tag1[54]), .d(tag1_n[54]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_55(.q(tag1[55]), .d(tag1_n[55]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_56(.q(tag1[56]), .d(tag1_n[56]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_57(.q(tag1[57]), .d(tag1_n[57]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_58(.q(tag1[58]), .d(tag1_n[58]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_59(.q(tag1[59]), .d(tag1_n[59]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_60(.q(tag1[60]), .d(tag1_n[60]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_61(.q(tag1[61]), .d(tag1_n[61]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_62(.q(tag1[62]), .d(tag1_n[62]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG1_63(.q(tag1[63]), .d(tag1_n[63]), .rst(reset), .clk(clk));
/*
sram22_64x32m4w32 sram0_tag (
  .clk(clk),
  .we(we_cache0_tag),
  .wmask(we_cache0_tag),
  .addr(tag_addr),
  .din(din_tag),
  .dout(dout_tag0)
);

sram22_64x32m4w32 sram1_tag (
  .clk(clk),
  .we(we_cache1_tag),
  .wmask(we_cache1_tag),
  .addr(tag_addr),
  .din(din_tag),
  .dout(dout_tag1)
);
*/

always@* begin
	dout_tag0 = tag0[tag_addr];
	dout_tag1 = tag1[tag_addr];
end

always@* begin
	valid0 = dout_tag0[21];
	dirty0 = dout_tag0[20];
	valid1 = dout_tag1[21];
	dirty1 = dout_tag1[20];
end

// cpu_req_addr_delay, cpu_req_data_delay, cpu_req_write_delay
always@(posedge clk) begin
		cpu_req_addr_delay <= cpu_req_addr;
		cpu_req_data_delay <= cpu_req_data;
		cpu_req_write_delay <= cpu_req_write;
		cpu_req_valid_delay <= cpu_req_valid;
	end

// cpu_req_addr_d, cpu_req_data_d, cpu_req_write_d
always@(posedge clk)
	if(cpu_req_valid_delay && state == READY && miss0 && miss1) begin
		cpu_req_addr_d  <= cpu_req_addr_delay;
		cpu_req_data_d  <= cpu_req_data_delay;
		cpu_req_write_d <= cpu_req_write_delay;
	end
	else begin
		cpu_req_addr_d  <= cpu_req_addr_d;
		cpu_req_data_d  <= cpu_req_data_d;
		cpu_req_write_d <= cpu_req_write_d;
	end

// cache_addr
always@*
	if(state == READY)
		cache_addr = cpu_req_addr[10-1:2];
	else if(state == SAVE)
		case(cnt)
			3'd0: cache_addr = {cpu_req_addr[10-1:4], 2'b00};
			3'd1: cache_addr = {cpu_req_addr[10-1:4], 2'b01};
			3'd2: cache_addr = {cpu_req_addr[10-1:4], 2'b10};
			3'd3: cache_addr = {cpu_req_addr[10-1:4], 2'b11};
			default: cache_addr = {cpu_req_addr[10-1:4], 2'b11};
		endcase
	else if(state == LOAD)
		case(cnt)
			3'd0: cache_addr = {cpu_req_addr[10-1:4], 2'b00};
			3'd1: cache_addr = {cpu_req_addr[10-1:4], 2'b00};
			3'd2: cache_addr = {cpu_req_addr[10-1:4], 2'b01};
			3'd3: cache_addr = {cpu_req_addr[10-1:4], 2'b10};
			3'd4: cache_addr = {cpu_req_addr[10-1:4], 2'b11};
			default: cache_addr = cpu_req_addr[10-1:2];
		endcase
	else
		cache_addr = 8'd0;

// tag_addr
always@*
	tag_addr = cpu_req_addr[10-1:4];

// state
always@(posedge clk)
	if(reset)
		state <= READY;
	else if(state == READY && cpu_req_valid && miss0 && miss1)
		case({valid1, valid0})
			2'b00: state <= LOAD;
			2'b01: state <= LOAD;
			2'b10: state <= LOAD;
			2'b11: begin
				if(~dirty0)
					state <= LOAD;
				else if(~dirty1)
					state <= LOAD;
				else
					state <= SAVE;
			end
		endcase
	else if(state == SAVE && cnt == 3'd4)
		state <= LOAD;
	else if(state == LOAD && cnt == 3'd4)
		state <= READY;
	else state <= state;

// cnt
always@(posedge clk)
	if(reset)
		cnt <= 0;
	else if(state == SAVE && cnt == 3'd4)
		cnt <= 0;
	else if(state == SAVE && mem_req_data_ready)
		cnt <= cnt + 1;
	else if(state == LOAD && cnt == 3'd4)
		cnt <= 0;
	else if(state == LOAD && mem_req_ready)
		cnt <= cnt + 1;
	else if(state == LOAD && cnt != 0)
		cnt <= cnt + 1;
	else 
		cnt <= cnt;

// set
always@(posedge clk)
	if(reset)
		set <= 0;
	else if(state == READY && miss0 && miss1)
		case({valid1, valid0})
			2'b00: set <= 0;
			2'b01: set <= 1;
			2'b10: set <= 0;
			2'b11: set <= 0;
		endcase
	else
		set <= set;
		
// hit0, hit1
always@*
	if(state == READY) begin
		hit0 = (dout_tag0[20-1:0] == cpu_req_addr[WORD_ADDR_BITS-1:10]) && valid0;
		hit1 = (dout_tag1[20-1:0] == cpu_req_addr[WORD_ADDR_BITS-1:10]) && valid1;
	end
	else begin
		hit0 = 0;
		hit1 = 0;
	end

// stall
always@*
	if(cpu_req_valid && state == READY && miss0 && miss1)
		cpu_req_ready = 0;
	else if(cpu_req_valid && state == READY)
		cpu_req_ready = 1;
	else if(state != READY)
		cpu_req_ready = 0;
	else
		cpu_req_ready = 1;

// mem_req_data_bits, mem_req_data_mask
always@*
	if(state == SAVE) begin
		mem_req_data_bits = {dout0_11, dout0_10, dout0_01, dout0_00};
		mem_req_data_mask = 16'hffff;
	end
	else begin
		mem_req_data_bits = 0;
		mem_req_data_mask = 16'h0000;
	end

// mem_req_data_valid, mem_req_rw
always@(posedge clk)
	if(reset) begin
		mem_req_data_valid <= 0;
		mem_req_rw <= 0;
	end
	else if(state == SAVE && mem_req_data_ready) begin
		mem_req_data_valid <= 1;
		mem_req_rw <= 1;
	end
	else begin
		mem_req_data_valid <= 0;
		mem_req_rw <= 0;
	end

// mem_req_valid
always@*
	mem_req_valid = (state == LOAD);

// mem_req_addr
always@*
	if(state == LOAD)
		case(cnt)
			3'd0: mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b00};
			3'd1: mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b01};
			3'd2: mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b10};
			3'd3: mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b11};
			default: mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b11};
		endcase
	else
		mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b00};

// din0_00 ~ din1_11
always@* begin
	// default case
	din0_00 = 0; din0_01 = 0; din0_10 = 0; din0_11 = 0; 
	din1_00 = 0; din1_01 = 0; din1_10 = 0; din1_11 = 0; 
	
	if(state == LOAD && mem_resp_valid) begin
		din0_00 = mem_resp_data[32*1-1:32*0]; din0_01 = mem_resp_data[32*2-1:32*1]; din0_10 = mem_resp_data[32*3-1:32*2]; din0_11 = mem_resp_data[32*4-1:32*3]; 
		din1_00 = mem_resp_data[32*1-1:32*0]; din1_01 = mem_resp_data[32*2-1:32*1]; din1_10 = mem_resp_data[32*3-1:32*2]; din1_11 = mem_resp_data[32*4-1:32*3]; 
	end
	else if(state == READY && (hit0 || hit1)) begin
		if(|cpu_req_write) // write operation
			if(hit0)       // write set0
				case(cpu_req_addr[1:0])
					2'b00: din0_00 = cpu_req_data;
					2'b01: din0_01 = cpu_req_data;
					2'b10: din0_10 = cpu_req_data;
					2'b11: din0_11 = cpu_req_data;
				endcase
			else
				case(cpu_req_addr[1:0])
					2'b00: din1_00 = cpu_req_data;
					2'b01: din1_01 = cpu_req_data;
					2'b10: din1_10 = cpu_req_data;
					2'b11: din1_11 = cpu_req_data;
				endcase
	end
end

// we_cache0_00 ~ we_cache1_11, wmask0_00 ~ wmask1_11
always@* begin
	// default case
	we_cache0_00 = 0; we_cache0_01 = 0; we_cache0_10 = 0; we_cache0_11 = 0;
	we_cache1_00 = 0; we_cache1_01 = 0; we_cache1_10 = 0; we_cache1_11 = 0;
	wmask0_00 = 0; wmask0_01 = 0; wmask0_10 = 0; wmask0_11 = 0;
	wmask1_00 = 0; wmask1_01 = 0; wmask1_10 = 0; wmask1_11 = 0;
	if(state == LOAD && cnt > 0 && cnt < 5) begin
		case({valid1, valid0})
			2'b00: begin 
				we_cache0_00 = 1; we_cache0_01 = 1; we_cache0_10 = 1; we_cache0_11 = 1;
				wmask0_00 = 4'hf; wmask0_01 = 4'hf; wmask0_10 = 4'hf; wmask0_11 = 4'hf; 
			end
			2'b01: begin 
				we_cache1_00 = 1; we_cache1_01 = 1; we_cache1_10 = 1; we_cache1_11 = 1;
				wmask1_00 = 4'hf; wmask1_01 = 4'hf; wmask1_10 = 4'hf; wmask1_11 = 4'hf;  
			end
			2'b10: begin 
				we_cache0_00 = 1; we_cache0_01 = 1; we_cache0_10 = 1; we_cache0_11 = 1;
				wmask0_00 = 4'hf; wmask0_01 = 4'hf; wmask0_10 = 4'hf; wmask0_11 = 4'hf; 
			end
			2'b11: begin 
				we_cache0_00 = 1; we_cache0_01 = 1; we_cache0_10 = 1; we_cache0_11 = 1;
				wmask0_00 = 4'hf; wmask0_01 = 4'hf; wmask0_10 = 4'hf; wmask0_11 = 4'hf; 
			end
		endcase
	end
	else if(state == READY && (hit0 || hit1)) begin
		if(|cpu_req_write) // write operation
			if(hit0)       // write set0
				case(cpu_req_addr[1:0])
					2'b00: begin we_cache0_00 = 1; wmask0_00 = cpu_req_write; end
					2'b01: begin we_cache0_01 = 1; wmask0_01 = cpu_req_write; end
					2'b10: begin we_cache0_10 = 1; wmask0_10 = cpu_req_write; end
					2'b11: begin we_cache0_11 = 1; wmask0_11 = cpu_req_write; end
				endcase
			else
				case(cpu_req_addr[1:0])
					2'b00: begin we_cache1_00 = 1; wmask1_00 = cpu_req_write; end
					2'b01: begin we_cache1_01 = 1; wmask1_01 = cpu_req_write; end
					2'b10: begin we_cache1_10 = 1; wmask1_10 = cpu_req_write; end
					2'b11: begin we_cache1_11 = 1; wmask1_11 = cpu_req_write; end
				endcase
	end
end

// we_cache0_tag, we_cache1_tag
always@*
	if(state == LOAD && cnt == 3'd4)
		case({valid1, valid0})
			2'b00: begin we_cache0_tag = 1; we_cache1_tag = 0; end
			2'b01: begin we_cache0_tag = 0; we_cache1_tag = 1; end
			2'b10: begin we_cache0_tag = 1; we_cache1_tag = 0; end
			2'b11: begin we_cache0_tag = 1; we_cache1_tag = 0; end
		endcase
	else if(state == READY && (hit0 || hit1)) begin
		if(|cpu_req_write) // write operation
			if(hit0)       // write set0
				begin we_cache0_tag = 1; we_cache1_tag = 0; end
			else
				begin we_cache0_tag = 0; we_cache1_tag = 1; end
		else
			begin we_cache0_tag = 0; we_cache1_tag = 0; end
	end
	else begin
		we_cache0_tag = 0; we_cache1_tag = 0;
	end

// din_tag
always@*
	if(state == LOAD && cnt == 3'd4)
		din_tag = {1'b1, 1'b0, cpu_req_addr[WORD_ADDR_BITS-1:10]};
	else if(state == READY && (hit0 || hit1))
		if(|cpu_req_write) // write operation
			if(hit0)       // write set0
				din_tag = {1'b1, 1'b1, dout_tag0[19:0]};
			else
				din_tag = {1'b1, 1'b1, dout_tag1[19:0]};
	else
		din_tag = 22'd0;

// cpu_resp_data
always@*
	case({set, cpu_req_addr_delay[1:0]})
		3'b000: cpu_resp_data = dout0_00;
		3'b001: cpu_resp_data = dout0_01;
		3'b010: cpu_resp_data = dout0_10;
		3'b011: cpu_resp_data = dout0_11;
		3'b100: cpu_resp_data = dout1_00;
		3'b101: cpu_resp_data = dout1_01;
		3'b110: cpu_resp_data = dout1_10;
		3'b111: cpu_resp_data = dout1_11;
	endcase


endmodule
