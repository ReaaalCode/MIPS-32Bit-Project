module hazard (
    input  [4:0] ifid_rs,       // source registers from IF/ID stage
    input  [4:0] ifid_rt,
    input  [4:0] idex_rt,       // destination register from ID/EX stage
    input        idex_memtoreg, // 1 if ID/EX instruction is a load
    output reg   stall,          // 1 = stall pipeline
    output reg   flush           // 1 = insert bubble
);
    always @(*) begin
        stall = 0;
        flush = 0;
        // Check load-use hazard: ID/EX is load and destination matches IF/ID sources
        if (idex_memtoreg && (idex_rt != 5'd0) && ((idex_rt == ifid_rs) || (idex_rt == ifid_rt))) begin
            stall = 1;
            flush = 1;
        end
    end
endmodule
