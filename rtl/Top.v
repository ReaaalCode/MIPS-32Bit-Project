module top(
    input  wire        clk,
    input  wire        reset,
    output wire [31:0] writedata,
    output wire [31:0] dataadr,
    output wire        memwrite,
    output wire [31:0] pc
);

    // --- PC unit wires (pc_unit handles pc_reg, pc+4, imem_addr) ---
    wire [31:0] pc_plus4_if;
    wire [5:0]  imem_addr;

    // control/hazard signals
    wire        stall_hazard;
    wire        flush_hazard;
    wire        id_jump_any;    // J or JR combined


    // Branch/jump signals from EX stage (computed later in EX)
    wire        branch_taken;
    wire [31:0] branch_target_ex;
    wire [31:0] jump_target;

    // Instantiate PC unit (pc_next removed)
    pc_unit u_pc (
        .clk(clk),
        .reset(reset),
        .stall(stall_hazard),
        .id_jump_any(id_jump_any),
        .branch_taken(branch_taken),
        .branch_target(branch_target_ex),
        .jump_target(jump_target),
        .pc(pc),
        .pc_plus4(pc_plus4_if),
        .imem_addr(imem_addr)
    );

    // ---------- Instruction memory (word-indexed by imem_addr) ----------
    wire [31:0] instr;
    imem u_imem (
        .a(imem_addr),
        .reset(reset),
        .rd(instr)
    );

    // ---------- IF/ID pipeline register ----------
    wire [31:0] ifid_pcplus4;
    wire [31:0] ifid_instr;
    wire        flush_ifid;
    if_id u_if_id (
        .clk(clk),
        .reset(reset),
        .stall(stall_hazard),
        .flush(flush_ifid),
        .pcplus4_in(pc_plus4_if),
        .instr_in(instr),
        .pcplus4_out(ifid_pcplus4),
        .instr_out(ifid_instr)
    );

    // ---------- ID stage: decode & control ----------
    wire [5:0] ifid_op    = ifid_instr[31:26];
    wire [5:0] ifid_funct = ifid_instr[5:0];

    // Replace controller wrapper with maindec + aludec
    wire [1:0] aluop;

    wire id_memtoreg;
    wire id_memwrite;
    wire id_alusrc;
    wire id_zeroext;
    wire id_regwrite;
    wire id_jump;        // jump output coming from maindec (J-type)
    wire [3:0] id_alucontrol;

    maindec u_maindec (
        .op(ifid_op),
        .memtoreg(id_memtoreg),
        .memwrite(id_memwrite),
        .alusrc(id_alusrc),
        .zeroext(id_zeroext),
        .regwrite(id_regwrite),
        .jump(id_jump),
        .aluop(aluop)
    );

    aludec u_aludec (
        .op(ifid_op),
        .funct(ifid_funct),
        .aluop(aluop),
        .alucontrol(id_alucontrol)
    );

    // Register file read (ID). WB stage drives writes back.
    wire [31:0] reg_rd1_id;
    wire [31:0] reg_rd2_id;
    wire [31:0] wb_writedata;
    wire [4:0]  wb_writereg;
    wire        wb_regwrite;
    wire [4:0]  id_writereg;

    regfile u_regfile (
        .clk(clk),
        .reset(reset),
        .op(ifid_op),
        .we3(wb_regwrite),
        .ra1(ifid_instr[25:21]),
        .ra2(ifid_instr[20:16]),
        .ra3(ifid_instr[15:11]),       
        .wa3(wb_writereg),
        .wd3(wb_writedata),
        .rd1(reg_rd1_id),
        .rd2(reg_rd2_id),
        .wao(id_writereg)
    );

    // Immediate extension (sign or zero) for ID stage
    wire [31:0] signzeroimm_id;
    signzeroext u_signzeroext (
        .imm16(ifid_instr[15:0]),
        .zeroext(id_zeroext),
        .imm32(signzeroimm_id)
    );

    // ---------- ID combinational glue moved to id ----------
    
    wire        flush_branch;
    wire        id_is_beq;
    wire        id_is_jr;
    wire [31:0] jr_target;

    // instantiate id (keeps behavior identical to original combinational block)
    jump_unit u_jump_unit (
        .ifid_instr(ifid_instr),
        .ifid_pcplus4(ifid_pcplus4),
        .reg_rd1_id(reg_rd1_id),
        .id_jump(id_jump),
        .flush_branch(flush_branch),
        .id_is_beq(id_is_beq),
        .id_jump_any(id_jump_any),
        .jump_target(jump_target),
        .flush_ifid(flush_ifid)
    );

    // ---------- ID/EX pipeline register ----------
    wire [31:0] idex_pcplus4, idex_rd1, idex_rd2, idex_signzeroimm;
    wire [4:0]  idex_rs, idex_rt, idex_writereg;
    wire        idex_regwrite, idex_memtoreg, idex_memwrite, idex_alusrc;
    wire [3:0]  idex_alucontrol;
    wire        idex_branch;
    wire [4:0]  idex_shamt;

    id_ex u_id_ex (
        .clk(clk),
        .reset(reset),
        .stall(stall_hazard),
        .flush(flush_hazard | flush_ifid),
        .pcplus4_in(ifid_pcplus4),
        .read_data1_in(reg_rd1_id),
        .read_data2_in(reg_rd2_id),
        .signzeroimm_in(signzeroimm_id),
        .rs_in(ifid_instr[25:21]),
        .rt_in(ifid_instr[20:16]),
        .writereg_in(id_writereg),
        .regwrite_in(id_regwrite),
        .memtoreg_in(id_memtoreg),
        .memwrite_in(id_memwrite),
        .branch_in(id_is_beq),           // opcode compare for BEQ
        .alusrc_in(id_alusrc),
        .alucontrol_in(id_alucontrol),
        .shamt_in(ifid_instr[10:6]),
        .pcplus4_out(idex_pcplus4),
        .read_data1_out(idex_rd1),
        .read_data2_out(idex_rd2),
        .signzeroimm_out(idex_signzeroimm),
        .rs_out(idex_rs),
        .rt_out(idex_rt),
        .writereg_out(idex_writereg),
        .regwrite_out(idex_regwrite),
        .memtoreg_out(idex_memtoreg),
        .memwrite_out(idex_memwrite),
        .branch_out(idex_branch),
        .alusrc_out(idex_alusrc),
        .alucontrol_out(idex_alucontrol),
        .shamt_out(idex_shamt)
    );

    // ---------- EX stage: forwarding + ALU moved to ex_unit ----------
    wire [31:0] exmem_alu_result;
    wire [31:0] exmem_write_data;
    wire [4:0]  exmem_writereg;
    wire        exmem_regwrite;
    wire        exmem_memtoreg;
    wire        exmem_memwrite;
    wire        exmem_branch;

    wire [31:0] memwb_readdata;
    wire [31:0] memwb_alu_result;
    wire [4:0]  memwb_writereg;
    wire        memwb_regwrite;
    wire        memwb_memtoreg;
    

    // ALU outputs moved out from top into ex_unit; keep same signal names used by ex_mem
    wire [31:0] alu_result_ex;
    wire [31:0] alu_muxB_pre;

    ex_unit u_ex_unit (
        .idex_pcplus4(idex_pcplus4),
        .idex_rd1(idex_rd1),
        .idex_rd2(idex_rd2),
        .idex_signzeroimm(idex_signzeroimm),
        .idex_rs(idex_rs),
        .idex_rt(idex_rt),
        .idex_alusrc(idex_alusrc),
        .idex_alucontrol(idex_alucontrol),
        .idex_shamt(idex_shamt),
        .idex_branch(idex_branch),

        .exmem_regwrite(exmem_regwrite),
        .exmem_rd(exmem_writereg),
        .exmem_alu_result(exmem_alu_result),

        .memwb_regwrite(memwb_regwrite),
        .memwb_rd(memwb_writereg),
        .memwb_memtoreg(memwb_memtoreg),
        .memwb_readdata(memwb_readdata),
        .memwb_alu_result(memwb_alu_result),

        .alu_result_ex(alu_result_ex),
        .alu_muxB_pre(alu_muxB_pre),
        .branch_taken(branch_taken),
        .branch_target_calc(branch_target_ex)
    );

    // ---------- EX/MEM pipeline register ----------
    ex_mem u_ex_mem (
        .clk(clk),
        .reset(reset),
        .alu_result_in(alu_result_ex),
        .write_data_in(alu_muxB_pre),
        .writereg_in(idex_writereg),
        .regwrite_in(idex_regwrite),
        .memtoreg_in(idex_memtoreg),
        .memwrite_in(idex_memwrite),
        .branch_in(idex_branch),
        .alu_result_out(exmem_alu_result),
        .write_data_out(exmem_write_data),
        .writereg_out(exmem_writereg),
        .regwrite_out(exmem_regwrite),
        .memtoreg_out(exmem_memtoreg),
        .memwrite_out(exmem_memwrite),
        .branch_out(exmem_branch)
    );

    // ---------- MEM stage: data memory ----------
    assign dataadr  = exmem_alu_result;
    assign writedata = exmem_write_data;
    assign memwrite = exmem_memwrite;

    wire [31:0] mem_readdata;
    dmem u_dmem (
        .clk(clk),
        .reset(reset),
        .we(exmem_memwrite),
        .a(exmem_alu_result),
        .wd(exmem_write_data),
        .rd(mem_readdata)
    );

    // ---------- MEM/WB pipeline register ----------
    mem_wb u_mem_wb (
        .clk(clk),
        .reset(reset),
        .readdata_in(mem_readdata),
        .alu_result_in(exmem_alu_result),
        .writereg_in(exmem_writereg),
        .regwrite_in(exmem_regwrite),
        .memtoreg_in(exmem_memtoreg),
        .readdata_out(memwb_readdata),
        .alu_result_out(memwb_alu_result),
        .writereg_out(memwb_writereg),
        .regwrite_out(memwb_regwrite),
        .memtoreg_out(memwb_memtoreg)
    );

    // ---------- WB stage: move selection into wb_mux ----------
    wb_mux u_wb_mux (
        .memwb_regwrite(memwb_regwrite),
        .memwb_writereg(memwb_writereg),
        .memwb_memtoreg(memwb_memtoreg),
        .memwb_readdata(memwb_readdata),
        .memwb_alu_result(memwb_alu_result),
        .wb_regwrite(wb_regwrite),
        .wb_writereg(wb_writereg),
        .wb_writedata(wb_writedata)
    );

    // ---------- Hazard detection ----------
    hazard u_hazard (
        .ifid_rs(ifid_instr[25:21]),
        .ifid_rt(ifid_instr[20:16]),
        .idex_rt(idex_rt),
        .idex_memtoreg(idex_memtoreg),
        .stall(stall_hazard),
        .flush(flush_hazard)
    );

    // drive flush_branch from EX branch resolution
    assign flush_branch = branch_taken;

endmodule