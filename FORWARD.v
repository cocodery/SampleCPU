`include "lib/defines.vh"
module FORWARD(
    input wire clk,
    input wire rst,
    //  input wire flush,
    input wire [`StallBus] stall,

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
    output reg [`RegBus] rs_forward_data, 
    
    output reg sel_rt_forward,
    output reg [`RegBus] rt_forward_data,

    output wire stall_for_load,
);

endmodule