`include "cpu_define.v"

module LoadStoreBuffer (
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire clear, 

    // <- LoadStoreBufferRS
    input wire LSBRS_enable, 
    input wire[`OPBus] LSBRS_op, 
    input wire[`DataBus] LSBRS_imm, 
    input wire[`DataBus] LSBRS_reg1_data, 
    input wire[`DataBus] LSBRS_reg2_data, 
    input wire[`TagBus] LSBRS_reg_dest_tag, 
    // -> LoadStoreBufferRS
    output reg LSB_is_full, 

    // <- MemCtrl
    input wire MemCtrl_data_valid, 
    input wire[`DataBus] MemCtrl_data, 
    // -> MemCtrl
    output reg MemCtrl_enable, 
    output reg MemCtrl_is_write, 
    output reg[`AddressBus] MemCtrl_addr, 
    output reg[`LenBus] MemCtrl_data_len, 
    output reg[`DataBus] MemCtrl_write_data, 

    // <- ROB
    input wire ROB_commit, 

    // -> CDB
    output reg CDB_valid, 
    output reg[`TagBus] CDB_tag, 
    output reg[`DataBus] CDB_data
);

reg[`OPBus] LSB_op[`RSSize] ;
reg[`AddressBus] LSB_addr[`RSSize] ;
reg[`TagBus] LSB_dest[`RSSize] ;
reg[`DataBus] LSB_data[`RSSize] ;

reg[`RSBus] head, tail, ROB_commit_pos ;

wire head_next = (head == `RSMaxIndex ? `RSZeroIndex : head + 1'b1) ;
wire tail_next = (tail == `RSMaxIndex ? `RSZeroIndex : tail + 1'b1) ;
wire tail_next_next = (tail_next == `RSMaxIndex ? `RSZeroIndex : tail + 1'b1) ;

always @(*) begin
    LSB_is_full = (tail_next == head || tail_next_next == head ? `RSFull : `RSNotFull) ;
end

always @(posedge clk) begin
    if (rst || clear) begin
        MemCtrl_enable <= `Disable ;
        MemCtrl_is_write <= `Null ;
        MemCtrl_data_len <= `Null ;
        MemCtrl_write_data <= `Null ;
        CDB_valid <= `Invalid ;
        CDB_tag <= `Null ;
        CDB_data <= `Null ;
    end
    else if (rdy) begin
        ROB_commit_pos <= ROB_commit_pos + ROB_commit ;
        if (LSBRS_enable == `Enable) begin
            LSB_op[tail] <= LSBRS_op ;
            LSB_addr[tail] <= LSBRS_reg1_data + LSBRS_imm ;
            LSB_dest[tail] <= LSBRS_reg_dest_tag ;
            LSB_data[tail] <= LSBRS_reg2_data ;
            tail <= tail_next ;
        end
        if (head < tail + LSBRS_enable && ROB_commit > head) begin
            case (LSB_op[head])
                `LB, `LBU: begin
                    MemCtrl_enable <= `Enable ;
                    MemCtrl_is_write <= `Read ;
                    MemCtrl_data_len <= 3'b001 ;
                    MemCtrl_addr <= LSB_addr[head] ;
                    MemCtrl_write_data <= `Null ;
                end
                `LH, `LHU: begin
                    MemCtrl_enable <= `Enable ;
                    MemCtrl_is_write <= `Read ;
                    MemCtrl_data_len <= 3'b010 ;
                    MemCtrl_addr <= LSB_addr[head] ;
                    MemCtrl_write_data <= `Null ;
                end
                `LW: begin
                    MemCtrl_enable <= `Enable ;
                    MemCtrl_is_write <= `Read ;
                    MemCtrl_data_len <= 3'b100 ;
                    MemCtrl_addr <= LSB_addr[head] ;
                    MemCtrl_write_data <= `Null ;
                end
                `SB: begin
                    MemCtrl_enable <= `Enable ;
                    MemCtrl_is_write <= `Write ;
                    MemCtrl_data_len <= 3'b001 ;
                    MemCtrl_addr <= LSB_addr[head] ;
                    MemCtrl_write_data <= {24'b0, LSB_data[head][7:0]} ;
                end
                `SH: begin
                    MemCtrl_enable <= `Enable ;
                    MemCtrl_is_write <= `Write ;
                    MemCtrl_data_len <= 3'b010 ;
                    MemCtrl_addr <= LSB_addr[head] ;
                    MemCtrl_write_data <= {16'b0, LSB_data[head][15:0]} ;
                end
                `SW: begin
                    MemCtrl_enable <= `Enable ;
                    MemCtrl_is_write <= `Write ;
                    MemCtrl_data_len <= 3'b010 ;
                    MemCtrl_addr <= LSB_addr[head] ;
                    MemCtrl_write_data <= LSB_data[head][31:0] ;
                end
                default: MemCtrl_enable <= `Disable ;
            endcase
        end
    end
    else MemCtrl_addr <= `Disable ;

    if (MemCtrl_data_valid == `Valid) begin
        case (LSB_op[head])
            `LB: begin
                CDB_valid <= `Valid ;
                CDB_tag <= LSB_dest[head] ;
                CDB_data <= {{24{MemCtrl_data[7]}}, MemCtrl_data[7:0]} ;
            end
            `LH: begin
                CDB_valid <= `Valid ;
                CDB_tag <= LSB_dest[head] ;
                CDB_data <= {{16{MemCtrl_data[15]}}, MemCtrl_data[15:0]} ;
            end
            `LW: begin
                CDB_valid <= `Valid ;
                CDB_tag <= LSB_dest[head] ;
                CDB_data <= MemCtrl_data ;
            end
            `LBU: begin
                CDB_valid <= `Valid ;
                CDB_tag <= LSB_dest[head] ;
                CDB_data <= {24'b0, MemCtrl_data[7:0]} ;
            end
            `LHU: begin
                CDB_valid <= `Valid ;
                CDB_tag <= LSB_dest[head] ;
                CDB_data <= {16'b0, MemCtrl_data[7:0]} ;
            end
            `SB, `SH, `SW: begin
                CDB_valid <= `Valid ;
                CDB_tag <= LSB_dest[head] ;
            end
            default: CDB_valid = `Invalid ;
        endcase
    end
    else CDB_valid = `Invalid ;
end

endmodule