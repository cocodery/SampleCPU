`include "lib/defines.vh"
module mycpu_core(
    input wire clk,
    input wire rst,
    input wire [5:0] int,

    output wire inst_sram_en,
    output wire [3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    input wire [31:0] inst_sram_rdata,

    output wire data_sram_en,
    output wire [3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    input wire [31:0] data_sram_rdata,

    output wire [31:0] debug_wb_pc,
    output wire [3:0] debug_wb_rf_wen,
    output wire [4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire [`IF_TO_ID_WD-1:0] if_to_id_bus;
    wire [`ID_TO_EX_WD-1:0] id_to_ex_bus;
    wire [`EX_TO_MEM_WD-1:0] ex_to_mem_bus;
    wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus;
    wire [`BR_WD-1:0] br_bus; 
    wire [`DATA_SRAM_WD-1:0] ex_dt_sram_bus;
    wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus;
    wire [`StallBus-1:0] stall;
    wire flush;
    wire [31:0] new_pc;
    wire stall_for_load;
    wire stall_for_ex;

    wire [31:0] hi_data, lo_data;
    wire [65:0] hilo_bus;

    IF u_IF(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .br_bus          (br_bus          ),
        .if_to_id_bus    (if_to_id_bus    ),
        .inst_sram_en    (inst_sram_en    ),
        .inst_sram_wen   (inst_sram_wen   ),
        .inst_sram_addr  (inst_sram_addr  ),
        .inst_sram_wdata (inst_sram_wdata )
    );


    ID u_ID(
    	.clk             (clk                 ),
        .rst             (rst                 ),
        .stall           (stall               ),
        .stallreq        (stallreq            ),
        .if_to_id_bus    (if_to_id_bus        ),

        .ex_we           (ex_to_mem_bus[37]   ),
        .ex_waddr        (ex_to_mem_bus[36:32]),
        .ex_wdata        (ex_to_mem_bus[31:0] ),
        .ex_ram_read     (ex_to_mem_bus[38]   ),

        .mem_we          (mem_to_wb_bus[37]   ),
        .mem_waddr       (mem_to_wb_bus[36:32]),
        .mem_wdata       (mem_to_wb_bus[31:0] ),

        .inst_sram_rdata (inst_sram_rdata     ),
        .wb_to_rf_bus    (wb_to_rf_bus        ),

        .stall_for_load  (stall_for_load      ),
        .id_to_ex_bus    (id_to_ex_bus        ),
        .br_bus          (br_bus              )
    );

    EX u_EX(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),
        .hi_data         (hi_data         ),
        .lo_data         (lo_data         ),
        .id_to_ex_bus    (id_to_ex_bus    ),
        .ex_to_mem_bus   (ex_to_mem_bus   ),
        .stall_for_ex    (stall_for_ex    ),
        .data_sram_en    (data_sram_en    ),
        .data_sram_wen   (data_sram_wen   ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata )
    );


    MEM u_MEM(
    	.clk             (clk             ),
        .rst             (rst             ),
        .stall           (stall           ),

        .ex_to_mem_bus   (ex_to_mem_bus   ),
        .data_sram_rdata (data_sram_rdata ),
        .mem_to_wb_bus   (mem_to_wb_bus   )
    );
    
    WB u_WB(
    	.clk               (clk               ),
        .rst               (rst               ),
        .stall             (stall             ),
        .mem_to_wb_bus     (mem_to_wb_bus     ),
        .wb_to_rf_bus      (wb_to_rf_bus      ),
        .hilo_bus          (hilo_bus          ),
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata )
    );

    CTRL u_CTRL(
    	.rst               (rst               ),
        .stall_for_load    (stall_for_load    ),
        .stall_for_ex      (stall_for_ex      ),
        .flush             (flush             ),
        .stall             (stall             )
    );

    hilo_reg u_hilo_reg(
        .clk                (clk                   ),
        .rst                (rst                   ),
        .stall              (stall                 ),

        .ex_hi_we           (ex_to_mem_bus[146]    ),
        .ex_lo_we           (ex_to_mem_bus[145]    ),
        .ex_hi_in           (ex_to_mem_bus[144:113]),
        .ex_lo_in           (ex_to_mem_bus[112:81] ),

        .mem_hi_we          (mem_to_wb_bus[135]    ),
        .mem_lo_we          (mem_to_wb_bus[134]    ),
        .mem_hi_in          (mem_to_wb_bus[133:102]),
        .mem_lo_in          (mem_to_wb_bus[101:70] ),

        .hilo_bus           (hilo_bus              ),

        .hi_data            (hi_data               ),
        .lo_data            (lo_data               )
    );
    
endmodule