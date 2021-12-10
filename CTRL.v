`include "lib/defines.vh"
module CTRL(
    input wire rst,
    // input wire stallreq_for_ex,
    input wire stall_for_load,
    input wire stall_for_ex,
    output reg flush,
    output reg [31:0] new_pc,
    output reg [`StallBus-1:0] stall
);  
    always @ (*) begin
        if (rst) begin
            stall  <= `StallBus'b0;
            flush  <= 1'b0;
            new_pc <= 32'b0;
        end
        else if (stall_for_load) begin
            stall  <= `StallBus'b00_0111;
            flush  <= 1'b0;
            new_pc <= 32'b0;
        end
        else if (stall_for_ex) begin
            stall  <= `StallBus'b00_1111;
            flush  <= 1'b0;
            new_pc <= 32'b0;
        end
        else begin
            stall  <= `StallBus'b0;
            flush  <= 1'b0;
            new_pc <= 32'b0;
        end
    end

endmodule