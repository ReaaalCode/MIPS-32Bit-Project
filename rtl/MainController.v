module maindec (
    input  [5:0] op,        // instruction opcode
    output       memtoreg,  // choose memory output for register write
    output       memwrite,  // enable memory write
    output       alusrc,    // select immediate for ALU input
    output       zeroext,   // use zero-extend for logical immediates
    output       regwrite,  // enable write to register file
    output       jump,      // jump instruction flag
    output [1:0] aluop      // tells ALU decoder which operation type
);

    reg [7:0] controls;     // holds all control bits in one register

    // unpack control bits into individual signals
    // mapping: {regwrite, alusrc, zeroext, memwrite, memtoreg, jump, aluop}
    assign {regwrite, alusrc, zeroext, memwrite, memtoreg, jump, aluop} = controls;

    always @(*) begin
        // set control signals based on opcode value
        case (op)
            6'b000000: controls = 8'b10000010; // R-type: regwrite, aluop=10
            6'b100011: controls = 8'b11001000; // LW: regwrite, alusrc, memtoreg
            6'b101011: controls = 8'b01010000; // SW: alusrc, memwrite
            6'b000100: controls = 8'b00000001; // BEQ: aluop=01
            6'b001000: controls = 8'b11000000; // ADDI: regwrite, alusrc
            6'b000010: controls = 8'b00000100; // JUMP: jump=1
            6'b001100: controls = 8'b11100011; // ANDI: regwrite, alusrc, zeroext, aluop=11
            6'b001101: controls = 8'b11100011; // ORI
            6'b001110: controls = 8'b11100011; // XORI
            default:   controls = 8'b00000000; // default safe state
        endcase
    end

endmodule