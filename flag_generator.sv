//------------------------------------------------------------------------------
// Module: flag_generator
// Description: Status Flag Generator for ALU
//              Generates zero, carry, overflow, negative, parity, saturation
//------------------------------------------------------------------------------

module flag_generator
  import alu_pkg::*;
#(
    parameter int DATA_WIDTH = 32
)(
    // Result from ALU core
    input logic [DATA_WIDTH-1:0] result,

    // Opcode (for determining which flags are valid)
    input logic [OPCODE_WIDTH-1:0] opcode,

    // Flags from arithmetic unit
    input logic carry_in,
    input logic overflow_in,

    // Flag from saturation unit
    input logic saturation_in,

    // Output flags
    output logic zero,
    output logic carry,
    output logic overflow,
    output logic negative,
    output logic parity,
    output logic saturation,

    // Packed flag output
    output logic [FLAG_WIDTH-1:0] flags
);

//==============================================================================
// Internal Signals
//==============================================================================
logic [2:0] func_sel;

assign func_sel = opcode[4:2];

//==============================================================================
// Zero Flag
//==============================================================================
// Asserted when all bits of result are zero
//==============================================================================
assign zero = (result == '0);

//==============================================================================
// Negative Flag
//==============================================================================
// Reflects the MSB (sign bit) of the result
//==============================================================================
assign negative = result[DATA_WIDTH-1];

//==============================================================================
// Parity Flag
//==============================================================================
// Even parity - XOR reduction of all result bits
// 0 = even number of 1s, 1 = odd number of 1s
//==============================================================================
assign parity = ^result;

//==============================================================================
// Carry Flag
//==============================================================================
// Only valid for arithmetic operations (func_sel = 000)
//==============================================================================
always_comb begin
    if (func_sel == 3'b000) begin
        carry = carry_in;
    end else begin
        carry = 1'b0;
    end
end

//==============================================================================
// Overflow Flag
//==============================================================================
// Only valid for arithmetic operations (func_sel = 000)
// Never set for saturation operations
//==============================================================================
always_comb begin
    if (func_sel == 3'b000) begin
        overflow = overflow_in;
    end else begin
        overflow = 1'b0;
    end
end

//==============================================================================
// Saturation Flag
//==============================================================================
// Only valid for saturation operations (func_sel = 110)
//==============================================================================
always_comb begin
    if (func_sel == 3'b110) begin
        saturation = saturation_in;
    end else begin
        saturation = 1'b0;
    end
end

//==============================================================================
// Packed Flag Output
//==============================================================================
// Order: {zero, carry, overflow, negative, parity, saturation}
//==============================================================================
assign flags = {zero, carry, overflow, negative, parity, saturation};

endmodule : flag_generator
