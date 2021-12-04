`include "cpu_define.v"

module MemCtrl (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- InstCache
    input wire InstCache_inst_read_valid, 
    input wire[`AddressBus] InstCache_inst_addr, 
    // -> InstCache
    output reg InstCache_inst_valid, 
    output reg[`InstBus] InstCache_inst, 

    // <- ram
    input wire [`RamDataBus]    mem_din, 
    // -> ram
    output reg [`RamDataBus]    mem_dout, 
    output reg [`AddressBus]    mem_a, 
    output reg                  mem_wr  
) ;

reg [`AddressBus] address = `Null ;
reg [`DataBus] data ;
reg [`StageBus] stage ;

always @(*) begin
    if (rst) begin
        mem_dout = `Null ;
        mem_a = `Null ;
        mem_wr = `Null ;
    end
    else if (rdy) begin
        case (stage)
            `Done: begin
                mem_dout = `Null ;
                mem_a = `Null ;
                mem_wr = `Null ;
            end 
            default: begin
                mem_wr = `Read ;
                mem_a = address + stage * `AddressStep ;
                mem_dout = `Null ;
            end
        endcase
    end
    else begin
        mem_dout = `Null ;
        mem_a = `Null ;
        mem_wr = `Null ;
    end
end

always @(posedge clk or negedge rst) begin
    if (rst) begin
        stage <= `None ;
    end
    else if (rdy) begin
        case (stage)
            `None: begin
                stage <= stage + `Step ;
            end 
            `StageOne: begin
                stage <= stage + `Step ;
                data[7 : 0] <= mem_din ;
            end
            `StageTwo: begin
                stage <= stage + `Step ;
                data[15 : 8] <= mem_din ;
            end
            `StageThree: begin
                stage <= stage + `Step ;
                data[23 : 16] <= mem_din ;
            end
            `Done: begin
                data[31 : 24] <= mem_din ;
                stage <= `None ;
                address <= address + `PcStep ;
            end
        endcase
    end
end

endmodule