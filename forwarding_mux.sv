//------------------------------------------------------------------------------
// Module: forwarding_mux
// Description: Forwarding Multiplexer for ALU Pipeline
//              Selects between input operand and forwarded results from
//              later pipeline stages to resolve data hazards
//------------------------------------------------------------------------------

module forwarding_mux
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Input operand (from register file or external source)
    input logic [DATA_WIDTH-1:0] operand_in,

    // Forwarded values from pipeline stages
    input logic [DATA_WIDTH-1:0] stage2_result,  // Result from execute stage
    input logic [DATA_WIDTH-1:0] stage3_result,  // Result from writeback stage

    // Forwarding select signal from hazard detection unit
    input fwd_sel_t fwd_sel,

    // Output operand (after forwarding)
    output logic [DATA_WIDTH-1:0] operand_out
);

//==============================================================================
// Forwarding Multiplexer Logic
//==============================================================================
// Priority: Stage 2 (most recent) > Stage 3 > No forwarding
//==============================================================================

always_comb begin
    case (fwd_sel)
        FWD_NONE:   operand_out = operand_in;       // No forwarding needed
        FWD_STAGE2: operand_out = stage2_result;    // Forward from execute stage
        FWD_STAGE3: operand_out = stage3_result;    // Forward from writeback stage
        default:    operand_out = operand_in;       // Default: use input operand
    endcase
end

endmodule : forwarding_mux
