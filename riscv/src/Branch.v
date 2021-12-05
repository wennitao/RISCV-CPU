`include "cpu_define.v"
module Branch (
    // <- BranchRS
    input wire BranchRS_enable, 
    input wire[`OPBus] BranchRS_op, 
    input wire[`DataBus] BranchRS_reg1,
    input wire[`DataBus] BranchRS_reg2, 
    input wire[`TagBus] BranchRS_dest_rob, 
    input wire[`DataBus] BranchRS_imm, 
    input wire[`AddressBus] BranchRS_pc, 

    // -> CDB
    output reg CDB_valid, 
    output reg[`TagBus] CDB_tag, 
    output reg CDB_jump_judge, 
    output reg[`AddressBus] CDB_pc, 
    output reg[`AddressBus] CDB_original_pc, 
    output reg[`DataBus] CDB_data
);

always @(*) begin
    if (BranchRS_enable == `Disable) begin
        CDB_valid = `Invalid ;
        CDB_tag = `Null ;
        CDB_jump_judge = `Null ;
        CDB_pc = `Null ;
        CDB_original_pc = `Null ;
        CDB_data = `Null ;
    end
    else begin
        CDB_valid = `Valid ;
        CDB_tag = BranchRS_dest_rob ;
        CDB_jump_judge = `Fail ;
        CDB_original_pc = BranchRS_pc ;
        CDB_pc = BranchRS_pc + `PcStep ;

        case (BranchRS_op)
            `BEQ: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = (BranchRS_reg1 == BranchRS_reg2) ;
            end
            `BNE: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = (BranchRS_reg1 != BranchRS_reg2) ;
            end
            `BLT: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = ($signed(BranchRS_reg1) < $signed(BranchRS_reg2)) ;
            end
            `BGE: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = ($signed(BranchRS_reg1) >= $signed(BranchRS_reg2)) ;
            end
            `BLTU: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = (BranchRS_reg1 < BranchRS_reg2) ;
            end
            `BGEU: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = (BranchRS_reg1 >= BranchRS_reg2) ;
            end
            `JAL: begin
                CDB_pc = BranchRS_pc + $signed(BranchRS_imm) ;
                CDB_jump_judge = `Fail ;
                CDB_data = BranchRS_pc + `PcStep ;
            end
            `JALR: begin
                CDB_pc = (BranchRS_reg1 + BranchRS_imm) & `Tilde1 ;
                CDB_jump_judge = `Success ;
                CDB_data = BranchRS_pc + `PcStep ;
            end
            default: CDB_valid = `Invalid ;
        endcase
    end
end
    
endmodule