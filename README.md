# ALU_Design
Parameterized ALU – Design & Verification
Author: G. Mathan  |  ID: 6909  |  Organization: Mirafra Technologies  
Tool: QuestaSim 10.6c  |  Language: Verilog RTL
---
Table of Contents
Project Overview
Repository Structure
Design Architecture
Pin Description
Supported Operations
Timing Behaviour
Testbench Architecture
How to Run
Coverage Results
Known Issues & Fixes
---
1. Project Overview
This project implements and verifies a parameterized Arithmetic Logic Unit (ALU) in synthesizable Verilog RTL. The ALU supports 13 arithmetic and 14 logical operations, controlled by a MODE signal and a 4-bit command bus.
Two separate verification efforts were carried out:
Task	Design	Coverage Achieved
Self-verification	`ALU_DESIGN_NEW` (own design)	97.16%
Independent verification	`alu.v` (assigned external design)	94.19%
---
2. Repository Structure
```
ALU_Design/
├── ALU_design.v               # Own ALU design (ALU_DESIGN_NEW)
├── alu.v                      # External ALU design assigned for verification
├── alu_reference_model.v      # Combinational reference model
├── alu_testbench.v            # Self-checking testbench
├── alu_test.vcd               # Simulation waveform output
├── coveragenew.ucdb           # Coverage database (own design)
├── covReport/                 # HTML coverage report (own design)
├── covReport_new/             # HTML coverage report (external design)
├── transcript                 # QuestaSim simulation transcript
├── work/                      # Compiled simulation library
└── README.md                  # This file
```
---
3. Design Architecture
Module
```verilog
module ALU_DESIGN_NEW #(parameter WIDTH = 4, M = 4)(
    OPA, OPB, CIN, CLK, RST, CMD, CE, MODE, INP_VAD,
    COUT, OFLOW, RES, G, E, L, ERR
);
```
Key Features
Fully parameterized — `WIDTH` sets operand width (default 8-bit); `M` sets command bus width (default 4-bit)
Two-stage pipeline — inputs registered on clock edge 1; computation on clock edge 2
Input validity checking — `INP_VAD[1:0]` controls which operands are active per command
Asynchronous active-high reset — clears all outputs and pipeline registers instantly
Clock enable (CE) — when `CE=0`, all outputs hold their current value
Two-cycle multiply — CMD=9 and CMD=10 use an internal state machine across 2 clock cycles
Signed arithmetic — CMD=11 (signed ADD) and CMD=12 (signed SUB) with overflow detection
Internal Pipeline Registers
Register	Purpose
`OPA_NEW`, `OPB_NEW`	Registered operands
`MODE_NEW`, `CMD_NEW`	Registered control signals
`CIN_NEW`, `INP_VALID_NEW`	Registered carry-in and validity
`OPA_MUL`, `OPB_MUL`	Intermediate multiply operands
`mul_state1`, `mul_state2`	State bits for 2-cycle multiply pipeline
---
4. Pin Description
Inputs
Signal	Width	Description
`OPA`	WIDTH	Operand A
`OPB`	WIDTH	Operand B
`CIN`	1	Carry-in (for ADD_CIN, SUB_CIN)
`CLK`	1	Rising-edge clock
`RST`	1	Asynchronous active-high reset
`CE`	1	Clock enable (active high)
`MODE`	1	`1` = Arithmetic, `0` = Logical
`INP_VAD`	2	`00`=none, `01`=OPA valid, `10`=OPB valid, `11`=both valid
`CMD`	M (4)	Operation select
Outputs
Signal	Width	Description
`RES`	2×WIDTH	Operation result
`COUT`	1	Carry out
`OFLOW`	1	Overflow flag
`G`	1	Greater-than (OPA > OPB)
`E`	1	Equal (OPA == OPB)
`L`	1	Less-than (OPA < OPB)
`ERR`	1	Error (invalid `INP_VAD` or unsupported `CMD`)
---
5. Supported Operations
Arithmetic Mode (`MODE=1`)
CMD	Mnemonic	INP_VAD Needed	Operation
`0000`	ADD	`11`	`RES = OPA + OPB`; COUT on carry
`0001`	SUB	`11`	`RES = OPA - OPB`; OFLOW if OPA < OPB
`0010`	ADD_CIN	`11`	`RES = OPA + OPB + CIN`; COUT on carry
`0011`	SUB_CIN	`11`	`RES = OPA - OPB - CIN`; OFLOW on borrow
`0100`	INC_A	`01` or `11`	`RES = OPA + 1`
`0101`	DEC_A	`01` or `11`	`RES = OPA - 1`
`0110`	INC_B	`10` or `11`	`RES = OPB + 1`
`0111`	DEC_B	`10` or `11`	`RES = OPB - 1`
`1000`	CMP	`11`	Sets G / E / L flags
`1001`	MUL9	`11`	`RES = (OPA+1) × (OPB+1)` — 2 cycles
`1010`	MUL10	`11`	`RES = (OPA<<1) × OPB` — 2 cycles
`1011`	SIGNED ADD	`11`	Signed addition; OFLOW, G, E, L
`1100`	SIGNED SUB	`11`	Signed subtraction; OFLOW, G, E, L
`1101–1111`	ERR	—	Unsupported → `ERR=1`
Logical Mode (`MODE=0`)
CMD	Mnemonic	INP_VAD Needed	Operation
`0000`	AND	`11`	`RES = OPA & OPB`
`0001`	NAND	`11`	`RES = ~(OPA & OPB)`
`0010`	OR	`11`	`RES = OPA | OPB`
`0011`	NOR	`11`	`RES = ~(OPA | OPB)`
`0100`	XOR	`11`	`RES = OPA ^ OPB`
`0101`	XNOR	`11`	`RES = ~(OPA ^ OPB)`
`0110`	NOT_A	`01` or `11`	`RES = ~OPA`
`0111`	NOT_B	`10` or `11`	`RES = ~OPB`
`1000`	SHR1_A	`01` or `11`	`RES = OPA >> 1`
`1001`	SHL1_A	`01` or `11`	`RES = OPA << 1`
`1010`	SHR1_B	`10` or `11`	`RES = OPB >> 1`
`1011`	SHL1_B	`10` or `11`	`RES = OPB << 1`
`1100`	ROL_A_B	`11`	Rotate OPA left by `OPB[2:0]`; `ERR=1` if `OPB[7:4]≠0`
`1101`	ROR_A_B	`11`	Rotate OPA right by `OPB[2:0]`; `ERR=1` if `OPB[7:4]≠0`
`1110–1111`	ERR	—	Unsupported → `ERR=1`
---
6. Timing Behaviour
The ALU has a 2-cycle latency for all operations except multiply (3 cycles):
```
Cycle 1  → Apply inputs (OPA, OPB, CMD, MODE, INP_VAD)
Cycle 2  → DUT registers inputs internally (OPA_NEW, CMD_NEW, …)
Cycle 3  → DUT computes and drives outputs ← sample here (#1 after posedge)

For MUL (CMD=9 or CMD=10):
Cycle 1  → Apply inputs
Cycle 2  → DUT registers; starts first multiply stage
Cycle 3  → DUT completes multiply
Cycle 4  → Outputs valid ← sample here
```
Reset & CE behaviour
```
RST=1  →  All outputs and pipeline registers clear to 0 (asynchronous, any time)
CE=0   →  All outputs hold their previous values; pipeline does not update
CE=1   →  Normal operation
```
---
7. Testbench Architecture
```
                 ┌─────────────────────┐
  Stimulus ─────►│   alu_testbench     │
                 │                     │
                 │  ┌──────────────┐   │
                 │  │ ALU_DESIGN   │──►│─── DUT outputs
                 │  │ _NEW (DUT)   │   │       │
                 │  └──────────────┘   │       │  compare()
                 │                     │       ▼
                 │  ┌──────────────┐   │  ┌─────────┐
                 │  │alu_reference │──►│─►│ PASS /  │
                 │  │  _model      │   │  │  FAIL   │
                 │  └──────────────┘   │  └─────────┘
                 └─────────────────────┘
```
Key Tasks
Task	Purpose
`apply_test(a, b, cmd, inp_vad, name)`	Drive inputs, wait for output, compare DUT vs REF
`compare(name, tc)`	Bit-by-bit comparison of all 7 outputs
`test_reset(name)`	Verify all outputs are zero after RST
`test_arithmetic()`	All MODE=1 test vectors
`test_logical()`	All MODE=0 test vectors
`display_mismatch()`	Print DUT and REF values on failure
Self-Checking Flow
```verilog
// Per-test flow inside apply_test
OPA = a; OPB = b; CMD = cmd; INP_VAD = inp_valid;
@(posedge CLK);   // cycle 1: inputs registered into pipeline
@(posedge CLK);   // cycle 2: computation executes
@(posedge CLK);   // cycle 3: outputs fully settled
#1;
RES_EXP = {RES_ref, COUT_ref, OFLOW_ref, G_ref, E_ref, L_ref, ERR_ref};
compare(test_name, tc);
```
---
8. How to Run
Compile
```bash
# Clean stale library first (important after any port rename)
rm -rf work

# Compile all source files
vlog ALU_design.v alu_reference_model.v alu_testbench.v
```
Simulate
```bash
# Basic simulation
vsim -c alu_testbench -do "run -all; quit"

# With coverage collection
vsim -c -coverage alu_testbench -do "run -all; quit"
```
Collect and View Coverage
```bash
# Merge coverage into UCDB
vcover merge coveragenew.ucdb vsim.ucdb

# Generate HTML report
vcover report -html coveragenew.ucdb -htmldir covReport -details

# Open report (local browser)
firefox covReport/index.html

# OR copy to local machine and open
scp -r user@feserver:/path/ALU_Design/covReport ~/Desktop/covReport
```
View Waveform
```bash
# In QuestaSim GUI
vsim alu_testbench
add wave -r /*
run -all

# Or open VCD in GTKWave
gtkwave alu_test.vcd
```
---
9. Coverage Results
Own Design — `ALU_DESIGN_NEW`
Coverage Type	Bins	Hits	Misses	Coverage
Statements	144	144	0	100.00%
Branches	122	119	3	97.54%
FEC Conditions	18	17	1	94.44%
Toggles	300	290	10	96.66%
Total				97.16%
External Design — `alu.v`
Coverage Type	Bins	Hits	Misses	Coverage
Statements	125	125	0	100.00%
Branches	100	100	0	100.00%
FEC Conditions	5	4	1	80.00%
Toggles	218	211	7	96.78%
Total				94.19%
---
10. Known Issues & Fixes
Issue	Root Cause	Fix Applied
`Port 'INV' not found` compile error	Port renamed from `INV` to `INP_VAD` but stale `work/` library cached old compiled object	`rm -rf work` then recompile all files
DUT always outputs stale result	`apply_test` sampled after only 2 clocks; 2-stage pipeline needs 3	Added third `@(posedge CLK)` before `compare()`
MUL tests failing	2-cycle multiply needs 4 total clocks before output	Added extra `@(posedge CLK)` for CMD=9 and CMD=10
`OPB_1[7:3]` never toggles	`OPB_1` is 8-bit but result of `3-bit mod 8` — upper bits structurally always 0	Accepted as design limitation; can exclude with `vcover exclude`
Missing `prev_mode != mode` FEC condition (external)	MODE transition with same CMD never occurred in test sequence	Run `test_arithmetic()` → `test_logical()` → `test_arithmetic()` in order
---
Report generated: 11 May 2026 — QuestaSim 10.6c — Mirafra Technologies
