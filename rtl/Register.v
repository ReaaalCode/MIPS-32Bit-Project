module regfile (
    input        clk,            // clock input
    input        reset,
    input  [5:0] op,
    input        we3,            // write enable
    input  [4:0] ra1,            // read address 1
    input  [4:0] ra2,            // read address 2
    input  [4:0] ra3,
    input  [4:0] wa3,            // write address
    input  [31:0] wd3,           // write data
    output [31:0] rd1,           // read data 1
    output [31:0] rd2,            // read data 2
    output [4:0]  wao
);

    // 32 general-purpose registers
    reg [31:0] rf[31:0];
    integer i;

    // initialize all registers to zero
    initial begin
        for (i = 0; i < 32; i = i + 1)
            rf[i] = 32'h00000000;
    end

    // write to a register on the rising clock edge
    // register 0 always stays zero
    always @(posedge clk) begin
        if(reset) begin
        for (i = 0; i < 32; i = i + 1)
            rf[i] = 32'h00000000;        
        end else if (we3) begin
            if (wa3 != 5'd0)
                rf[wa3] <= wd3;
            else
                rf[0] <= 32'h00000000;
        end
    end

    // read port 1 with forwarding support
    assign rd1 = (ra1 == 5'd0) ? 32'h00000000 :
                 ((we3 && (wa3 == ra1)) ? wd3 : rf[ra1]);

    // read port 2 with forwarding
    assign rd2 = (ra2 == 5'd0) ? 32'h00000000 :
                 ((we3 && (wa3 == ra2)) ? wd3 : rf[ra2]);



    // Choose write register based on opcode (R-type -> rd, JAL -> $31, else rt)
    assign wao =
        (op == 6'b000000) ? ra3 : // R-type -> rd
        (op == 6'b000011) ? 5'd31 :             // JAL -> $31
                             ra2; // I-type -> rt
    

endmodule