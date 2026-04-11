module if_id (
    input         clk,
    input         reset,
    input         stall,
    input         flush,
    input  [31:0] pcplus4_in,
    input  [31:0] instr_in,
    output reg [31:0] pcplus4_out,
    output reg [31:0] instr_out
);
    // Update pipeline register each cycle
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Clear outputs on reset
            pcplus4_out <= 32'b0;
            instr_out   <= 32'b0;
        end else if (stall) begin
            // Keep previous values when stalled
            pcplus4_out <= pcplus4_out;
            instr_out   <= instr_out;
        end else if (flush) begin
            // Insert a NOP when flushed
            pcplus4_out <= 32'b0;
            instr_out   <= 32'b0;
        end else begin
            // Normal pipeline advance
            pcplus4_out <= pcplus4_in;
            instr_out   <= instr_in;
        end
    end
endmodule