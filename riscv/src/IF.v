`include "cpu_define.v"

module IF (
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in, 

    input  wire [ 7:0]          mem_din,		// data input bus
    output reg [ 7:0]          mem_dout,		// data output bus
    output reg [31:0]          mem_a,			// address bus (only 17:0 is used)
    output reg                 mem_wr			// write/read signal (1 for write)
);

reg [`AddressBus] pc ;
reg [`AddressBus] npc ;

reg [`InstructionBus] cur_instruction ;

always @(posedge clk_in) begin
    
end

endmodule