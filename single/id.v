`include "lib/defines.vh"
module id (
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus] stall,
    input wire br_e,
    output wire stallreq,

    input wire [`IC_TO_ID_WD-1:0] ic_to_id_bus,

    // input wire [31:0] pc_i,  
    input wire [31:0] ic_inst,

    input wire wb_rf_we,
    input wire [`RegAddrBus] wb_rf_waddr,
    input wire [`RegBus] wb_rf_wdata,

    output wire [`ID_TO_EX_WD-1:0] id_to_ex_bus,
    output wire [`RegAddrBus] rs_rf_raddr,
    output wire [`RegAddrBus] rt_rf_raddr,

    // mem lwl&lwr
    input wire [4:0] mem_raddr,
    output wire [31:0] mem_rdata,

    input wire [4:0] bypass_raddr,
    output wire [31:0] bypass_rdata
);  
    wire [31:0] excepttype_i;
    wire ic_ce;
    wire [31:0] ic_pc;
    reg [31:0] id_pc;
    reg [31:0] id_inst;
    reg [31:0] excepttype_arr;
    wire [31:0] excepttype_decoder;
    wire [31:0] excepttype_o;
    // wire [31:0] inst_i,
    assign {
        excepttype_i,
        ic_ce,
        ic_pc
    } = ic_to_id_bus;

    wire [3:0] sel_nextpc;
    wire [2:0] sel_alu_src1;
    wire [3:0] sel_alu_src2;
    wire [11:0] br_op;
    wire [8:0] hilo_op;
    wire [4:0] mem_op;
    wire [5:0] cp0_op;
    wire [6:0] cache_op;
    wire branch_likely;
    wire [3:0] extra_mem_op;
    wire final_inst;
    wire [13:0] alu_op;
    wire sel_load_zero_extend;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    
    wire rf_we;
    wire [`RegAddrBus] rf_waddr;
    wire sel_rf_res;

    wire [`RegBus] rf_rdata1, rf_rdata2;

    assign excepttype_o = {excepttype_decoder[31:17],excepttype_arr[16],excepttype_decoder[15:8],excepttype_arr[7:1],excepttype_decoder[0]};

    assign id_to_ex_bus = {
        final_inst,     // 242
        rt_rf_raddr,    // 241:237
        extra_mem_op,   // 236:233
        branch_likely,  // 232
        cache_op,       // 231:225
        cp0_op,         // 224:219
        excepttype_o,   // 218:187
        mem_op,         // 186:180
        hilo_op,        // 181:173
        br_op,          // 172:161
        id_pc,          // 160:129
        id_inst,        // 128:97
        alu_op,         // 96:83
        sel_alu_src1,   // 82:80
        sel_alu_src2,   // 79:76
        data_ram_en,    // 75
        data_ram_wen,   // 74:71
        rf_we,          // 70
        rf_waddr,       // 69:65
        sel_rf_res,     // 64
        rf_rdata1,      // 63:32
        rf_rdata2       // 31:0
    };
    reg flag;
    reg [`InstAddrBus] inst;
    always @ (posedge clk) begin
        if (rst) begin
            excepttype_arr <= 32'b0;
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            flag <= 1'b0;
        end
        else if (flush) begin
            excepttype_arr <= 32'b0;
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            flag <= 1'b0;
        end
        else if (stall[2]==`NoStop && stall[3]==`NoStop && br_e) begin
            excepttype_arr <= 32'b0;
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            flag <= 1'b0;
        end
        else if (stall[2] == `Stop && stall[3] == `NoStop) begin
            excepttype_arr <= 32'b0;
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            flag <= 1'b0;
        end 
        else if (stall[2] == `NoStop&&flag) begin
            excepttype_arr <= excepttype_i;
            id_pc <= ic_pc;
            id_inst <= inst;
            flag <= 1'b0;
        end
        else if (stall[2]==`NoStop&&~flag) begin
            excepttype_arr <= excepttype_i;
            id_pc <= ic_pc;
            id_inst <= ic_inst;
            flag <= 1'b0;
        end
        else if (~flag&br_e) begin
            inst <= 32'b0;
            flag <= 1'b1;
        end
        else if (~flag) begin
            inst <= ic_inst;
            flag <= 1'b1;
        end
    end

    decoder u_decoder(
    	.rst          (rst          ),
        .stallreq     (stallreq     ),
        .pc_i         (id_pc        ),
        .inst_i       (id_inst      ),

        .br_op        (br_op        ),
        .hilo_op      (hilo_op      ),
        .mem_op       (mem_op       ),
        .cp0_op       (cp0_op       ),
        .cache_op     (cache_op     ),
        .branch_likely(branch_likely),
        .extra_mem_op (extra_mem_op ),
        .final_inst   (final_inst   ),

        // .sel_nextpc   (sel_nextpc   ),
        .sel_alu_src1 (sel_alu_src1 ),
        .sel_alu_src2 (sel_alu_src2 ),
        .alu_op       (alu_op       ),
        // .sel_load_zero_extend(sel_load_zero_extend),
        .data_ram_en  (data_ram_en  ),
        .data_ram_wen (data_ram_wen ),
        .rf_we        (rf_we        ),
        .rf_waddr     (rf_waddr     ),
        .sel_rf_res   (sel_rf_res   ),

        .excepttype_o (excepttype_decoder)
    );

    wire [`RegAddrBus] raddr1;
    wire [`RegAddrBus] raddr2;
    wire [`RegAddrBus] raddr3;
    wire [`RegAddrBus] raddr4;
    wire [`RegBus] rdata1;
    wire [`RegBus] rdata2;
    wire [`RegBus] rdata3;
    wire [`RegBus] rdata4;
    assign raddr1 = id_inst[25:21];
    assign raddr2 = id_inst[20:16];
    assign raddr3 = mem_raddr;
    assign raddr4 = bypass_raddr;
    assign rs_rf_raddr = raddr1;
    assign rt_rf_raddr = raddr2;
    
    regfile u_regfile(
    	.clk    (clk    ),
        .raddr1 (raddr1 ),
        .rdata1 (rdata1 ),
        .raddr2 (raddr2 ),
        .rdata2 (rdata2 ),
        .raddr3 (raddr3 ),
        .rdata3 (rdata3 ),
        .raddr4 (raddr4 ),
        .rdata4 (rdata4 ),
        .we     (wb_rf_we     ),
        .waddr  (wb_rf_waddr  ),
        .wdata  (wb_rf_wdata  )
    );
    

    // write first & bypass
    wire sel_r1_wdata;
    wire sel_r2_wdata;
    wire sel_r3_wdata;
    wire sel_r4_wdata;
    assign sel_r1_wdata = wb_rf_we & (wb_rf_waddr == raddr1);
    assign sel_r2_wdata = wb_rf_we & (wb_rf_waddr == raddr2);
    assign sel_r3_wdata = wb_rf_we & (wb_rf_waddr == raddr3);
    assign sel_r4_wdata = wb_rf_we & (wb_rf_waddr == raddr4);

    assign rf_rdata1 = sel_r1_wdata ? wb_rf_wdata : rdata1;
    assign rf_rdata2 = sel_r2_wdata ? wb_rf_wdata : rdata2;
    assign mem_rdata = sel_r3_wdata ? wb_rf_wdata : rdata3;
    assign bypass_rdata= sel_r4_wdata ? wb_rf_wdata : rdata4;
 
endmodule