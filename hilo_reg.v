`include "lib/defines.vh"
module hilo_reg(
    input wire clk,
    input wire rst,
    input wire [`StallBus-1:0] stall,

    input wire ex_hi_we, ex_lo_we,
    input wire [31:0] ex_hi_in,
    input wire [31:0] ex_lo_in,

    input wire mem_hi_we, mem_lo_we,
    input wire [31:0] mem_hi_in,
    input wire [31:0] mem_lo_in,
    
    input wire [65:0] hilo_bus,

    output reg [31:0] hi_data,
    output reg [31:0] lo_data
);

    reg [31:0] reg_hi, reg_lo;

    wire wb_hi_we, wb_lo_we;
    wire [31:0] wb_hi_in, wb_lo_in;
    assign {
        wb_hi_we, 
        wb_lo_we,
        wb_hi_in,
        wb_lo_in
    } = hilo_bus;

    always @ (posedge clk) begin
        if (rst) begin
            reg_hi <= 32'b0;
        end
        else if (wb_hi_we) begin
            reg_hi <= wb_hi_in;
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            reg_lo <= 32'b0;
        end
        else if (wb_lo_we) begin
            reg_lo <= wb_lo_in;
        end
    end

    wire [31:0] hi_temp, lo_temp;
    
    assign hi_temp = ex_hi_we  ? ex_hi_in
                   : mem_hi_we ? mem_hi_in
                   : wb_hi_we  ? wb_hi_in
                   : reg_hi;
    
    assign lo_temp = ex_lo_we  ? ex_lo_in
                   : mem_lo_we ? mem_lo_in
                   : wb_lo_we  ? wb_lo_in
                   : reg_lo;

    always @ (posedge clk) begin
        if (rst) begin
            {hi_data, lo_data} <= {32'b0, 32'b0};
        end
        else if(stall[2] == `Stop && stall[3] == `NoStop) begin
            {hi_data, lo_data} <= {32'b0, 32'b0};
        end
        else if (stall[2] == `NoStop) begin
            {hi_data, lo_data} <= {hi_temp, lo_temp};
        end
    end
endmodule