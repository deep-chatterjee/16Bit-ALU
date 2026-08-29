`timescale 1ns / 1ps

//============================================================================
// 16-bit ALU with built-in Multiply and Divide
// Operations: ADD, SUB, AND, OR, XOR, NOT, LSL, LSR, ASR, ROL, ROR,
//             MUL, DIV, REM, CMP, PASS
//============================================================================

module alu16 (
    input  wire [15:0] a,           // Operand A
    input  wire [15:0] b,           // Operand B
    input  wire [3:0]  op,          // Operation select
    output reg  [31:0] result,      // Result (32-bit for MUL)
    output reg         zero,        // Zero flag
    output reg         negative,    // Negative flag (MSB of 16-bit result)
    output reg         carry,       // Carry/Borrow flag
    output reg         overflow,    // Signed overflow flag
    output reg         div_by_zero  // Division by zero flag
);

    //------------------------------------------------------------------------
    // Operation Encoding
    //------------------------------------------------------------------------
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOT  = 4'b0101;
    localparam OP_LSL  = 4'b0110;
    localparam OP_LSR  = 4'b0111;
    localparam OP_ASR  = 4'b1000;
    localparam OP_ROL  = 4'b1001;
    localparam OP_ROR  = 4'b1010;
    localparam OP_MUL  = 4'b1011;
    localparam OP_DIV  = 4'b1100;
    localparam OP_REM  = 4'b1101;
    localparam OP_CMP  = 4'b1110;
    localparam OP_PASS = 4'b1111;

    //------------------------------------------------------------------------
    // Internal arithmetic wires (17-bit to capture carry)
    //------------------------------------------------------------------------
    wire [16:0] add_ext = {1'b0, a} + {1'b0, b};
    wire [16:0] sub_ext = {1'b0, a} - {1'b0, b};

    //------------------------------------------------------------------------
    // Combinational multiply & divide (baked in!)
    //------------------------------------------------------------------------
    wire [31:0] mul_full = a * b;
    wire [15:0] div_quot = (b == 16'd0) ? 16'd0 : (a / b);
    wire [15:0] div_rem  = (b == 16'd0) ? 16'd0 : (a % b);

    //------------------------------------------------------------------------
    // ALU Logic
    //------------------------------------------------------------------------
    always @(*) begin
        // Defaults
        result      = 32'd0;
        carry       = 1'b0;
        overflow    = 1'b0;
        div_by_zero = 1'b0;

        case (op)
            //---- Arithmetic -------------------------------------------------
            OP_ADD: begin
                result   = {16'd0, add_ext[15:0]};
                carry    = add_ext[16];
                overflow = (a[15] == b[15]) && (a[15] != add_ext[15]);
            end

            OP_SUB: begin
                result   = {16'd0, sub_ext[15:0]};
                carry    = sub_ext[16];                 // borrow out
                overflow = (a[15] != b[15]) && (a[15] != sub_ext[15]);
            end

            //---- Logic ----------------------------------------------------
            OP_AND:  result = {16'd0, a & b};
            OP_OR:   result = {16'd0, a | b};
            OP_XOR:  result = {16'd0, a ^ b};
            OP_NOT:  result = {16'd0, ~a};

            //---- Shifts ---------------------------------------------------
            OP_LSL:  result = {16'd0, a << b[3:0]};
            OP_LSR:  result = {16'd0, a >> b[3:0]};
            OP_ASR:  result = {16'd0, $signed(a) >>> b[3:0]};

            //---- Rotates --------------------------------------------------
            OP_ROL:  result = {16'd0, (a << b[3:0]) | (a >> (16 - b[3:0]))};
            OP_ROR:  result = {16'd0, (a >> b[3:0]) | (a << (16 - b[3:0]))};

            //---- Multiply / Divide ----------------------------------------
            OP_MUL:  result = mul_full;

            OP_DIV: begin
                result      = {16'd0, div_quot};
                div_by_zero = (b == 16'd0);
            end

            OP_REM: begin
                result      = {16'd0, div_rem};
                div_by_zero = (b == 16'd0);
            end

            //---- Compare / Pass -------------------------------------------
            OP_CMP: begin
                result   = {16'd0, sub_ext[15:0]};
                carry    = sub_ext[16];
                overflow = (a[15] != b[15]) && (a[15] != sub_ext[15]);
            end

            OP_PASS: result = {16'd0, a};

            default: result = 32'd0;
        endcase

        //---- Status flags (based on lower 16 bits) -------------------------
        zero     = (result[15:0] == 16'd0);
        negative = result[15];
    end

endmodule
