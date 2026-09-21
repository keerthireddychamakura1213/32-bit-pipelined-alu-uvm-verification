//------------------------------------------------------------------------------
// Module: arith_unit
// Description: Arithmetic Unit for ALU
//              Implements ADD, SUB, ADDC, SUBB operations
//------------------------------------------------------------------------------

module arith_unit
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Operands
    input  logic [DATA_WIDTH-1:0] operand_a,
    input  logic [DATA_WIDTH-1:0] operand_b,

    // Operation select (opcode[1:0])
    input  logic [1:0] op_sel,

    // Carry input for ADDC/SUBB
    input  logic carry_in,

    // Results
    output logic [DATA_WIDTH-1:0] result,
    output logic carry_out,
    output logic overflow
);

//==============================================================================
// Internal Signals
//==============================================================================
logic [DATA_WIDTH:0] result_ext;  // 33-bit for carry detection
logic [DATA_WIDTH:0] a_ext;
logic [DATA_WIDTH:0] b_ext;
logic                cin;
logic                is_subtract;

//==============================================================================
// Operation Logic
//==============================================================================
always_comb begin
    // Extend operands to 33 bits
    a_ext = {1'b0, operand_a};

    // Determine operation type
    case (op_sel)
        2'b00: begin // ADD
            b_ext       = {1'b0, operand_b};
            cin         = 1'b0;
            is_subtract = 1'b0;
        end

        2'b01: begin // SUB: A - B = A + (~B) + 1
            b_ext       = {1'b0, ~operand_b};
            cin         = 1'b1;
            is_subtract = 1'b1;
        end

        2'b10: begin // ADDC: A + B + Cin
            b_ext       = {1'b0, operand_b};
            cin         = carry_in;
            is_subtract = 1'b0;
        end

        2'b11: begin // SUBB: A - B - ~Cin = A + (~B) + Cin
            b_ext       = {1'b0, ~operand_b};
            cin         = carry_in;
            is_subtract = 1'b1;
        end

        default: begin
            b_ext       = '0;
            cin         = 1'b0;
            is_subtract = 1'b0;
        end
    endcase

    // Perform addition
    result_ext = a_ext + b_ext + {{DATA_WIDTH{1'b0}}, cin};

    // Extract result and carry
    result   = result_ext[DATA_WIDTH-1:0];
    carry_out = result_ext[DATA_WIDTH];

    // Overflow detection for signed arithmetic
    // ADD/ADDC: overflow when same sign inputs produce different sign output
    // SUB/SUBB: overflow when different sign inputs produce unexpected sign
    if (!is_subtract) begin
        // Addition overflow: pos + pos = neg, or neg + neg = pos
        overflow = (operand_a[DATA_WIDTH-1] == operand_b[DATA_WIDTH-1]) &&
                   (operand_a[DATA_WIDTH-1] != result[DATA_WIDTH-1]);
    end else begin
        // Subtraction overflow: pos - neg = neg, or neg - pos = pos
        overflow = (operand_a[DATA_WIDTH-1] != operand_b[DATA_WIDTH-1]) &&
                   (operand_a[DATA_WIDTH-1] != result[DATA_WIDTH-1]);
    end
end

endmodule : arith_unit
