`include "cpu_define.v"
// RISCV32I CPU top module
// port modification allowed for debugging purposes
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// ALU <- ALURS
wire ALU_ALURS_enable ;
wire[`OPBus] ALU_ALURS_op ; 
wire[`DataBus] ALU_ALURS_reg1 ; 
wire[`DataBus] ALU_ALURS_reg2 ; 
wire[`TagBus] ALU_ALURS_des_rob ; 
wire[`DataBus] ALU_ALURS_imm ; 
wire[`AddressBus] ALU_ALURS_pc ; 

// ALU_cdb
wire ALU_cdb_valid ;
wire [`TagBus] ALU_cdb_tag ;
wire [`DataBus] ALU_cdb_data ;

// ALURS <-> ID
wire ALURS_ID_is_full ;

// ALURS <-> dispatch
wire ALURS_dispatch_valid ; 
wire[`OPBus] ALURS_dispatch_op ; 
wire[`DataBus] ALURS_dispatch_imm ; 
wire[`AddressBus] ALURS_dispatch_pc ; 
wire ALURS_dispatch_reg1_valid ; 
wire[`DataBus] ALURS_dispatch_reg1_data ; 
wire[`TagBus] ALURS_dispatch_reg1_tag ; 
wire ALURS_dispatch_reg2_valid ; 
wire[`DataBus] ALURS_dispatch_reg2_data ; 
wire[`TagBus] ALURS_dispatch_reg2_tag ; 
wire[`TagBus] ALURS_dispatch_reg_dest_tag ; 

// Branch <-> BranchRS
wire Branch_BranchRS_enable ; 
wire[`OPBus] Branch_BranchRS_op ;
wire[`DataBus] Branch_BranchRS_reg1 ;
wire[`DataBus] Branch_BranchRS_reg2 ; 
wire[`TagBus] Branch_BranchRS_dest_rob ; 
wire[`DataBus] Branch_BranchRS_imm ; 
wire[`AddressBus] Branch_BranchRS_pc ; 

// Branch_cdb 
wire Branch_cdb_valid ; 
wire[`TagBus] Branch_cdb_tag ; 
wire Branch_cdb_jump_judge ; 
wire[`AddressBus] Branch_cdb_pc ; 
wire[`AddressBus] Branch_cdb_original_pc ; 
wire[`DataBus] Branch_cdb_data ;

// BranchRS <-> ID
wire BranchRS_ID_is_full ;

// BranchRS <-> dispatch
wire BranchRS_dispatch_valid ;
wire[`OPBus] BranchRS_dispatch_op ;
wire[`DataBus] BranchRS_dispatch_imm ;
wire[`AddressBus] BranchRS_dispatch_pc ;
wire BranchRS_dispatch_reg1_valid ;
wire[`DataBus] BranchRS_dispatch_reg1_data ;
wire[`TagBus] BranchRS_dispatch_reg1_tag ;
wire BranchRS_dispatch_reg2_valid ;
wire[`DataBus] BranchRS_dispatch_reg2_data ;
wire[`TagBus] BranchRS_dispatch_reg2_tag ;
wire[`TagBus] BranchRS_dispatch_reg_dest_tag ;

// dispatch <-> ID
wire dispatch_ID_valid ; 
wire[`OPBus] dispatch_ID_op ; 
wire[`DataBus] dispatch_ID_imm ; 
wire[`AddressBus] dispatch_ID_pc ; 
wire[`TagBus] dispatch_ID_reg_dest_tag ; 

// dispatch <-> regfile
wire dispatch_regfile_reg1_valid ; 
wire[`DataBus] dispatch_regfile_reg1_data ; 
wire[`TagBus] dispatch_regfile_reg1_tag ; 
wire dispatch_regfile_reg2_valid ; 
wire[`DataBus] dispatch_regfile_reg2_data ; 
wire[`TagBus] dispatch_regfile_reg2_tag ; 

// dispatch <-> ROB
wire dispatch_ROB_reg1_enable ; 
wire[`TagBus] dispatch_ROB_reg1_tag ; 
wire dispatch_ROB_reg2_enable ; 
wire[`TagBus] dispatch_ROB_reg2_tag ; 
wire dispatch_ROB_reg1_valid ; 
wire[`DataBus] dispatch_ROB_reg1_data ; 
wire dispatch_ROB_reg2_valid ; 
wire[`DataBus] dispatch_ROB_reg2_data ; 

// dispatch <-> LoadStoreBufferRS
wire dispatch_LSBRS_enable ; 
wire[`OPBus] dispatch_LSBRS_op ; 
wire[`DataBus] dispatch_LSBRS_imm ; 
wire[`AddressBus] dispatch_LSBRS_pc ; 
wire dispatch_LSBRS_reg1_valid ; 
wire[`DataBus] dispatch_LSBRS_reg1_data ; 
wire[`TagBus] dispatch_LSBRS_reg1_tag ; 
wire dispatch_LSBRS_reg2_valid ; 
wire[`DataBus] dispatch_LSBRS_reg2_data ; 
wire[`TagBus] dispatch_LSBRS_reg2_tag ; 
wire[`TagBus] dispatch_LSBRS_reg_dest_tag ;

// ID <-> InstructionQueue
wire ID_InstQueue_queue_is_empty ;
wire[`InstBus] ID_InstQueue_inst ;
wire[`AddressBus] ID_InstQueue_pc ;
wire ID_InstQueue_enable ;

// ID <-> LoadStoreBufferRS
wire ID_LSBRS_is_full;

// ID <-> ROB
wire ID_ROB_is_full ;

// ID <-> regfile
wire ID_regfile_reg1_valid ;
wire[`RegBus] ID_regfile_reg1_addr ;
wire ID_regfile_reg2_valid ;
wire[`RegBus] ID_regfile_reg2_addr ;

wire ID_regfile_reg_dest_valid ;
wire[`RegBus] ID_regfile_reg_dest_addr ;
wire[`TagBus] ID_regfile_reg_dest_tag ;

// ID <-> ROB
wire[`InstBus] ID_ROB_debug_inst ;
wire[`TagBus] ID_ROB_tag ;
wire ID_ROB_valid ;
wire ID_ROB_ready ;
wire[`RegBus] ID_ROB_reg_dest ;
wire[`TypeBus] ID_ROB_type ;

// IF <-> InstCache
wire IF_InstCache_inst_valid, IF_InstCache_inst_read_valid ;
wire [`AddressBus] IF_InstCache_inst_addr ;
wire [`InstBus] IF_InstCache_inst ;

// IF <-> InstructionQueue
wire IF_InstQueue_inst_valid ;
wire [`InstBus] IF_InstQueue_inst ;
wire [`AddressBus] IF_InstQueue_pc ;
wire IF_InstQueue_queue_is_full ;

// IF <-> ROB
wire IF_ROB_jump_judge ;
wire[`AddressBus] IF_ROB_pc ;

// InstCache <-> MemCtrl
wire InstCache_MemCtrl_inst_read_valid, InstCache_MemCtrl_inst_valid ;
wire [`AddressBus] InstCache_MemCtrl_inst_addr ;
wire [`InstBus] InstCache_MemCtrl_inst ;

// LoadStoreBuffer <-> LoadStoreBufferRS
wire LSB_LSBRS_enable ;
wire[`OPBus] LSB_LSBRS_op ;
wire[`DataBus] LSB_LSBRS_imm ;
wire[`DataBus] LSB_LSBRS_reg1_data ;
wire[`DataBus] LSB_LSBRS_reg2_data ;
wire[`TagBus] LSB_LSBRS_reg_dest_tag ;
wire LSB_LSBRS_is_full ;

// LoadStoreBuffer <-> MemCtrl
wire LSB_MemCtrl_valid, LSB_MemCtrl_is_write ;
wire [`AddressBus] LSB_MemCtrl_addr ;
wire [`LenBus] LSB_MemCtrl_data_len ;
wire [`DataBus] LSB_MemCtrl_write_data ;
wire LSB_MemCtrl_data_valid ;
wire [`DataBus] LSB_MemCtrl_data ;

// LoadStoreBuffer <-> ROB
wire LSB_ROB_commit ;

// LoadStoreBuffer cdb
wire LSB_cdb_valid ;
wire[`TagBus] LSB_cdb_tag ;
wire[`DataBus] LSB_cdb_data ;

// regfile <-> ROB
wire regfile_ROB_data_valid ;
wire[`RegBus] regfile_ROB_reg_dest ;
wire[`TagBus] regfile_ROB_tag ;
wire[`DataBus] regfile_ROB_data ;

wire clear ;

// ROB cdb
wire ROB_cdb_valid ;
wire[`RegBus] ROB_cdb_reg_dest ;
wire[`TagBus] ROB_cdb_tag ;
wire[`DataBus] ROB_cdb_data ;

ALU ALU (
  .ALURS_enable (ALU_ALURS_enable), 
  .ALURS_op (ALU_ALURS_op), 
  .ALURS_reg1 (ALU_ALURS_reg1), 
  .ALURS_reg2 (ALU_ALURS_reg2), 
  .ALURS_des_rob (ALU_ALURS_des_rob),  
  .ALURS_imm (ALU_ALURS_imm), 
  .ALURS_pc (ALU_ALURS_pc), 

  .CDB_valid (ALU_cdb_valid), 
  .CDB_tag (ALU_cdb_tag), 
  .CDB_data (ALU_cdb_data)
) ;

ALURS ALURS (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 
  .clear (clear), 

  .ALURS_is_full (ALURS_ID_is_full), 

  .dispatch_valid (ALURS_dispatch_valid), 
  .dispatch_op (ALURS_dispatch_op), 
  .dispatch_imm (ALURS_dispatch_imm), 
  .dispatch_pc (ALURS_dispatch_pc), 
  .dispatch_reg1_valid (ALURS_dispatch_reg1_valid), 
  .dispatch_reg1_data (ALURS_dispatch_reg1_data), 
  .dispatch_reg1_tag (ALURS_dispatch_reg1_tag), 
  .dispatch_reg2_valid (ALURS_dispatch_reg2_valid), 
  .dispatch_reg2_data (ALURS_dispatch_reg2_data), 
  .dispatch_reg2_tag (ALURS_dispatch_reg2_tag), 
  .dispatch_reg_dest_tag (ALURS_dispatch_reg_dest_tag), 

  .ALU_valid (ALU_ALURS_enable), 
  .ALU_op (ALU_ALURS_op), 
  .ALU_reg1 (ALU_ALURS_reg1), 
  .ALU_reg2 (ALU_ALURS_reg2), 
  .ALU_reg_des_rob (ALU_ALURS_des_rob), 
  .ALU_imm (ALU_ALURS_imm), 
  .ALU_pc (ALU_ALURS_pc), 

  .ALU_cdb_valid (ALU_cdb_valid), 
  .ALU_cdb_tag (ALU_cdb_tag), 
  .ALU_cdb_data (ALU_cdb_data), 
  .LSB_cdb_valid (LSB_cdb_valid), 
  .LSB_cdb_tag (LSB_cdb_tag), 
  .LSB_cdb_data (LSB_cdb_data), 
  .Branch_cdb_valid (Branch_cdb_valid), 
  .Branch_cdb_tag (Branch_cdb_tag), 
  .Branch_cdb_data (Branch_cdb_data), 
  .ROB_cdb_valid (ROB_cdb_valid), 
  .ROB_cdb_tag (ROB_cdb_tag), 
  .ROB_cdb_data (ROB_cdb_data)
) ;

Branch Branch(
  .BranchRS_enable (Branch_BranchRS_enable), 
  .BranchRS_op (Branch_BranchRS_op), 
  .BranchRS_reg1 (Branch_BranchRS_reg1), 
  .BranchRS_reg2 (Branch_BranchRS_reg2), 
  .BranchRS_dest_rob (Branch_BranchRS_dest_rob), 
  .BranchRS_imm (Branch_BranchRS_imm), 
  .BranchRS_pc (Branch_BranchRS_pc), 

  .CDB_valid (Branch_cdb_valid), 
  .CDB_tag (Branch_cdb_tag), 
  .CDB_jump_judge (Branch_cdb_jump_judge), 
  .CDB_pc (Branch_cdb_pc), 
  .CDB_original_pc (Branch_cdb_original_pc), 
  .CDB_data (Branch_cdb_data)
) ;

BranchRS BranchRS (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 
  .clear (clear), 

  .BranchRS_is_full (BranchRS_ID_is_full), 

  .dispatch_valid (BranchRS_dispatch_valid), 
  .dispatch_op (BranchRS_dispatch_op), 
  .dispatch_imm (BranchRS_dispatch_imm), 
  .dispatch_pc (BranchRS_dispatch_pc), 
  .dispatch_reg1_valid (BranchRS_dispatch_reg1_valid), 
  .dispatch_reg1_data (BranchRS_dispatch_reg1_data), 
  .dispatch_reg1_tag (BranchRS_dispatch_reg1_tag), 
  .dispatch_reg2_valid (BranchRS_dispatch_reg2_valid), 
  .dispatch_reg2_data (BranchRS_dispatch_reg2_data), 
  .dispatch_reg2_tag (BranchRS_dispatch_reg2_tag), 
  .dispatch_reg_dest_tag (BranchRS_dispatch_reg_dest_tag), 

  .Branch_valid (Branch_BranchRS_enable), 
  .Branch_op (Branch_BranchRS_op), 
  .Branch_reg1 (Branch_BranchRS_reg1), 
  .Branch_reg2 (Branch_BranchRS_reg2), 
  .Branch_reg_des_rob (Branch_BranchRS_dest_rob), 
  .Branch_imm (Branch_BranchRS_imm), 
  .Branch_pc (Branch_BranchRS_pc), 

  .ALU_cdb_valid (ALU_cdb_valid), 
  .ALU_cdb_tag (ALU_cdb_tag), 
  .ALU_cdb_data (ALU_cdb_data), 
  .LSB_cdb_valid (LSB_cdb_valid), 
  .LSB_cdb_tag (LSB_cdb_tag), 
  .LSB_cdb_data (LSB_cdb_data), 
  .Branch_cdb_valid (Branch_cdb_valid), 
  .Branch_cdb_tag (Branch_cdb_tag), 
  .Branch_cdb_data (Branch_cdb_data), 
  .ROB_cdb_valid (ROB_cdb_valid), 
  .ROB_cdb_tag (ROB_cdb_tag), 
  .ROB_cdb_data (ROB_cdb_data)
) ;

dispatch dispatch (
  .ID_valid (dispatch_ID_valid), 
  .ID_op (dispatch_ID_op), 
  .ID_imm (dispatch_ID_imm), 
  .ID_pc (dispatch_ID_pc), 
  .ID_reg_dest_tag (dispatch_ID_reg_dest_tag), 

  .regfile_reg1_valid (dispatch_regfile_reg1_valid), 
  .regfile_reg1_data (dispatch_regfile_reg1_data), 
  .regfile_reg1_tag (dispatch_regfile_reg1_tag), 
  .regfile_reg2_valid (dispatch_regfile_reg2_valid), 
  .regfile_reg2_data (dispatch_regfile_reg2_data), 
  .regfile_reg2_tag (dispatch_regfile_reg2_tag), 

  .ROB_reg1_enable (dispatch_ROB_reg1_enable), 
  .ROB_reg1_tag (dispatch_ROB_reg1_tag), 
  .ROB_reg2_enable (dispatch_ROB_reg2_enable), 
  .ROB_reg2_tag (dispatch_ROB_reg2_tag), 
  .ROB_reg1_valid (dispatch_ROB_reg1_valid), 
  .ROB_reg1_data (dispatch_ROB_reg1_data), 
  .ROB_reg2_valid (dispatch_ROB_reg2_valid), 
  .ROB_reg2_data (dispatch_ROB_reg2_data), 

  .ALURS_enable (ALURS_dispatch_valid), 
  .ALURS_op (ALURS_dispatch_op), 
  .ALURS_imm (ALURS_dispatch_imm), 
  .ALURS_pc (ALURS_dispatch_pc), 
  .ALURS_reg1_valid (ALURS_dispatch_reg1_valid), 
  .ALURS_reg1_data (ALURS_dispatch_reg1_data), 
  .ALURS_reg1_tag (ALURS_dispatch_reg1_tag), 
  .ALURS_reg2_valid (ALURS_dispatch_reg2_valid), 
  .ALURS_reg2_data (ALURS_dispatch_reg2_data), 
  .ALURS_reg2_tag (ALURS_dispatch_reg2_tag), 
  .ALURS_reg_dest_tag (ALURS_dispatch_reg_dest_tag), 

  .BranchRS_enable (BranchRS_dispatch_valid), 
  .BranchRS_op (BranchRS_dispatch_op), 
  .BranchRS_imm (BranchRS_dispatch_imm), 
  .BranchRS_pc (BranchRS_dispatch_pc), 
  .BranchRS_reg1_valid (BranchRS_dispatch_reg1_valid), 
  .BranchRS_reg1_data (BranchRS_dispatch_reg1_data), 
  .BranchRS_reg1_tag (BranchRS_dispatch_reg1_tag), 
  .BranchRS_reg2_valid (BranchRS_dispatch_reg2_valid), 
  .BranchRS_reg2_data (BranchRS_dispatch_reg2_data), 
  .BranchRS_reg2_tag (BranchRS_dispatch_reg2_tag), 
  .BranchRS_reg_dest_tag (BranchRS_dispatch_reg_dest_tag), 

  .LSBRS_enable (dispatch_LSBRS_enable), 
  .LSBRS_op (dispatch_LSBRS_op), 
  .LSBRS_imm (dispatch_LSBRS_imm), 
  .LSBRS_pc (dispatch_LSBRS_pc), 
  .LSBRS_reg1_valid (dispatch_LSBRS_reg1_valid), 
  .LSBRS_reg1_data (dispatch_LSBRS_reg1_data), 
  .LSBRS_reg1_tag (dispatch_LSBRS_reg1_tag), 
  .LSBRS_reg2_valid (dispatch_LSBRS_reg2_valid), 
  .LSBRS_reg2_data (dispatch_LSBRS_reg2_data), 
  .LSBRS_reg2_tag (dispatch_LSBRS_reg2_tag), 
  .LSBRS_reg_dest_tag (dispatch_LSBRS_reg_dest_tag)
) ;

ID ID (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 

  .ALURS_is_full (ALURS_ID_is_full), 
  .BranchRS_is_full (BranchRS_ID_is_full), 
  .LSBRS_is_full (ID_LSBRS_is_full), 
  .ROB_is_full (ID_ROB_is_full), 

  .InstQueue_queue_is_empty (ID_InstQueue_queue_is_empty), 
  .InstQueue_inst (ID_InstQueue_inst), 
  .InstQueue_pc (ID_InstQueue_pc), 
  .InstQueue_enable (ID_InstQueue_enable), 

  .regfile_reg1_valid (ID_regfile_reg1_valid), 
  .regfile_reg1_addr (ID_regfile_reg1_addr), 
  .regfile_reg2_valid (ID_regfile_reg2_valid), 
  .regfile_reg2_addr (ID_regfile_reg2_addr), 
  .regfile_reg_dest_valid (ID_regfile_reg_dest_valid), 
  .regfile_reg_dest_addr (ID_regfile_reg_dest_addr), 
  .regfile_reg_dest_tag (ID_regfile_reg_dest_tag), 

  .dispatch_enable (dispatch_ID_valid), 
  .dispatch_op (dispatch_ID_op), 
  .dispatch_imm (dispatch_ID_imm), 
  .dispatch_pc (dispatch_ID_pc), 
  .dispatch_reg_dest_tag (dispatch_ID_reg_dest_tag), 

  .ROB_tag (ID_ROB_tag), 
  .ROB_valid (ID_ROB_valid), 
  .ROB_ready (ID_ROB_ready), 
  .ROB_reg_dest (ID_ROB_reg_dest), 
  .ROB_type (ID_ROB_type), 

  .ROB_debug_inst (ID_ROB_debug_inst)
) ;

IF IF (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 

  .InstCache_inst_valid (IF_InstCache_inst_valid), 
  .InstCache_inst (IF_InstCache_inst), 
  .InstCache_inst_read_valid (IF_InstCache_inst_read_valid), 
  .InstCache_inst_addr (IF_InstCache_inst_addr), 

  .InstQueue_queue_is_full (IF_InstQueue_queue_is_full), 
  .InstQueue_inst_valid (IF_InstQueue_inst_valid), 
  .InstQueue_inst (IF_InstQueue_inst), 
  .InstQueue_pc (IF_InstQueue_pc), 

  .ROB_jump_judge (IF_ROB_jump_judge), 
  .ROB_pc (IF_ROB_pc)
) ;

InstructionCache InstructionCache (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 

  .IF_inst_read_valid (IF_InstCache_inst_read_valid), 
  .IF_inst_addr (IF_InstCache_inst_addr), 
  .IF_inst_valid (IF_InstCache_inst_valid), 
  .IF_inst (IF_InstCache_inst), 

  .MemCtrl_inst_valid (InstCache_MemCtrl_inst_valid), 
  .MemCtrl_inst (InstCache_MemCtrl_inst), 
  .MemCtrl_inst_read_valid (InstCache_MemCtrl_inst_read_valid), 
  .MemCtrl_inst_addr (InstCache_MemCtrl_inst_addr)
) ;

InstructionQueue InstructionQueue (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 
  .clear (clear), 

  .IF_inst_valid (IF_InstQueue_inst_valid), 
  .IF_inst (IF_InstQueue_inst), 
  .IF_pc (IF_InstQueue_pc), 
  .queue_is_full (IF_InstQueue_queue_is_full), 

  .ID_enable (ID_InstQueue_enable), 
  .queue_is_empty (ID_InstQueue_queue_is_empty), 
  .ID_inst (ID_InstQueue_inst), 
  .ID_pc (ID_InstQueue_pc)
) ;

LoadStoreBuffer LoadStoreBuffer (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 
  .clear (clear), 

  .LSBRS_enable (LSB_LSBRS_enable), 
  .LSBRS_op (LSB_LSBRS_op), 
  .LSBRS_imm (LSB_LSBRS_imm), 
  .LSBRS_reg1_data (LSB_LSBRS_reg1_data), 
  .LSBRS_reg2_data (LSB_LSBRS_reg2_data), 
  .LSBRS_reg_dest_tag (LSB_LSBRS_reg_dest_tag), 
  .LSB_is_full (LSB_LSBRS_is_full), 

  .MemCtrl_data_valid (LSB_MemCtrl_data_valid), 
  .MemCtrl_data (LSB_MemCtrl_data), 
  .MemCtrl_enable (LSB_MemCtrl_valid), 
  .MemCtrl_is_write (LSB_MemCtrl_is_write), 
  .MemCtrl_addr (LSB_MemCtrl_addr), 
  .MemCtrl_data_len (LSB_MemCtrl_data_len), 
  .MemCtrl_write_data (LSB_MemCtrl_write_data), 

  .ROB_commit (LSB_ROB_commit), 

  .CDB_valid (LSB_cdb_valid), 
  .CDB_tag (LSB_cdb_tag), 
  .CDB_data (LSB_cdb_data)
) ;

LoadStoreBufferRS LoadStoreBufferRS (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 
  .clear (clear), 

  .LSBRS_is_full (ID_LSBRS_is_full), 

  .dispatch_valid (dispatch_LSBRS_enable), 
  .dispatch_op (dispatch_LSBRS_op), 
  .dispatch_imm (dispatch_LSBRS_imm), 
  .dispatch_pc (dispatch_LSBRS_pc), 
  .dispatch_reg1_valid (dispatch_LSBRS_reg1_valid), 
  .dispatch_reg1_data (dispatch_LSBRS_reg1_data), 
  .dispatch_reg1_tag (dispatch_LSBRS_reg1_tag), 
  .dispatch_reg2_valid (dispatch_LSBRS_reg2_valid), 
  .dispatch_reg2_data (dispatch_LSBRS_reg2_data), 
  .dispatch_reg2_tag (dispatch_LSBRS_reg2_tag), 
  .dispatch_reg_dest_tag (dispatch_LSBRS_reg_dest_tag), 

  .LSB_valid (LSB_LSBRS_enable), 
  .LSB_op (LSB_LSBRS_op), 
  .LSB_reg1 (LSB_LSBRS_reg1_data), 
  .LSB_reg2 (LSB_LSBRS_reg2_data), 
  .LSB_reg_des_rob (LSB_LSBRS_reg_dest_tag), 
  .LSB_imm (LSB_LSBRS_imm), 

  .ALU_cdb_valid (ALU_cdb_valid), 
  .ALU_cdb_tag (ALU_cdb_tag), 
  .ALU_cdb_data (ALU_cdb_data), 
  .LSB_cdb_valid (LSB_cdb_valid), 
  .LSB_cdb_tag (LSB_cdb_tag), 
  .LSB_cdb_data (LSB_cdb_data), 
  .Branch_cdb_valid (Branch_cdb_valid), 
  .Branch_cdb_tag (Branch_cdb_tag), 
  .Branch_cdb_data (Branch_cdb_data), 
  .ROB_cdb_valid (ROB_cdb_valid), 
  .ROB_cdb_tag (ROB_cdb_tag), 
  .ROB_cdb_data (ROB_cdb_data)
) ;

MemCtrl MemCtrl (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in),
  .clear (clear),  

  .io_buffer_full (io_buffer_full), 

  .InstCache_inst_read_valid (InstCache_MemCtrl_inst_read_valid), 
  .InstCache_inst_addr (InstCache_MemCtrl_inst_addr), 
  .InstCache_inst_valid (InstCache_MemCtrl_inst_valid), 
  .InstCache_inst (InstCache_MemCtrl_inst), 

  .LSB_valid (LSB_MemCtrl_valid), 
  .LSB_is_write (LSB_MemCtrl_is_write), 
  .LSB_addr (LSB_MemCtrl_addr), 
  .LSB_data_len (LSB_MemCtrl_data_len), 
  .LSB_write_data (LSB_MemCtrl_write_data), 
  .LSB_data_valid (LSB_MemCtrl_data_valid), 
  .LSB_data (LSB_MemCtrl_data), 

  .mem_din (mem_din), 
  .mem_dout (mem_dout), 
  .mem_a (mem_a), 
  .mem_wr (mem_wr)
) ;

regfile regfile (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 
  .clear (clear), 

  .ID_reg1_valid (ID_regfile_reg1_valid), 
  .ID_reg1_addr (ID_regfile_reg1_addr), 
  .ID_reg2_valid (ID_regfile_reg2_valid), 
  .ID_reg2_addr (ID_regfile_reg2_addr), 
  .ID_reg_dest_valid (ID_regfile_reg_dest_valid), 
  .ID_reg_dest_addr (ID_regfile_reg_dest_addr), 
  .ID_reg_dest_reorder (ID_regfile_reg_dest_tag), 

  .dispatch_reg1_valid (dispatch_regfile_reg1_valid), 
  .dispatch_reg1_data (dispatch_regfile_reg1_data), 
  .dispatch_reg1_reorder (dispatch_regfile_reg1_tag), 
  .dispatch_reg2_valid (dispatch_regfile_reg2_valid), 
  .dispatch_reg2_data (dispatch_regfile_reg2_data), 
  .dispatch_reg2_reorder (dispatch_regfile_reg2_tag), 

  .ROB_data_valid (ROB_cdb_valid), 
  .ROB_reg_dest (ROB_cdb_reg_dest), 
  .ROB_tag (ROB_cdb_tag), 
  .ROB_data (ROB_cdb_data)
) ;

ROB ROB (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 

  .clear (clear), 

  .IF_jump_judge (IF_ROB_jump_judge), 
  .IF_pc (IF_ROB_pc), 

  .ID_debug_inst (ID_ROB_debug_inst), 

  .ID_valid (ID_ROB_valid), 
  .ID_rob_ready (ID_ROB_ready), 
  .ID_dest_reg (ID_ROB_reg_dest), 
  .ID_type (ID_ROB_type), 
  .ID_rob_is_full (ID_ROB_is_full), 
  .ID_tag (ID_ROB_tag), 

  .LSB_commit (LSB_ROB_commit), 

  .dispatch_reg1_valid (dispatch_ROB_reg1_valid), 
  .dispatch_reg1_tag (dispatch_ROB_reg1_tag), 
  .dispatch_reg2_valid (dispatch_ROB_reg2_valid), 
  .dispatch_reg2_tag (dispatch_ROB_reg2_tag), 
  .dispatch_reg1_data_valid (dispatch_ROB_reg1_valid), 
  .dispatch_reg1_data (dispatch_ROB_reg1_data), 
  .dispatch_reg2_data_valid (dispatch_ROB_reg2_valid), 
  .dispatch_reg2_data (dispatch_ROB_reg2_data), 

  .CDB_valid (ROB_cdb_valid), 
  .CDB_reg_dest (ROB_cdb_reg_dest), 
  .CDB_tag (ROB_cdb_tag), 
  .CDB_data (ROB_cdb_data), 

  .ALU_cdb_valid (ALU_cdb_valid), 
  .ALU_cdb_tag (ALU_cdb_tag), 
  .ALU_cdb_data (ALU_cdb_data), 
  .LSB_cdb_valid (LSB_cdb_valid), 
  .LSB_cdb_tag (LSB_cdb_tag), 
  .LSB_cdb_data (LSB_cdb_data), 
  .Branch_cdb_valid (Branch_cdb_valid), 
  .Branch_cdb_jump_judge (Branch_cdb_jump_judge), 
  .Branch_cdb_pc (Branch_cdb_pc), 
  .Branch_cdb_original_pc (Branch_cdb_original_pc), 
  .Branch_cdb_tag (Branch_cdb_tag), 
  .Branch_cdb_data (Branch_cdb_data)
) ;

endmodule