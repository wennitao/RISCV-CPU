`include "cpu_define.v"

module dispatch (
    // <- ID
    input wire ID_valid, 
    input wire[`OPBus] ID_op, 
    input wire[`DataBus] ID_imm, 
    input wire[`AddressBus] ID_pc, 
    input wire[`TagBus] ID_reg_dest_tag, 

    // <- regfile
    input wire regfile_reg1_valid, 
    input wire[`DataBus] regfile_reg1_data, 
    input wire[`TagBus] regfile_reg1_tag, 
    input wire regfile_reg2_valid, 
    input wire[`DataBus] regfile_reg2_data, 
    input wire[`TagBus] regfile_reg2_tag, 

    // -> ROB
    output reg ROB_reg1_enable, 
    output reg[`TagBus] ROB_reg1_tag, 
    output reg ROB_reg2_enable, 
    output reg[`TagBus] ROB_reg2_tag, 
    // <- ROB
    input wire ROB_reg1_valid, 
    input wire[`DataBus] ROB_reg1_data, 
    input wire ROB_reg2_valid, 
    input wire[`DataBus] ROB_reg2_data, 

    // -> ALURS
    output reg ALURS_enable, 
    output reg[`OPBus] ALURS_op, 
    output reg[`DataBus] ALURS_imm, 
    output reg[`AddressBus] ALURS_pc, 
    output reg ALURS_reg1_valid, 
    output reg[`DataBus] ALURS_reg1_data, 
    output reg[`TagBus] ALURS_reg1_tag, 
    output reg ALURS_reg2_valid, 
    output reg[`DataBus] ALURS_reg2_data, 
    output reg[`TagBus] ALURS_reg2_tag, 
    output reg[`TagBus] ALURS_reg_dest_tag, 

    // -> BranchRS
    output reg BranchRS_enable, 
    output reg[`OPBus] BranchRS_op, 
    output reg[`DataBus] BranchRS_imm, 
    output reg[`AddressBus] BranchRS_pc, 
    output reg BranchRS_reg1_valid, 
    output reg[`DataBus] BranchRS_reg1_data, 
    output reg[`TagBus] BranchRS_reg1_tag, 
    output reg BranchRS_reg2_valid, 
    output reg[`DataBus] BranchRS_reg2_data, 
    output reg[`TagBus] BranchRS_reg2_tag, 
    output reg[`TagBus] BranchRS_reg_dest_tag, 

    // -> LoadStoreBufferRS
    output reg LSBRS_enable, 
    output reg[`OPBus] LSBRS_op, 
    output reg[`DataBus] LSBRS_imm, 
    output reg[`AddressBus] LSBRS_pc, 
    output reg LSBRS_reg1_valid, 
    output reg[`DataBus] LSBRS_reg1_data, 
    output reg[`TagBus] LSBRS_reg1_tag, 
    output reg LSBRS_reg2_valid, 
    output reg[`DataBus] LSBRS_reg2_data, 
    output reg[`TagBus] LSBRS_reg2_tag, 
    output reg[`TagBus] LSBRS_reg_dest_tag
);

wire toBranchRS = (ID_op >= `BEQ && ID_op <= `JALR) ;
wire toLSBRS = (ID_op >= `LB && ID_op <= `SW) ;

always @(*) begin
    if (ID_valid == `Valid) begin
        if (toLSBRS == `True) begin
            ALURS_enable = `Disable ;
            BranchRS_enable = `Disable ;
            LSBRS_enable = `Enable ;
            LSBRS_op = ID_op ;
            LSBRS_imm = ID_imm ;
            LSBRS_pc = ID_pc ;
            LSBRS_reg_dest_tag = ID_reg_dest_tag ;
            if (regfile_reg1_valid == `Valid) begin
                LSBRS_reg1_valid = `Valid ;
                LSBRS_reg1_tag = `Null ;
                LSBRS_reg1_data = regfile_reg1_data ;
            end
            else if (ROB_reg1_valid == `Valid) begin
                LSBRS_reg1_valid = `Valid ;
                LSBRS_reg1_tag = `Null ;
                LSBRS_reg1_data = ROB_reg1_data ;
            end
            else begin
                LSBRS_reg1_valid = `Valid ;
                LSBRS_reg1_tag = regfile_reg1_tag ;
                LSBRS_reg1_data = `Null ;
            end
            if (regfile_reg2_valid == `Valid) begin
                LSBRS_reg2_valid = `Valid ;
                LSBRS_reg2_tag = `Null ;
                LSBRS_reg2_data = regfile_reg2_data ;
            end
            else if (ROB_reg2_valid == `Valid) begin
                LSBRS_reg2_valid = `Valid ;
                LSBRS_reg2_tag = `Null ;
                LSBRS_reg2_data = ROB_reg2_data ;
            end
            else begin
                LSBRS_reg2_valid = `Valid ;
                LSBRS_reg2_tag = regfile_reg2_tag ;
                LSBRS_reg2_data = `Null ;
            end
        end
        else if (toBranchRS == `True) begin
            ALURS_enable = `Disable ;
            LSBRS_enable = `Disable ;
            BranchRS_enable = `Enable ;
            BranchRS_op = ID_op ;
            BranchRS_imm = ID_imm ;
            BranchRS_pc = ID_pc ;
            BranchRS_reg_dest_tag = ID_reg_dest_tag ;
            if (regfile_reg1_valid == `Valid) begin
                BranchRS_reg1_valid = `Valid ;
                BranchRS_reg1_tag = `Null ;
                BranchRS_reg1_data = regfile_reg1_data ;
            end
            else if (ROB_reg1_valid == `Valid) begin
                BranchRS_reg1_valid = `Valid ;
                BranchRS_reg1_tag = `Null ;
                BranchRS_reg1_data = ROB_reg1_data ;
            end
            else begin
                BranchRS_reg1_valid = `Valid ;
                BranchRS_reg1_tag = regfile_reg1_tag ;
                BranchRS_reg1_data = `Null ;
            end
            if (regfile_reg2_valid == `Valid) begin
                BranchRS_reg2_valid = `Valid ;
                BranchRS_reg2_tag = `Null ;
                BranchRS_reg2_data = regfile_reg2_data ;
            end
            else if (ROB_reg2_valid == `Valid) begin
                BranchRS_reg2_valid = `Valid ;
                BranchRS_reg2_tag = `Null ;
                BranchRS_reg2_data = ROB_reg2_data ;
            end
            else begin
                BranchRS_reg2_valid = `Valid ;
                BranchRS_reg2_tag = regfile_reg2_tag ;
                BranchRS_reg2_data = `Null ;
            end
        end 
        else begin
            BranchRS_enable = `Disable ;
            LSBRS_enable = `Disable ;
            ALURS_enable = `Enable ;
            ALURS_op = ID_op ;
            ALURS_imm = ID_imm ;
            ALURS_pc = ID_pc ;
            ALURS_reg_dest_tag = ID_reg_dest_tag ;
            if (regfile_reg1_valid == `Valid) begin
                ALURS_reg1_valid = `Valid ;
                ALURS_reg1_tag = `Null ;
                ALURS_reg1_data = regfile_reg1_data ;
            end
            else if (ROB_reg1_valid == `Valid) begin
                ALURS_reg1_valid = `Valid ;
                ALURS_reg1_tag = `Null ;
                ALURS_reg1_data = ROB_reg1_data ;
            end
            else begin
                ALURS_reg1_valid = `Valid ;
                ALURS_reg1_tag = regfile_reg1_tag ;
                ALURS_reg1_data = `Null ;
            end
            if (regfile_reg2_valid == `Valid) begin
                ALURS_reg2_valid = `Valid ;
                ALURS_reg2_tag = `Null ;
                ALURS_reg2_data = regfile_reg2_data ;
            end
            else if (ROB_reg2_valid == `Valid) begin
                ALURS_reg2_valid = `Valid ;
                ALURS_reg2_tag = `Null ;
                ALURS_reg2_data = ROB_reg2_data ;
            end
            else begin
                ALURS_reg2_valid = `Valid ;
                ALURS_reg2_tag = regfile_reg2_tag ;
                ALURS_reg2_data = `Null ;
            end
        end
    end
    else begin
        ALURS_enable = `Disable ;
        BranchRS_enable = `Disable ;
        LSBRS_enable = `Disable ;
    end
end

endmodule