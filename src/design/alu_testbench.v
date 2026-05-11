`timescale 1ns / 1ps
module alu_testbench();
// DUT signals
    reg [7:0] OPA, OPB;
    reg CLK, RST, CE, MODE, CIN;
    reg [1:0]INP_VAD;
    reg [3:0] CMD;
    wire [15:0] RES_dut;
    wire COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut;

    // Reference model signals
    wire [15:0] RES_ref;
    wire COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref;
    reg [21:0] RES_EXP;

    // Test counters
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_count=0;
    reg compare_outputs;
    // DUT instantiation
alu #(.N(8),.M(4)) dut  (
        .opa(OPA), .opb(OPB), .cin(CIN),
        .clk(CLK), .rst(RST), .cmd(CMD),
        .ce(CE), .mode(MODE),.inp_valid(INP_VAD),
        .cout(COUT_dut), .oflow(OFLOW_dut),
        .res(RES_dut),
        .G(G_dut), .E(E_dut), .L(L_dut),
        .err(ERR_dut)
    );
// Reference model instantiation
    alu_reference_model #(.WIDTH(8),.M(4)) ref (
        .OPA(OPA), .OPB(OPB), .CIN(CIN),
        .MODE(MODE), .CMD(CMD),.INP_VAD(INP_VAD),
        .RES(RES_ref),
        .COUT(COUT_ref), .OFLOW(OFLOW_ref),
        .G(G_ref), .E(E_ref), .L(L_ref),
        .ERR(ERR_ref)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    // Test stimulus
    initial begin
        @(posedge CLK);
        @(posedge CLK);
        test_reset("RESET");
        RST = 0;MODE=1;
	@(posedge CLK);
	apply_test(8'h0F, 8'h11, 4'b0000,2'b11, "ADD without carry");

	CE=0;
	@(posedge CLK);	
	@(posedge CLK);
	#1;test_ce("checking ce");
	@(posedge CLK);
	RST=1;CE=1;
	@(posedge CLK);
	test_reset("checking reset again");
	RST=0;MODE=0;
        @(posedge CLK);
        // Test Arithmetic Operations
        $display("\n=== Testing Arithmetic Operations (MODE=1) ===");
        MODE = 1;
        test_arithmetic();

        // Test Logical Operations
        $display("\n=== Testing Logical Operations (MODE=0) ===");
        MODE = 0;
        test_logical();

        // Summary
        $display("\n=== TEST SUMMARY ===");
        $display("Total Tests: %0d", test_count);
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        
        if (fail_count == 0)
            $display("\n*** ALL TESTS PASSED ***\n");
        else
            $display("\n*** SOME TESTS FAILED ***\n");

        #100;
        $finish;
    end
    	task test_ce(input [80*8:1] test_name);
	begin
		test_count =test_count+1;
		if((RES_dut!='d32)||(COUT_dut!=1'b0)||(OFLOW_dut!=0)||(G_dut!=0)||(E_dut!=0)||(L_dut!=0)||(ERR_dut!=0))begin
			$display("[FAIL]%s",test_name);
		fail_count=fail_count+1;
		display_mismatch();
		end else begin
			$display("[PASS] %s",test_name);
			pass_count=pass_count+1;
			display_mismatch();
		end
	end
	endtask
	task test_reset(input [80*8:1] test_name);
        begin
            test_count = test_count + 1;
            if ((RES_dut!='B0)||(COUT_dut!=1'b0)||(OFLOW_dut!=0)||(G_dut!=0)||(E_dut!=0)||(L_dut!=0)||(ERR_dut!=0)) begin
                $display("[FAIL] %s", test_name);
                fail_count = fail_count + 1;
                display_mismatch();
            end else begin
                $display("[PASS] %s",test_name);
                pass_count = pass_count + 1;
                display_mismatch();
            end
        end
    endtask

    // Test arithmetic operations
    task test_arithmetic();
        begin


        // -- ADD (CMD=0) ---------------------------------------------------
        // valid
        apply_test(8'h0F, 8'h11, 4'b0000, 2'b11, "ADD no carry");
        apply_test(8'hFF, 8'h01, 4'b0000, 2'b11, "ADD with carry");
        apply_test(8'h00, 8'h00, 4'b0000, 2'b11, "ADD zero");
        // ELSE branch  inp_valid != 11 (hits alu.v:186 err<=1)
        apply_test(8'h0F, 8'h11, 4'b0000, 2'b00, "ADD INP=00 ERR");
        apply_test(8'h0F, 8'h11, 4'b0000, 2'b01, "ADD INP=01 ERR");
        apply_test(8'h0F, 8'h11, 4'b0000, 2'b10, "ADD INP=10 ERR");

        // -- SUB (CMD=1) ---------------------------------------------------
        // valid
        apply_test(8'h20, 8'h10, 4'b0001, 2'b11, "SUB no overflow");
        apply_test(8'h10, 8'h20, 4'b0001, 2'b11, "SUB with overflow");
        apply_test(8'h00, 8'h00, 4'b0001, 2'b11, "SUB zero");
        // ELSE branch (hits alu.v:208 err<=1)
        apply_test(8'h20, 8'h10, 4'b0001, 2'b00, "SUB INP=00 ERR");
        apply_test(8'h20, 8'h10, 4'b0001, 2'b01, "SUB INP=01 ERR");
        apply_test(8'h20, 8'h10, 4'b0001, 2'b10, "SUB INP=10 ERR");

        // -- ADD_CIN (CMD=2) -----------------------------------------------
        // valid
        CIN = 0;
        apply_test(8'h10, 8'h20, 4'b0010, 2'b11, "ADD_CIN CIN=0 no cout");
        CIN = 1;
        apply_test(8'hDF, 8'h20, 4'b0010, 2'b11, "ADD_CIN CIN=1 with cout");
        CIN = 0;
        // ELSE branch (hits alu.v:235 err<=1)
        apply_test(8'h10, 8'h20, 4'b0010, 2'b00, "ADD_CIN INP=00 ERR");
        apply_test(8'h10, 8'h20, 4'b0010, 2'b01, "ADD_CIN INP=01 ERR");
        apply_test(8'h10, 8'h20, 4'b0010, 2'b10, "ADD_CIN INP=10 ERR");

        // -- SUB_CIN (CMD=3) -----------------------------------------------
        // valid
        CIN = 0;
        apply_test(8'h40, 8'h20, 4'b0011, 2'b11, "SUB_CIN no oflow");
        CIN = 1;
        apply_test(8'h20, 8'h20, 4'b0011, 2'b11, "SUB_CIN CIN=1 oflow");
        CIN = 1;
        apply_test(8'h10, 8'h20, 4'b0011, 2'b11, "SUB_CIN OPA<OPB CIN=1");
        CIN = 0;
        apply_test(8'h01, 8'hFF, 4'b0011, 2'b11, "SUB_CIN OPA<<OPB");
        // ELSE branch (hits alu.v:314 err<=1)
        CIN = 0;
        apply_test(8'h40, 8'h20, 4'b0011, 2'b00, "SUB_CIN INP=00 ERR");
        apply_test(8'h40, 8'h20, 4'b0011, 2'b01, "SUB_CIN INP=01 ERR");
        apply_test(8'h40, 8'h20, 4'b0011, 2'b10, "SUB_CIN INP=10 ERR");

        // -- INC_A (CMD=4) -------------------------------------------------
        apply_test(8'hFF, 8'h00, 4'b0100, 2'b11, "INC_A INP=11");
        apply_test(8'h0B, 8'h00, 4'b0100, 2'b01, "INC_A INP=01");
        // ELSE (hits alu.v:344 err<=1)
        apply_test(8'h0B, 8'h00, 4'b0100, 2'b10, "INC_A INP=10 ERR");
        apply_test(8'h0A, 8'h00, 4'b0100, 2'b00, "INC_A INP=00 ERR");

        // -- DEC_A (CMD=5) -------------------------------------------------
        apply_test(8'h0A, 8'h00, 4'b0101, 2'b11, "DEC_A INP=11");
        apply_test(8'h0A, 8'h00, 4'b0101, 2'b01, "DEC_A INP=01");
        // ELSE (hits alu.v:384 err<=1)
        apply_test(8'h0B, 8'h00, 4'b0101, 2'b00, "DEC_A INP=00 ERR");
        apply_test(8'h0A, 8'h00, 4'b0101, 2'b10, "DEC_A INP=10 ERR");

        // -- INC_B (CMD=6) -------------------------------------------------
        apply_test(8'h00, 8'hFF, 4'b0110, 2'b11, "INC_B INP=11");
        apply_test(8'h00, 8'h0B, 4'b0110, 2'b10, "INC_B INP=10");
        // ELSE (hits alu.v:433 err<=1)
        apply_test(8'h0A, 8'h00, 4'b0110, 2'b00, "INC_B INP=00 ERR");
        apply_test(8'h0B, 8'h00, 4'b0110, 2'b01, "INC_B INP=01 ERR");

        // -- DEC_B (CMD=7) -------------------------------------------------
        apply_test(8'h0A, 8'h00, 4'b0111, 2'b11, "DEC_B INP=11");
        apply_test(8'h0B, 8'h0D, 4'b0111, 2'b10, "DEC_B INP=10");
        // ELSE (hits alu.v:472 err<=1)
        apply_test(8'h0B, 8'h00, 4'b0111, 2'b00, "DEC_B INP=00 ERR");
        apply_test(8'h0A, 8'h00, 4'b0111, 2'b01, "DEC_B INP=01 ERR");

        // -- CMP (CMD=8) ---------------------------------------------------
        apply_test(8'h10, 8'h10, 4'b1000, 2'b11, "CMP equal");
        apply_test(8'h20, 8'h10, 4'b1000, 2'b11, "CMP greater");
        apply_test(8'h10, 8'h20, 4'b1000, 2'b11, "CMP less");
        // ELSE (hits alu.v:516 err<=1)
        apply_test(8'h10, 8'h10, 4'b1000, 2'b00, "CMP INP=00 ERR");
        apply_test(8'h10, 8'h10, 4'b1000, 2'b01, "CMP INP=01 ERR");
        apply_test(8'h10, 8'h10, 4'b1000, 2'b10, "CMP INP=10 ERR");

        // -- MUL CMD=9  hits valid_r ELSE (alu.v:526) --------------------
        // First run with INP_VAD=11 to set valid_r=1 (count=0 sample)
        apply_test(8'hFE, 8'hFE, 4'b1001, 2'b11, "MUL9 valid");
        // Now run with INP_VAD=00  when count==1, valid_r=0 ? ELSE err<=1
        // (hits alu.v:526 else err<=1)
        apply_test(8'h10, 8'h10, 4'b1001, 2'b00, "MUL9 invalid valid_r ERR");

        // -- MUL CMD=10  hits valid_r ELSE (alu.v:536) -------------------
        apply_test(8'h10, 8'h10, 4'b1010, 2'b11, "MUL10 valid");
        apply_test(8'h10, 8'h10, 4'b1010, 2'b00, "MUL10 invalid valid_r ERR");

        // -- prev_mode != mode  hits condition (alu.v image1) ------------
        // Switch MODE mid-stream while cmd stays same to hit prev_mode!=mode
        // Switch from MODE=1 back to MODE=0 then back to MODE=1
        // (done by calling test_logical in between  handled in main initial)

        // -- SIGNED ADD (CMD=11) -------------------------------------------
        apply_test(8'h10, 8'h10, 4'b1011, 2'b11, "SADD same sign no OV");
        apply_test(8'hFF, 8'h80, 4'b1011, 2'b11, "SADD same sign OV");
        apply_test(8'hF0, 8'h10, 4'b1011, 2'b11, "SADD diff sign no OV");
        apply_test(8'h20, 8'h10, 4'b1011, 2'b11, "SADD G=1");
        apply_test(8'hFF, 8'hFF, 4'b1011, 2'b11, "SADD E=1");
        apply_test(8'hF0, 8'hF2, 4'b1011, 2'b11, "SADD L=1");
        // ELSE (hits alu.v:546 err<=1)
        apply_test(8'h10, 8'h10, 4'b1011, 2'b00, "SADD INP=00 ERR");
        apply_test(8'h10, 8'h10, 4'b1011, 2'b01, "SADD INP=01 ERR");
        apply_test(8'h10, 8'h10, 4'b1011, 2'b10, "SADD INP=10 ERR");

        // -- SIGNED SUB (CMD=12) -------------------------------------------
        apply_test(8'hF0, 8'h0F, 4'b1100, 2'b11, "SSUB diff sign no OV");
        apply_test(8'hF0, 8'hF0, 4'b1100, 2'b11, "SSUB same sign no OV");
        apply_test(8'h70, 8'h90, 4'b1100, 2'b11, "SSUB OV pos-neg");
        apply_test(8'h7F, 8'h80, 4'b1100, 2'b11, "SSUB OV max");
        apply_test(8'hF0, 8'h0F, 4'b1100, 2'b11, "SSUB G=1");
        apply_test(8'hF0, 8'hF0, 4'b1100, 2'b11, "SSUB E=1");
        apply_test(8'h80, 8'hF0, 4'b1100, 2'b11, "SSUB L=1");
        // ELSE (hits alu.v:556 err<=1)
        apply_test(8'hF0, 8'h0F, 4'b1100, 2'b00, "SSUB INP=00 ERR");
        apply_test(8'hF0, 8'h0F, 4'b1100, 2'b01, "SSUB INP=01 ERR");
        apply_test(8'hF0, 8'h0F, 4'b1100, 2'b10, "SSUB INP=10 ERR");

        // -- Default ERR CMDs ----------------------------------------------
        apply_test(8'hAA, 8'hFB, 4'b1101, 2'b11, "MODE1 CMD=13 ERR");
        apply_test(8'hAA, 8'hFB, 4'b1110, 2'b11, "MODE1 CMD=14 ERR");
        apply_test(8'hAA, 8'hFB, 4'b1111, 2'b11, "MODE1 CMD=15 ERR");

	end
    endtask

    // Test logical operations
    task test_logical();
        begin
    
 // -- AND (CMD=0) ---------------------------------------------------
        apply_test(8'hF0, 8'h0F, 4'b0000, 2'b11, "AND");
        apply_test(8'hFF, 8'hFF, 4'b0000, 2'b11, "AND all ones");
        apply_test(8'h00, 8'hFF, 4'b0000, 2'b11, "AND zero result");
        // ELSE (hits alu.v:586 err<=1)
        apply_test(8'hF0, 8'h0F, 4'b0000, 2'b00, "AND INP=00 ERR");
        apply_test(8'hF0, 8'h0F, 4'b0000, 2'b01, "AND INP=01 ERR");
        apply_test(8'hF0, 8'h0F, 4'b0000, 2'b10, "AND INP=10 ERR");

        // -- NAND (CMD=1) --------------------------------------------------
        apply_test(8'hF0, 8'h0F, 4'b0001, 2'b11, "NAND");
        apply_test(8'hFF, 8'hFF, 4'b0001, 2'b11, "NAND all ones");
        // ELSE (hits alu.v:596 err<=1)
        apply_test(8'hF0, 8'h0F, 4'b0001, 2'b00, "NAND INP=00 ERR");
        apply_test(8'hF0, 8'h0F, 4'b0001, 2'b01, "NAND INP=01 ERR");

        // -- OR (CMD=2) ----------------------------------------------------
        apply_test(8'hF0, 8'h0F, 4'b0010, 2'b11, "OR");
        apply_test(8'h00, 8'h00, 4'b0010, 2'b11, "OR zero");
        // ELSE (hits alu.v:606 err<=1)
        apply_test(8'hF0, 8'h0F, 4'b0010, 2'b00, "OR INP=00 ERR");
        apply_test(8'hF0, 8'h0F, 4'b0010, 2'b01, "OR INP=01 ERR");

        // -- NOR (CMD=3) ---------------------------------------------------
        apply_test(8'hF0, 8'h0F, 4'b0011, 2'b11, "NOR");
        apply_test(8'h00, 8'h00, 4'b0011, 2'b11, "NOR zero input");
        // ELSE
        apply_test(8'hF0, 8'h0F, 4'b0011, 2'b00, "NOR INP=00 ERR");

        // -- XOR (CMD=4) ---------------------------------------------------
        apply_test(8'hAA, 8'h55, 4'b0100, 2'b11, "XOR");
        apply_test(8'hFF, 8'hFF, 4'b0100, 2'b11, "XOR same = zero");
        // ELSE
        apply_test(8'hAA, 8'h55, 4'b0100, 2'b00, "XOR INP=00 ERR");

        // -- XNOR (CMD=5) -------------------------------------------------
        apply_test(8'hAA, 8'h55, 4'b0101, 2'b11, "XNOR");
        apply_test(8'hFF, 8'hFF, 4'b0101, 2'b11, "XNOR same = ones");
        // ELSE
        apply_test(8'hAA, 8'h55, 4'b0101, 2'b00, "XNOR INP=00 ERR");

        // -- NOT_A (CMD=6) -------------------------------------------------
        apply_test(8'hF0, 8'h00, 4'b0110, 2'b01, "NOT_A INP=01");
        apply_test(8'hF0, 8'h00, 4'b0110, 2'b11, "NOT_A INP=11");
        // ELSE (hits alu.v:635 err<=1)
        apply_test(8'h00, 8'h00, 4'b0110, 2'b10, "NOT_A INP=10 ERR");
        apply_test(8'h00, 8'h00, 4'b0110, 2'b00, "NOT_A INP=00 ERR");

        // -- NOT_B (CMD=7) -------------------------------------------------
        apply_test(8'h00, 8'hF0, 4'b0111, 2'b10, "NOT_B INP=10");
        apply_test(8'h00, 8'hF0, 4'b0111, 2'b11, "NOT_B INP=11");
        // ELSE (hits alu.v:636 err<=1)
        apply_test(8'h00, 8'h00, 4'b0111, 2'b01, "NOT_B INP=01 ERR");
        apply_test(8'h00, 8'h00, 4'b0111, 2'b00, "NOT_B INP=00 ERR");

        // -- SHR_A (CMD=8) ------------------------------------------------
        apply_test(8'hAA, 8'h00, 4'b1000, 2'b11, "SHR_A INP=11");
        apply_test(8'hAA, 8'h00, 4'b1000, 2'b01, "SHR_A INP=01");
        apply_test(8'h01, 8'h00, 4'b1000, 2'b11, "SHR_A LSB");
        // ELSE (hits alu.v:656 err<=1)
        apply_test(8'hAA, 8'h00, 4'b1000, 2'b10, "SHR_A INP=10 ERR");
        apply_test(8'hAA, 8'h00, 4'b1000, 2'b00, "SHR_A INP=00 ERR");

        // -- SHL_A (CMD=9) -------------------------------------------------
        apply_test(8'h55, 8'h00, 4'b1001, 2'b01, "SHL_A INP=01");
        apply_test(8'h55, 8'h00, 4'b1001, 2'b11, "SHL_A INP=11");
        apply_test(8'h80, 8'h00, 4'b1001, 2'b11, "SHL_A MSB");
        // ELSE (hits alu.v:657 err<=1)
        apply_test(8'h55, 8'h00, 4'b1001, 2'b10, "SHL_A INP=10 ERR");
        apply_test(8'h55, 8'h00, 4'b1001, 2'b00, "SHL_A INP=00 ERR");

        // -- SHR_B (CMD=10) -----------------------------------------------
        apply_test(8'hAA, 8'h0A, 4'b1010, 2'b11, "SHR_B INP=11");
        apply_test(8'h00, 8'h0A, 4'b1010, 2'b10, "SHR_B INP=10");
        // ELSE
        apply_test(8'h00, 8'h0A, 4'b1010, 2'b01, "SHR_B INP=01 ERR");
        apply_test(8'h00, 8'h0A, 4'b1010, 2'b00, "SHR_B INP=00 ERR");

        // -- SHL_B (CMD=11) -----------------------------------------------
        apply_test(8'h00, 8'h55, 4'b1011, 2'b10, "SHL_B INP=10");
        apply_test(8'h00, 8'h80, 4'b1011, 2'b11, "SHL_B MSB");
        // ELSE
        apply_test(8'h00, 8'h55, 4'b1011, 2'b01, "SHL_B INP=01 ERR");
        apply_test(8'h00, 8'h55, 4'b1011, 2'b00, "SHL_B INP=00 ERR");

        // -- ROL (CMD=12) valid --------------------------------------------
        apply_test(8'hAA, 8'h00, 4'b1100, 2'b11, "ROL rot_amt=0");
        apply_test(8'hAA, 8'h01, 4'b1100, 2'b11, "ROL rot_amt=1");
        apply_test(8'hAA, 8'h03, 4'b1100, 2'b11, "ROL rot_amt=3");
        apply_test(8'hAA, 8'h07, 4'b1100, 2'b11, "ROL rot_amt=7");
        apply_test(8'hFF, 8'h03, 4'b1100, 2'b11, "ROL OPA=FF");
        apply_test(8'h00, 8'h03, 4'b1100, 2'b11, "ROL OPA=00");
        // opb >= N=8 ? err=1 (hits alu.v ERR branch)
        apply_test(8'hAA, 8'h08, 4'b1100, 2'b11, "ROL ERR opb=8");
        apply_test(8'hAA, 8'hFF, 4'b1100, 2'b11, "ROL ERR opb=FF");
        // ELSE inp_valid != 11
        apply_test(8'hAA, 8'h03, 4'b1100, 2'b00, "ROL INP=00 ERR");
        apply_test(8'hAA, 8'h03, 4'b1100, 2'b01, "ROL INP=01 ERR");
        apply_test(8'hAA, 8'h03, 4'b1100, 2'b10, "ROL INP=10 ERR");

        // -- ROR (CMD=13) valid --------------------------------------------
        apply_test(8'hAA, 8'h00, 4'b1101, 2'b11, "ROR rot_amt=0");
        apply_test(8'hAA, 8'h01, 4'b1101, 2'b11, "ROR rot_amt=1");
        apply_test(8'hAA, 8'h02, 4'b1101, 2'b11, "ROR rot_amt=2");
        apply_test(8'h01, 8'h07, 4'b1101, 2'b11, "ROR rot_amt=7");
        apply_test(8'hFF, 8'h02, 4'b1101, 2'b11, "ROR OPA=FF");
        apply_test(8'h00, 8'h02, 4'b1101, 2'b11, "ROR OPA=00");
        // opb >= N=8 ? err=1
        apply_test(8'hAA, 8'h08, 4'b1101, 2'b11, "ROR ERR opb=8");
        apply_test(8'hAA, 8'hFF, 4'b1101, 2'b11, "ROR ERR opb=FF");
        // ELSE inp_valid != 11
        apply_test(8'hAA, 8'h02, 4'b1101, 2'b00, "ROR INP=00 ERR");
        apply_test(8'hAA, 8'h02, 4'b1101, 2'b01, "ROR INP=01 ERR");
        apply_test(8'hAA, 8'h02, 4'b1101, 2'b10, "ROR INP=10 ERR");

        // -- Default ERR CMDs ----------------------------------------------
        apply_test(8'hAA, 8'hFB, 4'b1110, 2'b11, "MODE0 CMD=14 ERR");
        apply_test(8'hAA, 8'hFB, 4'b1111, 2'b11, "MODE0 CMD=15 ERR");


	end
    endtask

    // Apply test and check
    task apply_test(
        input [7:0] a, b,
        input [3:0] cmd,
	    input [1:0] inp_valid,
        input [80*20:1] test_name
    );
        begin
            OPA = a;
            OPB = b;
            CMD = cmd;
	        INP_VAD = inp_valid;
	      //  @(posedge CLK);
		    if((cmd == 4'b1001 || cmd == 4'b1010) && MODE==1)begin
		          @(posedge CLK);
		    end  
            @(posedge CLK);
	    @(posedge CLK);
	    #1;
            RES_EXP = {RES_ref,COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref};
            compare(test_name);
        end
    endtask

    // Compare DUT vs Reference
    task compare(
        input [80*20:1] test_name
    );
        begin
	    test_count=test_count+1;
            compare_outputs = 1;
            // Compare RES (handle Z values)
            if (RES_dut !== RES_EXP[21:6]) begin
                if (!((RES_dut === 'bz) && (RES_EXP[21:6] === 'bz)))
                    compare_outputs = 0;
            end

            if (!compare_bit(COUT_dut, RES_EXP[5])) compare_outputs = 0;
            if (!compare_bit(OFLOW_dut, RES_EXP[4])) compare_outputs = 0;
            if (!compare_bit(G_dut, RES_EXP[3])) compare_outputs = 0;
            if (!compare_bit(E_dut, RES_EXP[2])) compare_outputs = 0;
            if (!compare_bit(L_dut, RES_EXP[1])) compare_outputs = 0;
            if (!compare_bit(ERR_dut, RES_EXP[0])) compare_outputs = 0;
            
            if (compare_outputs) begin
                $display("[PASS] test_name = %s test_number = %d : OPA=%d OPB=%d CMD=%d MODE = %B INP_VALID=%B ", 
                         test_name,test_count, OPA, OPB, CMD,MODE,INP_VAD);
		display_mismatch();
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] test_name = %s test_number = %d : OPA=%d OPB=%d CMD=%d MODE = %B INP_VALID=%B ", 
                         test_name,test_count, OPA, OPB, CMD,MODE,INP_VAD);
                display_mismatch();
                fail_count = fail_count + 1;
            end
            
        end
    endtask

    // Compare single bit (handle Z)
    function compare_bit(input dut, ref);
        begin
            if (dut === ref)
                compare_bit = 1;
            else
                compare_bit = 0;
        end
    endfunction

    // Display mismatch details
    task display_mismatch();
        begin
            $display("  DUT: RES=%d COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                     RES_dut, COUT_dut, OFLOW_dut, G_dut, E_dut, L_dut, ERR_dut);
            $display("  REF: RES=%d COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
                     RES_EXP[21:6],RES_EXP[5], RES_EXP[4], RES_EXP[3], RES_EXP[2], RES_EXP[1], RES_EXP[0]);
        end
    endtask

    // Waveform dump
    initial begin
        $dumpfile("alu_test.vcd");
        $dumpvars(0, alu_testbench);
    end
endmodule

