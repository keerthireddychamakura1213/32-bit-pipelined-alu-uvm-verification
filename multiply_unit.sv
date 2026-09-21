//------------------------------------------------------------------------------
// Module: multiply_unit
// Description: Multiply Unit for ALU
//              Implements MUL, MULH, MULHU, MULSU operations
//------------------------------------------------------------------------------

module multiply_unit
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Operands
    input logic [DATA_WIDTH-1:0] operand_a,
    input logic [DATA_WIDTH-1:0] operand_b,

    // Operation select (opcode[1:0])
    input logic [1:0] op_sel,

    // Result
    output logic [DATA_WIDTH-1:0] result
);

//==============================================================================
// Internal Signals
//==============================================================================
logic signed [DATA_WIDTH-1:0]   signed_a;
logic signed [DATA_WIDTH-1:0]   signed_b;
logic signed [2*DATA_WIDTH-1:0] mul_signed;
logic        [2*DATA_WIDTH-1:0] mul_unsigned;
logic signed [2*DATA_WIDTH-1:0] mul_signed_unsigned;

//==============================================================================
// Multiplication Operations
//==============================================================================

assign signed_a = $signed(operand_a);
assign signed_b = $signed(operand_b);

// Signed multiplication (for MULH)
assign mul_signed = signed_a * signed_b;

// Unsigned multiplication (for MUL and MULHU)
assign mul_unsigned = operand_a * operand_b;

// Mixed signed x unsigned multiplication (for MULSU)
// A is signed, B is unsigned (zero-extended to signed)
assign mul_signed_unsigned = signed_a * $signed({1'b0, operand_b});

//==============================================================================
// Operation Logic
//==============================================================================

always_comb begin
    case (op_sel)
        2'b00: begin // MUL - Lower 32 bits of unsigned multiplication
            result = mul_unsigned[DATA_WIDTH-1:0];
        end

        2'b01: begin // MULH - Upper 32 bits of signed multiplication
            result = mul_signed[2*DATA_WIDTH-1:DATA_WIDTH];
        end

        2'b10: begin // MULHU - Upper 32 bits of unsigned multiplication
            result = mul_unsigned[2*DATA_WIDTH-1:DATA_WIDTH];
        end

        2'b11: begin // MULSU - Upper 32 bits of signed x unsigned multiplication
            result = mul_signed_unsigned[2*DATA_WIDTH-1:DATA_WIDTH];
        end

        default: result = '0;
    endcase
end

endmodule : multiply_unit
