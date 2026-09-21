//------------------------------------------------------------------------------
// Module: hazard_detect
// Description: Hazard Detection Unit for ALU Pipeline
//              Detects data hazards by comparing source register addresses
//              of the incoming instruction against destination addresses of
//              in-flight instructions in Stage 2 and Stage 3.
//              Generates forwarding select signals to resolve hazards.
//------------------------------------------------------------------------------

module hazard_detect
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Pipeline stage valid signals
    input logic                    stage1_valid, // Instruction entering decode
    input logic                    stage2_valid, // Instruction in execute stage
    input logic                    stage3_valid, // Instruction in writeback stage

    // Source register addresses (from incoming instruction)
    input logic [REG_ADDR_WIDTH-1:0] src_a_addr, // Source A register address
    input logic [REG_ADDR_WIDTH-1:0] src_b_addr, // Source B register address

    // Destination register addresses (from in-flight instructions)
    input logic [REG_ADDR_WIDTH-1:0] stage2_dest_addr, // Dest addr in execute stage
    input logic [REG_ADDR_WIDTH-1:0] stage3_dest_addr, // Dest addr in writeback stage

    // Forwarding select outputs
    output fwd_sel_t forward_a_sel,
    output fwd_sel_t forward_b_sel
);

//==============================================================================
// Hazard Detection Logic
//==============================================================================
// Compare source register addresses of the incoming instruction against
// destination addresses of instructions in Stage 2 and Stage 3.
//
// Priority: Stage 2 (most recent result) takes precedence over Stage 3
//
// Forwarding is only needed when:
// 1. The later stage has a valid instruction
// 2. The destination address matches the source address
// 3. The destination address is not register 0 (x0 is hardwired to 0)
//==============================================================================

//==============================================================================
// Hazard Signals for Operand A
//==============================================================================

logic hazard_a_stage2; // Operand A depends on Stage 2 result
logic hazard_a_stage3; // Operand A depends on Stage 3 result

// Stage 2 hazard: dest addr matches src_a and stage 2 is valid
// Exclude register 0 (always reads as zero, no forwarding needed)
assign hazard_a_stage2 = stage2_valid &&
                         (stage2_dest_addr == src_a_addr) &&
                         (src_a_addr != '0);

// Stage 3 hazard: dest addr matches src_a and stage 3 is valid
// Only matters if Stage 2 doesn't already have the value
assign hazard_a_stage3 = stage3_valid &&
                         (stage3_dest_addr == src_a_addr) &&
                         (src_a_addr != '0) &&
                         !hazard_a_stage2; // Stage 2 takes priority

//==============================================================================
// Hazard Signals for Operand B
//==============================================================================

logic hazard_b_stage2; // Operand B depends on Stage 2 result
logic hazard_b_stage3; // Operand B depends on Stage 3 result

// Stage 2 hazard: dest addr matches src_b and stage 2 is valid
assign hazard_b_stage2 = stage2_valid &&
                         (stage2_dest_addr == src_b_addr) &&
                         (src_b_addr != '0);

// Stage 3 hazard: dest addr matches src_b and stage 3 is valid
assign hazard_b_stage3 = stage3_valid &&
                         (stage3_dest_addr == src_b_addr) &&
                         (src_b_addr != '0) &&
                         !hazard_b_stage2; // Stage 2 takes priority

//==============================================================================
// Forwarding Select for Operand A
//==============================================================================

always_comb begin
    if (hazard_a_stage2) begin
        forward_a_sel = FWD_STAGE2; // Forward from execute stage (most recent)
    end else if (hazard_a_stage3) begin
        forward_a_sel = FWD_STAGE3; // Forward from writeback stage
    end else begin
        forward_a_sel = FWD_NONE;   // Use register value (no hazard)
    end
end

//==============================================================================
// Forwarding Select for Operand B
//==============================================================================

always_comb begin
    if (hazard_b_stage2) begin
        forward_b_sel = FWD_STAGE2; // Forward from execute stage (most recent)
    end else if (hazard_b_stage3) begin
        forward_b_sel = FWD_STAGE3; // Forward from writeback stage
    end else begin
        forward_b_sel = FWD_NONE;   // Use register value (no hazard)
    end
end

//==============================================================================
// Assertions (Synthesis Off)
//==============================================================================

`ifndef SYNTHESIS
    // Cover all forwarding combinations
    // Operand A forwarding from Stage 2
    cover property (@(posedge stage1_valid) forward_a_sel == FWD_STAGE2);
    // Operand A forwarding from Stage 3
    cover property (@(posedge stage1_valid) forward_a_sel == FWD_STAGE3);
    // Operand B forwarding from Stage 2
    cover property (@(posedge stage1_valid) forward_b_sel == FWD_STAGE2);
    // Operand B forwarding from Stage 3
    cover property (@(posedge stage1_valid) forward_b_sel == FWD_STAGE3);
    // Both operands forwarding simultaneously
    cover property (@(posedge stage1_valid)
                    (forward_a_sel != FWD_NONE) && (forward_b_sel != FWD_NONE));
`endif

endmodule : hazard_detect
