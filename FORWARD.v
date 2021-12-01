`include "lib/defines.vh"
module FORWARD(
    input wire clk,
    input wire rst,
    //input wire flush,
    input wire [`StallBus-1:0] stall,
    
    input wire [4:0] rs_rf_raddr,
    input wire [4:0] rt_rf_raddr,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    output reg sel_rs_forward_r,
    output reg sel_rt_forward_r,

    output reg [31:0] rs_forward_data_r,
    output reg [31:0] rt_forward_data_r,

    output wire stall_for_load
);

    wire sel_rs_forward;
    wire sel_rt_forward;
    wire [31:0] rs_forward_data;
    wire [31:0] rt_forward_data;

    wire ex_is_load;
    wire ex_we;
    wire [4:0] ex_waddr;
    wire [31:0] ex_wdata;
    wire [4:0] ex_ram_ctrl;

    wire mem_we;
    wire [4:0] mem_waddr;
    wire [31:0] mem_wdata;

    wire rs_ex_ok, rs_mem_ok;
    wire rt_ex_ok, rt_mem_ok;

    assign ex_we = ex_to_mem_bus[37];
    assign ex_waddr = ex_to_mem_bus[36:32];
    assign ex_wdata = ex_to_mem_bus[31:0];
    assign ex_ram_ctrl = ex_to_mem_bus[42:39];

    assign mem_we = mem_to_wb_bus[37];
    assign mem_waddr = mem_to_wb_bus[36:32];
    assign mem_wdata = mem_to_wb_bus[31:0];

    assign rs_ex_ok  = (rs_rf_raddr == ex_waddr)  && ex_we  ? 1'b1 : 1'b0;
    assign rs_mem_ok = (rs_rf_raddr == mem_waddr) && mem_we ? 1'b1 : 1'b0;

    assign rt_ex_ok  = (rt_rf_raddr == ex_waddr)  && ex_we  ? 1'b1 : 1'b0;
    assign rt_mem_ok = (rt_rf_raddr == mem_waddr) && mem_we ? 1'b1 : 1'b0;

    assign sel_rs_forward = rs_ex_ok | rs_mem_ok;
    assign sel_rt_forward = rt_ex_ok | rt_mem_ok;

    assign rs_forward_data = rs_ex_ok  ? ex_wdata  :
                             rs_mem_ok ? mem_wdata :
                             32'b0;
    assign rt_forward_data = rt_ex_ok  ? ex_wdata  :
                             rt_mem_ok ? mem_waddr :
                             32'b0;
    
    assign ex_is_load = ex_ram_ctrl[4] & ~(|ex_ram_ctrl[3:0]);
    assign stall_for_load = (ex_is_load & (rs_ex_ok|rt_ex_ok));

    always @ (posedge clk) begin
        if (rst) begin
            sel_rs_forward_r  <= 1'b0;
            sel_rt_forward_r  <= 1'b0;
            rs_forward_data_r <= 32'b0;
            rt_forward_data_r <= 32'b0;
        end
        else if (stall[2]==`Stop && stall[3]==`NoStop) begin
            sel_rs_forward_r  <= 1'b0;
            sel_rt_forward_r  <= 1'b0;
            rs_forward_data_r <= 32'b0;
            rt_forward_data_r <= 32'b0;
        end
        else if (stall[2]==`NoStop) begin
            sel_rs_forward_r  <= sel_rs_forward;
            sel_rt_forward_r  <= sel_rt_forward;
            rs_forward_data_r <= rs_forward_data;
            rt_forward_data_r <= rt_forward_data;
        end
    end
endmodule