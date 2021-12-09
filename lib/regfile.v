`include "defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,

    input wire [`HILO_BUS-1:0] hilo_bus,
    
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);
    reg [31:0] reg_array [31:0];
    reg [31:0] reg_hi, reg_lo;
    wire inst_mfhi, inst_mflo, inst_mthi, inst_mtlo;
    wire [4:0] hilo_raddr, hilo_waddr;

    assign {
        inst_mfhi,
        inst_mflo,
        inst_mthi,
        inst_mtlo,
        hilo_raddr, // rd, read from reg
        hilo_waddr  // rs, write to  reg
    } = hilo_bus;
    // write
    always @ (posedge clk) begin
        if (we && waddr != 5'b0) begin
            reg_array[waddr] <= wdata;
        end
        else if (inst_mfhi && hilo_waddr != 5'b0) begin
            reg_array[hilo_waddr] <= reg_hi;
        end
        else if (inst_mflo && hilo_waddr != 5'b0) begin
            reg_array[hilo_waddr] <= reg_lo;
        end
    end

    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 :
                    inst_mfhi        ? reg_hi:
                    reg_array[raddr1];

    // read out2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 :
                    inst_mflo        ? reg_lo: 
                    reg_array[raddr2];
endmodule