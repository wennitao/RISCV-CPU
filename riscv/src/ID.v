`include "cpu_define.v"
module ID (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- InstQueue
    input wire [`InstBus] InstQueue_inst, 
    input wire [`AddressBus] InstQueue_pc, 
    // -> InstQueue
    output reg InstQueue_enable
);
    
endmodule