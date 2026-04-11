module ex_unit(
    // ID/EX inputs
    input  wire [31:0] idex_pcplus4,
    input  wire [31:0] idex_rd1,
    input  wire [31:0] idex_rd2,
    input  wire [31:0] idex_signzeroimm,
    input  wire [4:0]  idex_rs,
    input  wire [4:0]  idex_rt,
    input  wire        idex_alusrc,
    input  wire [3:0]  idex_alucontrol,
    input  wire [4:0]  idex_shamt,
    input  wire        idex_branch,

    // forwarding inputs (EX/MEM and MEM/WB stage outputs)
    input  wire        exmem_regwrite,
    input  wire [4:0]  exmem_rd,
    input  wire [31:0] exmem_alu_result,
    input  wire        memwb_regwrite,
    input  wire [4:0]  memwb_rd,
    input  wire        memwb_memtoreg,
    input  wire [31:0] memwb_readdata,
    input  wire [31:0] memwb_alu_result,

    // outputs to be latched into EX/MEM by top
    output wire [31:0] alu_result_ex,
    output wire [31:0] alu_muxB_pre,    // value used as write-data / second operand before ALUSrc
    // branch outputs
    output wire        branch_taken,
    output wire [31:0] branch_target_calc
);

    // forwarding signals
    wire [1:0] forwardA, forwardB;

    // instantiate the existing forwarding module
    forwarding u_forwarding (
        .idex_rs(idex_rs),
        .idex_rt(idex_rt),
        .exmem_regwrite(exmem_regwrite),
        .exmem_rd(exmem_rd),
        .memwb_regwrite(memwb_regwrite),
        .memwb_rd(memwb_rd),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    // forwarded muxes
    reg [31:0] alu_muxA, alu_muxB_pre_r;
    always @(*) begin
        // A operand
        case (forwardA)
            2'b10: alu_muxA = exmem_alu_result;
            2'b01: alu_muxA = (memwb_memtoreg ? memwb_readdata : memwb_alu_result);
            default: alu_muxA = idex_rd1;
        endcase
        // B operand (pre ALUSrc)
        case (forwardB)
            2'b10: alu_muxB_pre_r = exmem_alu_result;
            2'b01: alu_muxB_pre_r = (memwb_memtoreg ? memwb_readdata : memwb_alu_result);
            default: alu_muxB_pre_r = idex_rd2;
        endcase
    end
    assign alu_muxB_pre = alu_muxB_pre_r;

    // choose ALU operands (ALUSrc)
    wire [31:0] alu_operand1 = alu_muxA;
    wire [31:0] alu_operand2 = idex_alusrc ? idex_signzeroimm : alu_muxB_pre;

    // instantiate ALU
    wire [31:0] alu_out;
    wire        alu_zero;
    alu u_alu (
        .a(alu_operand1),
        .b(alu_operand2),
        .alucontrol(idex_alucontrol),
        .shamt(idex_shamt),
        .aluout(alu_out),
        .zero(alu_zero)
    );
    assign alu_result_ex = alu_out;

    // branch calculation (EX)
    wire [31:0] signzeroimm_shifted = {idex_signzeroimm[29:0], 2'b00};
    assign branch_target_calc = idex_pcplus4 + signzeroimm_shifted;
    // use internal ALU zero directly (no external alias)
    assign branch_taken = idex_branch & alu_zero;

endmodule
