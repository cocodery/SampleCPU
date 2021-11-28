`include "lib/defines.vh"
module ID(
    input wire clk,
    input wire rst,
    // input wire flush,
    input wire [`StallBus-1:0] stall,
    
    output wire stallreq,

    input wire [`IF_TO_ID_WD-1:0] if_to_id_bus,

    input wire [31:0] inst_sram_rdata,

    input wire [`WB_TO_RF_WD-1:0] wb_to_rf_bus,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,

    output wire [`BR_WD-1:0] br_bus 
);

    reg [`IF_TO_ID_WD-1:0] if_to_id_bus_r;
    wire [31:0] inst;
    wire [31:0] id_pc;
    wire ce;

    wire wb_rf_we;
    wire [4:0] wb_rf_waddr;
    wire [31:0] wb_rf_wdata;

    always @ (posedge clk) begin
        if (rst) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;        
        end
        // else if (flush) begin
        //     ic_to_id_bus <= `IC_TO_ID_WD'b0;
        // end
        else if (stall[1]==`Stop && stall[2]==`NoStop) begin
            if_to_id_bus_r <= `IF_TO_ID_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            if_to_id_bus_r <= if_to_id_bus;
        end
    end
    
    assign inst = inst_sram_rdata;
    assign {
        ce,
        id_pc
    } = if_to_id_bus_r;
    assign {
        wb_rf_we,
        wb_rf_waddr,
        wb_rf_wdata
    } = wb_to_rf_bus;

    wire [5:0] opcode;
    wire [4:0] rs,rt,rd,sa;
    wire [5:0] func;
    wire [15:0] imm;
    wire [25:0] instr_index;
    wire [19:0] code;
    wire [4:0] base;
    wire [15:0] offset;
    wire [2:0] sel;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;

    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] alu_op;

    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [4:0] rf_waddr;
    wire sel_rf_res;
    wire [2:0] sel_rf_dst;

    wire [31:0] rdata1, rdata2;

    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (rs ),
        .rdata1 (rdata1 ),
        .raddr2 (rt ),
        .rdata2 (rdata2 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );

    assign opcode = inst[31:26];
    assign rs = inst[25:21];
    assign rt = inst[20:16];
    assign rd = inst[15:11];
    assign sa = inst[10:6];
    assign func = inst[5:0];
    assign imm = inst[15:0];
    assign instr_index = inst[25:0];
    assign code = inst[25:6];
    assign base = inst[25:21];
    assign offset = inst[15:0];
    assign sel = inst[2:0];

    // Arithmetic 14
    wire inst_add,   inst_addi,  inst_addu,  inst_addiu;
    wire inst_sub,   inst_subu,  inst_slt,   inst_slti;
    wire inst_sltu,  inst_sltiu, inst_div,   inst_divu;
    wire inst_mult,  inst_multu;
    // Logic 8
    wire inst_and,   inst_andi,  inst_lui,   inst_nor;
    wire inst_or,    inst_ori,   inst_xor,   inst_xori;
    // Shift 6
    wire inst_sllv,  inst_sll,   inst_srav,  inst_sra;
    wire inst_srlv,  inst_srl;
    // Branch Instruction 12
    wire inst_beq,   inst_bne,   inst_bgez,  inst_bgtz;
    wire inst_blez,  inst_bltz,  inst_bltzal,inst_bgezal;
    wire inst_j,     inst_jal,   inst_jr,    inst_jalr;
    // Data Move 4
    wire inst_mfhi,  inst_mflo,  inst_mthi,  inst_mtlo;
    // Trap 2
    wire inst_break, inst_syscall;
    // Memory Access 8
    wire inst_lb,    inst_lbu,   inst_lh,    inst_lhu;
    wire inst_lw,    inst_sb,    inst_sh,    inst_sw;
    // Super 3
    wire inst_eret,  inst_mfc0,  inst_mtc0;


    wire op_add, op_sub, op_slt, op_sltu;
    wire op_and, op_nor, op_or, op_xor;
    wire op_sll, op_srl, op_sra, op_lui;

    decoder_6_64 u0_decoder_6_64(
    	.in  (opcode  ),
        .out (op_d )
    );

    decoder_6_64 u1_decoder_6_64(
    	.in  (func  ),
        .out (func_d )
    );
    
    decoder_5_32 u0_decoder_5_32(
    	.in  (rs  ),
        .out (rs_d )
    );

    decoder_5_32 u1_decoder_5_32(
    	.in  (rt  ),
        .out (rt_d )
    );

    // Arithmetic
    assign inst_add     = op_d[6'b00_0000] & func_d[6'b10_0000];
    assign inst_addi    = op_d[6'b00_1000];
    assign inst_addu    = op_d[6'b00_0000] & func_d[6'b10_0001];
    assign inst_addiu   = op_d[6'b00_1001];
    assign inst_sub     = op_d[6'b00_0000] & func_d[6'b10_0010];
    assign inst_subu    = op_d[6'b00_0000] & func_d[6'b10_0011];
    assign inst_slt     = op_d[6'b00_0000] & func_d[6'b10_1010];
    assign inst_slti    = op_d[6'b00_1010];
    assign inst_sltu    = op_d[6'b00_0000] & func_d[6'b10_1011];
    assign inst_sltiu   = op_d[6'b00_1011];

    assign inst_div     = op_d[6'b00_0000] & func_d[6'b01_1010];
    assign inst_divu    = op_d[6'b00_0000] & func_d[6'b01_1011];
    assign inst_mult    = op_d[6'b00_0000] & func_d[6'b01_1000];
    assign inst_multu   = op_d[6'b00_0000] & func_d[6'b01_1001];
    // Logic 8
    assign inst_and     = op_d[6'b00_0000] & func_d[6'b10_0100];
    assign inst_andi    = op_d[6'b00_1100];
    assign inst_lui     = op_d[6'b00_1111];
    assign inst_nor     = op_d[6'b00_0000] & func_d[6'b10_0111];
    assign inst_or      = op_d[6'b00_0000] & func_d[6'b10_0101];
    assign inst_ori     = op_d[6'b00_1101];
    assign inst_xor     = op_d[6'b00_0000] & func_d[6'b10_0110];
    assign inst_xori    = op_d[6'b00_1110];
    // Shift
    assign inst_sllv    = op_d[6'b00_0000] & func_d[6'b00_0100];
    assign inst_sll     = op_d[6'b00_0000] & func_d[6'b00_0000];
    assign inst_srav    = op_d[6'b00_0000] & func_d[6'b00_0111];
    assign inst_sra     = op_d[6'b00_0000] & func_d[6'b00_0011];
    assign inst_srlv    = op_d[6'b00_0000] & func_d[6'b00_0110];
    assign inst_srl     = op_d[6'b00_0000] & func_d[6'b00_0010];
    // Branch-Instruction
    assign inst_beq     = op_d[6'b00_0100];
    assign inst_bne     = op_d[6'b00_0101];
    assign inst_bgez    = op_d[6'b00_0001] & rt_d[5'b0_0001];
    assign inst_bgtz    = op_d[6'b00_0111];
    assign inst_blez    = op_d[6'b00_0110];
    assign inst_bltz    = op_d[6'b00_0001] & rt_d[5'b0_0000];
    assign inst_bgezal  = op_d[6'b00_0001] & rt_d[5'b1_0001];
    assign inst_bltzal  = op_d[6'b00_0001] & rt_d[5'b1_0000];
    assign inst_j       = op_d[6'b00_0010];
    assign inst_jal     = op_d[6'b00_0011];
    assign inst_jr      = op_d[6'b00_0000] & func_d[6'b00_1000];
    assign inst_jalr    = op_d[6'b00_0000] & func_d[6'b00_1001];
    // Data Move
    assign inst_mfhi    = op_d[6'b00_0000] & func_d[6'b01_0000];
    assign inst_mflo    = op_d[6'b00_0000] & func_d[6'b01_0010];
    assign inst_mthi    = op_d[6'b00_0000] & func_d[6'b01_0001];
    assign inst_mtlo    = op_d[6'b00_0000] & func_d[6'b01_0011];
    // Trap 2
    assign inst_break   = op_d[6'b00_0000] & func_d[6'b00_1101];
    assign inst_syscall = op_d[6'b00_0000] & func_d[6'b00_1100];
    // Memory Access 8
    assign inst_lb      = op_d[6'b10_0000];
    assign inst_lbu     = op_d[6'b10_0100];
    assign inst_lh      = op_d[6'b10_0001];
    assign inst_lhu     = op_d[6'b10_0101];
    assign inst_lw      = op_d[6'b10_0011];
    assign inst_sb      = op_d[6'b10_1000];
    assign inst_sh      = op_d[6'b10_1001];
    assign inst_sw      = op_d[6'b10_1011];
    // Super 3
    assign inst_eret    = op_d[6'b01_0000] & func_d[6'b01_1000];
    assign inst_mfc0    = op_d[6'b01_0000] & rs_d[5'b0_0000];
    assign inst_mtc0    = op_d[6'b01_0000] & rs_d[5'b0_0100];

    // rs to reg1
    assign sel_alu_src1[0] =  inst_add  | inst_addi   | inst_addu  | inst_addiu 
                            | inst_sub  | inst_subu   | inst_slt   | inst_slti 
                            | inst_sltu | inst_sltiu  | inst_div   | inst_divu 
                            | inst_mult | inst_multu  | inst_and   | inst_andi 
                            | inst_nor  | inst_or     | inst_ori   | inst_xor  
                            | inst_xori | inst_sllv   | inst_srav  | inst_srlv 
                            | inst_mthi | inst_mtlo   | inst_lb    | inst_lbu  
                            | inst_lh   | inst_lhu    | inst_lw    | inst_sb   
                            | inst_sh   | inst_sw; 
    // pc to reg1
    assign sel_alu_src1[1] =  inst_jal  | inst_bltzal | inst_jalr  | inst_bgezal;
    // sa_zero_extend to reg1
    assign sel_alu_src1[2] =  inst_sll  | inst_sra    | inst_srl;
    
    // rt to reg2
    assign sel_alu_src2[0] =  inst_add  | inst_addu   | inst_sub   | inst_subu 
                            | inst_slt  | inst_sltu   | inst_div   | inst_divu 
                            | inst_mult | inst_multu  | inst_and   | inst_nor 
                            | inst_or   | inst_xor    | inst_sllv  | inst_sll 
                            | inst_srav | inst_sra    | inst_srlv  | inst_srl;
    
    // imm_sign_extend to reg2
    assign sel_alu_src2[1] =  inst_addi | inst_addiu  | inst_lw     | inst_lb
                            | inst_lbu  | inst_lh     | inst_lhu    | inst_sw 
                            | inst_sh   | inst_sb     | inst_lui    | inst_slti 
                            | inst_sltiu;
    // 32'b8 to reg2
    assign sel_alu_src2[2] =  inst_jal  | inst_bltzal | inst_bgezal | inst_jalr;
    // imm_zero_extend to reg2
    assign sel_alu_src2[3] =  inst_ori  | inst_andi   | inst_xori;


   assign op_add   =  inst_add  | inst_addu  | inst_addi    | inst_addiu 
                    | inst_lw | | inst_lb    | inst_lbu     | inst_lh 
                    | inst_lhu  | inst_sw    | inst_sh      | inst_sb 
                    | inst_jal  | inst_bltzal | inst_bgezal | inst_jalr;
    assign op_sub  =  inst_sub  | inst_subu;
    assign op_slt  =  inst_slt  | inst_slti;
    assign op_sltu =  inst_sltu | inst_sltiu;
    assign op_and  =  inst_and  | inst_andi;
    assign op_nor  =  inst_nor;
    assign op_or   =  inst_or   | inst_ori;
    assign op_xor  =  inst_xor  | inst_xori;
    assign op_sll  =  inst_sllv | inst_sll;
    assign op_srl  =  inst_srlv | inst_srl;
    assign op_sra  =  inst_srav | inst_sra;
    assign op_lui  =  inst_lui;

    assign alu_op = { op_add, op_sub, op_slt, op_sltu,
                      op_and, op_nor, op_or, op_xor,
                      op_sll, op_srl, op_sra, op_lui };



    // load and store enable
    assign data_ram_en =  inst_lb | inst_lbu | inst_lh | inst_lhu 
                        | inst_lw | inst_sb  | inst_sh | inst_sw;
    // write enable
    assign data_ram_wen = { 1'b0,   inst_sb,   inst_sh,  inst_sw };


    // regfile store enable
    assign rf_we =    inst_add    | inst_addu   | inst_addi  | inst_addiu 
                    | inst_sub    | inst_subu   | inst_lw    | inst_lb 
                    | inst_lbu    | inst_lh     | inst_lhu   | inst_jal  
                    | inst_bltzal | inst_bgezal | inst_jalr  | inst_slt 
                    | inst_slti   | inst_sltu   | inst_sltiu | inst_sllv 
                    | inst_sll    | inst_srlv   | inst_srl   | inst_srav 
                    | inst_sra    | inst_lui    | inst_and   | inst_andi
                    | inst_or     | inst_ori    | inst_xor   | inst_xori 
                    | inst_nor    | inst_mfhi   | inst_mflo  | inst_mfc0;



    // store in [rd]
    assign sel_rf_dst[0] = inst_add  | inst_addu  | inst_sub   | inst_subu 
                         | inst_slt  | inst_sltu  | inst_sllv  | inst_sll 
                         | inst_srlv | inst_srl   | inst_srav  | inst_sra 
                         | inst_and  | inst_or    | inst_xor   | inst_nor 
                         | inst_mfhi | inst_mflo;
    // store in [rt] 
    assign sel_rf_dst[1] = inst_addi  | inst_addiu  | inst_lw    | inst_lb 
                         | inst_lbu   | inst_lh     | inst_lhu   | inst_lui 
                         | inst_ori   | inst_andi   | inst_xori  | inst_slti 
                         | inst_sltiu | inst_mfc0;
    // store in [31]
    assign sel_rf_dst[2] = inst_jal   | inst_bltzal | inst_bgezal | inst_jalr;

    // sel for regfile address
    assign rf_waddr = {5{sel_rf_dst[0]}} & rd 
                    | {5{sel_rf_dst[1]}} & rt
                    | {5{sel_rf_dst[2]}} & 32'd31;

    // 0 from alu_res ; 1 from ld_res
    assign sel_rf_res = inst_lw | inst_lb | inst_lbu | inst_lh | inst_lhu;

    assign id_to_ex_bus = {
        id_pc,          // 158:127
        inst,           // 126:95
        alu_op,         // 94:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rdata1,         // 63:32
        rdata2          // 31:0
    };

    // Branch-Instruction
    wire br_e;
    wire [31:0] br_addr;
    wire rs_eq_rt; // rs == rt
    wire rs_ge_z;  // rs >= 0
    wire rs_gt_z;  // rs >  0
    wire rs_le_z;  // rs <= 0
    wire rs_lt_z;  // rs <  0
    wire [31:0] pc_plus_4;

    assign pc_plus_4 = id_pc + 32'h4;

    assign rs_eq_rt = (rdata1 == rdata2);
    assign rs_ge_z = ~rdata1[31];
    assign rs_gt_z = (rdata1[31] == 1'b0 & rdata1 != 32'b0);
    assign rs_le_z = (rdata1[31] == 1'b1 | rdata1 == 32'b0);
    assign rs_lt_z = rdata1[31];

    assign br_e = inst_beq    & rs_eq_rt
                | inst_bne    & ~rs_eq_rt
                | inst_bgez   & rs_ge_z
                | inst_bgtz   & rs_gt_z
                | inst_blez   & rs_le_z
                | inst_bltz   & rs_lt_z
                | inst_bgezal & rs_gt_z
                | inst_bltzal & rs_le_z
                | inst_j
                | inst_jal
                | inst_jr
                | inst_jalr;
    
    assign br_addr = inst_beq    ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bne    ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bgez   ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bgtz   ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_blez   ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bltz   ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bgezal ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_bltzal ? (pc_plus_4 + {{14{inst[15]}},inst[15:0],2'b0}) :
                     inst_j      ? {pc_plus_4[31:28], inst[25:0], 2'b0}           :
                     inst_jal    ? {pc_plus_4[31:28], inst[25:0], 2'b0}           :
                     inst_jr     ? rdata1                                         :
                     inst_jalr   ? rdata1                                         :
                     32'b0;

    assign br_bus = {
        br_e,
        br_addr
    };
    


endmodule