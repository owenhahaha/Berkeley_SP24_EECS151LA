module IF_DE(
    input clk,
    input reset,
    input stall,
    input icache_re,
    input [31:0] icache_dout,
    input [31:0] PC_4_F,
    input PC_sel_F,
    input interlock,
    output reg [31:0] instr_D,
    output reg [31:0] PC_4_D,
    output reg PC_sel_D
);

wire stall_delay;
wire [31:0] instr_D_delay;
wire PC_sel_F_delay;

REGISTER_R_CE #(.N(32)) R0 (
    .ce(~stall),
    .clk(clk),
    .rst(reset),
    .d(PC_4_F),
    .q(PC_4_D)
);

REGISTER_R_CE #(.N(1), .INIT(1'd1)) R1 (
    .ce(~stall),
    .clk(clk),
    .rst(icache_re == 0),
    .d(PC_sel_F),
    .q(PC_sel_D)
);

REGISTER_R #(.N(1)) R4 (
    .clk(clk),
    .rst(reset),
    .d(stall),
    .q(stall_delay)
);

REGISTER_R #(.N(1)) R2 (
    .clk(clk),
    .rst(reset),
    .d(PC_sel_F),
    .q(PC_sel_F_delay)
);


REGISTER_R #(.N(32)) R3 (
    .clk(clk),
    .rst(reset),
    .d(instr_D),
    .q(instr_D_delay)
);

always@* begin
    instr_D = icache_dout;
    if(stall_delay)
        instr_D = instr_D_delay;
    if (PC_sel_F_delay)
        instr_D = {32{1'b0}};
end

// always@(posedge clk)
//   if(reset)
//     PC_4_D <= 0;
//   else 
//     PC_4_D <= PC_4_F;

// always@(posedge clk)
//   if(icache_re == 0)
//     PC_sel_D <= 1;
//   else
//     PC_sel_D <= PC_sel_F;

endmodule