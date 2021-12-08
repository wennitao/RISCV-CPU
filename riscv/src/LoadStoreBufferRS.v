`include "cpu_define.v" 

module LoadStoreBufferRS (
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire clear, 

    // -> ID
    output reg LSBRS_is_full, 

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

    // -> LoadStoreBuffer
    output reg LSB_valid, 
    output reg[`OPBus] LSB_op, 
    output reg[`DataBus] LSB_reg1, 
    output reg[`DataBus] LSB_reg2, 
    output reg[`TagBus] LSB_reg_des_rob, 
    output reg[`DataBus] LSB_imm, 
    // output reg[`AddressBus] LSB_pc, 

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

reg[`RSBus] LSBRS_valid ;
reg[`OPBus] LSBRS_op[`RSSize] ;
reg[`DataBus] LSBRS_imm[`RSSize] ;
reg[`AddressBus] LSBRS_pc[`RSSize] ;
reg[`RSBus] LSBRS_reg1_valid ;
reg[`DataBus] LSBRS_reg1_data[`RSSize] ;
reg[`TagBus] LSBRS_reg1_tag[`RSSize] ;
reg[`RSBus] LSBRS_reg2_valid ;
reg[`DataBus] LSBRS_reg2_data[`RSSize] ;
reg[`TagBus] LSBRS_reg2_tag[`RSSize] ;
reg[`TagBus] LSBRS_reg_dest_tag[`RSSize] ;

integer i ;

wire[`RSBus] empty ; // empty[pos] = 1'b1
wire[`RSBus] valid ; // valid[pos] = 1'b1

assign empty = (~LSBRS_valid & (-(~LSBRS_valid))) ; //x & -x
assign valid = (LSBRS_valid & LSBRS_reg1_valid & LSBRS_reg2_valid) & (-(LSBRS_valid & LSBRS_reg1_valid & LSBRS_reg2_valid)) ;

always @(*) begin
    if (empty == `Null) LSBRS_is_full = `RSFull ;
    else LSBRS_is_full = `RSNotFull ;
end

always @(posedge clk) begin
    if (rst | clear) begin
        LSB_valid <= `Invalid ;
        LSB_op <= `Null ;
        LSB_reg1 <= `Null ;
        LSB_reg2 <= `Null ;
        LSB_reg_des_rob <= `Null ;
        LSB_imm <= `Null ;
        // LSB_pc <= `Null ;
        for (i = 0; i < `RSSize; i = i + 1) begin
            LSBRS_valid[i] <= `Invalid ;
            LSBRS_op[i] <= `Null ;
            LSBRS_imm[i] <= `Null ;
            LSBRS_pc[i] <= `Null ;
            LSBRS_reg1_valid[i] <= `Invalid ;
            LSBRS_reg1_data[i] <= `Null ;
            LSBRS_reg1_tag[i] <= `Null ;
            LSBRS_reg2_valid[i] <= `Invalid ;
            LSBRS_reg2_data[i] <= `Null ;
            LSBRS_reg2_tag[i] <= `Null ;
            LSBRS_reg_dest_tag[i] <= `Null ;
        end
    end
    else if (rdy) begin
        for (i = 0; i < `RSSize; i = i + 1) begin
            if (LSBRS_valid[i] == `Valid && LSBRS_reg1_valid[i] == `Invalid) begin // get reg1 data from cdb
                if (ALU_cdb_valid == `Valid && ALU_cdb_tag == LSBRS_reg1_tag[i]) begin
                    LSBRS_reg1_valid[i] <= `Valid ;
                    LSBRS_reg1_data[i] <= ALU_cdb_data ;
                end
                else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == LSBRS_reg1_tag[i]) begin
                    LSBRS_reg1_valid[i] <= `Valid ;
                    LSBRS_reg1_data[i] <= LSB_cdb_data ;
                end
                else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == LSBRS_reg1_tag[i]) begin
                    LSBRS_reg1_valid[i] <= `Valid ;
                    LSBRS_reg1_data[i] <= Branch_cdb_data ;
                end
                else if (ROB_cdb_valid == `Valid && ROB_cdb_tag == LSBRS_reg1_tag[i]) begin
                    LSBRS_reg1_valid[i] <= `Valid ;
                    LSBRS_reg1_data[i] <= ROB_cdb_data ;
                end
            end
            if (LSBRS_valid[i] == `Valid && LSBRS_reg2_valid[i] == `Invalid) begin // get reg2 data from cdb
                if (ALU_cdb_valid == `Valid && ALU_cdb_tag == LSBRS_reg2_tag[i]) begin
                    LSBRS_reg2_valid[i] <= `Valid ;
                    LSBRS_reg2_data[i] <= ALU_cdb_data ;
                end
                else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == LSBRS_reg2_tag[i]) begin
                    LSBRS_reg2_valid[i] <= `Valid ;
                    LSBRS_reg2_data[i] <= LSB_cdb_data ;
                end
                else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == LSBRS_reg2_tag[i]) begin
                    LSBRS_reg2_valid[i] <= `Valid ;
                    LSBRS_reg2_data[i] <= Branch_cdb_data ;
                end
                else if (ROB_cdb_valid == `Valid && ROB_cdb_tag == LSBRS_reg2_tag[i]) begin
                    LSBRS_reg2_valid[i] <= `Valid ;
                    LSBRS_reg2_data[i] <= ROB_cdb_data ;
                end
            end
        end

        if (valid == `Null) begin // no RS reg ready
            LSB_valid <= `Invalid ;
            LSB_op <= `Null ;
            LSB_reg1 <= `Null ;
            LSB_reg2 <= `Null ;
            LSB_reg_des_rob <= `Null ;
            LSB_imm <= `Null ;
            // LSB_pc <= `Null ;
        end
        else begin // push to LSB
            for (i = 0; i < `RSSize; i = i + 1) begin
                if (valid[i] == `Valid) begin
                    LSB_valid <= `Valid ;
                    LSB_op <= LSBRS_op[i] ;
                    LSB_reg1 <= LSBRS_reg1_data[i] ;
                    LSB_reg2 <= LSBRS_reg2_data[i] ;
                    LSB_reg_des_rob <= LSBRS_reg_dest_tag[i] ;
                    LSB_imm <= LSBRS_imm[i] ;
                    // LSB_pc <= LSBRS_pc[i] ;
                end
            end
        end

        // push in LSBRS
        if (dispatch_valid == `Valid && empty != `Null) begin
            for (i = 0; i < `RSSize; i = i + 1) begin
                if (empty[i] == `Valid) begin
                    LSBRS_valid[i] <= `Valid ;
                    LSBRS_op[i] <= dispatch_op ;
                    LSBRS_imm[i] <= dispatch_imm ;
                    LSBRS_pc[i] <= dispatch_pc ;
                    LSBRS_reg1_valid[i] <= dispatch_reg1_valid ;
                    LSBRS_reg1_data[i] <= dispatch_reg1_data ;
                    LSBRS_reg1_tag[i] <= dispatch_reg1_tag ;
                    LSBRS_reg2_valid[i] <= dispatch_reg2_valid ;
                    LSBRS_reg2_data[i] <= dispatch_reg2_data ;
                    LSBRS_reg2_tag[i] <= dispatch_reg2_tag ;
                end
            end
        end
    end
end
    
endmodule