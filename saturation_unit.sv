//------------------------------------------------------------------------------
// Module: saturation_unit
// Description: Saturation Arithmetic Unit for ALU
//              Implements SAT_ADD, SAT_SUB, SAT_MUL, SAT_RSHIFT operations
//              Clamps results to representable bounds instead of wrapping
//------------------------------------------------------------------------------

module saturation_unit
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Operands
    input logic [DATA_WIDTH-1:0] operand_a,
    input logic [DATA_WIDTH-1:0] operand_b,

    // Operation select (opcode[1:0])
    input logic [1:0] op_sel,

    // Results
    output logic [DATA_WIDTH-1:0] result,
    output logic                  saturation_occurred
);

//==============================================================================
// Constants
//==============================================================================

localparam logic [DATA_WIDTH-1:0] MAX_POS = {1'b0, {(DATA_WIDTH-1){1'b1}}}; // 0x7FFF_FFFF
localparam logic [DATA_WIDTH-1:0] MIN_NEG = {1'b1, {(DATA_WIDTH-1){1'b0}}}; // 0x8000_0000

//==============================================================================
// Internal Signals
//==============================================================================

logic signed [DATA_WIDTH-1:0]   signed_a;
logic signed [DATA_WIDTH-1:0]   signed_b;
logic signed [DATA_WIDTH:0]     sum_ext;       // Extended sum for overflow detection
logic signed [2*DATA_WIDTH-1:0] mul_full;      // Full multiplication result
logic                           pos_overflow;
logic                           neg_overflow;

//==============================================================================
// Signed Conversion
//==============================================================================

assign signed_a = $signed(operand_a);
assign signed_b = $signed(operand_b);

//==============================================================================
// Operation Logic
//==============================================================================

always_comb begin
    // Default values
    result = '0;
    saturation_occurred = 1'b0;
    pos_overflow = 1'b0;
    neg_overflow = 1'b0;
    sum_ext = '0;
    mul_full = '0;

    case (op_sel)
        2'b00: begin // SAT_ADD - Saturating Addition
            // Sign-extend operands and add
            sum_ext = {operand_a[DATA_WIDTH-1], signed_a} +
                      {operand_b[DATA_WIDTH-1], signed_b};

            // Detect overflow
            // Positive overflow: both positive, result negative
            pos_overflow = ~operand_a[DATA_WIDTH-1] &
                           ~operand_b[DATA_WIDTH-1] &
                           sum_ext[DATA_WIDTH];
            // Negative overflow: both negative, result positive
            neg_overflow = operand_a[DATA_WIDTH-1] &
                           operand_b[DATA_WIDTH-1] &
                           ~sum_ext[DATA_WIDTH];

            if (pos_overflow) begin
                result = MAX_POS;
                saturation_occurred = 1'b1;
            end else if (neg_overflow) begin
                result = MIN_NEG;
                saturation_occurred = 1'b1;
            end else begin
                result = sum_ext[DATA_WIDTH-1:0];
            end
        end

        2'b01: begin // SAT_SUB - Saturating Subtraction
            // Sign-extend operands and subtract
            sum_ext = {operand_a[DATA_WIDTH-1], signed_a} -
                      {operand_b[DATA_WIDTH-1], signed_b};

            // Detect overflow
            // Positive overflow: positive - negative = negative (impossible for valid result)
            pos_overflow = ~operand_a[DATA_WIDTH-1] & operand_b[DATA_WIDTH-1] & sum_ext[DATA_WIDTH];
            // Negative overflow: negative - positive = positive (impossible for valid result)
            neg_overflow = operand_a[DATA_WIDTH-1] & ~operand_b[DATA_WIDTH-1] & ~sum_ext[DATA_WIDTH];

            if (pos_overflow) begin
                result = MAX_POS;
                saturation_occurred = 1'b1;
            end else if (neg_overflow) begin
                result = MIN_NEG;
                saturation_occurred = 1'b1;
            end else begin
                result = sum_ext[DATA_WIDTH-1:0];
            end
        end

        2'b10: begin // SAT_MUL - Saturating Multiplication
            mul_full = signed_a * signed_b;

            // Check if result fits in DATA_WIDTH bits
            // Positive overflow: result > MAX_POS
            if (mul_full > $signed({{DATA_WIDTH{1'b0}}, MAX_POS})) begin
                result = MAX_POS;
                saturation_occurred = 1'b1;
            end
            // Negative overflow: result < MIN_NEG
            else if (mul_full < $signed({{DATA_WIDTH{1'b1}}, MIN_NEG})) begin
                result = MIN_NEG;
                saturation_occurred = 1'b1;
            end
            else begin
                result = mul_full[DATA_WIDTH-1:0];
            end
        end

        2'b11: begin // SAT_RSHIFT - Saturating Right Shift
            // Arithmetic right shift preserves sign, cannot overflow
            result = signed_a >>> operand_b[4:0];
            saturation_occurred = 1'b0;  // Right shift cannot saturate
        end

        default: begin
            result = '0;
            saturation_occurred = 1'b0;
        end
    endcase
end

endmodule : saturation_unit
