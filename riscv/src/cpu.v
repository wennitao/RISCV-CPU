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

// ID <-> regfile
wire regfile_reg1_valid ;
wire[`RegBus] regfile_reg1_addr ;
wire regfile_reg2_valid ;
wire[`RegBus] regfile_reg2_addr ;

wire regfile_reg_dest_valid ;
wire[`RegBus] regfile_reg_dest_addr ;
wire[`TagBus] regfile_reg_dest_tag ;

// ID <-> ROB
wire ID_ROB_tag ;
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
wire [`DataBus] LSB_data ;

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

MemCtrl MemCtrl (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 

  .InstCache_inst_read_valid (InstCache_MemCtrl_inst_read_valid), 
  .InstCache_inst_addr (InstCache_MemCtrl_inst_addr), 
  .InstCache_inst_valid (InstCache_MemCtrl_inst_valid), 
  .InstCache_inst (InstCache_MemCtrl_inst), 

  .mem_din (mem_din), 
  .mem_dout (mem_dout), 
  .mem_a (mem_a), 
  .mem_wr (mem_wr)
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

IF IF (
  .clk (clk_in), 
  .rst (rst_in), 
  .rdy (rdy_in), 

  .InstCache_inst_valid (IF_InstCache_inst_valid), 
  .InstCache_inst (IF_InstCache_inst), 
  .InstCache_inst_read_valid (IF_InstCache_inst_read_valid), 
  .InstCache_inst_addr (IF_InstCache_inst_addr)
) ;

endmodule