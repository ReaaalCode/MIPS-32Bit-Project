module imem (
    input  [5:0]  a,
    input         reset,
    output [31:0] rd
);
    // Instruction memory (64 words)
    reg [31:0] RAM[63:0];
    integer i;

    // Initialize memory to zeros, then load program from file
    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 32'h00000000;
        $readmemh("memfile.dat", RAM);
    end

    // Output zero during reset, otherwise return instruction
    assign rd = reset ? 32'h00000000 : RAM[a];
endmodule