//=============================================================================
// Module: pipelined_alu_32bit
// Description: Top-level 32-bit Pipelined ALU Module
//              3-stage pipeline: Input -> Execute -> Writeback
// Features:
// - Valid/Ready handshake for input and output
// - Operand forwarding to eliminate pipeline bubbles
// - 32 operations across 8 functional units
// - 6 status flags: zero, carry, overflow, negative, parity, saturation
//=============================================================================

module pipelined_alu_32bit
import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Clock and Reset
    input  logic clk,
    input  logic rst_n,

    // Input Interface (Valid/Ready Handshake)
    input  logic in_valid,
    output logic in_ready,

    // Input Operands and Control
    input  logic [DATA_WIDTH-1:0] operand_a,
    input  logic [DATA_WIDTH-1:0] operand_b,
    input  logic [OPCODE_WIDTH-1:0] opcode,
    input  logic carry_in,

    // Register Addresses (for hazard detection and forwarding)
    input  logic [REG_ADDR_WIDTH-1:0] src_a_addr,   // Source register A address
    input  logic [REG_ADDR_WIDTH-1:0] src_b_addr,   // Source register B address
    input  logic [REG_ADDR_WIDTH-1:0] dest_addr,    // Destination register address

    // Output Interface (Valid/Ready Handshake)
    output logic out_valid,
    input  logic out_ready,

    // Output Results
    output logic [DATA_WIDTH-1:0] result,

    // Output Destination Address (for downstream hazard detection)
    output logic [REG_ADDR_WIDTH-1:0] result_dest_addr,

    // Status Flags (individual outputs for interface compatibility)
    output logic zero,
    output logic carry,
    output logic overflow,
    output logic negative,
    output logic parity,
    output logic saturation
);

//=============================================================================
// Internal Signals
//=============================================================================

// Pipeline stall signal
logic stall;

// Pipeline stage registers
stage1_reg_t stage1_reg;
stage2_reg_t stage2_reg;

// Stage valid signals for hazard detection
logic stage3_valid;

// Forwarding select signals
fwd_sel_t forward_a_sel;
fwd_sel_t forward_b_sel;

// Combinational result from execute stage (for forwarding)
logic [DATA_WIDTH-1:0] stage2_result_comb;

// Stage 3 result (registered, for forwarding)
logic [DATA_WIDTH-1:0] stage3_result;

// Destination addresses for hazard detection
logic [REG_ADDR_WIDTH-1:0] stage3_dest_addr;

//=============================================================================
// Hazard Detection and Forwarding
//=============================================================================

hazard_detect #(
    .DATA_WIDTH(DATA_WIDTH)
) u_hazard_detect (
    .stage1_valid       (in_valid & in_ready),
    .stage2_valid       (stage1_reg.valid),
    .stage3_valid       (stage2_reg.valid),
    .src_a_addr         (src_a_addr),
    .src_b_addr         (src_b_addr),
    .stage2_dest_addr   (stage1_reg.dest_addr),
    .stage3_dest_addr   (stage2_reg.dest_addr),
    .forward_a_sel      (forward_a_sel),
    .forward_b_sel      (forward_b_sel)
);

//=============================================================================
// Pipeline Stage 1: Input/Fetch/Decode
//=============================================================================

alu_input_stage #(
    .DATA_WIDTH(DATA_WIDTH)
) u_input_stage (
    .clk          (clk),
    .rst_n        (rst_n),
    .in_valid     (in_valid),
    .in_ready     (in_ready),
    .operand_a    (operand_a),
    .operand_b    (operand_b),
    .opcode       (opcode),
    .carry_in     (carry_in),
    .src_a_addr   (src_a_addr),
    .src_b_addr   (src_b_addr),
    .dest_addr    (dest_addr),
    .stage2_result(stage2_result_comb),
    .stage3_result(stage3_result),
    .forward_a_sel(forward_a_sel),
    .forward_b_sel(forward_b_sel),
    .stall        (stall),
    .stage1_out  (stage1_reg)
);

//=============================================================================
// Pipeline Stage 2: Execute
//=============================================================================

alu_execute_stage #(
    .DATA_WIDTH(DATA_WIDTH)
) u_execute_stage (
    .clk         (clk),
    .rst_n       (rst_n),
    .stage1_in   (stage1_reg),
    .stall       (stall),
    .stage2_out  (stage2_reg),
    .result_comb (stage2_result_comb)
);

//=============================================================================
// Pipeline Stage 3: Writeback
//=============================================================================

alu_writeback_stage #(
    .DATA_WIDTH(DATA_WIDTH)
) u_writeback_stage (
    .clk        (clk),
    .rst_n      (rst_n),
    .stage2_in  (stage2_reg),
    .out_valid  (out_valid),
    .out_ready  (out_ready),
    .result     (result),
    .dest_addr  (stage3_dest_addr),
    .zero       (zero),
    .carry      (carry),
    .overflow   (overflow),
    .negative   (negative),
    .parity     (parity),
    .saturation (saturation),
    .stage3_valid(stage3_valid),
    .stall      (stall)
);

// Stage 3 result for forwarding
// Use stage2_reg.result (not result_reg from writeback) so the forwarded value
// matches the instruction identified by stage3_dest_addr (= stage2_reg.dest_addr)
assign stage3_result = stage2_reg.result;

// Output destination address (for downstream use)
assign result_dest_addr = stage3_dest_addr;

endmodule : pipelined_alu_32bit
