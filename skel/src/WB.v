module WB(
    input clk,
    input [1:0] wb_sel,
    input [2:0] funct3,
    input [1:0] last_2bit,
    input [31:0] branch_target,
    input [31:0] PC_4,
    input [31:0] ALUout,
    input [31:0] dcache_dout,

    output reg [31:0] wdata
);

reg [31:0] dout;

always@* begin
    case(funct3) // cadence full_case
        3'h0: case(last_2bit)  // lb
                2'b00: dout = {{24{dcache_dout[7]}}, dcache_dout[7:0]};
                2'b01: dout = {{24{dcache_dout[15]}}, dcache_dout[15:8]};
                2'b10: dout = {{24{dcache_dout[23]}}, dcache_dout[23:16]};
                2'b11: dout = {{24{dcache_dout[31]}}, dcache_dout[31:24]};
            endcase
        3'h4: case(last_2bit)   // lbu
                2'b00: dout = {{24{1'b0}}, dcache_dout[7:0]};
                2'b01: dout = {{24{1'b0}}, dcache_dout[15:8]};
                2'b10: dout = {{24{1'b0}}, dcache_dout[23:16]};
                2'b11: dout = {{24{1'b0}}, dcache_dout[31:24]};
            endcase
        3'h1: case(last_2bit)   // lh
                2'b00: dout = {{16{dcache_dout[15]}}, dcache_dout[15:0]};
                2'b01: dout = {{16{dcache_dout[23]}}, dcache_dout[23:8]};
                2'b10: dout = {{16{dcache_dout[31]}}, dcache_dout[31:16]};
                2'b11: dout = 0;
            endcase
        3'h5: case(last_2bit)   // lhu
                2'b00: dout = {{16{1'b0}}, dcache_dout[15:0]};
                2'b01: dout = {{16{1'b0}}, dcache_dout[23:8]};
                2'b10: dout = {{16{1'b0}}, dcache_dout[31:16]};
                2'b11: dout = 0;
            endcase
        3'h2: dout = dcache_dout;  // lw
        3'h0: dout = 0;
    endcase
end

always@* begin
    case(wb_sel)
        2'd0: wdata = ALUout;           // write back memory
        2'd1: wdata = dout;             // write back branch_target
        2'd2: wdata = PC_4;             // jal/jalr
        2'd3: wdata = branch_target;    // auipc
    endcase
end             
        

endmodule