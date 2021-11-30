`include "lib/defines.vh"
module FORWARD(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus-1:0] stall,
    
    input wire [4:0] rs_rf_raddr,
    input wire [4:0] rt_rf_raddr,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    //input wire 
    output reg sel_rs_forward_r,
    output reg sel_rt_forward_r,

    output reg [31:0] rs_forward_data_r,
    output reg [31:0] rt_forward_data_r
);

    wire sel_rs_forward;
    wire sel_rt_forward;

    wire [31:0] rs_forward_data;
    wire [31:0] rt_forward_data;

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