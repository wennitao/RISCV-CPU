`include "cpu_define.v"

module MemCtrl (
    input wire clk, 
    input wire rst, 
    input wire rdy, 
    input wire clear, 

    input wire io_buffer_full, 

    // <- InstCache
    input wire InstCache_inst_read_valid, 
    input wire [`AddressBus] InstCache_inst_addr, 
    // -> InstCache
    output reg InstCache_inst_valid, 
    output reg [`InstBus] InstCache_inst, 

    // <- LoadStoreBuffer
    input wire LSB_valid, 
    input wire LSB_is_write, 
    input wire[`AddressBus] LSB_addr, 
    input wire[`LenBus] LSB_data_len, 
    input wire[`DataBus] LSB_write_data, 
    // -> LoadStoreBuffer
    output reg LSB_data_valid, 
    output reg[`DataBus] LSB_data, 

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
    if (rst || clear) begin
        mem_dout = `Null ;
        mem_a = `Null ;
        mem_wr = `Null ;
        InstCache_inst_valid = `Invalid ;
        status <= `Null ;
        stage <= `Null ;
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
                        mem_wr = `Null ;
                    end
                endcase
            end
            `DataRead: begin   
                case (stage)
                    `Wait, `Done: begin
                        mem_dout = `Null ;
                        mem_a = `Null ;
                        mem_wr = `Null ;
                    end
                    default: begin
                        if (stage == LSB_data_len) begin
                            mem_dout = `Null ;
                            mem_a = `Null ;
                            mem_wr = `Null ;
                        end
                        else begin
                            mem_wr = `Read ;
                            mem_a = LSB_addr + stage * `AddressStep ;
                            mem_dout = `Null ;
                        end
                    end
                endcase
            end
            `DataWrite: begin
                if (io_buffer_full == `Full) begin
                    mem_dout = `Null ;
                    mem_a = `Null ;
                    mem_wr = `Null ;
                end
                else begin
                    case (stage)
                        `None: begin
                            mem_wr = `Write ;
                            mem_a = LSB_addr ;
                            mem_dout = LSB_write_data[7:0] ;
                        end
                        `StageOne: begin
                            if (stage == LSB_data_len) begin
                                mem_dout = `Null ;
                                mem_a = `Null ;
                                mem_wr = `Null ;
                            end
                            else begin
                                mem_wr = `Write ;
                                mem_a = LSB_addr + stage * `AddressStep ;
                                mem_dout = LSB_write_data[15:8] ;
                            end
                        end
                        `StageTwo: begin
                            if (stage == LSB_data_len) begin
                                mem_dout = `Null ;
                                mem_a = `Null ;
                                mem_wr = `Null ;
                            end
                            else begin
                                mem_wr = `Write ;
                                mem_a = LSB_addr + stage * `AddressStep ;
                                mem_dout = LSB_write_data[23:16] ;
                            end
                        end
                        `StageThree: begin
                            mem_wr = `Write ;
                            mem_a = LSB_addr + stage * `AddressStep ;
                            mem_dout = LSB_write_data[31:24] ;
                        end
                        default: begin
                            mem_dout = `Null ;
                            mem_a = `Null ;
                            mem_wr = `Null ;
                        end
                    endcase
                end
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
        LSB_data_valid <= `Invalid ;
    end
    else if (rdy) begin
        case (status)
            `NoTask: begin
                if (LSB_valid == `Valid) begin
                    status <= (LSB_is_write == `Read ? `DataRead : `DataWrite) ;
                    stage <= `None ;
                end
                else if (InstCache_inst_read_valid == `Valid) begin
                    status <= `Inst ;
                    stage <= `None ;
                end
                else begin
                    status <= `NoTask ;
                    stage <= `None ;
                end
                InstCache_inst_valid <= `Invalid ;
                LSB_data_valid <= `Invalid ;
            end 
            `Inst: begin
                LSB_data_valid <= `Invalid ;
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
            `DataRead: begin
                InstCache_inst_valid <= `Invalid ;
                case (stage)
                    `None: begin
                        stage <= stage + `Step ;
                        LSB_data_valid <= `Invalid ;
                    end
                    `StageOne: begin
                        data[7:0] <= mem_din ;
                        if (stage == LSB_data_len) begin
                            LSB_data_valid <= `Valid ;
                            LSB_data <= {24'b0, mem_din} ;
                            stage <= `Wait ;
                            $display ("clock: %d load finish from %h data: %h", $time, LSB_addr, {24'b0, mem_din}) ;
                        end
                        else begin
                            stage <= stage + `Step ;
                            LSB_data_valid <= `Invalid ;
                        end
                    end
                    `StageTwo: begin
                        data[15:8] <= mem_din ;
                        if (stage == LSB_data_len) begin
                            LSB_data_valid <= `Valid ;
                            LSB_data <= {16'b0, mem_din, data[7:0]} ;
                            stage <= `Wait ;
                            $display ("clock: %d load finish from %h data: %h", $time, LSB_addr, {16'b0, mem_din, data[7:0]}) ;
                        end
                        else begin
                            stage <= stage + `Step ;
                            LSB_data_valid <= `Invalid ;
                        end
                    end
                    `StageThree: begin
                        data[23:16] <= mem_din ;
                        stage <= stage + `Step ;
                        LSB_data_valid <= `Invalid ;
                    end
                    `Done: begin
                        data[31:24] <= mem_din ;
                        LSB_data_valid <= `Valid ;
                        stage <= `Wait ;
                        LSB_data <= {mem_din, data[23:0]} ;
                        $display ("clock: %d load finish from %h data: %h", $time, LSB_addr, {mem_din, data[23:0]}) ;
                    end
                    `Wait: begin
                        InstCache_inst_valid <= `Invalid ;
                        LSB_data_valid <= `Invalid ;
                        status <= `NoTask ;
                    end
                endcase
            end
            `DataWrite: begin
                if (io_buffer_full == `Full) begin
                    InstCache_inst_valid <= `Invalid ;
                    LSB_data_valid <= `Invalid ;
                end
                else begin
                    InstCache_inst_valid <= `Invalid ;
                    case (stage)
                        `None: begin
                            if (stage + `AddressStep == LSB_data_len) begin
                                LSB_data_valid <= `Valid ;
                                InstCache_inst_valid <= `Invalid ;
                                LSB_data <= `Null ;
                                stage <= `Done ;
                                // $display ("clock: %d store finish to %h", $time, LSB_addr) ;
                            end
                            else begin
                                LSB_data_valid <= `Invalid ;
                                InstCache_inst_valid <= `Invalid ;
                                stage <= `NoneWait ;
                            end
                        end
                        `NoneWait: begin
                            stage <= `StageOne ;
                            InstCache_inst_valid <= `Invalid ;
                            LSB_data_valid <= `Invalid ;
                        end
                        `StageOne: begin
                            if (stage + `AddressStep == LSB_data_len) begin
                                LSB_data_valid <= `Valid ;
                                InstCache_inst_valid <= `Invalid ;
                                LSB_data <= `Null ;
                                stage <= `Done ;
                                // $display ("clock: %d store finish to %h", $time, LSB_addr) ;
                            end
                            else begin
                                LSB_data_valid <= `Invalid ;
                                InstCache_inst_valid <= `Invalid ;
                                stage <= `StageOneWait ;
                            end
                        end
                        `StageOneWait: begin
                            stage <= `StageTwo ;
                            InstCache_inst_valid <= `Invalid ;
                            LSB_data_valid <= `Invalid ;
                        end
                        `StageTwo: begin
                            LSB_data_valid <= `Invalid ;
                            InstCache_inst_valid <= `Invalid ;
                            stage <= `StageTwoWait ;
                        end
                        `StageTwoWait: begin
                            stage <= `StageThree ;
                            InstCache_inst_valid <= `Invalid ;
                            LSB_data_valid <= `Invalid ;
                        end
                        `StageThree: begin
                            LSB_data_valid <= `Valid ;
                            InstCache_inst_valid <= `Invalid ;
                            LSB_data <= `Null ;
                            stage <= `Done ;
                        end
                        `Done: begin
                            LSB_data_valid <= `Invalid ;
                            InstCache_inst_valid <= `Invalid ;
                            LSB_data <= `Null ;
                            status <= `NoTask ;
                            $display ("clock: %d store finish to %h", $time, LSB_addr) ;
                        end
                    endcase
                end
            end
        endcase
    end
    else begin
        InstCache_inst_valid <= `Invalid ;
        LSB_data_valid <= `Invalid ;
    end
end

endmodule