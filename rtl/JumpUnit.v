module jump_unit(
    input  wire [31:0] ifid_instr,
    input  wire [31:0] ifid_pcplus4,   // for J target composition
    input  wire [31:0] reg_rd1_id,     // regfile read (for JR target)
    input  wire        id_jump,        // from maindec (J opcode)
    input  wire        flush_branch,   // branch flush computed by EX
    output wire        id_is_beq,
    output wire        id_jump_any,
    output wire [31:0] jump_target,
    output wire        flush_ifid
);
    wire [5:0] op    = ifid_instr[31:26];
    wire [5:0] funct = ifid_instr[5:0];

    // BEQ detection
    assign id_is_beq = (op == 6'b000100);

   
    // JR detection and target
    assign id_is_jr = (op == 6'b000000) && (funct == 6'b001000);
    assign jr_target = reg_rd1_id;

    // combine J (maindec) and JR
    assign id_jump_any = id_jump | id_is_jr;

    // compute jump target: JR uses register value, J uses instr immediate
    assign jump_target = id_is_jr ? jr_target :
                         { ifid_pcplus4[31:28], ifid_instr[25:0], 2'b00 };

    // flush IF/ID on branch or jump
    assign flush_ifid = flush_branch | id_jump_any;

endmodule