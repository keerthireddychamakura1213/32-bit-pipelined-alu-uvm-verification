//-----------------------------------------------------------------------------
// Module: alu_core
// Description: ALU Core - Instantiates all functional units and multiplexes results
//-----------------------------------------------------------------------------

module alu_core
  import alu_pkg::*;
#(
  parameter int DATA_WIDTH = 32
)(
  // Operands
  input  logic [DATA_WIDTH-1:0]   operand_a,
  input  logic [DATA_WIDTH-1:0]   operand_b,

  // Opcode
  input  logic [OPCODE_WIDTH-1:0] opcode,

  // Carry input for ADDC/SUBB
  input  logic                    carry_in,

  // Results
  output logic [DATA_WIDTH-1:0]   result,
  output logic                   carry_out,
  output logic                   overflow_out,
  output logic                   saturation_out
);

//=============================================================================
// Internal Signals
//=============================================================================

// Functional unit select
logic [2:0] func_sel;
logic [1:0] op_sel;

// Results from each functional unit
logic [DATA_WIDTH-1:0] arith_result;
logic [DATA_WIDTH-1:0] logic_result;
logic [DATA_WIDTH-1:0] shift_result;
logic [DATA_WIDTH-1:0] compare_result;
logic [DATA_WIDTH-1:0] multiply_result;
logic [DATA_WIDTH-1:0] divide_result;
logic [DATA_WIDTH-1:0] saturation_result;
logic [DATA_WIDTH-1:0] special_result;

// Arithmetic unit flags
logic arith_carry;
logic arith_overflow;

// Saturation unit flag
logic sat_occurred;

//=============================================================================
// Opcode Decode
//=============================================================================
assign func_sel = opcode[4:2];  // Functional unit select
assign op_sel   = opcode[1:0];  // Operation within unit

//=============================================================================
// Functional Unit Instantiations
//=============================================================================

// Arithmetic Unit (ADD, SUB, ADDC, SUBB)
arith_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_arith_unit (
  .operand_a  (operand_a),
  .operand_b  (operand_b),
  .op_sel     (op_sel),
  .carry_in   (carry_in),
  .result     (arith_result),
  .carry_out  (arith_carry),
  .overflow   (arith_overflow)
);

// Logic Unit (AND, OR, XOR, NAND)
logic_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_logic_unit (
  .operand_a (operand_a),
  .operand_b (operand_b),
  .op_sel    (op_sel),
  .result    (logic_result)
);

// Shift Unit (SLL, SRL, SRA, ROR)
shift_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_shift_unit (
  .operand_a (operand_a),
  .operand_b (operand_b),
  .op_sel    (op_sel),
  .result    (shift_result)
);

// Compare Unit (SLT, SLTU, SGT, SEQ)
compare_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_compare_unit (
  .operand_a (operand_a),
  .operand_b (operand_b),
  .op_sel    (op_sel),
  .result    (compare_result)
);

// Multiply Unit (MUL, MULH, MULHU, MULSU)
multiply_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_multiply_unit (
  .operand_a (operand_a),
  .operand_b (operand_b),
  .op_sel    (op_sel),
  .result    (multiply_result)
);

// Divide Unit (DIV, DIVU, REM, REMU)
divide_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_divide_unit (
  .operand_a (operand_a),
  .operand_b (operand_b),
  .op_sel    (op_sel),
  .result    (divide_result)
);

// Saturation Unit (SAT_ADD, SAT_SUB, SAT_MUL, SAT_RSHIFT)
saturation_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_saturation_unit (
  .operand_a          (operand_a),
  .operand_b          (operand_b),
  .op_sel             (op_sel),
  .result             (saturation_result),
  .saturation_occurred (sat_occurred)
);

// Special Unit (MIN, MAX, ABS, CLZ)
special_unit #(
  .DATA_WIDTH(DATA_WIDTH)
) u_special_unit (
  .operand_a (operand_a),
  .operand_b (operand_b),
  .op_sel    (op_sel),
  .result    (special_result)
);

//=============================================================================
// Result Multiplexer
//=============================================================================
always_comb begin
  case (func_sel)
    3'b000: result = arith_result;       // Arithmetic
    3'b001: result = logic_result;       // Logic
    3'b010: result = shift_result;       // Shift
    3'b011: result = compare_result;     // Compare
    3'b100: result = multiply_result;    // Multiply
    3'b101: result = divide_result;      // Divide
    3'b110: result = saturation_result;  // Saturation
    3'b111: result = special_result;     // Special
    default: result = '0;
  endcase
end

//=============================================================================
// Flag Outputs
//=============================================================================

// Carry out (only valid for arithmetic operations)
always_comb begin
  if (func_sel == 3'b000) begin
    carry_out = arith_carry;
  end else begin
    carry_out = 1'b0;
  end
end

  always_comb begin
  if(func_sel == 3'b000) begin
    overflow_out = arith_overflow;
  end else begin
    overflow_out =1'b0;
  end
  end

  always_comb begin
    if(func_sel ==3'b110) begin
      saturation_out = sat_occurred;
    end else begin
      saturation_out =1'b0;
    end
  end
endmodule : alu_core
    
  
