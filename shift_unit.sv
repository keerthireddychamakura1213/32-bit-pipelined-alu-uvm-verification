//------------------------------------------------------------------------------
 // Module: shift_unit
 // Description: Shift Unit for ALU
 //              Implements SLL, SRL, SRA, ROR operations
//------------------------------------------------------------------------------

module shift_unit
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Operands
    input logic [DATA_WIDTH-1:0] operand_a,  // Value to shift
    input logic [DATA_WIDTH-1:0] operand_b,  // Shift amount (uses lower 5 bits)

    // Operation select (opcode[1:0])
    input logic [1:0] op_sel,

    // Result
    output logic [DATA_WIDTH-1:0] result
);

//==============================================================================
// Internal Signals
//==============================================================================
logic [4:0] shift_amt;
logic signed [DATA_WIDTH-1:0] signed_a;

//==============================================================================
// Shift Amount
//==============================================================================
assign shift_amt = operand_b[4:0];
assign signed_a = $signed(operand_a);

//==============================================================================
// Operation Logic
//==============================================================================
always_comb begin
    case (op_sel)
        2'b00: begin // SLL - Shift Left Logical
            result = operand_a << shift_amt;
        end

        2'b01: begin // SRL - Shift Right Logical
            result = operand_a >> shift_amt;
        end

        2'b10: begin // SRA - Shift Right Arithmetic
            result = signed_a >>> shift_amt;
        end

        2'b11: begin // ROR - Rotate Right
            if (shift_amt == 0) begin
                result = operand_a;
            end else begin
                result = (operand_a >> shift_amt) |
                         (operand_a << (DATA_WIDTH - shift_amt));
            end
        end

        default: result = '0;
    endcase
end

endmodule : shift_unit
