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
    // input wire[`AddressBus] dispatch_pc, 
    input wire dispatch_reg1_valid, 
    input wire[`DataBus] dispatch_reg1_data, 
    input wire[`TagBus] dispatch_reg1_tag, 
    input wire dispatch_reg2_valid, 
    input wire[`DataBus] dispatch_reg2_data, 
    input wire[`TagBus] dispatch_reg2_tag, 
    input wire[`TagBus] dispatch_reg_dest_tag, 

    // <- LoadStoreBuffer
    input wire LSB_is_full, 
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

reg[`RSBus] head, tail ;
integer i ;

reg[`RSSizeBus] LSBRS_valid ;
reg[`OPBus] LSBRS_op[`RSSizeBus] ;
reg[`DataBus] LSBRS_imm[`RSSizeBus] ;
// reg[`AddressBus] LSBRS_pc[`RSSizeBus] ;
reg[`RSSizeBus] LSBRS_reg1_valid ;
reg[`DataBus] LSBRS_reg1_data[`RSSizeBus] ;
reg[`TagBus] LSBRS_reg1_tag[`RSSizeBus] ;
reg[`RSSizeBus] LSBRS_reg2_valid ;
reg[`DataBus] LSBRS_reg2_data[`RSSizeBus] ;
reg[`TagBus] LSBRS_reg2_tag[`RSSizeBus] ;
reg[`TagBus] LSBRS_reg_dest_tag[`RSSizeBus] ;

wire[`RSBus] head_next = (head == `RSMaxIndex ? `RSZeroIndex : head + 1'b1) ;
wire[`RSBus] tail_next = (tail == `RSMaxIndex ? `RSZeroIndex : tail + 1'b1) ;

// wire debug_reg1_valid = LSBRS_reg1_valid[head] ;
// wire debug_reg2_valid = LSBRS_reg2_valid[head] ;

always @(*) begin
    LSBRS_is_full = (tail_next == head ? `RSFull : `RSNotFull) ;
end

always @(posedge clk) begin
    if (rst || clear) begin
        head <= `Null ;
        tail <= `Null ;
        LSB_valid <= `Invalid ;
        LSB_op <= `Null ;
        LSB_reg1 <= `Null ;
        LSB_reg2 <= `Null ;
        LSB_reg_des_rob <= `Null ;
        LSB_imm <= `Null ;
        for (i = 0; i < `RSSize; i = i + 1) begin
            LSBRS_valid[i] <= `Invalid ;
            LSBRS_op[i] <= `Null ;
            LSBRS_imm[i] <= `Null ;
            // LSBRS_pc[i] <= `Null ;
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

        if (LSB_is_full == `RSNotFull && LSBRS_valid[head] == `Valid && LSBRS_reg1_valid[head] == `Valid && LSBRS_reg2_valid[head] == `Valid) begin
            LSB_valid <= `Valid ;
            LSB_op <= LSBRS_op[head] ;
            LSB_reg1 <= LSBRS_reg1_data[head] ;
            LSB_reg2 <= LSBRS_reg2_data[head] ;
            LSB_reg_des_rob <= LSBRS_reg_dest_tag[head] ;
            LSB_imm <= LSBRS_imm[head] ;
            LSBRS_valid[head] <= `Invalid ;
            head <= head_next ;
        end
        else begin
            LSB_valid <= `Invalid ;
            LSB_op <= `Null ;
            LSB_reg1 <= `Null ;
            LSB_reg2 <= `Null ;
            LSB_reg_des_rob <= `Null ;
            LSB_imm <= `Null ;
        end

        // push in LSBRS
        if (dispatch_valid == `Valid) begin
            LSBRS_valid[tail] <= `Valid ;
            LSBRS_op[tail] <= dispatch_op ;
            LSBRS_imm[tail] <= dispatch_imm ;
            // LSBRS_pc[tail] <= dispatch_pc ;
            LSBRS_reg1_valid[tail] <= dispatch_reg1_valid ;
            LSBRS_reg1_data[tail] <= dispatch_reg1_data ;
            LSBRS_reg1_tag[tail] <= dispatch_reg1_tag ;
            LSBRS_reg2_valid[tail] <= dispatch_reg2_valid ;
            LSBRS_reg2_data[tail] <= dispatch_reg2_data ;
            LSBRS_reg2_tag[tail] <= dispatch_reg2_tag ;
            LSBRS_reg_dest_tag[tail] <= dispatch_reg_dest_tag ;
            tail <= tail_next ;
        end
    end
end
    
endmodule