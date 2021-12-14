`include "cpu_define.v" 

module ALURS (
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire clear, 

    // -> ID
    output reg ALURS_is_full, 

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

    // -> ALU
    output reg ALU_valid, 
    output reg[`OPBus] ALU_op, 
    output reg[`DataBus] ALU_reg1, 
    output reg[`DataBus] ALU_reg2, 
    output reg[`TagBus] ALU_reg_des_rob, 
    output reg[`DataBus] ALU_imm, 
    output reg[`AddressBus] ALU_pc, 

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

reg[`RSBus] ALURS_valid ;
reg[`OPBus] ALURS_op[`RSSizeBus] ;
reg[`DataBus] ALURS_imm[`RSSizeBus] ;
reg[`AddressBus] ALURS_pc[`RSSizeBus] ;
reg[`RSBus] ALURS_reg1_valid ;
reg[`DataBus] ALURS_reg1_data[`RSSizeBus] ;
reg[`TagBus] ALURS_reg1_tag[`RSSizeBus] ;
reg[`RSBus] ALURS_reg2_valid ;
reg[`DataBus] ALURS_reg2_data[`RSSizeBus] ;
reg[`TagBus] ALURS_reg2_tag[`RSSizeBus] ;
reg[`TagBus] ALURS_reg_dest_tag[`RSSizeBus] ;

integer i ;

wire[`RSBus] empty ; // empty[pos] = 1'b1
wire[`RSBus] valid ; // valid[pos] = 1'b1

assign empty = (~ALURS_valid & (-(~ALURS_valid))) ; //x & -x
assign valid = (ALURS_valid & ALURS_reg1_valid & ALURS_reg2_valid) & (-(ALURS_valid & ALURS_reg1_valid & ALURS_reg2_valid)) ;

always @(*) begin
    if (empty == `Null) ALURS_is_full = `RSFull ;
    else ALURS_is_full = `RSNotFull ;
end

always @(posedge clk) begin
    if (rst || clear) begin
        ALU_valid <= `Invalid ;
        ALU_op <= `Null ;
        ALU_reg1 <= `Null ;
        ALU_reg2 <= `Null ;
        ALU_reg_des_rob <= `Null ;
        ALU_imm <= `Null ;
        ALU_pc <= `Null ;
        for (i = 0; i < `RSSize; i = i + 1) begin
            ALURS_valid[i] <= `Invalid ;
            ALURS_op[i] <= `Null ;
            ALURS_imm[i] <= `Null ;
            ALURS_pc[i] <= `Null ;
            ALURS_reg1_valid[i] <= `Invalid ;
            ALURS_reg1_data[i] <= `Null ;
            ALURS_reg1_tag[i] <= `Null ;
            ALURS_reg2_valid[i] <= `Invalid ;
            ALURS_reg2_data[i] <= `Null ;
            ALURS_reg2_tag[i] <= `Null ;
            ALURS_reg_dest_tag[i] <= `Null ;
        end
    end
    else if (rdy) begin
        for (i = 0; i < `RSSize; i = i + 1) begin
            if (ALURS_valid[i] == `Valid && ALURS_reg1_valid[i] == `Invalid) begin // get reg1 data from cdb
                if (ALU_cdb_valid == `Valid && ALU_cdb_tag == ALURS_reg1_tag[i]) begin
                    ALURS_reg1_valid[i] <= `Valid ;
                    ALURS_reg1_data[i] <= ALU_cdb_data ;
                end
                else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == ALURS_reg1_tag[i]) begin
                    ALURS_reg1_valid[i] <= `Valid ;
                    ALURS_reg1_data[i] <= LSB_cdb_data ;
                end
                else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == ALURS_reg1_tag[i]) begin
                    ALURS_reg1_valid[i] <= `Valid ;
                    ALURS_reg1_data[i] <= Branch_cdb_data ;
                end
                else if (ROB_cdb_valid == `Valid && ROB_cdb_tag == ALURS_reg1_tag[i]) begin
                    ALURS_reg1_valid[i] <= `Valid ;
                    ALURS_reg1_data[i] <= ROB_cdb_data ;
                end
            end
            if (ALURS_valid[i] == `Valid && ALURS_reg2_valid[i] == `Invalid) begin // get reg2 data from cdb
                if (ALU_cdb_valid == `Valid && ALU_cdb_tag == ALURS_reg2_tag[i]) begin
                    ALURS_reg2_valid[i] <= `Valid ;
                    ALURS_reg2_data[i] <= ALU_cdb_data ;
                end
                else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == ALURS_reg2_tag[i]) begin
                    ALURS_reg2_valid[i] <= `Valid ;
                    ALURS_reg2_data[i] <= LSB_cdb_data ;
                end
                else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == ALURS_reg2_tag[i]) begin
                    ALURS_reg2_valid[i] <= `Valid ;
                    ALURS_reg2_data[i] <= Branch_cdb_data ;
                end
                else if (ROB_cdb_valid == `Valid && ROB_cdb_tag == ALURS_reg2_tag[i]) begin
                    ALURS_reg2_valid[i] <= `Valid ;
                    ALURS_reg2_data[i] <= ROB_cdb_data ;
                end
            end
        end

        if (valid == `Null) begin // no RS reg ready
            ALU_valid <= `Invalid ;
            ALU_op <= `Null ;
            ALU_reg1 <= `Null ;
            ALU_reg2 <= `Null ;
            ALU_reg_des_rob <= `Null ;
            ALU_imm <= `Null ;
            ALU_pc <= `Null ;
        end
        else begin // push to ALU
            for (i = 0; i < `RSSize; i = i + 1) begin
                if (valid[i] == `Valid) begin
                    // $display ("ALURS to ALU: idx: %h", i) ;
                    // $display ("clock: %d ALURS to ALU: idx:%h op:%h reg1:%h reg2:%h des_rob:%h imm:%h pc:%h", $time, i, ALURS_op[i], ALURS_reg1_data[i], ALURS_reg2_data[i], ALURS_reg_dest_tag[i], ALURS_imm[i], ALURS_pc[i]) ;
                    ALU_valid <= `Valid ;
                    ALU_op <= ALURS_op[i] ;
                    ALU_reg1 <= ALURS_reg1_data[i] ;
                    ALU_reg2 <= ALURS_reg2_data[i] ;
                    ALU_reg_des_rob <= ALURS_reg_dest_tag[i] ;
                    ALU_imm <= ALURS_imm[i] ;
                    ALU_pc <= ALURS_pc[i] ;
                    ALURS_valid[i] <= `Invalid ;
                end
            end
        end

        // push in ALURS
        if (dispatch_valid == `Valid && empty != `Null) begin
            for (i = 0; i < `RSSize; i = i + 1) begin
                if (empty[i] == `Valid) begin
                    // $display ("clock: %d dispatch to ALURS: idx: %h", $time, i) ;
                    ALURS_valid[i] <= `Valid ;
                    ALURS_op[i] <= dispatch_op ;
                    ALURS_imm[i] <= dispatch_imm ;
                    ALURS_pc[i] <= dispatch_pc ;
                    ALURS_reg1_valid[i] <= dispatch_reg1_valid ;
                    ALURS_reg1_data[i] <= dispatch_reg1_data ;
                    ALURS_reg1_tag[i] <= dispatch_reg1_tag ;
                    ALURS_reg2_valid[i] <= dispatch_reg2_valid ;
                    ALURS_reg2_data[i] <= dispatch_reg2_data ;
                    ALURS_reg2_tag[i] <= dispatch_reg2_tag ;
                    ALURS_reg_dest_tag[i] <= dispatch_reg_dest_tag ;
                end
            end
        end
    end
end
    
endmodule