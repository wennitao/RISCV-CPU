`include "cpu_define.v"

module regfile (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- ID
    input wire ID_reg1_valid, 
    input wire [`RegBus] ID_reg1_addr, 
    input wire ID_reg2_valid, 
    input wire [`RegBus] ID_reg2_addr,

    input wire ID_reg_dest_valid, 
    input wire [`RegBus] ID_reg_dest_addr, 
    input wire [`TagBus] ID_reg_dest_reorder, 

    // -> dispatch
    output reg dispatch_reg1_valid, 
    output reg[`DataBus] dispatch_reg1_data, 
    output reg[`TagBus] dispatch_reg1_reorder, 
    output reg dispatch_reg2_valid, 
    output reg[`DataBus] dispatch_reg2_data, 
    output reg[`TagBus] dispatch_reg2_reorder, 

    // <- ROB
    input wire ROB_data_valid, 
    input wire[`RegBus] ROB_reg_dest, 
    input wire[`TagBus] ROB_tag, 
    input wire[`DataBus] ROB_data
);

reg[`DataBus] regs[32] ;
reg[`TagBus] tags[32] ;
reg[31:0] busy ;

always @(posedge clk) begin
    if (rst) begin
        busy <= `Null ;
    end
    else if (rdy) begin
        if (ID_reg_dest_valid == `Valid) begin
            tags[ID_reg_dest_addr] <= ID_reg_dest_reorder ;
            busy[ID_reg_dest_addr] <= `Busy ;
        end
        if (ROB_data_valid == `Valid && ROB_reg_dest != `Null) begin
            regs[ROB_reg_dest] <= ROB_data ;
            if (tags[ROB_reg_dest] == ROB_tag) begin
                busy[ID_reg_dest_addr] <= `Free ;
            end
        end
    end
end

always @(*) begin
    if (rst) begin
        dispatch_reg1_valid = `Invalid ;
        dispatch_reg1_data = `Null ;
        dispatch_reg1_reorder = `Null ;
    end
    else if (ID_reg1_valid == `Invalid) begin
        dispatch_reg1_valid = `Invalid ;
        dispatch_reg1_data = `Null ;
        dispatch_reg1_reorder = `Null ;
    end
    else if (ID_reg1_addr == `Null) begin
        dispatch_reg1_valid = `Valid ;
        dispatch_reg1_data = `Null ;
        dispatch_reg1_reorder = `Null ;
    end
    else begin
        dispatch_reg1_valid = `Valid ;
        dispatch_reg1_data = regs[ID_reg1_addr] ;
        dispatch_reg1_reorder = tags[ID_reg1_addr] ;
    end
end

always @(*) begin
    if (rst) begin
        dispatch_reg2_valid = `Invalid ;
        dispatch_reg2_data = `Null ;
        dispatch_reg2_reorder = `Null ;
    end
    else if (ID_reg2_valid == `Invalid) begin
        dispatch_reg2_valid = `Invalid ;
        dispatch_reg2_data = `Null ;
        dispatch_reg2_reorder = `Null ;
    end
    else if (ID_reg2_addr == `Null) begin
        dispatch_reg2_valid = `Valid ;
        dispatch_reg2_data = `Null ;
        dispatch_reg2_reorder = `Null ;
    end
    else begin
        dispatch_reg2_valid = `Valid ;
        dispatch_reg2_data = regs[ID_reg1_addr] ;
        dispatch_reg2_reorder = tags[ID_reg1_addr] ;
    end
end
    
endmodule