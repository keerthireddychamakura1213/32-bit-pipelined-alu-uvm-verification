//------------------------------------------------------------------------------
// Module: alu_input_stage
// Description: Pipeline Stage 1 - Input/Fetch/Decode Stage
//              Captures input operands and opcode, applies forwarding,
//              and registers data for the execute stage
//------------------------------------------------------------------------------

module alu_input_stage
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

    // Register Addresses (for hazard detection)
    input  logic [REG_ADDR_WIDTH-1:0] src_a_addr,
    input  logic [REG_ADDR_WIDTH-1:0] src_b_addr,
    input  logic [REG_ADDR_WIDTH-1:0] dest_addr,

    // Forwarded values from later pipeline stages
    input  logic [DATA_WIDTH-1:0] stage2_result,
    input  logic [DATA_WIDTH-1:0] stage3_result,

    // Forwarding select signals from hazard detection
    input  fwd_sel_t forward_a_sel,
    input  fwd_sel_t forward_b_sel,

    // Pipeline stall control
    input  logic stall,

    // Output to Execute Stage (Stage 1 Register)
    output stage1_reg_t stage1_out
);

//==============================================================================
// Internal Signals
//==============================================================================
logic [DATA_WIDTH-1:0] operand_a_fwd;
logic [DATA_WIDTH-1:0] operand_b_fwd;
logic                  accept_input;

//==============================================================================
// Forwarding Multiplexers
//==============================================================================

// Forwarding MUX for Operand A
forwarding_mux #(
    .DATA_WIDTH(DATA_WIDTH)
) u_fwd_mux_a (
    .operand_in   (operand_a),
    .stage2_result(stage2_result),
    .stage3_result(stage3_result),
    .fwd_sel      (forward_a_sel),
    .operand_out  (operand_a_fwd)
);

// Forwarding MUX for Operand B
forwarding_mux #(
    .DATA_WIDTH(DATA_WIDTH)
) u_fwd_mux_b (
    .operand_in   (operand_b),
    .stage2_result(stage2_result),
    .stage3_result(stage3_result),
    .fwd_sel      (forward_b_sel),
    .operand_out  (operand_b_fwd)
);

//==============================================================================
// Ready/Accept Logic
//==============================================================================
// Ready to accept new input when not stalled
assign in_ready     = ~stall;
assign accept_input = in_valid & in_ready;

//==============================================================================
// Stage 1 Pipeline Register
//==============================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        stage1_out.operand_a   <= '0;
        stage1_out.operand_b   <= '0;
        stage1_out.opcode      <= '0;
        stage1_out.carry_in    <= 1'b0;
        stage1_out.src_a_addr  <= '0;
        stage1_out.src_b_addr  <= '0;
        stage1_out.dest_addr   <= '0;
        stage1_out.valid       <= 1'b0;
    end else if (!stall) begin
        if (accept_input) begin
            stage1_out.operand_a  <= operand_a_fwd;
            stage1_out.operand_b  <= operand_b_fwd;
            stage1_out.opcode     <= opcode;
            stage1_out.carry_in   <= carry_in;
            stage1_out.src_a_addr <= src_a_addr;
            stage1_out.src_b_addr <= src_b_addr;
            stage1_out.dest_addr  <= dest_addr;
            stage1_out.valid      <= 1'b1;
        end else begin
            // No valid input, create bubble
            stage1_out.valid <= 1'b0;
        end
    end
    // When stalled, maintain current register values
end

endmodule : alu_input_stage
