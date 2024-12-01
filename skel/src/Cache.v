////////////////////////////////////////////////////
// 4KB Cache                                      //
// direct-mapped                                  //
// 512-bit Cache line                             //
// 256x128                                        //
// Regfile Metadata                               //
////////////////////////////////////////////////////
`include "util.vh"
`include "const.vh"

module cache #
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

// FSM state
localparam READY = 2'd0, SAVE = 2'd1, LOAD = 2'd2;

integer i;

reg hit0;
reg valid0;
reg dirty0;
reg [7:0] cache_addr;
reg [1:0] state_n;
reg [2:0] cnt_n;
reg we_cache0_00, we_cache0_01, we_cache0_10, we_cache0_11;
reg [3:0] wmask0_00, wmask0_01, wmask0_10, wmask0_11;
reg [31:0] din0_00, din0_01, din0_10, din0_11;
reg we_cache0_tag;
reg [22-1:0] din_tag;
reg [22-1:0] dout_tag0;
reg [6-1:0] tag_addr;
reg [22-1:0] tag0_n [0:63];

wire [WORD_ADDR_BITS-1:0] cpu_req_addr_delay;
wire [1:0] state;
wire [2:0] cnt;
wire [31:0] dout0_00, dout0_01, dout0_10, dout0_11;
wire [22-1:0] tag0 [0:63];
wire miss0;

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

REGISTER_R #(.N(WORD_ADDR_BITS)) R0(.q(cpu_req_addr_delay), .d(cpu_req_addr), .rst(reset), .clk(clk));
REGISTER_R #(.N(2))              R1(.q(state), .d(state_n), .rst(reset), .clk(clk));
REGISTER_R #(.N(3))              R2(.q(cnt), .d(cnt_n), .rst(reset), .clk(clk));

REGISTER_R #(.N(22)) REG0_0 (.q(tag0[ 0]), .d(tag0_n[ 0]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_1 (.q(tag0[ 1]), .d(tag0_n[ 1]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_2 (.q(tag0[ 2]), .d(tag0_n[ 2]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_3 (.q(tag0[ 3]), .d(tag0_n[ 3]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_4 (.q(tag0[ 4]), .d(tag0_n[ 4]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_5 (.q(tag0[ 5]), .d(tag0_n[ 5]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_6 (.q(tag0[ 6]), .d(tag0_n[ 6]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_7 (.q(tag0[ 7]), .d(tag0_n[ 7]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_8 (.q(tag0[ 8]), .d(tag0_n[ 8]), .rst(reset), .clk(clk));
REGISTER_R #(.N(22)) REG0_9 (.q(tag0[ 9]), .d(tag0_n[ 9]), .rst(reset), .clk(clk));
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

// tag0_n
always@*
	for(i = 0; i < 64; i = i + 1)
		tag0_n[i] = (we_cache0_tag && (i == tag_addr)) ? din_tag : tag0[i];

// dout_tag0
always@*
	dout_tag0 = tag0[tag_addr];

// valid0, dirty0
always@* begin
	valid0 = dout_tag0[21];
	dirty0 = dout_tag0[20];
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

// state_n
always@*
	if(state == READY && cpu_req_valid && miss0)
		case({valid0, dirty0})
			2'b00: state_n = LOAD;
			2'b01: state_n = LOAD;
			2'b10: state_n = LOAD;
			2'b11: state_n = SAVE;
		endcase
	else if(state == SAVE && cnt == 3'd3 && mem_req_data_ready)
		state_n = LOAD;
	else if(state == LOAD && cnt == 3'd4)
		state_n = READY;
	else 
		state_n = state;

// cnt_n
always@*
	if(state == SAVE && cnt == 3'd3 && mem_req_data_ready)
		cnt_n = 0;
	else if(state == SAVE && mem_req_data_ready)
		cnt_n = cnt + 1;
	else if(state == LOAD && cnt == 3'd4)
		cnt_n = 0;
	else if(state == LOAD && mem_req_ready)
		cnt_n = cnt + 1;
	else if(state == LOAD && cnt != 0)
		cnt_n = cnt + 1;
	else 
		cnt_n = cnt;
		
// hit0
always@*
	if(state == READY)
		hit0 = (dout_tag0[20-1:0] == cpu_req_addr[WORD_ADDR_BITS-1:10]) && valid0;
	else
		hit0 = 0;

// miss0
assign miss0 = ~hit0;

// stall
always@*
	if(cpu_req_valid && state == READY && miss0)
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

// mem_req_rw
always@*
	if(state == SAVE)
		mem_req_rw = 1;
	else 
		mem_req_rw = 0;

// mem_req_data_valid
always@*
	mem_req_data_valid = (state == SAVE);

// mem_req_valid
always@*
	mem_req_valid = (state == LOAD) || (state == SAVE);

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
	else if(state == SAVE)
		mem_req_addr = {dout_tag0[20-1:0], cache_addr};
	else
		mem_req_addr = {cpu_req_addr[WORD_ADDR_BITS-1:4], 2'b00};

// din0_00 ~ din0_11
always@* begin
	// default case
	din0_00 = 0; din0_01 = 0; din0_10 = 0; din0_11 = 0; 
	if(state == LOAD && mem_resp_valid) begin
		din0_00 = mem_resp_data[32*1-1:32*0]; 
		din0_01 = mem_resp_data[32*2-1:32*1]; 
		din0_10 = mem_resp_data[32*3-1:32*2]; 
		din0_11 = mem_resp_data[32*4-1:32*3]; 
	end
	else if(state == READY && hit0) begin
		if(|cpu_req_write) // write operation
			case(cpu_req_addr[1:0])
				2'b00: din0_00 = cpu_req_data;
				2'b01: din0_01 = cpu_req_data;
				2'b10: din0_10 = cpu_req_data;
				2'b11: din0_11 = cpu_req_data;
			endcase
	end
end

// we_cache0_00 ~ we_cache0_11, wmask0_00 ~ wmask0_11
always@* begin
	// default case
	we_cache0_00 = 0; we_cache0_01 = 0; we_cache0_10 = 0; we_cache0_11 = 0;
	wmask0_00 = 0; wmask0_01 = 0; wmask0_10 = 0; wmask0_11 = 0;
	if(state == LOAD && cnt > 0 && cnt < 5) begin
		we_cache0_00 = 1; we_cache0_01 = 1; we_cache0_10 = 1; we_cache0_11 = 1;
		wmask0_00 = 4'hf; wmask0_01 = 4'hf; wmask0_10 = 4'hf; wmask0_11 = 4'hf;
	end
	else if(state == READY && hit0) begin
		if(|cpu_req_write) // write operation
			case(cpu_req_addr[1:0])
				2'b00: begin we_cache0_00 = 1; wmask0_00 = cpu_req_write; end
				2'b01: begin we_cache0_01 = 1; wmask0_01 = cpu_req_write; end
				2'b10: begin we_cache0_10 = 1; wmask0_10 = cpu_req_write; end
				2'b11: begin we_cache0_11 = 1; wmask0_11 = cpu_req_write; end
			endcase
	end
end

// we_cache0_tag
always@*
	if(state == LOAD && cnt == 3'd4)
		we_cache0_tag = 1;
	else if(state == READY && hit0) begin
		if(|cpu_req_write) // write operation
			we_cache0_tag = 1;
		else
			we_cache0_tag = 0;
	end
	else
		we_cache0_tag = 0;

// din_tag
always@*
	if(state == LOAD && cnt == 3'd4)
		din_tag = {1'b1, 1'b0, cpu_req_addr[WORD_ADDR_BITS-1:10]};
	else if(state == READY && hit0)
		if(|cpu_req_write) // write operation
			din_tag = {1'b1, 1'b1, dout_tag0[19:0]};
	else
		din_tag = 22'd0;

// cpu_resp_data
always@*
	case(cpu_req_addr_delay[1:0])
		2'b00: cpu_resp_data = dout0_00;
		2'b01: cpu_resp_data = dout0_01;
		2'b10: cpu_resp_data = dout0_10;
		2'b11: cpu_resp_data = dout0_11;
	endcase


endmodule
