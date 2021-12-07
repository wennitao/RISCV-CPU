`define False 1'b0
`define True 1'b1
`define Disable 1'b0
`define Enable 1'b1
`define Invalid 1'b0
`define Valid 1'b1
`define Free 1'b0
`define Busy 1'b1
`define Fail 1'b0
`define Success 1'b1
`define Unready 1'b0
`define Ready 1'b1

`define Tilde1 32'hfffffffe

`define AddressBus 31:0
`define DataBus 31:0
`define RamDataBus 7:0
`define InstBus 31:0
`define RegBus 4:0

`define PcStep 32'h4
`define AddressStep 32'h1

`define Read 1'b0
`define Write 1'b1

`define Null 0

// MemCtrl
`define StatusBus 1:0
`define NoTask 2'b00
`define Inst 2'b01
`define DataRead 2'b10
`define DataWrite 2'b11
`define StageBus 2:0
`define None 3'b000
`define StageOne 3'b001
`define StageTwo 3'b010
`define StageThree 3'b011
`define Done 3'b100
`define Step 3'b001
`define LenBus 2:0

// InstCache
`define InstCacheSizeBus 511:0
`define InstCacheIndexBus 10:2
`define InstCacheTagBus 17:11
`define InstCacheTagLenBus 6:0

// InstructionQueue
`define IQLenBus 16
`define IQIdxBus 3:0
`define IQMaxIndex 4'b1111
`define IQZeroIndex 4'b0000
`define IQFull 1'b1
`define IQNotFull 1'b0
`define IQEmpty 1'b1
`define IQNotEmpty 1'b0

// RS
`define RSBus 3:0
`define RSSize 16
`define RSFull 1'b1
`define RSNotFull 1'b0
`define RSZeroIndex 4'b0000
`define RSMaxIndex 4'b1111

// ROB
`define TagBus 3:0
`define TypeBus 2:0
`define TypeReg 3'b000
`define TypePc 3'b001
`define TypeStore 3'b010
`define TypeLoad 3'b011
`define TypePcAndReg 3'b100
`define ROBBus 3:0
`define ROBSize 16
`define ROBSizeBus 15:0
`define ROBZeroIndex 4'b0000
`define ROBMaxIndex 4'b1111

// op
`define OPBus 5:0
`define LB    6'b000001
`define LH    6'b000010
`define LW    6'b000011
`define LBU   6'b000100
`define LHU   6'b000101
`define SB    6'b000110
`define SH    6'b000111
`define SW    6'b001000
`define ADD   6'b001001
`define ADDI  6'b001010
`define SUB   6'b001011
`define LUI   6'b001100
`define AUIPC 6'b001101
`define XOR   6'b001110
`define XORI  6'b001111
`define OR    6'b010000
`define ORI   6'b010001
`define AND   6'b010010
`define ANDI  6'b010011
`define SLL   6'b010100
`define SLLI  6'b010101
`define SRL   6'b010110
`define SRLI  6'b010111
`define SRA   6'b011000
`define SRAI  6'b011001
`define SLT   6'b011010
`define SLTI  6'b011011
`define SLTU  6'b011100
`define SLTIU 6'b011101
`define BEQ   6'b011110
`define BNE   6'b011111
`define BLT   6'b100000
`define BGE   6'b100001
`define BLTU  6'b100010
`define BGEU  6'b100011
`define JAL   6'b100100
`define JALR  6'b100101