`include "cpu_define.v"

module IF (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- InstCache
    input wire InstCache_inst_valid, 
    input wire [`InstBus] InstCache_inst, 
    // -> InstCache
    output reg InstCache_inst_read_valid, 
    output reg [`AddressBus] InstCache_inst_addr
);

reg [`AddressBus] pc ;
reg [`AddressBus] npc ;

always @(posedge clk) begin
    if (rst) begin
        pc <= `Null ;
        npc <= `Null + `PcStep ;
        InstCache_inst_read_valid <= `Invalid ;
        InstCache_inst_addr <= `Null ;
    end
    else if (rdy) begin
        if (InstCache_inst_valid == `Valid) begin
            pc <= npc ;
            npc <= npc + `PcStep ;
            InstCache_inst_read_valid = `Valid ;
            InstCache_inst_addr <= npc ;
        end
        else begin
            InstCache_inst_read_valid = `Valid ;
            InstCache_inst_addr <= pc ;
        end
    end
end

endmodule