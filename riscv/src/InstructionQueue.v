`include "cpu_define.v"

module InstructionQueue (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    input wire[`InstructionBus] inst_in, 

    output wire[`InstructionBus] inst_out, 

    output reg empty, 
    output reg full
);

reg [`IQIdxBus] head, tail ;
reg [`InstructionBus] queue[`IQLenBus] ;


    
endmodule