`include "cpu_define.v"

module MemCtrl (
    input wire clk, 
    input wire rst, 
    input wire rdy, 

    // <- InstCache
    input wire InstCache_inst_read_valid, 
    input wire [`AddressBus] InstCache_inst_addr, 
    // -> InstCache
    output reg InstCache_inst_valid, 
    output reg [`InstBus] InstCache_inst, 

    // <- ram
    input wire [`RamDataBus]    mem_din, 
    // -> ram
    output reg [`RamDataBus]    mem_dout, 
    output reg [`AddressBus]    mem_a, 
    output reg                  mem_wr  
) ;

reg [`StatusBus] status ;
reg [`DataBus] data ;
reg [`StageBus] stage ;

always @(*) begin
    if (rst) begin
        mem_dout = `Null ;
        mem_a = `Null ;
        mem_wr = `Null ;
    end
    else if (rdy) begin
        case (status)
            `NoTask: begin
                mem_dout = `Null ;
                mem_a = `Null ;
                mem_wr = `Null ;
            end 
            `Inst: begin
                case (stage)
                    `Done: begin
                        mem_dout = `Null ;
                        mem_a = `Null ;
                        mem_wr = `Null ;
                    end 
                    default: begin
                        mem_wr = `Read ;
                        mem_a = InstCache_inst_addr + stage * `AddressStep ;
                    end
                endcase
            end
            default: begin
                mem_dout = `Null ;
                mem_a = `Null ;
                mem_wr = `Null ;
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
        status <= `None ;
        stage <= `None ;
        InstCache_inst_valid <= `Invalid ;
    end
    else if (rdy) begin
        case (status)
            `NoTask: begin
                if (InstCache_inst_read_valid == `Valid) begin
                    status <= `Inst ;
                    stage <= `None ;
                end
                else begin
                    status <= `None ;
                    stage <= `None ;
                end
                InstCache_inst_valid <= `Invalid ;
            end 
            `Inst: begin
                case (stage)
                    `None: begin
                        stage <= stage + `Step ;
                        InstCache_inst_valid <= `Invalid ;
                    end 
                    `StageOne: begin
                        stage <= stage + `Step ;
                        data[7 : 0] <= mem_din ;
                        InstCache_inst_valid <= `Invalid ;
                    end
                    `StageTwo: begin
                        stage <= stage + `Step ;
                        data[15 : 8] <= mem_din ;
                        InstCache_inst_valid <= `Invalid ;
                    end
                    `StageThree: begin
                        stage <= stage + `Step ;
                        data[23 : 16] <= mem_din ;
                        InstCache_inst_valid <= `Invalid ;
                    end
                    `Done: begin
                        data[31 : 24] <= mem_din ;
                        InstCache_inst_valid <= `Valid ;
                        InstCache_inst <= {mem_din, data[23 : 0]} ;
                        stage <= `None ;
                        status <= `NoTask ;
                    end
                endcase
            end
        endcase
    end
    else begin
        InstCache_inst_valid <= `Invalid ;
    end
end

endmodule