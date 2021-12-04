`include "cpu_define.v"

module InstructionCache (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- IF
    input wire IF_inst_read_valid, 
    input wire[`AddressBus] IF_inst_addr, 
    // -> IF
    output reg IF_inst_valid,
    output reg[`InstBus] IF_inst, 

    // <- MemCtrl
    input wire MemCtrl_inst_valid, 
    input wire[`InstBus] MemCtrl_inst, 
    // -> MemCtrl
    output reg MemCtrl_inst_read_valid,  
    output reg[`AddressBus] MemCtrl_inst_addr
);

reg[`InstBus] inst[`InstCacheSizeBus] ;
reg[`InstCacheTagLenBus] tag[`InstCacheSizeBus] ;
reg valid[`InstCacheSizeBus] ;
integer i ;

always @(posedge clk) begin
    if (rst) begin
        repeat (512) begin
            valid[i] <= `Invalid ;
        end
    end
    else if (rdy && MemCtrl_inst_valid == `Valid) begin
        tag[MemCtrl_inst[`InstCacheIndexBus]] <= MemCtrl_inst[`InstCacheTagBus] ;
        valid[MemCtrl_inst[`InstCacheIndexBus]] <= `Valid ;
        inst[MemCtrl_inst[`InstCacheIndexBus]] <= MemCtrl_inst ;
    end
end

always @(*) begin
    if (rst) begin
        IF_inst_valid = `Disable ;
        IF_inst = `Null ;
        MemCtrl_inst_read_valid = `Disable ;
        MemCtrl_inst_addr = `Null ;
    end
    else if (rdy && IF_inst_read_valid == `Valid) begin
        if (valid[IF_inst_addr[`InstCacheIndexBus]] == `Valid && tag[IF_inst_addr[`InstCacheIndexBus]] == IF_inst_addr[`InstCacheTagBus]) begin
            IF_inst_valid = `Valid ;
            IF_inst = inst[IF_inst_addr[`InstCacheIndexBus]] ;
            MemCtrl_inst_read_valid = `Invalid ;
            MemCtrl_inst_addr = `Null ;
        end
        else if (MemCtrl_inst_valid == `Valid) begin
            IF_inst_valid = `Valid ;
            IF_inst = MemCtrl_inst ;
            MemCtrl_inst_read_valid = `Invalid ;
            MemCtrl_inst_addr = `Null ;
        end
        else begin
            MemCtrl_inst_read_valid = `Valid ;
            MemCtrl_inst_addr = IF_inst_addr ;
            IF_inst_valid = `Invalid ;
            IF_inst = `Null ;
        end
    end
    else begin
        IF_inst_valid = `Disable ;
        IF_inst = `Null ;
        MemCtrl_inst_read_valid = `Disable ;
        MemCtrl_inst_addr = `Null ;
    end
end
    
endmodule