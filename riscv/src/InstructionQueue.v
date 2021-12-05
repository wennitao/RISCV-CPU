`include "cpu_define.v"

module InstructionQueue (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- IF
    input wire IF_inst_valid, 
    input wire [`InstBus] IF_inst, 
    input wire [`AddressBus] IF_pc, 
    // -> IF
    output reg queue_is_full, 

    // <- ID
    input wire ID_enable, 
    // -> ID
    output reg [`InstBus] ID_inst, 
    output reg [`AddressBus] ID_pc
) ;

reg [`IQIdxBus] head, tail ;
reg [`InstBus] inst_queue[`IQLenBus] ;
reg [`AddressBus] pc_queue[`IQLenBus] ;

wire head_next, tail_next, tail_next_next ;

assign head_next = (head == `IQMaxIndex) ? `IQZeroIndex : head + 1'b1 ;
assign tail_next = (tail == `IQMaxIndex) ? `IQZeroIndex : tail + 1'b1 ;
assign tail_next_next = (tail_next == `IQMaxIndex) ? `IQZeroIndex : tail_next + 1'b1 ;

always @(posedge clk) begin
    if (rst) begin
        head <= `Null ;
        tail <= `Null ;
        queue_is_full <= `IQNotFull ;
    end
    else if (rdy) begin
        queue_is_full <= (tail_next == head || tail_next_next == head) ? `IQFull : `IQNotFull ;
        if (IF_inst_valid == `Valid && ID_enable == `Enable) begin
            ID_inst <= IF_inst ;
            ID_pc <= IF_pc ;
        end
        else if (IF_inst_valid == `Valid) begin
            inst_queue[tail] <= IF_inst ;
            pc_queue[tail] <= IF_pc ;
            tail <= tail_next ;
        end
        else if (ID_enable == `Enable) begin
            ID_inst <= inst_queue[head] ;
            ID_pc <= pc_queue[head] ;
            head <= head_next ;
        end
    end
end

endmodule