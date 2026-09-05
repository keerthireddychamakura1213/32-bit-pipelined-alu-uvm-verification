//================================================================================
// Module: alu_execute_stage
// Description: Pipeline Stage 2 - Execute Stage
//              Performs ALU computation using alu_core and generates flags
//              using flag_generator, then registers results for writeback
//================================================================================

module alu_execute_stage
    import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Clock and Reset
    input  logic        clk,
    input  logic        rst_n,

    // Input from Stage 1
    input  stage1_reg_t stage1_in,

    // Pipeline stall control
    input  logic        stall,

    // Output to Writeback Stage (Stage 2 Register)
    output stage2_reg_t stage2_out,

    // Combinational result output (for forwarding)
    output logic [DATA_WIDTH-1:0] result_comb
);

//================================================================================
// Internal Signals
//================================================================================
logic [DATA_WIDTH-1:0] alu_result;
logic                  carry_out;
logic                  overflow_out;
logic                  saturation_out;

// Individual flags
logic                  zero_flag;
logic                  carry_flag;
logic                  overflow_flag;
logic                  negative_flag;
logic                  parity_flag;
logic                  saturation_flag;
logic [FLAG_WIDTH-1:0] flags_combined;

//================================================================================
// ALU Core Instantiation
//================================================================================
alu_core #(
    .DATA_WIDTH(DATA_WIDTH)
) u_alu_core (
    .operand_a      (stage1_in.operand_a),
    .operand_b      (stage1_in.operand_b),
    .opcode         (stage1_in.opcode),
    .carry_in       (stage1_in.carry_in),
    .result         (alu_result),
    .carry_out      (carry_out),
    .overflow_out   (overflow_out),
    .saturation_out (saturation_out)
);

//================================================================================
// Flag Generator Instantiation
//================================================================================
flag_generator #(
    .DATA_WIDTH(DATA_WIDTH)
) u_flag_generator (
    .result       (alu_result),
    .opcode       (stage1_in.opcode),
    .carry_in     (carry_out),
    .overflow_in  (overflow_out),
    .saturation_in(saturation_out),
    .zero         (zero_flag),
    .carry        (carry_flag),
    .overflow     (overflow_flag),
    .negative     (negative_flag),
    .parity       (parity_flag),
    .saturation   (saturation_flag),
    .flags        (flags_combined)
);

//================================================================================
// Combinational Result Output (for forwarding)
//================================================================================
assign result_comb = alu_result;

//================================================================================
// Stage 2 Pipeline Register
//================================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage2_out.result    <= '0;
        stage2_out.flags     <= '0;
        stage2_out.dest_addr <= '0;
        stage2_out.valid     <= 1'b0;
    end else if (!stall) begin
        if (stage1_in.valid) begin
            stage2_out.result    <= alu_result;
            stage2_out.flags     <= flags_combined;
            stage2_out.dest_addr <= stage1_in.dest_addr;
            stage2_out.valid     <= 1'b1;
        end else begin
            // No valid input from stage 1, create bubble
            stage2_out.valid <= 1'b0;
        end
    end
    // When stalled, maintain current register values
end

endmodule : alu_execute_stage
