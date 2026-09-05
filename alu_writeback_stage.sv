//================================================================================
// Module: alu_writeback_stage
// Description: Pipeline Stage 3 - Writeback Stage
//              Provides final registered results and handles output handshake
//================================================================================

module alu_writeback_stage
    import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Clock and Reset
    input  logic                 clk,
    input  logic                 rst_n,

    // Input from Stage 2
    input  stage2_reg_t          stage2_in,

    // Output Interface (Valid/Ready Handshake)
    output logic                 out_valid,
    input  logic                 out_ready,

    // Output Results
    output logic [DATA_WIDTH-1:0] result,

    // Destination Address Output (for downstream hazard detection)
    output logic [REG_ADDR_WIDTH-1:0] dest_addr,

    // Individual Flag Outputs
    output logic                 zero,
    output logic                 carry,
    output logic                 overflow,
    output logic                 negative,
    output logic                 parity,
    output logic                 saturation,

    // Stage valid signal (for forwarding/hazard detection)
    output logic                 stage3_valid,

    // Pipeline stall signal (backpressure from output)
    output logic                 stall
);

//================================================================================
// Internal Signals
//================================================================================
logic [DATA_WIDTH-1:0]       result_reg;
logic [FLAG_WIDTH-1:0]       flags_reg;
logic [REG_ADDR_WIDTH-1:0]   dest_addr_reg;
logic                         valid_reg;

//================================================================================
// Stall Logic
//================================================================================
// Generate backpressure when output is valid but downstream is not ready
assign stall = valid_reg & ~out_ready;

//================================================================================
// Stage 3 Pipeline Register (Output Register)
//================================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        result_reg    <= '0;
        flags_reg     <= '0;
        dest_addr_reg <= '0;
        valid_reg     <= 1'b0;
    end else if (!stall) begin
        if (stage2_in.valid) begin
            result_reg    <= stage2_in.result;
            flags_reg     <= stage2_in.flags;
            dest_addr_reg <= stage2_in.dest_addr;
            valid_reg     <= 1'b1;
        end else begin
            // No valid input from stage 2, create bubble
            valid_reg <= 1'b0;
        end
    end
    // When stalled, maintain current register values
end

//================================================================================
// Output Assignments
//================================================================================
assign out_valid    = valid_reg;
assign result       = result_reg;
assign dest_addr    = dest_addr_reg;
assign stage3_valid = valid_reg;

// Extract individual flags from packed format
// Flag order: {zero, carry, overflow, negative, parity, saturation}
assign zero       = flags_reg[FLAG_ZERO];
assign carry      = flags_reg[FLAG_CARRY];
assign overflow   = flags_reg[FLAG_OVERFLOW];
assign negative   = flags_reg[FLAG_NEGATIVE];
assign parity     = flags_reg[FLAG_PARITY];
assign saturation = flags_reg[FLAG_SATURATION];

endmodule : alu_writeback_stage
