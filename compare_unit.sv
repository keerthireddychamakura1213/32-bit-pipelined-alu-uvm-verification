//------------------------------------------------------------------------------
// Module: compare_unit
// Description: Comparison Unit for ALU
//              Implements SLT, SLTU, SGT, SEQ operations
//------------------------------------------------------------------------------

module compare_unit
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Operands
    input logic [DATA_WIDTH-1:0] operand_a,
    input logic [DATA_WIDTH-1:0] operand_b,

    // Operation select (opcode[1:0])
    input logic [1:0] op_sel,

    // Result (1 or 0)
    output logic [DATA_WIDTH-1:0] result
);

//==============================================================================
// Internal Signals
//==============================================================================
logic signed [DATA_WIDTH-1:0] signed_a;
logic signed [DATA_WIDTH-1:0] signed_b;

//==============================================================================
// Signed Conversion
//==============================================================================
assign signed_a = $signed(operand_a);
assign signed_b = $signed(operand_b);

//==============================================================================
// Operation Logic
//==============================================================================
always_comb begin
    case (op_sel)
        2'b00: begin // SLT - Set Less Than (Signed)
            result = (signed_a < signed_b) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
        end

        2'b01: begin // SLTU - Set Less Than Unsigned
            result = (operand_a < operand_b) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
        end

        2'b10: begin // SGT - Set Greater Than (Signed)
            result = (signed_a > signed_b) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
        end

        2'b11: begin // SEQ - Set Equal
            result = (operand_a == operand_b) ? {{(DATA_WIDTH-1){1'b0}}, 1'b1} : '0;
        end

        default: result = '0;
    endcase
end

endmodule : compare_unit
