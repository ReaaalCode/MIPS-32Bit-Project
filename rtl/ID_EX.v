module id_ex (
    input         clk,
    input         reset,
    input         stall,          // hold current values
    input         flush,          // insert bubble (NOP)
    input  [31:0] pcplus4_in,
    input  [31:0] read_data1_in,
    input  [31:0] read_data2_in,
    input  [31:0] signzeroimm_in,
    input  [4:0]  rs_in,
    input  [4:0]  rt_in,
    input  [4:0]  writereg_in,
    input         regwrite_in,
    input         memtoreg_in,
    input         memwrite_in,
    input         branch_in,
    input         alusrc_in,
    input  [3:0]  alucontrol_in,
    input  [4:0]  shamt_in,        // shift amount
    output reg [31:0] pcplus4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] signzeroimm_out,
    output reg [4:0]  rs_out,
    output reg [4:0]  rt_out,
    output reg [4:0]  writereg_out,
    output reg        regwrite_out,
    output reg        memtoreg_out,
    output reg        memwrite_out,
    output reg        branch_out,
    output reg        alusrc_out,
    output reg [3:0]  alucontrol_out,
    output reg [4:0]  shamt_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // clear all outputs on reset
            pcplus4_out    <= 32'b0;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            signzeroimm_out    <= 32'b0;
            rs_out         <= 5'b0;
            rt_out         <= 5'b0;
            writereg_out   <= 5'b0;
            regwrite_out   <= 1'b0;
            memtoreg_out   <= 1'b0;
            memwrite_out   <= 1'b0;
            branch_out     <= 1'b0;
            alusrc_out     <= 1'b0;
            alucontrol_out <= 4'b0;
            shamt_out      <= 5'b0;
        end else if (flush) begin
            // IMPORTANT: flush must have priority over stall
            // insert bubble (NOP)
            pcplus4_out    <= 32'b0;
            read_data1_out <= 32'b0;
            read_data2_out <= 32'b0;
            signzeroimm_out    <= 32'b0;
            rs_out         <= 5'b0;
            rt_out         <= 5'b0;
            writereg_out   <= 5'b0;
            regwrite_out   <= 1'b0;
            memtoreg_out   <= 1'b0;
            memwrite_out   <= 1'b0;
            branch_out     <= 1'b0;
            alusrc_out     <= 1'b0;
            alucontrol_out <= 4'b0;
            shamt_out      <= 5'b0;
        end else if (stall) begin
            // hold current values
            pcplus4_out    <= pcplus4_out;
            read_data1_out <= read_data1_out;
            read_data2_out <= read_data2_out;
            signzeroimm_out    <= signzeroimm_out;
            rs_out         <= rs_out;
            rt_out         <= rt_out;
            writereg_out   <= writereg_out;
            regwrite_out   <= regwrite_out;
            memtoreg_out   <= memtoreg_out;
            memwrite_out   <= memwrite_out;
            branch_out     <= branch_out;
            alusrc_out     <= alusrc_out;
            alucontrol_out <= alucontrol_out;
            shamt_out      <= shamt_out;
        end else begin
            // normal latch: copy inputs to outputs
            pcplus4_out    <= pcplus4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            signzeroimm_out    <= signzeroimm_in;
            rs_out         <= rs_in;
            rt_out         <= rt_in;
            writereg_out   <= writereg_in;
            regwrite_out   <= regwrite_in;
            memtoreg_out   <= memtoreg_in;
            memwrite_out   <= memwrite_in;
            branch_out     <= branch_in;
            alusrc_out     <= alusrc_in;
            alucontrol_out <= alucontrol_in;
            shamt_out      <= shamt_in;
        end
    end
endmodule