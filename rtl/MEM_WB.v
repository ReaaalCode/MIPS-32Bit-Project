module mem_wb (
    input         clk,           // clock
    input         reset,         // reset pipeline
    input  [31:0] readdata_in,   // data read from memory
    input  [31:0] alu_result_in, // ALU result from EX/MEM
    input  [4:0]  writereg_in,   // destination register
    input         regwrite_in,   // enable register write
    input         memtoreg_in,   // choose memory data for WB
    output reg [31:0] readdata_out,
    output reg [31:0] alu_result_out,
    output reg [4:0]  writereg_out,
    output reg        regwrite_out,
    output reg        memtoreg_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // clear outputs on reset
            readdata_out   <= 32'b0;
            alu_result_out <= 32'b0;
            writereg_out   <= 5'b0;
            regwrite_out   <= 1'b0;
            memtoreg_out   <= 1'b0;
        end else begin
            // normal operation: latch inputs
            readdata_out   <= readdata_in;
            alu_result_out <= alu_result_in;
            writereg_out   <= writereg_in;
            regwrite_out   <= regwrite_in;
            memtoreg_out   <= memtoreg_in;
        end
    end
endmodule