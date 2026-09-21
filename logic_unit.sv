//------------------------------------------------------------------------------
// Module: logic_unit
// Description: Logic Unit for ALU
//              Implements AND, OR, XOR, NAND operations
//------------------------------------------------------------------------------

module logic_unit
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
// Operation Logic
//==============================================================================

always_comb begin
    case (op_sel)
        2'b00:   result = operand_a & operand_b;        // AND
        2'b01:   result = operand_a | operand_b;        // OR
        2'b10:   result = operand_a ^ operand_b;        // XOR
        2'b11:   result = ~(operand_a & operand_b);     // NAND
        default: result = '0;
    endcase
end

endmodule : logic_unit
