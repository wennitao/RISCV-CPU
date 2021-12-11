`include "cpu_define.v"

module ROB (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    output reg clear, 

    // -> IF
    output reg IF_jump_judge, 
    output reg[`AddressBus] IF_pc, 

    // <- ID
    input wire ID_valid, 
    input wire ID_rob_ready, 
    input wire[`RegBus] ID_dest_reg, 
    input wire[`TypeBus] ID_type, 
    // -> ID
    output reg ID_rob_is_full, 
    output reg[`TagBus] ID_tag,  

    // -> LSB
    output reg LSB_commit, 

    // <- dispatch
    input wire dispatch_reg1_valid, 
    input wire[`TagBus] dispatch_reg1_tag, 
    input wire dispatch_reg2_valid, 
    input wire[`TagBus] dispatch_reg2_tag, 
    // -> dispatch
    output reg dispatch_reg1_data_valid, 
    output reg[`DataBus] dispatch_reg1_data, 
    output reg dispatch_reg2_data_valid, 
    output reg[`DataBus] dispatch_reg2_data, 

    // output CDB
    output reg CDB_valid, 
    output reg[`RegBus] CDB_reg_dest, 
    output reg[`TagBus] CDB_tag, 
    output reg[`DataBus] CDB_data, 

    // from CDB
    input wire ALU_cdb_valid, 
    input wire[`TagBus] ALU_cdb_tag, 
    input wire[`DataBus] ALU_cdb_data, 

    input wire LSB_cdb_valid, 
    input wire[`TagBus] LSB_cdb_tag, 
    input wire[`DataBus] LSB_cdb_data, 

    input wire Branch_cdb_valid, 
    input wire Branch_cdb_jump_judge, 
    input wire[`AddressBus] Branch_cdb_pc, 
    input wire[`AddressBus] Branch_cdb_original_pc, 
    input wire[`TagBus] Branch_cdb_tag, 
    input wire[`DataBus] Branch_cdb_data
);

reg[`ROBBus] head, tail ;
reg[`ROBSizeBus] ROB_ready ;
reg[`RegBus] ROB_reg_dest[`ROBSize] ;
reg[`TypeBus] ROB_type[`ROBSize] ;
reg[`DataBus] ROB_data[`ROBSize] ;
reg ROB_jump_judge[`ROBSize] ;
reg[`AddressBus] ROB_pc[`ROBSize] ;

reg lastReady, lastClear ;

wire[`ROBBus] head_next, tail_now_next, tail_next, tail_next_next ; 

assign head_next = (head == `ROBMaxIndex ? `ROBZeroIndex : head + 1'b1) ;
assign tail_now_next = (ID_valid == `Valid ? (tail == `ROBMaxIndex ? `ROBZeroIndex : tail + 1'b1) : tail) ;
assign tail_next = (tail == `ROBMaxIndex ? `ROBZeroIndex : tail + 1'b1) ;
assign tail_next_next = (tail_next == `ROBMaxIndex ? `ROBZeroIndex : tail_next + 1'b1) ;

always @(*) begin
    if (dispatch_reg1_valid == `Valid) begin
        if (ROB_ready[dispatch_reg1_tag] == `Ready) begin
            dispatch_reg1_data_valid = `Valid ;
            dispatch_reg1_data = ROB_data[dispatch_reg1_tag] ;
        end
        else if (ALU_cdb_valid == `Valid && ALU_cdb_tag == dispatch_reg1_tag) begin
            dispatch_reg1_data_valid = `Valid ;
            dispatch_reg1_data = ALU_cdb_data ;
        end
        else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == dispatch_reg1_tag) begin
            dispatch_reg1_data_valid = `Valid ;
            dispatch_reg1_data = LSB_cdb_data ;
        end
        else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == dispatch_reg1_tag) begin
            dispatch_reg1_data_valid = `Valid ;
            dispatch_reg1_data = Branch_cdb_data ;
        end
        else begin
            dispatch_reg1_data_valid = `Invalid ;
            dispatch_reg1_data = `Null ;
        end
    end
    else begin
        dispatch_reg1_data_valid = `Invalid ;
        dispatch_reg1_data = `Null ;
    end
end

always @(*) begin
    if (dispatch_reg2_valid == `Valid) begin
        if (ROB_ready[dispatch_reg2_tag] == `Ready) begin
            dispatch_reg2_data_valid = `Valid ;
            dispatch_reg2_data = ROB_data[dispatch_reg1_tag] ;
        end
        else if (ALU_cdb_valid == `Valid && ALU_cdb_tag == dispatch_reg2_tag) begin
            dispatch_reg2_data_valid = `Valid ;
            dispatch_reg2_data = ALU_cdb_data ;
        end
        else if (LSB_cdb_valid == `Valid && LSB_cdb_tag == dispatch_reg2_tag) begin
            dispatch_reg2_data_valid = `Valid ;
            dispatch_reg2_data = LSB_cdb_data ;
        end
        else if (Branch_cdb_valid == `Valid && Branch_cdb_tag == dispatch_reg2_tag) begin
            dispatch_reg2_data_valid = `Valid ;
            dispatch_reg2_data = Branch_cdb_data ;
        end
        else begin
            dispatch_reg2_data_valid = `Invalid ;
            dispatch_reg2_data = `Null ;
        end
    end
    else begin
        dispatch_reg2_data_valid = `Invalid ;
        dispatch_reg2_data = `Null ;
    end
end

always @(*) begin
    if (ALU_cdb_valid == `Valid) begin
        ROB_ready[ALU_cdb_tag] <= `Ready ;
        ROB_data[ALU_cdb_tag] <= ALU_cdb_data ;
        ROB_jump_judge[ALU_cdb_tag] <= `Fail ;
    end
    // if ($time <= 600) $display ("clock: %d %h LSB_cdb_valid: %h", $time, clk, LSB_cdb_valid) ;
    if (LSB_cdb_valid == `Valid) begin
        // $display ("clock: %d ROB LSB ready tag: %h", $time, LSB_cdb_tag) ;
        ROB_ready[LSB_cdb_tag] <= `Ready ;
        ROB_data[LSB_cdb_tag] <= LSB_cdb_data ;
        ROB_jump_judge[LSB_cdb_tag] <= `Fail ;
    end
    if (Branch_cdb_valid == `Valid) begin
        ROB_ready[Branch_cdb_tag] <= `Ready ;
        ROB_data[Branch_cdb_tag] <= Branch_cdb_data ;
        ROB_jump_judge[Branch_cdb_tag] <= Branch_cdb_jump_judge ;
        ROB_pc[Branch_cdb_tag] <= Branch_cdb_pc ;
    end
end

always @(posedge clk) begin
    if (rst || clear) begin
        clear <= `Disable ;
        lastClear <= `Disable ;
        head <= `Null ;
        tail <= `Null ;
        ROB_ready <= `Null ;
        lastReady <= `Unready ;
        IF_jump_judge <= `Invalid ;
        IF_pc <= `Null ;
        ID_rob_is_full <= `RSNotFull ;
        dispatch_reg1_data_valid <= `Invalid ;
        dispatch_reg1_data <= `Null ;
        dispatch_reg2_data_valid <= `Invalid ;
        dispatch_reg2_data <= `Null ;
        CDB_valid <= `Invalid ;
        CDB_reg_dest <= `Null ;
        CDB_data <= `Null ;
        CDB_tag <= `Null ;
    end
    else if (rdy) begin
        if (lastClear == `Valid) begin
            clear <= `Valid ;
            lastClear <= `Invalid ;
        end

        ID_tag <= tail_now_next ;
        tail <= tail_now_next ;
        ID_rob_is_full <= (tail_next == head || tail_next_next == head) ? `RSFull : `RSNotFull ;
        if (lastClear == `Invalid && ((head != tail && lastReady == `Ready && (ROB_type[head] == `TypeStore || ROB_type[head] == `TypeLoad))
        || (head == tail && ID_valid == `Valid && (ID_type == `TypeStore || ID_type == `TypeLoad)))) LSB_commit <= `Enable ;
        else LSB_commit <= `Disable ;

        if (lastClear == `Invalid && ID_valid == `Valid) begin
            ROB_ready[tail] <= ID_rob_ready ;
            ROB_reg_dest[tail] <= ID_dest_reg ;
            ROB_type[tail] <= ID_type ;
            // tail <= tail_next ;
        end

        if (lastClear == `Invalid && head != tail && ROB_ready[head] == `Ready) begin
            if (ROB_type[head] == `TypeReg || ROB_type[head] == `TypeLoad) begin
                CDB_valid <= `Valid ;
                CDB_reg_dest <= ROB_reg_dest[head] ;
                CDB_tag <= head ;
                CDB_data <= ROB_data[head] ;
            end
            else if (ROB_type[head] == `TypePc) begin
                if (ROB_jump_judge[head] == `Success) begin
                    IF_jump_judge <= `Success ;
                    IF_pc <= ROB_pc[head] ;
                    lastClear <= `Enable ;
                end
                else begin
                    IF_jump_judge <= `Fail ;
                    lastClear <= `Disable ;
                end
                CDB_valid <= `Invalid ;
            end
            else if (ROB_type[head] == `TypePcAndReg) begin
                CDB_valid <= `Valid ;
                CDB_reg_dest <= ROB_reg_dest[head] ;
                CDB_tag <= head ;
                CDB_data <= ROB_data[head] ;
                if (ROB_jump_judge[head] == `Success) begin
                    IF_jump_judge <= `Success ;
                    IF_pc <= ROB_pc[head] ;
                    lastClear <= `Enable ;
                end
                else begin
                    IF_jump_judge <= `Fail ;
                    lastClear <= `Disable ;
                end
            end
            lastReady <= `Ready ;
            head <= head_next ;
        end
        else begin
            lastReady <= `Unready ;
            IF_jump_judge <= `Invalid ;
            CDB_valid <= `Invalid ;
        end

        // if (ALU_cdb_valid == `Valid) begin
        //     ROB_ready[ALU_cdb_tag] <= `Ready ;
        //     ROB_data[ALU_cdb_tag] <= ALU_cdb_data ;
        //     ROB_jump_judge[ALU_cdb_tag] <= `Fail ;
        // end
        // if ($time <= 600) $display ("clock: %d %h LSB_cdb_valid: %h", $time, clk, LSB_cdb_valid) ;
        // if (LSB_cdb_valid == `Valid) begin
        //     $display ("clock: %d %h ROB LSB ready tag: %h", $time, clk, LSB_cdb_tag) ;
        //     ROB_ready[LSB_cdb_tag] <= `Ready ;
        //     ROB_data[LSB_cdb_tag] <= LSB_cdb_data ;
        //     ROB_jump_judge[LSB_cdb_tag] <= `Fail ;
        // end
        // if (Branch_cdb_valid == `Valid) begin
        //     ROB_ready[Branch_cdb_tag] <= `Ready ;
        //     ROB_data[Branch_cdb_tag] <= Branch_cdb_data ;
        //     ROB_jump_judge[Branch_cdb_tag] <= Branch_cdb_jump_judge ;
        //     ROB_pc[Branch_cdb_tag] <= Branch_cdb_pc ;
        // end
    end
end

endmodule