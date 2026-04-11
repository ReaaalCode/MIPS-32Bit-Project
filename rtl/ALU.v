module alu(
    input  [31:0] a,           // first input
    input  [31:0] b,           // second input
    input  [3:0]  alucontrol,  // operation selector
    input  [4:0]  shamt,       // shift amount for shift ops
    output reg [31:0] aluout,  // ALU result
    output         zero        // 1 if result is zero
);

    // signed version for comparisons like SLT
    wire signed [31:0] as = a;
    wire signed [31:0] bs = b;

    always @(*) begin
        case (alucontrol)
            4'b0000: aluout = a & b;           // AND
            4'b0001: aluout = a | b;           // OR
            4'b0010: aluout = a + b;           // ADD
            4'b0110: aluout = a - b;           // SUB
            4'b0111: aluout = (as < bs) ? 32'd1 : 32'd0; // SLT
            4'b1100: aluout = ~(a | b);        // NOR
            4'b1001: aluout = a ^ b;           // XOR
            4'b0011: aluout = b << shamt;      // SLL
            4'b0100: aluout = b >> shamt;      // SRL
            4'b0101: aluout = bs >>> shamt;    // SRA
            default: aluout = 32'd0;           // default to 0
        endcase
    end

    assign zero = (aluout == 32'b0);

endmodule