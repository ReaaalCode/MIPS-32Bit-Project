module aludec (
    input  [5:0] op,             // opcode (used for I-type logic ops)
    input  [5:0] funct,          // function code for R-type ops
    input  [1:0] aluop,          // ALU operation type from main decoder
    output reg [3:0] alucontrol  // final ALU control signal
);

    always @(*) begin
        case (aluop)
            2'b00: begin
                // use ADD for load, store, and add-immediate
                alucontrol = 4'b0010;
            end

            2'b01: begin
                // use SUB for beq comparison
                alucontrol = 4'b0110;
            end

            2'b10: begin
                // R-type instructions: choose based on funct field
                case (funct)
                    6'b100000: alucontrol = 4'b0010; // ADD
                    6'b100010: alucontrol = 4'b0110; // SUB
                    6'b100100: alucontrol = 4'b0000; // AND
                    6'b100101: alucontrol = 4'b0001; // OR
                    6'b100110: alucontrol = 4'b1001; // XOR
                    6'b100111: alucontrol = 4'b1100; // NOR
                    6'b101010: alucontrol = 4'b0111; // SLT
                    6'b000000: alucontrol = 4'b0011; // SLL
                    6'b000010: alucontrol = 4'b0100; // SRL
                    6'b000011: alucontrol = 4'b0101; // SRA
                    default:   alucontrol = 4'b0010;
                endcase
            end

            2'b11: begin
                // I-type logic operations: choose based on opcode
                case (op)
                    6'b001100: alucontrol = 4'b0000; // ANDI
                    6'b001101: alucontrol = 4'b0001; // ORI
                    6'b001110: alucontrol = 4'b1001; // XORI
                    default:   alucontrol = 4'b0010;
                endcase
            end

            default: begin
                alucontrol = 4'b0010;
            end
        endcase
    end
endmodule