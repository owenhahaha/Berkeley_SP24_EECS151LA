`include "const.vh"

module IF(
    input clk,
    input reset,
    input icache_re,
    input [31:0] branch_target,
    input [31:0] jalr_target,
    input interlock,
    input stall,

    input zero,
    input [1:0] taken,
    input br_type,

    output reg PC_sel,
    output [31:0] PC_4,
    output [31:0] icache_addr
);

reg [31:0] PC, PC_n;
reg PC_sel_delay;

always@* begin
    if(interlock | stall)
        PC_sel = 0;
    else
        case (taken) 
            0: PC_sel = 0;
            1: PC_sel = br_type ^ zero;      // branch
            2: PC_sel = 1;                   // jal
            3: PC_sel = 1;                   // jalr
        endcase
end

always@* begin
    case(PC_sel) 
        1'b0: PC_n = PC_4;
        1'b1: case (taken) 
            0: PC_n = 0;
            1: PC_n = branch_target;        // branch
            2: PC_n = branch_target;        // jal
            3: PC_n = jalr_target;          // jalr
        endcase
    endcase
end

REGISTER_R #(.N(32), .INIT(`PC_RESET)) R0 (
    .clk(clk),
    .rst(reset),
    .d(PC_n),
    .q(PC)
);

// always@(posedge clk)
//     if(reset)              // reset program counter
//         PC <= `PC_RESET;
//     else 
//         PC <= PC_n;

assign PC_4 = (interlock || stall)? PC: PC + 4;
// assign icache_addr = (interlock)? PC - 4: PC;
assign icache_addr = PC;

endmodule