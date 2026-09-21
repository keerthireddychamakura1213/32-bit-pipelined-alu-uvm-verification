//------------------------------------------------------------------------------
// Module: alu_pkg
// Description: Package containing types, parameters, and opcodes for the
//              32-bit Pipelined ALU
//------------------------------------------------------------------------------

package alu_pkg;

//==============================================================================
// Parameters
//==============================================================================
parameter int DATA_WIDTH      = 32;
parameter int OPCODE_WIDTH   = 5;
parameter int FLAG_WIDTH     = 6;
parameter int PIPELINE_STAGES = 3;
parameter int REG_ADDR_WIDTH = 5;    // 5 bits for 32 registers

// Saturation boundary values
parameter logic [DATA_WIDTH-1:0] MAX_POS = 32'h7FFF_FFFF;
parameter logic [DATA_WIDTH-1:0] MIN_NEG = 32'h8000_0000;

//==============================================================================
// Opcode Encoding
// Upper 3 bits [4:2] select functional unit
// Lower 2 bits [1:0] select operation within unit
//==============================================================================

// Arithmetic Operations (000xx)
typedef enum logic [OPCODE_WIDTH-1:0] {
    OP_ADD  = 5'b00000,  // Addition (A + B)
    OP_SUB  = 5'b00001,  // Subtraction (A - B)
    OP_ADDC = 5'b00010,  // Add with carry
    OP_SUBB = 5'b00011,  // Subtract with borrow

// Logical Operations (001xx)
    OP_AND  = 5'b00100,  // Bitwise AND
    OP_OR   = 5'b00101,  // Bitwise OR
    OP_XOR  = 5'b00110,  // Bitwise XOR
    OP_NAND = 5'b00111,  // Bitwise NAND

// Shift Operations (010xx)
    OP_SLL = 5'b01000,   // Shift left logical
    OP_SRL = 5'b01001,   // Shift right logical
    OP_SRA = 5'b01010,   // Shift right arithmetic
    OP_ROR = 5'b01011,   // Rotate right

// Comparison Operations (011xx)
    OP_SLT = 5'b01100,   // Set less than (signed)
    OP_SLTU = 5'b01101,  // Set less than (unsigned)
    OP_SGT = 5'b01110,   // Set greater than
    OP_SEQ = 5'b01111,   // Set equal

// Multiply Operations (100xx)
    OP_MUL = 5'b10000,   // Multiply (lower 32 bits)
    OP_MULH =5'b10001,  // Multiply (singed)
    OP_MULHU =5'b10010, //Multiply(unsigned)
    OP_MULSU = 5'b10011, // Multiply (signed & unsigned)

// Divide Operations (101xx)
    OP_DIV  = 5'b10100,  // Signed division
    OP_DIVU = 5'b10101,  // Unsigned division
    OP_REM  = 5'b10110,  // Signed remainder
    OP_REMU = 5'b10111,  // Unsigned remainder

// Saturation Operations (110xx)
    OP_SAT_ADD   = 5'b11000,  // Saturating addition
    OP_SAT_SUB   = 5'b11001,  // Saturating subtraction
    OP_SAT_MUL   = 5'b11010,  // Saturating multiply
    OP_SAT_RSHIFT = 5'b11011, // Saturating right shift

// Special Operations (111xx)
    OP_MIN = 5'b11100,   // Minimum of A and B
    OP_MAX = 5'b11101,   // Maximum of A and B
    OP_ABS = 5'b11110,   // Absolute value of A
    OP_CLZ = 5'b11111    // Count leading zeros
} opcode_t;

//==============================================================================
// Functional Unit Select (decoded from opcode[4:2])
//==============================================================================

typedef enum logic [2:0] {
    FUNC_ARITH   = 3'b000,
    FUNC_LOGIC   = 3'b001,
    FUNC_SHIFT   = 3'b010,
    FUNC_COMPARE = 3'b011,
    FUNC_MULTIPLY = 3'b100,
    FUNC_DIVIDE   = 3'b101,
    FUNC_SATURATE = 3'b110,
    FUNC_SPECIAL  = 3'b111
} func_unit_t;

//==============================================================================
// Flag Bit Positions
//==============================================================================

typedef enum int {
    FLAG_SATURATION = 0,
    FLAG_PARITY     = 1,
    FLAG_NEGATIVE   = 2,
    FLAG_OVERFLOW   = 3,
    FLAG_CARRY      = 4,
    FLAG_ZERO       = 5
} flag_pos_t;

//==============================================================================
// Pipeline Register Structures
//==============================================================================

// Stage 1 to Stage 2 register
typedef struct packed {
    logic [DATA_WIDTH-1:0] operand_a;
    logic [DATA_WIDTH-1:0] operand_b;
    logic [OPCODE_WIDTH-1:0] opcode;
    logic                   carry_in;     // For ADDC/SUBB
    logic [REG_ADDR_WIDTH-1:0] src_a_addr; // Source register A address
    logic [REG_ADDR_WIDTH-1:0] src_b_addr; // Source register B address
    logic [REG_ADDR_WIDTH-1:0] dest_addr;  // Destination register address
    logic                   valid;
} stage1_reg_t;

// Stage 2 to Stage 3 register
typedef struct packed {
    logic [DATA_WIDTH-1:0] result;
    logic [FLAG_WIDTH-1:0] flags;
    logic [REG_ADDR_WIDTH-1:0] dest_addr; // Destination register address
    logic                     valid;
} stage2_reg_t;

//==============================================================================
// Forwarding Select
//==============================================================================

typedef enum logic [1:0] {
    FWD_NONE   = 2'b00,  // Use register value (no hazard)
    FWD_STAGE2 = 2'b01,  // Forward from Stage 2
    FWD_STAGE3 = 2'b10   // Forward from Stage 3
} fwd_sel_t;

//==============================================================================
// Helper Functions
//==============================================================================

// Get functional unit from opcode
function automatic func_unit_t get_func_unit(input logic [OPCODE_WIDTH-1:0] opcode);
    return func_unit_t'(opcode[4:2]);
endfunction

// Check if operation is arithmetic (for carry/overflow flags)
function automatic logic is_arithmetic_op(input logic [OPCODE_WIDTH-1:0] opcode);
    func_unit_t fu = get_func_unit(opcode);
    return (fu == FUNC_ARITH);
endfunction

// Check if operation is saturation type
function automatic logic is_saturation_op(input logic [OPCODE_WIDTH-1:0] opcode);
    func_unit_t fu = get_func_unit(opcode);
    return (fu == FUNC_SATURATE);
endfunction

// Count leading zeros function
function automatic logic [5:0] count_leading_zeros(input logic [DATA_WIDTH-1:0] value);
    logic [5:0] count;
    count = 0;
    for (int i = DATA_WIDTH-1; i >= 0; i--) begin
        if (value[i] == 1'b1)
            return count;
        count++;
    end
    return DATA_WIDTH; // All zeros
endfunction

endpackage : alu_pkg
