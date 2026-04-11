module signzeroext(
    input  [15:0] imm16,       // 16-bit immediate input
    input         zeroext,     // 1 = zero-extend, 0 = sign-extend
    output [31:0] imm32        // 32-bit extended output
);

    assign imm32 = zeroext ? {16'b0, imm16} : {{16{imm16[15]}}, imm16};

endmodule
