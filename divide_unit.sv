//------------------------------------------------------------------------------
// Module: divide_unit
// Description: Divide Unit for ALU
//              Implements DIV, DIVU, REM, REMU operations
//------------------------------------------------------------------------------

module divide_unit
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Operands
    input logic [DATA_WIDTH-1:0] operand_a,  // Dividend
    input logic [DATA_WIDTH-1:0] operand_b,  // Divisor

    // Operation select (opcode[1:0])
    input logic [1:0] op_sel,

    // Result
    output logic [DATA_WIDTH-1:0] result
);

//==============================================================================
// Internal Signals
//==============================================================================
logic signed [DATA_WIDTH-1:0] signed_a;
logic signed [DATA_WIDTH-1:0] signed_b;

// Division results
logic [DATA_WIDTH-1:0] quotient_signed;
logic [DATA_WIDTH-1:0] quotient_unsigned;
logic [DATA_WIDTH-1:0] remainder_signed;
logic [DATA_WIDTH-1:0] remainder_unsigned;

// Divide by zero flag
logic div_by_zero;

//==============================================================================
// Signed Conversion
//==============================================================================
assign signed_a = $signed(operand_a);
assign signed_b = $signed(operand_b);

assign div_by_zero = (operand_b == '0);

//==============================================================================
// Division Operations
//==============================================================================
always_comb begin
    if (div_by_zero) begin
        // Divide by zero handling
        // Quotient returns all 1s, remainder returns dividend
        quotient_signed   = '1;
        quotient_unsigned = '1;
        remainder_signed  = operand_a;
        remainder_unsigned = operand_a;
    end else begin
        // Normal division
        quotient_signed   = signed_a / signed_b;
        quotient_unsigned = operand_a / operand_b;
        remainder_signed  = signed_a % signed_b;
        remainder_unsigned = operand_a % operand_b;
    end
end

//==============================================================================
// Operation Logic
//==============================================================================
always_comb begin
    case (op_sel)
        2'b00: begin // DIV - Signed Division
            result = quotient_signed;
        end

        2'b01: begin // DIVU - Unsigned Division
            result = quotient_unsigned;
        end

        2'b10: begin // REM - Signed Remainder
            result = remainder_signed;
        end

        2'b11: begin // REMU - Unsigned Remainder
            result = remainder_unsigned;
        end

        default: result = '0;
    endcase
end

endmodule : divide_unit
