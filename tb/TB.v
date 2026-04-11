// Full testbench (cleaned & updated to match cleaned top): tb_combined
// Note: replaced dut.idex_jump (removed from design) with dut.id_jump_any

module tb_combined;
    reg clk;
    reg reset;

    // top DUT signals (match your top ports)
    wire [31:0] writedata;
    wire [31:0] dataadr;
    wire        memwrite;
    wire [31:0] pc;

    // instantiate device under test
    top dut (
        .clk(clk),
        .reset(reset),
        .writedata(writedata),
        .dataadr(dataadr),
        .memwrite(memwrite),
        .pc(pc)
    );

    // clock generator (10 ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // waveform dump (Icarus / ModelSim)
    initial begin
        $dumpfile("trace.vcd");
        // dump entire DUT
        $dumpvars(0, dut);

        // useful nested instances (adjusted for ex_unit housing forwarding & alu)
        $dumpvars(0, dut.u_if_id);
        $dumpvars(0, dut.u_id_ex);
        $dumpvars(0, dut.u_ex_mem);
        $dumpvars(0, dut.u_mem_wb);
        // forwarding and alu now live inside ex_unit
        $dumpvars(0, dut.u_ex_unit.u_forwarding);
        $dumpvars(0, dut.u_ex_unit.u_alu);
        $dumpvars(0, dut.u_hazard);
        $dumpvars(0, dut.u_dmem);
        $dumpvars(0, dut.u_regfile);
        $dumpvars(0, dut.u_jump_unit);
        $dumpvars(0, dut.u_ex_unit);
        $dumpvars(0, dut.u_wb_mux);
    end

    // --- Memory dump task ---
    task dump_data_memory;
        integer i;
        begin
            $display("\n----- DATA MEMORY DUMP (word indices 0..63) -----");
            $display(" Index | ByteAddr |    Value (hex)   ");
            $display("-----------------------------------------");
            for (i = 0; i < 64; i = i + 1) begin
                $display(" %3d   |  %3d     | 0x%08x", i, i*4, dut.u_dmem.RAM[i]);
            end
            $display("-----------------------------------------\n");
        end
    endtask

    // helper to format forwarding signals as text
    function [8*32:1] format_forwarding;
        input [1:0] fa;
        input [1:0] fb;
        reg [8*32:1] s;
        begin
            s = "";
            if (fa == 2'b00 && fb == 2'b00) begin
                s = "NONE";
            end else begin
                if (fa != 2'b00) begin
                    s = {s, "A->"};
                    case (fa)
                        2'b10: s = {s, "EX/MEM "};
                        2'b01: s = {s, "MEM/WB "};
                        default: s = {s, "?? "};
                    endcase
                end
                if (fb != 2'b00) begin
                    s = {s, "B->"};
                    case (fb)
                        2'b10: s = {s, "EX/MEM"};
                        2'b01: s = {s, "MEM/WB"};
                        default: s = {s, "??  "};
                    endcase
                end
            end
            format_forwarding = s;
        end
    endfunction

    integer cyc;
    integer Ncycles;
    integer i;

    initial begin
        Ncycles = 30;

        // -------------------------
        // Startup: keep reset asserted so asynchronous reset drives DUT to 0
        // Print Cycle 1 PRE-EDGE while reset is asserted -> PC shows 0
        // Then deassert reset and run remaining cycles (pre-edge prints each cycle)
        // -------------------------
        reset = 1;        // assert asynchronous reset immediately
        cyc = 0;
        #1;               // small delta so reset propagates combinationally

        // Cycle 1 snapshot while reset is asserted (pre-edge)
        $display("STARTUP SNAPSHOT: time=%0t  PC=0x%08h  IF_instr=0x%08h  IF/ID_instr=0x%08h",
                 $time, dut.pc, dut.instr, dut.ifid_instr);

        // initial pre-edge, compact snapshot for cycle 0
        $display("===========================================================================");
        $display("CYCLE %0d   TIME=%0t   PC=0x%08h ", cyc, $time, dut.pc);
        $display("---------------------------------------------------------------------------");

        // Compact per-cycle pipeline snapshot (cleaned & reformatted)
        $display("IF:    instr=0x%08h    IF/ID: instr=0x%08h",
                 dut.instr, dut.ifid_instr);

        $display("ID/EX: pc+4=0x%08h  rs=%2d  rt=%2d  rd=%2d  shamt=%2d  | rd1=0x%08h  rd2=0x%08h  signimm=0x%08h",
                 dut.idex_pcplus4, dut.idex_rs, dut.idex_rt, dut.idex_writereg, dut.idex_shamt,
                 dut.idex_rd1, dut.idex_rd2, dut.idex_signzeroimm);

        $display("       CTRL: alu=%b  alusrc=%b  branch=%b  jump=%b",
                 dut.idex_alucontrol, dut.idex_alusrc, dut.idex_branch, dut.id_jump_any);

        $display("EX/MEM: alu_res=0x%08h  write_data=0x%08h  writereg=%2d  | memwrite=%b  memtoreg=%b  branch=%b",
                 dut.exmem_alu_result, dut.exmem_write_data, dut.exmem_writereg,
                 dut.exmem_memwrite, dut.exmem_memtoreg, dut.exmem_branch);

        $display("MEM/WB: readdata=0x%08h  alu_res=0x%08h  writereg=%2d  regwrite=%b  memtoreg=%b",
                 dut.memwb_readdata, dut.memwb_alu_result, dut.memwb_writereg, dut.memwb_regwrite, dut.memwb_memtoreg);

        $display("HAZARD: stall=%b  flush_hazard=%b  flush_branch=%b  branch_taken=%b",
                 dut.stall_hazard, dut.flush_hazard, dut.flush_branch, dut.branch_taken);

        // forwarding signals are internal to ex_unit; access via hierarchical path
        $display("FORWARD: A=%b  B=%b   %s",
                 dut.u_ex_unit.forwardA, dut.u_ex_unit.forwardB,
                 format_forwarding(dut.u_ex_unit.forwardA, dut.u_ex_unit.forwardB));

        $display("WB: we=%b  wa=%2d  wd=0x%08h    MEM_IF: memwrite=%b  dataadr=0x%08h  writedata=0x%08h  mem_readdata=0x%08h",
                 dut.wb_regwrite, dut.wb_writereg, dut.wb_writedata,
                 dut.memwrite, dut.dataadr, dut.writedata, dut.mem_readdata);

        $display("----- cycle %0d (time=%0t) -----", cyc, $time);
        $display("$zero: %08x  $at: %08x  $v0: %08x  $v1: %08x",
                 dut.u_regfile.rf[0], dut.u_regfile.rf[1], dut.u_regfile.rf[2], dut.u_regfile.rf[3]);
        $display("$a0:   %08x  $a1:   %08x  $a2:   %08x  $a3:   %08x",
                 dut.u_regfile.rf[4], dut.u_regfile.rf[5], dut.u_regfile.rf[6], dut.u_regfile.rf[7]);
        $display("$t0:   %08x  $t1:   %08x  $t2:   %08x  $t3:   %08x",
                 dut.u_regfile.rf[8], dut.u_regfile.rf[9], dut.u_regfile.rf[10], dut.u_regfile.rf[11]);
        $display("$t4:   %08x  $t5:   %08x  $t6:   %08x  $t7:   %08x",
                 dut.u_regfile.rf[12], dut.u_regfile.rf[13], dut.u_regfile.rf[14], dut.u_regfile.rf[15]);
        $display("$s0:   %08x  $s1:   %08x  $s2:   %08x  $s3:   %08x",
                 dut.u_regfile.rf[16], dut.u_regfile.rf[17], dut.u_regfile.rf[18], dut.u_regfile.rf[19]);
        $display("$s4:   %08x  $s5:   %08x  $s6:   %08x  $s7:   %08x",
                 dut.u_regfile.rf[20], dut.u_regfile.rf[21], dut.u_regfile.rf[22], dut.u_regfile.rf[23]);
        $display("$t8:   %08x  $t9:   %08x  $k0:   %08x  $k1:   %08x",
                 dut.u_regfile.rf[24], dut.u_regfile.rf[25], dut.u_regfile.rf[26], dut.u_regfile.rf[27]);
        $display("$gp:   %08x  $sp:   %08x  $fp:   %08x  $ra:   %08x",
                 dut.u_regfile.rf[28], dut.u_regfile.rf[29], dut.u_regfile.rf[30], dut.u_regfile.rf[31]);
        $display(""); // blank line

        // Now release reset and run remaining cycles
        reset = 0;
        #1; // settle after deasserting reset

        for (i = 1; i <= Ncycles; i = i + 1) begin
            cyc = i;

            // Compact per-cycle pipeline snapshot (cleaned & reformatted)
            $display("===========================================================================");
            $display("CYCLE %0d   TIME=%0t   PC=0x%08h ", cyc, $time, dut.pc);
            $display("---------------------------------------------------------------------------");

            $display("IF:    instr=0x%08h    IF/ID: instr=0x%08h",
                     dut.instr, dut.ifid_instr);

            $display("ID/EX: pc+4=0x%08h  rs=%2d  rt=%2d  rd=%2d  shamt=%2d  | rd1=0x%08h  rd2=0x%08h  signimm=0x%08h",
                     dut.idex_pcplus4, dut.idex_rs, dut.idex_rt, dut.idex_writereg, dut.idex_shamt,
                     dut.idex_rd1, dut.idex_rd2, dut.idex_signzeroimm);

            $display("       CTRL: alu=%b  alusrc=%b  branch=%b  jump=%b",
                     dut.idex_alucontrol, dut.idex_alusrc, dut.idex_branch, dut.id_jump_any);

            $display("EX/MEM: alu_res=0x%08h  write_data=0x%08h  writereg=%2d  | memwrite=%b  memtoreg=%b  branch=%b",
                     dut.exmem_alu_result, dut.exmem_write_data, dut.exmem_writereg,
                     dut.exmem_memwrite, dut.exmem_memtoreg, dut.exmem_branch);

            $display("MEM/WB: readdata=0x%08h  alu_res=0x%08h  writereg=%2d  regwrite=%b  memtoreg=%b",
                     dut.memwb_readdata, dut.memwb_alu_result, dut.memwb_writereg, dut.memwb_regwrite, dut.memwb_memtoreg);

            $display("HAZARD: stall=%b  flush_hazard=%b  flush_branch=%b  branch_taken=%b",
                     dut.stall_hazard, dut.flush_hazard, dut.flush_branch, dut.branch_taken);

            $display("FORWARD: A=%b  B=%b   %s",
                     dut.u_ex_unit.forwardA, dut.u_ex_unit.forwardB,
                     format_forwarding(dut.u_ex_unit.forwardA, dut.u_ex_unit.forwardB));

            $display("WB: we=%b  wa=%2d  wd=0x%08h    MEM_IF: memwrite=%b  dataadr=0x%08h  writedata=0x%08h  mem_readdata=0x%08h",
                     dut.wb_regwrite, dut.wb_writereg, dut.wb_writedata,
                     dut.memwrite, dut.dataadr, dut.writedata, dut.mem_readdata);

            // Original detailed register printing (kept for convenience)
            $display("----- cycle %0d (time=%0t) -----", cyc, $time);
            $display("$zero: %08x  $at: %08x  $v0: %08x  $v1: %08x",
                     dut.u_regfile.rf[0], dut.u_regfile.rf[1], dut.u_regfile.rf[2], dut.u_regfile.rf[3]);
            $display("$a0:   %08x  $a1:   %08x  $a2:   %08x  $a3:   %08x",
                     dut.u_regfile.rf[4], dut.u_regfile.rf[5], dut.u_regfile.rf[6], dut.u_regfile.rf[7]);
            $display("$t0:   %08x  $t1:   %08x  $t2:   %08x  $t3:   %08x",
                     dut.u_regfile.rf[8], dut.u_regfile.rf[9], dut.u_regfile.rf[10], dut.u_regfile.rf[11]);
            $display("$t4:   %08x  $t5:   %08x  $t6:   %08x  $t7:   %08x",
                     dut.u_regfile.rf[12], dut.u_regfile.rf[13], dut.u_regfile.rf[14], dut.u_regfile.rf[15]);
            $display("$s0:   %08x  $s1:   %08x  $s2:   %08x  $s3:   %08x",
                     dut.u_regfile.rf[16], dut.u_regfile.rf[17], dut.u_regfile.rf[18], dut.u_regfile.rf[19]);
            $display("$s4:   %08x  $s5:   %08x  $s6:   %08x  $s7:   %08x",
                     dut.u_regfile.rf[20], dut.u_regfile.rf[21], dut.u_regfile.rf[22], dut.u_regfile.rf[23]);
            $display("$t8:   %08x  $t9:   %08x  $k0:   %08x  $k1:   %08x",
                     dut.u_regfile.rf[24], dut.u_regfile.rf[25], dut.u_regfile.rf[26], dut.u_regfile.rf[27]);
            $display("$gp:   %08x  $sp:   %08x  $fp:   %08x  $ra:   %08x",
                     dut.u_regfile.rf[28], dut.u_regfile.rf[29], dut.u_regfile.rf[30], dut.u_regfile.rf[31]);
            $display(""); // blank line

            // Advance clock after printing to move pipeline for next pre-edge snapshot
            @(posedge clk);
            #1;
        end

        // after running cycles, dump memory contents
        #1; // ensure last instructions have settled
        dump_data_memory();

        $display("Finished printing registers and memory; stopping simulation.");
        $stop;
    end

endmodule
