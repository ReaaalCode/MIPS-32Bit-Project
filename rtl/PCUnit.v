module pc_unit (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,          // stall_hazard from hazard unit
    input  wire        id_jump_any,    // id_jump | id_is_jr
    input  wire        branch_taken,   // computed in EX (idex_branch & alu_zero_ex)
    input  wire [31:0] branch_target,  // branch_target_ex (from EX stage)
    input  wire [31:0] jump_target,    // full jump target (J target or JR value)
    output wire [31:0] pc,             // exposed PC
    output wire [31:0] pc_plus4,       // pc + 4 for IF/ID
    output wire [5:0]  imem_addr       // pc[7:2] for 64-word IMEM
);

    reg [31:0] pc_reg;

    assign pc_plus4 = pc_reg + 32'd4;
    wire [31:0] next_pc_default = pc_plus4;

    // priority: jump > branch > default
    wire [31:0] next_pc = id_jump_any ? jump_target
                       : (branch_taken ? branch_target : next_pc_default);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= 32'b0;
        end else if (!stall) begin
            pc_reg <= next_pc;
        end else begin
            pc_reg <= pc_reg;
        end
    end

    assign pc = pc_reg;
    assign imem_addr = pc_reg[7:2];

endmodule