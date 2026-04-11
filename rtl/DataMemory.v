module dmem (
    input        clk,      // clock
    input        reset,
    input        we,       // write enable
    input  [31:0] a,       // address
    input  [31:0] wd,      // data to write
    output [31:0] rd       // data read
);

    reg [31:0] RAM[63:0];  // 64-word memory
    integer i;

    // initialize memory to 0 at simulation start
    initial begin
        for (i = 0; i < 64; i = i + 1)
            RAM[i] = 32'h00000000;
    end

    // read word (word-aligned)
    assign rd = RAM[a[31:2]];

    // write data on rising edge if write enabled
    always @(posedge clk)
        if(reset) begin
            for (i = 0; i < 64; i = i + 1)
                RAM[i] = 32'h00000000;
        end else if (we)
            RAM[a[31:2]] <= wd;
endmodule