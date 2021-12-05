`include "cpu_define.v"
module ID (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

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
    output reg[`TagBus] dispatch_reg_dest_tag 
);

wire [6:0] opcode ;
wire [2:0] funct3 ;
wire [6:0] funct7 ;
wire [`InstBus] inst ;

assign inst = InstQueue_inst ;
assign opcode = inst[6:0] ;
assign funct3 = inst[14:12] ;
assign funct7 = inst[31:25] ;

always @(*) begin
    if (rst || InstQueue_queue_is_empty == `IQEmpty) begin
        InstQueue_enable = `Disable ;
        regfile_reg1_valid = `Invalid ;
        regfile_reg1_addr = `Null ;
        regfile_reg2_valid = `Invalid ;
        regfile_reg2_addr = `Null ;
        regfile_reg_dest_valid = `Invalid ;
        regfile_reg_dest_addr = `Null ;
        regfile_reg_dest_tag = `Null ;
    end
    else begin
        InstQueue_enable = `Enable ;
        dispatch_enable = `Enable ;
        dispatch_pc = InstQueue_pc ;
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
                dispatch_imm = {{20{inst[31]}}, inst[31:20]} ;
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
                dispatch_imm = {{20{inst[31]}}, inst[31:25], inst[11:7]} ;
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
                if (funct3 != 3'b101 && funct3 != 3'b001)
                    dispatch_imm = {{20{inst[31]}}, inst[31:20]} ;
                else
                    dispatch_imm = {{26{1'b0}}, inst[25:20]} ;
            end
            7'b0110111: begin
                dispatch_op = `LUI ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                dispatch_imm = {inst[31:12], 12'b0} ;
            end
            7'b0010111: begin
                dispatch_op = `AUIPC ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                dispatch_imm = {inst[31:12], 12'b0} ;
            end
            7'b1100011: begin
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
                dispatch_imm = {{20{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8]} ;
            end
            7'b1101111: begin
                dispatch_op = `JAL ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = `Null ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                dispatch_imm = {{12{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0} ;
            end
            7'b1100111: begin
                dispatch_op = `JALR ;
                regfile_reg1_valid = `Valid ;
                regfile_reg1_addr = inst[19:15] ;
                regfile_reg2_valid = `Valid ;
                regfile_reg2_addr = `Null ;
                regfile_reg_dest_valid = `Valid ;
                regfile_reg_dest_addr = inst[11:7] ;
                dispatch_imm = {{20{inst[31]}}, inst[31:20]} ;
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
            end
        endcase
    end
end

    
endmodule