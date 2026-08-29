`timescale 1ns / 1ps

//============================================================================
// Testbench for 16-bit ALU
//============================================================================

module alu16_tb;

    reg  [15:0] a, b;
    reg  [3:0]  op;
    wire [31:0] result;
    wire        zero, negative, carry, overflow, div_by_zero;

    alu16 uut (
        .a(a), .b(b), .op(op),
        .result(result),
        .zero(zero), .negative(negative),
        .carry(carry), .overflow(overflow),
        .div_by_zero(div_by_zero)
    );

    // Operation codes
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

    integer errors = 0;

    task check16;
        input [15:0] expected;
        input        exp_z, exp_n, exp_c, exp_v, exp_dvz;
        begin
            if (result[15:0] !== expected) begin
                $display("  FAIL result: got %h expected %h", result[15:0], expected);
                errors = errors + 1;
            end
            if (zero !== exp_z)       begin $display("  FAIL zero flag");     errors = errors + 1; end
            if (negative !== exp_n)   begin $display("  FAIL negative flag"); errors = errors + 1; end
            if (carry !== exp_c)      begin $display("  FAIL carry flag");    errors = errors + 1; end
            if (overflow !== exp_v)   begin $display("  FAIL overflow flag"); errors = errors + 1; end
            if (div_by_zero !== exp_dvz) begin $display("  FAIL div0 flag");  errors = errors + 1; end
        end
    endtask

    task check32;
        input [31:0] expected;
        begin
            if (result !== expected) begin
                $display("  FAIL result: got %h expected %h", result, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("alu16.vcd");
        $dumpvars(0, alu16_tb);

        $display("============================================================");
        $display("           16-bit ALU Testbench Starting");
        $display("============================================================\n");

        //------------------------------------------------------------
        // ADD
        //------------------------------------------------------------
        $display("--- ADD ---");
        a = 16'd5; b = 16'd3; op = OP_ADD; #10;
        $display("ADD: %0d + %0d = %0d  | Z=%b N=%b C=%b V=%b", a, b, result[15:0], zero, negative, carry, overflow);
        check16(16'd8, 0, 0, 0, 0, 0);

        a = 16'h7FFF; b = 16'h0001; op = OP_ADD; #10;
        $display("ADD: 0x%h + 0x%h = 0x%h  | V=%b (should overflow)", a, b, result[15:0], overflow);
        check16(16'h8000, 0, 1, 0, 1, 0);

        a = 16'hFFFF; b = 16'h0001; op = OP_ADD; #10;
        $display("ADD: 0xFFFF + 0x1 = 0x%h  | Z=%b C=%b", result[15:0], zero, carry);
        check16(16'h0000, 1, 0, 1, 0, 0);

        //------------------------------------------------------------
        // SUB
        //------------------------------------------------------------
        $display("\n--- SUB ---");
        a = 16'd10; b = 16'd3; op = OP_SUB; #10;
        $display("SUB: %0d - %0d = %0d", a, b, result[15:0]);
        check16(16'd7, 0, 0, 0, 0, 0);

        a = 16'd3; b = 16'd10; op = OP_SUB; #10;
        $display("SUB: %0d - %0d = %0d  | N=%b", a, b, result[15:0], negative);
        check16(16'hFFF9, 0, 1, 1, 0, 0);

        //------------------------------------------------------------
        // Logic
        //------------------------------------------------------------
        $display("\n--- LOGIC ---");
        a = 16'hFF00; b = 16'h0F0F; op = OP_AND; #10;
        $display("AND: %h & %h = %h", a, b, result[15:0]);
        check16(16'h0F00, 0, 0, 0, 0, 0);

        a = 16'hF0F0; b = 16'h0F0F; op = OP_OR; #10;
        $display("OR:  %h | %h = %h", a, b, result[15:0]);
        check16(16'hFFFF, 0, 1, 0, 0, 0);

        a = 16'hFFFF; b = 16'h0F0F; op = OP_XOR; #10;
        $display("XOR: %h ^ %h = %h", a, b, result[15:0]);
        check16(16'hF0F0, 0, 1, 0, 0, 0);

        a = 16'hFF00; op = OP_NOT; #10;
        $display("NOT: ~%h = %h", a, result[15:0]);
        check16(16'h00FF, 0, 0, 0, 0, 0);

        //------------------------------------------------------------
        // Shifts
        //------------------------------------------------------------
        $display("\n--- SHIFTS ---");
        a = 16'h0001; b = 16'd4; op = OP_LSL; #10;
        $display("LSL: %h << %0d = %h", a, b, result[15:0]);
        check16(16'h0010, 0, 0, 0, 0, 0);

        a = 16'h8000; b = 16'd4; op = OP_LSR; #10;
        $display("LSR: %h >> %0d = %h", a, b, result[15:0]);
        check16(16'h0800, 0, 0, 0, 0, 0);

        a = 16'hF000; b = 16'd4; op = OP_ASR; #10;
        $display("ASR: %h >>> %0d = %h", a, b, result[15:0]);
        check16(16'hFF00, 0, 1, 0, 0, 0);

        //------------------------------------------------------------
        // Rotates
        //------------------------------------------------------------
        $display("\n--- ROTATES ---");
        a = 16'h8001; b = 16'd1; op = OP_ROL; #10;
        $display("ROL: %h ROL %0d = %h", a, b, result[15:0]);
        check16(16'h0003, 0, 0, 0, 0, 0);

        a = 16'h8001; b = 16'd1; op = OP_ROR; #10;
        $display("ROR: %h ROR %0d = %h", a, b, result[15:0]);
        check16(16'hC000, 0, 1, 0, 0, 0);

        a = 16'hABCD; b = 16'd0; op = OP_ROL; #10;
        $display("ROL: %h ROL %0d = %h (should be same)", a, b, result[15:0]);
        check16(16'hABCD, 0, 1, 0, 0, 0);

        //------------------------------------------------------------
        // MULTIPLY (the star of the show)
        //------------------------------------------------------------
        $display("\n--- MULTIPLY ---");
        a = 16'd100; b = 16'd200; op = OP_MUL; #10;
        $display("MUL: %0d * %0d = %0d (0x%h)", a, b, result, result);
        check32(32'd20000);

        a = 16'h1234; b = 16'h5678; op = OP_MUL; #10;
        $display("MUL: 0x%h * 0x%h = 0x%h", a, b, result);
        check32(32'h06260060);

        a = 16'hFFFF; b = 16'hFFFF; op = OP_MUL; #10;
        $display("MUL: 0xFFFF * 0xFFFF = 0x%h", result);
        check32(32'hFFFE0001);

        //------------------------------------------------------------
        // DIVIDE & REMAINDER
        //------------------------------------------------------------
        $display("\n--- DIVIDE / REMAINDER ---");
        a = 16'd100; b = 16'd3; op = OP_DIV; #10;
        $display("DIV: %0d / %0d = %0d, div0=%b", a, b, result[15:0], div_by_zero);
        check16(16'd33, 0, 0, 0, 0, 0);

        a = 16'd100; b = 16'd3; op = OP_REM; #10;
        $display("REM: %0d %% %0d = %0d", a, b, result[15:0]);
        check16(16'd1, 0, 0, 0, 0, 0);

        a = 16'd100; b = 16'd0; op = OP_DIV; #10;
        $display("DIV: %0d / %0d = %0d, div0=%b (should assert div0)", a, b, result[15:0], div_by_zero);
        check16(16'd0, 1, 0, 0, 0, 1);

        a = 16'd100; b = 16'd0; op = OP_REM; #10;
        $display("REM: %0d %% %0d = %0d, div0=%b", a, b, result[15:0], div_by_zero);
        check16(16'd0, 1, 0, 0, 0, 1);

        a = 16'hFFFF; b = 16'h00FF; op = OP_DIV; #10;
        $display("DIV: 0xFFFF / 0xFF = 0x%h", result[15:0]);
        check16(16'h0101, 0, 0, 0, 0, 0);

        //------------------------------------------------------------
        // CMP & PASS
        //------------------------------------------------------------
        $display("\n--- CMP / PASS ---");
        a = 16'd5; b = 16'd10; op = OP_CMP; #10;
        $display("CMP: %0d vs %0d | Z=%b N=%b", a, b, zero, negative);

        a = 16'd10; b = 16'd5; op = OP_CMP; #10;
        $display("CMP: %0d vs %0d | Z=%b N=%b", a, b, zero, negative);

        a = 16'hABCD; op = OP_PASS; #10;
        $display("PASS: %h", result[15:0]);
        check16(16'hABCD, 0, 1, 0, 0, 0);

        //------------------------------------------------------------
        // Summary
        //------------------------------------------------------------
        $display("\n============================================================");
        if (errors == 0)
            $display("           ALL TESTS PASSED!");
        else
            $display("           TESTS FAILED: %0d error(s)", errors);
        $display("============================================================");

        $finish;
    end

endmodule
