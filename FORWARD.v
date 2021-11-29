`include "lib/defines.vh"
module FORWARD(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus-1:0] stall,
    
    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus,
    input wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    //input wire 
    output reg sel_rs_forward,
    output reg sel_rt_forward,

    output reg [31:0] rs_forward_data,
    output reg [31:0] rt_forward_data
);