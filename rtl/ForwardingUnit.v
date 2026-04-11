module forwarding (
    input  [4:0] idex_rs,       // source register A in EX stage
    input  [4:0] idex_rt,       // source register B in EX stage
    input        exmem_regwrite, // EX/MEM write enable
    input  [4:0] exmem_rd,      // EX/MEM destination register
    input        memwb_regwrite, // MEM/WB write enable
    input  [4:0] memwb_rd,      // MEM/WB destination register
    output reg [1:0] forwardA,  // select for ALU operand A
    output reg [1:0] forwardB   // select for ALU operand B
);

    always @(*) begin
        // default: take operands from ID/EX registers
        forwardA = 2'b00;
        forwardB = 2'b00;

        // forward from EX/MEM if it writes to the needed register
        if (exmem_regwrite && (exmem_rd != 0) && (exmem_rd == idex_rs))
            forwardA = 2'b10;
        if (exmem_regwrite && (exmem_rd != 0) && (exmem_rd == idex_rt))
            forwardB = 2'b10;

        // forward from MEM/WB if EX/MEM did not already forward
        if (memwb_regwrite && (memwb_rd != 0) &&
            !(exmem_regwrite && (exmem_rd != 0) && (exmem_rd == idex_rs)) &&
            (memwb_rd == idex_rs))
            forwardA = 2'b01;

        if (memwb_regwrite && (memwb_rd != 0) &&
            !(exmem_regwrite && (exmem_rd != 0) && (exmem_rd == idex_rt)) &&
            (memwb_rd == idex_rt))
            forwardB = 2'b01;
    end
endmodule