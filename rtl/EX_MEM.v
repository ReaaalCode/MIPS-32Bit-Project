module ex_mem (
    input         clk,
    input         reset,
    input  [31:0] alu_result_in,   // ALU result from EX
    input  [31:0] write_data_in,   // data to write to memory
    input  [4:0]  writereg_in,     // destination register
    input         regwrite_in,     // write to register
    input         memtoreg_in,     // write memory data to register
    input         memwrite_in,     // write to memory
    input         branch_in,       // branch flag
    output reg [31:0] alu_result_out,
    output reg [31:0] write_data_out,
    output reg [4:0]  writereg_out,
    output reg        regwrite_out,
    output reg        memtoreg_out,
    output reg        memwrite_out,
    output reg        branch_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // clear all outputs
            alu_result_out <= 32'b0;
            write_data_out <= 32'b0;
            writereg_out   <= 5'b0;
            regwrite_out   <= 1'b0;
            memtoreg_out   <= 1'b0;
            memwrite_out   <= 1'b0;
            branch_out     <= 1'b0;
        end else begin
            // normal: pass inputs to outputs
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            writereg_out   <= writereg_in;
            regwrite_out   <= regwrite_in;
            memtoreg_out   <= memtoreg_in;
            memwrite_out   <= memwrite_in;
            branch_out     <= branch_in;
        end
    end
endmodule