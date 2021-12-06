`include "cpu_define.v" 

module BranchRS (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // -> ID
    output reg BranchRS_is_full, 

    // <- dispatch
    input wire dispatch_valid, 
    input wire[`OPBus] dispatch_op, 
    input wire[`DataBus] dispatch_imm, 
    input wire[`AddressBus] dispatch_pc, 
    input wire dispatch_reg1_valid, 
    input wire[`DataBus] dispatch_reg1_data, 
    input wire[`TagBus] dispatch_reg1_tag, 
    input wire dispatch_reg2_valid, 
    input wire[`DataBus] dispatch_reg2_data, 
    input wire[`TagBus] dispatch_reg2_tag, 
    input wire[`TagBus] dispatch_reg_dest_tag, 

    // -> Branch
    output reg Branch_valid, 
    output reg[`OPBus] Branch_op, 
    output reg[`DataBus] Branch_reg1, 
    output reg[`DataBus] Branch_reg2, 
    output reg[`TagBus] Branch_reg_des_rob, 
    output reg[`DataBus] Branch_imm, 
    output reg[`AddressBus] Branch_pc, 

    // CDB
    input wire ALU_cdb_valid, 
    input wire[`TagBus] ALU_cdb_tag, 
    input wire[`DataBus] ALU_cdb_data, 

    input wire LSB_cdb_valid, 
    input wire[`TagBus] LSB_cdb_tag, 
    input wire[`DataBus] LSB_cdb_data, 

    input wire Branch_cdb_valid, 
    input wire[`TagBus] Branch_cdb_tag, 
    input wire[`DataBus] Branch_cdb_data, 

    input wire ROB_cdb_valid, 
    input wire[`TagBus] ROB_cdb_tag, 
    input wire[`DataBus] ROB_cdb_data
);

reg[`RSBus] BranchRS_valid ;
reg[`OPBus] BranchRS_op[`RSSize] ;
reg[`DataBus] BranchRS_imm[`RSSize] ;
reg[`AddressBus] BranchRS_pc[`RSSize] ;
reg[`RSBus] BranchRS_reg1_valid ;
reg[`DataBus] BranchRS_reg1_data[`RSSize] ;
reg[`TagBus] BranchRS_reg1_tag[`RSSize] ;
reg[`RSBus] BranchRS_reg2_valid ;
reg[`DataBus] BranchRS_reg2_data[`RSSize] ;
reg[`TagBus] BranchRS_reg2_tag[`RSSize] ;
reg[`TagBus] BranchRS_reg_dest_tag[`RSSize] ;

integer i ;

wire[`RSBus] empty ; // empty[pos] = 1'b1
wire[`RSBus] valid ; // valid[pos] = 1'b1

assign empty = (~BranchRS_valid & (-(~BranchRS_valid))) ; //x & -x
assign valid = (BranchRS_valid & BranchRS_reg1_valid & BranchRS_reg2_valid) & (-(BranchRS_valid & BranchRS_reg1_valid & BranchRS_reg2_valid)) ;

always @(*) begin
    if (empty == `Null) BranchRS_is_full = `RSFull ;
    else BranchRS_is_full = `RSNotFull ;
end

always @(posedge clk) begin
    if (rst) begin
        Branch_valid <= `Invalid ;
        Branch_op <= `Null ;
        Branch_reg1 <= `Null ;
        Branch_reg2 <= `Null ;
        Branch_reg_des_rob <= `Null ;
        Branch_imm <= `Null ;
        Branch_pc <= `Null ;
        for (i = 0; i < `RSSize; i = i + 1) begin
            BranchRS_valid[i] <= `Invalid ;
            BranchRS_op[i] <= `Null ;
            BranchRS_imm[i] <= `Null ;
            BranchRS_pc[i] <= `Null ;
            BranchRS_reg1_valid[i] <= `Invalid ;
            BranchRS_reg1_data[i] <= `Null ;
            BranchRS_reg1_tag[i] <= `Null ;
            BranchRS_reg2_valid[i] <= `Invalid ;
            BranchRS_reg2_data[i] <= `Null ;
            BranchRS_reg2_tag[i] <= `Null ;
            BranchRS_reg_dest_tag[i] <= `Null ;
        end
    end
    else if (rdy) begin
        for (i = 0; i < `RSSize; i = i + 1) begin
            if (BranchRS_valid[i] == `Valid && BranchRS_reg1_valid[i] == `Invalid) begin // get reg1 data from cdb
                if (ALU_cdb_valid == `Valid && ALU_cdb_tag == BranchRS_reg1_tag[i]) begin
                    BranchRS_reg1_valid[i] <= `Valid ;
                    BranchRS_reg1_data[i] <= ALU_cdb_data ;
                end
                else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == BranchRS_reg1_tag[i]) begin
                    BranchRS_reg1_valid[i] <= `Valid ;
                    BranchRS_reg1_data[i] <= LSB_cdb_data ;
                end
                else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == BranchRS_reg1_tag[i]) begin
                    BranchRS_reg1_valid[i] <= `Valid ;
                    BranchRS_reg1_data[i] <= Branch_cdb_data ;
                end
                else if (ROB_cdb_valid == `Valid && ROB_cdb_tag == BranchRS_reg1_tag[i]) begin
                    BranchRS_reg1_valid[i] <= `Valid ;
                    BranchRS_reg1_data[i] <= ROB_cdb_data ;
                end
            end
            if (BranchRS_valid[i] == `Valid && BranchRS_reg2_valid[i] == `Invalid) begin // get reg2 data from cdb
                if (ALU_cdb_valid == `Valid && ALU_cdb_tag == BranchRS_reg2_tag[i]) begin
                    BranchRS_reg2_valid[i] <= `Valid ;
                    BranchRS_reg2_data[i] <= ALU_cdb_data ;
                end
                else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == BranchRS_reg2_tag[i]) begin
                    BranchRS_reg2_valid[i] <= `Valid ;
                    BranchRS_reg2_data[i] <= LSB_cdb_data ;
                end
                else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == BranchRS_reg2_tag[i]) begin
                    BranchRS_reg2_valid[i] <= `Valid ;
                    BranchRS_reg2_data[i] <= Branch_cdb_data ;
                end
                else if (ROB_cdb_valid == `Valid && ROB_cdb_tag == BranchRS_reg2_tag[i]) begin
                    BranchRS_reg2_valid[i] <= `Valid ;
                    BranchRS_reg2_data[i] <= ROB_cdb_data ;
                end
            end
        end

        if (valid == `Null) begin // no RS reg ready
            Branch_valid <= `Invalid ;
            Branch_op <= `Null ;
            Branch_reg1 <= `Null ;
            Branch_reg2 <= `Null ;
            Branch_reg_des_rob <= `Null ;
            Branch_imm <= `Null ;
            Branch_pc <= `Null ;
        end
        else begin // push to ALU
            for (i = 0; i < `RSSize; i = i + 1) begin
                if (valid[i] == `Valid) begin
                    Branch_valid <= `Valid ;
                    Branch_op <= BranchRS_op[i] ;
                    Branch_reg1 <= BranchRS_reg1_data[i] ;
                    Branch_reg2 <= BranchRS_reg2_data[i] ;
                    Branch_reg_des_rob <= BranchRS_reg_dest_tag[i] ;
                    Branch_imm <= BranchRS_imm[i] ;
                    Branch_pc <= BranchRS_pc[i] ;
                end
            end
        end

        // push in BranchRS
        if (dispatch_valid == `Valid && empty != `Null) begin
            for (i = 0; i < `RSSize; i = i + 1) begin
                if (empty[i] == `Valid) begin
                    BranchRS_valid[i] <= `Valid ;
                    BranchRS_op[i] <= dispatch_op ;
                    BranchRS_imm[i] <= dispatch_imm ;
                    BranchRS_pc[i] <= dispatch_pc ;
                    BranchRS_reg1_valid[i] <= dispatch_reg1_valid ;
                    BranchRS_reg1_data[i] <= dispatch_reg1_data ;
                    BranchRS_reg1_tag[i] <= dispatch_reg1_tag ;
                    BranchRS_reg2_valid[i] <= dispatch_reg2_valid ;
                    BranchRS_reg2_data[i] <= dispatch_reg2_data ;
                    BranchRS_reg2_tag[i] <= dispatch_reg2_tag ;
                end
            end
        end
    end
end
    
endmodule