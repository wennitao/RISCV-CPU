`include "cpu_define.v"
module ID (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    input wire ALURS_is_full, 
    input wire BranchRS_is_full, 
    input wire LSBRS_is_full, 
    input wire ROB_is_full, 

    // <- InstQueue
    input wire InstQueue_queue_is_empty, 
    input wire [`InstBus] InstQueue_inst, 
    input wire [`AddressBus] InstQueue_pc, 
    // -> InstQueue
    output reg InstQueue_enable, 

    // -> regfile
    output reg regfile_reg1_valid, 
    output reg[`RegBus] regfile_reg1_addr, 
    output reg regfile_reg2_valid, 
    output reg[`RegBus] regfile_reg2_addr, 

    output reg regfile_reg_dest_valid, 
    output reg[`RegBus] regfile_reg_dest_addr, 
    output reg[`TagBus] regfile_reg_dest_tag, 

    // -> dispatch
    output reg dispatch_enable, 
    output reg[`OPBus] dispatch_op, 
    output reg[`DataBus] dispatch_imm, 
    output reg[`AddressBus] dispatch_pc, 
    output reg[`TagBus] dispatch_reg_dest_tag, 

    // <- ROB
    input wire[`TagBus] ROB_tag, 
    // -> ROB
    output reg ROB_valid, 
    output reg ROB_ready, 
    output reg[`RegBus] ROB_reg_dest, 
    output reg[`TypeBus] ROB_type, 

    output reg[`InstBus] ROB_debug_inst
);

wire [6:0] opcode ;
wire [2:0] funct3 ;
wire [6:0] funct7 ;
wire [`InstBus] inst ;
wire isALU, isBranch, isLSB ;
wire stall ;

assign inst = InstQueue_inst ;
assign opcode = inst[6:0] ;
assign funct3 = inst[14:12] ;
assign funct7 = inst[31:25] ;
assign isLSB = (opcode == 7'b0000011 || opcode == 7'b0100011) ;
assign isBranch = (opcode == 7'b1100011 || opcode == 7'b1100111 || opcode == 7'b1101111) ;
assign isALU = (!isLSB) && (!isBranch) ;
assign stall = (InstQueue_queue_is_empty == `IQEmpty) || (ROB_is_full == `RSFull) || (isALU && ALURS_is_full == `RSFull) || (isBranch && BranchRS_is_full == `RSFull) || (isLSB && LSBRS_is_full == `RSFull) ;

always @(*) begin
    if (stall) begin
        InstQueue_enable = `Disable ;
        regfile_reg1_valid = `Invalid ;
        regfile_reg1_addr = `Null ;
        regfile_reg2_valid = `Invalid ;
        regfile_reg2_addr = `Null ;
        regfile_reg_dest_valid = `Invalid ;
        regfile_reg_dest_addr = `Null ;
        regfile_reg_dest_tag = `Null ;
        dispatch_enable = `Disable ;
        ROB_valid = `Invalid ;
        ROB_ready = `Unready ;
    end
    else begin
        InstQueue_enable = `Enable ;
        dispatch_enable = `Enable ;
        dispatch_pc = InstQueue_pc ;
        ROB_debug_inst = inst ;
        case (opcode)
            7'b0000011: begin
                case (funct3)
                    3'b000: dispatch_op = `LB ;
                    3'b001: dispatch_op = `LH ;
                    3'b010: dispatch_op = `LW ;
                    3'b100: dispatch_op = `LBU ;
                    3'b101: dispatch_op = `LHU ;
                endcase
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_imm = {{20{inst[31]}}, inst[31:20]} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypeLoad ;
            end 
            7'b0100011: begin
                case (funct3) 
                    3'b000: dispatch_op = `SB ;
                    3'b001: dispatch_op = `SH ;
                    3'b010: dispatch_op = `SW ;
                endcase
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = inst[24:20] ;
                regfile_reg_dest_valid = `Invalid ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = `Null ;
                ROB_type = `TypeStore ;
            end
            7'b0110011: begin
                case (funct3)
                    3'b000: begin
                        case (funct7)
                            7'b0000000: dispatch_op = `ADD ; 
                            7'b0100000: dispatch_op = `SUB ;
                        endcase
                    end
                    3'b100: dispatch_op = `XOR ;
                    3'b110: dispatch_op = `OR ;
                    3'b111: dispatch_op = `AND ;
                    3'b001: dispatch_op = `SLL ;
                    3'b101: begin
                        case (funct7)
                             7'b0000000: dispatch_op = `SRL ;
                             7'b0100000: dispatch_op = `SRA ;
                        endcase
                    end
                    3'b010: dispatch_op = `SLT ;
                    3'b011: dispatch_op = `SLTU ;
                endcase
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = inst[24:20] ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypeReg ;
            end
            7'b0010011: begin
                case (funct3)
                    3'b000: dispatch_op = `ADDI ; 
                    3'b100: dispatch_op = `XORI ;
                    3'b110: dispatch_op = `ORI ;
                    3'b111: dispatch_op = `ANDI ;
                    3'b001: dispatch_op = `SLLI ;
                    3'b101: begin
                        case (inst[30])
                            1'b0: dispatch_op = `SRLI ;
                            1'b1: dispatch_op = `SRAI ;  
                        endcase
                    end
                    3'b010: dispatch_op = `SLTI ;
                    3'b011: dispatch_op = `SLTIU ;
                endcase
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                if (funct3 != 3'b101 && funct3 != 3'b001)
                    dispatch_imm = {{20{inst[31]}}, inst[31:20]} ;
                else
                    dispatch_imm = {{26{1'b0}}, inst[25:20]} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypeReg ;
            end
            7'b0110111: begin
                dispatch_op = `LUI ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_imm = {inst[31:12], 12'b0} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypeReg ;
            end
            7'b0010111: begin
                dispatch_op = `AUIPC ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_imm = {inst[31:12], 12'b0} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypeReg ;
            end
            7'b1100011: begin
                // $display ("clock: %d 1100011", $time) ;
                case (funct3)
                    3'b000: dispatch_op = `BEQ ;
                    3'b001: dispatch_op = `BNE ;
                    3'b100: dispatch_op = `BLT ;
                    3'b101: dispatch_op = `BGE ;
                    3'b110: dispatch_op = `BLTU ;
                    3'b111: dispatch_op = `BGEU ;
                endcase
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = inst[24:20] ;
                regfile_reg_dest_valid = `Invalid ;
                dispatch_imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypePc ;
            end
            7'b1101111: begin
                dispatch_op = `JAL ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_imm = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypePcAndReg ;
            end
            7'b1100111: begin
                dispatch_op = `JALR ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                regfile_reg_dest_tag = ROB_tag ;
                dispatch_imm = {{20{inst[31]}}, inst[31:20]} ;
                dispatch_reg_dest_tag = ROB_tag ;
                ROB_valid = `Valid ;
                ROB_ready = `Unready ;
                ROB_reg_dest = inst[11:7] ;
                ROB_type = `TypePcAndReg ;
            end
            default: begin
                InstQueue_enable = `Disable ;
                regfile_reg1_valid = `Invalid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Invalid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Invalid ;
                regfile_reg_dest_addr = `Null ;
                regfile_reg_dest_tag = `Null ;
                dispatch_enable = `Disable ;
                ROB_valid = `Invalid ;
                ROB_ready = `Unready ;
            end
        endcase
    end
end

    
endmodule