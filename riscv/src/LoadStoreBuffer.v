`include "cpu_define.v"

module LoadStoreBuffer (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- LoadStoreBufferRS
    input wire LSBRS_enable, 
    input wire[`OPBus] LSBRS_op, 
    input wire[`DataBus] LSBRS_imm, 
    input wire[`DataBus] LSBRS_reg1_data, 
    input wire[`DataBus] LSBRS_reg2_data, 
    input wire[`TagBus] LSBRS_reg_dest_tag, 
    // -> LoadStoreBufferRS
    output reg LSB_valid, 

    // <- MemCtrl
    input wire MemCtrl_data_valid, 
    input wire[`DataBus] MemCtrl_data, 
    // -> MemCtrl
    output reg MemCtrl_enable, 
    output reg MemCtrl_is_write, 
    output reg[`LenBus] MemCtrl_write_len, 
    output reg[`DataBus] MemCtrl_write_data, 

    // -> CDB
    output reg CDB_valid, 
    output reg[`TagBus] CDB_tag, 
    output reg[`DataBus] CDB_data
);


    
endmodule