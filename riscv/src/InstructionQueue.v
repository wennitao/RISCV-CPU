`include "cpu_define.v"

module InstructionQueue (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    input wire[`InstBus] inst_in, 

    output wire[`InstBus] inst_out, 

    output reg empty, 
    output reg full
);

reg [`IQIdxBus] head, tail ;
reg [`InstBus] queue[`IQLenBus] ;


    
endmodule