`include "cpu_define.v"
module ALU (
    // <- ALURS
    input wire ALURS_enable, 
    input wire[`OPBus] ALURS_op, 
    input wire[`DataBus] ALURS_reg1, 
    input wire[`DataBus] ALURS_reg2, 
    input wire[`TagBus] ALURS_des_rob, 
    input wire[`DataBus] ALURS_imm, 
    input wire[`AddressBus] ALURS_pc, 

    // -> CDB
    output reg CDB_valid, 
    output reg[`TagBus] CDB_tag, 
    output reg[`DataBus] CDB_data
);

always @(*) begin
    if (ALURS_enable == `Disable) begin
        CDB_valid = `Invalid ;
        CDB_tag = `Null ;
        CDB_data = `Null ;
    end
    else begin
        CDB_valid = `Valid ;
        CDB_tag = ALURS_des_rob ;
        CDB_data = `Null ;
        case (ALURS_op)
            `ADD: CDB_data = ALURS_reg1 + ALURS_reg2 ;
            `ADDI: CDB_data = ALURS_reg1 + ALURS_imm ;
            `SUB: CDB_data = ALURS_reg1 - ALURS_reg2 ;
            `LUI: CDB_data = ALURS_imm ;
            `AUIPC: CDB_data = ALURS_pc + ALURS_imm ;
            `XOR: CDB_data = ALURS_reg1 ^ ALURS_reg2 ;
            `XORI: CDB_data = ALURS_reg1 ^ ALURS_imm ;
            `OR: CDB_data = ALURS_reg1 | ALURS_reg2 ;
            `ORI: CDB_data = ALURS_reg1 | ALURS_imm ;
            `AND: CDB_data = ALURS_reg1 & ALURS_reg2 ;
            `ANDI: CDB_data = ALURS_reg1 & ALURS_imm ;
            `SLL: CDB_data = ALURS_reg1 << ALURS_reg2[5:0] ;
            `SLLI: CDB_data = ALURS_reg1 << ALURS_imm[5:0] ;
            `SRL: CDB_data = ALURS_reg1 >> ALURS_reg2[5:0] ;
            `SRLI: CDB_data = ALURS_reg1 >> ALURS_imm[5:0] ;
            `SRA: CDB_data = $signed(ALURS_reg1) >> ALURS_reg2[5:0] ;
            `SRAI: CDB_data = $signed(ALURS_reg1) >> ALURS_imm[5:0] ;
            `SLT: CDB_data = $signed(ALURS_reg1) < $signed(ALURS_reg2) ;
            `SLTI: CDB_data = $signed(ALURS_reg1) < $signed(ALURS_imm) ;
            `SLTU: CDB_data = ALURS_reg1 < ALURS_reg2 ;
            `SLTIU: CDB_data = ALURS_reg1 < ALURS_imm ;
            
            default: CDB_valid = `Invalid ;
        endcase
    end
end
    
endmodule