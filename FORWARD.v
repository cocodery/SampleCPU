`include "lib/defines.vh"
module FORWARD(
    input wire clk,
    input wire rst,
    //  input wire flush,
    input wire [`StallBus:0] stall,

    input wire [4:0] rs_rf_raddr,
    input wire [4:0] rt_rf_raddr,

    input wire ex_we,
    input wire [4:0] ex_waddr,
    input wire [31:0] ex_wdata,
    input wire [4:0] ex_ram_ctrl,

    input wire mem_we,
    input wire [4:0] mem_waddr,
    input wire [31:0] mem_wdata,

    output reg sel_rs_forward,
    output reg [31:0] rs_forward_data, 
    
    output reg sel_rt_forward,
    output reg [31:0] rt_forward_data,

    output wire stall_for_load
);

    wire rs_ex_ok, rt_ex_ok;
    wire sel_rs_forward_r, sel_rt_forward_r;
    wire [31:0] rs_forward_data_r;
    wire [31:0] rt_forward_data_r;
    wire stall_for_load_r;

    assign rs_ex_ok =  (rs_rf_raddr == ex_waddr)  &&  ex_we ? 1'b1 : 1'b0;
    assign rt_ex_ok =  (rt_rf_raddr == ex_waddr)  &&  ex_we ? 1'b1 : 1'b0;

    assign rs_mem_ok = (rs_rf_raddr == mem_waddr) && mem_we ? 1'b1 : 1'b0;
    assign rt_mem_ok = (rt_rf_raddr == mem_waddr) && mem_we ? 1'b1 : 1'b0;

    assign sel_rs_forward_r = rs_ex_ok | rs_mem_ok;
    assign sel_rt_forward_r = rt_ex_ok | rt_mem_ok;
    
    assign rs_forward_data_r = rs_ex_ok  ? ex_wdata :
                               rs_mem_ok ? mem_wdata:
                               32'b0;

    assign rt_forward_data_r = rt_ex_ok  ? ex_wdata :
                               rt_mem_ok ? mem_wdata:
                               32'b0;

    always @ (posedge clk) begin
        if (rst) begin
            sel_rs_forward <= 1'b0;
            sel_rt_forward <= 1'b0;
            rs_forward_data <= 32'b0;
            rt_forward_data <= 32'b0;
        end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            sel_rs_forward <= 1'b0;
            sel_rt_forward <= 1'b0;
            rs_forward_data <= 32'b0;
            rt_forward_data <= 32'b0;
        end
        else begin
            sel_rs_forward <= sel_rs_forward_r;
            sel_rt_forward <= sel_rt_forward_r;
            rs_forward_data <= rs_forward_data_r;
            rt_forward_data <= rt_forward_data_r;
        end
    end

endmodule