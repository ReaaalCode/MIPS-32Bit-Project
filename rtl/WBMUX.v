module wb_mux(
    input  wire        memwb_regwrite,
    input  wire [4:0]  memwb_writereg,
    input  wire        memwb_memtoreg,
    input  wire [31:0] memwb_readdata,
    input  wire [31:0] memwb_alu_result,
    output wire        wb_regwrite,
    output wire [4:0]  wb_writereg,
    output wire [31:0] wb_writedata
);
    assign wb_regwrite = memwb_regwrite;
    assign wb_writereg = memwb_writereg;
    assign wb_writedata = memwb_memtoreg ? memwb_readdata : memwb_alu_result;
endmodule