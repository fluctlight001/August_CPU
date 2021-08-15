`include "lib/defines.vh"
module mycpu_core(
    input wire clk,
    input wire rst,
    input wire [5:0] ext_int,
    
    output wire[3:0]   arid,
    output wire[31:0]  araddr,
    output wire[3:0]   arlen,
    output wire[2:0]   arsize,
    output wire[1:0]   arburst,
    output wire[1:0]   arlock,
    output wire[3:0]   arcache,
    output wire[2:0]   arprot,
    output wire        arvalid,
    input  wire        arready,

    input  wire[3:0]   rid,
    input  wire[31:0]  rdata,
    input  wire[1:0]   rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    output wire[3:0]   awid,
    output wire[31:0]  awaddr,
    output wire[3:0]   awlen,
    output wire[2:0]   awsize,
    output wire[1:0]   awburst,
    output wire[1:0]   awlock,
    output wire[3:0]   awcache,
    output wire[2:0]   awprot,
    output wire        awvalid,
    input  wire        awready,

    output wire[3:0]   wid,
    output wire[31:0]  wdata,
    output wire[3:0]   wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    input  wire[3:0]   bid,
    input  wire[1:0]   bresp,
    input  wire        bvalid,
    output wire        bready,

    output wire [31:0] debug_wb_pc,
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata 
);

    wire inst_sram_en;
    wire inst_sram_wen;
    wire [3:0] inst_sram_sel;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;
    wire inst_uncached;
    wire [19:0] inst_tag;

    wire data_sram_en;
    wire data_sram_wen;
    wire [3:0] data_sram_sel;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;
    wire data_uncached;
    wire [19:0] data_tag;

    // icache tag
    wire icache_cached;
    wire icache_refresh;
    wire icache_miss;
    wire [31:0] icache_raddr;
    wire icache_write_back;
    wire [31:0] icache_waddr;
    wire [`HIT_WIDTH-1:0] icache_hit;
    wire [`LRU_WIDTH-1:0] icache_lru;

    // icache data
    wire [`CACHELINE_WIDTH-1:0] icache_cacheline_new;
    wire [`CACHELINE_WIDTH-1:0] icache_cacheline_old;

    // dcache tag
    wire dcache_cached;
    wire dcache_refresh;
    wire dcache_miss;
    wire [31:0] dcache_raddr;
    wire dcache_write_back;
    wire [31:0] dcache_waddr;
    wire [`HIT_WIDTH-1:0] dcache_hit;
    wire [`LRU_WIDTH-1:0] dcache_lru;

    // dcache data
    wire [`CACHELINE_WIDTH-1:0] dcache_cacheline_new;
    wire [`CACHELINE_WIDTH-1:0] dcache_cacheline_old;

    // uncache tag
    wire uncache_refresh;
    wire uncache_en;
    wire uncache_wen;
    wire [3:0] uncache_sel;
    wire [31:0] uncache_addr;
    wire uncache_hit;
    
    // uncache data
    wire [31:0] uncache_rdata;

    //ctrl 
    wire [`StallBus] stall;
    wire flush;
    wire [`InstAddrBus] new_pc;
    
    wire stallreq_from_icache;
    wire stallreq_from_dcache;
    wire stallreq_from_uncache;

    axi_control_v5 u_axi_control(
    	.clk                  (clk                  ),
        .rstn                 (~rst                 ),

        .icache_ren           (icache_miss          ),
        .icache_raddr         (icache_raddr         ),
        .icache_cacheline_new (icache_cacheline_new ),
        .icache_wen           (1'b0           ),
        .icache_waddr         (icache_waddr         ),
        .icache_cacheline_old (icache_cacheline_old ),
        .icache_refresh       (icache_refresh       ),

        .dcache_ren           (dcache_miss          ),
        .dcache_raddr         (dcache_raddr         ),
        .dcache_cacheline_new (dcache_cacheline_new ),
        .dcache_wen           (dcache_write_back    ),
        .dcache_waddr         (dcache_waddr         ),
        .dcache_cacheline_old (dcache_cacheline_old ),
        .dcache_refresh       (dcache_refresh       ),

        .uncache_en           (uncache_en           ),
        .uncache_wen          (uncache_wen          ),
        .uncache_sel          (uncache_sel          ),
        .uncache_addr         (uncache_addr         ),
        .uncache_wdata        (data_sram_wdata      ),
        .uncache_rdata        (uncache_rdata        ),
        .uncache_refresh      (uncache_refresh      ),

        .arid                 (arid                 ),
        .araddr               (araddr               ),
        .arlen                (arlen                ),
        .arsize               (arsize               ),
        .arburst              (arburst              ),
        .arlock               (arlock               ),
        .arcache              (arcache              ),
        .arprot               (arprot               ),
        .arvalid              (arvalid              ),
        .arready              (arready              ),
        .rid                  (rid                  ),
        .rdata                (rdata                ),
        .rresp                (rresp                ),
        .rlast                (rlast                ),
        .rvalid               (rvalid               ),
        .rready               (rready               ),
        .awid                 (awid                 ),
        .awaddr               (awaddr               ),
        .awlen                (awlen                ),
        .awsize               (awsize               ),
        .awburst              (awburst              ),
        .awlock               (awlock               ),
        .awcache              (awcache              ),
        .awprot               (awprot               ),
        .awvalid              (awvalid              ),
        .awready              (awready              ),
        .wid                  (wid                  ),
        .wdata                (wdata                ),
        .wstrb                (wstrb                ),
        .wlast                (wlast                ),
        .wvalid               (wvalid               ),
        .wready               (wready               ),
        .bid                  (bid                  ),
        .bresp                (bresp                ),
        .bvalid               (bvalid               ),
        .bready               (bready               )
    );

    wire [31:0] cp0_index;
    wire [31:0] cp0_entrylo0;
    wire [31:0] cp0_entrylo1;
    wire [31:0] cp0_entryhi;
    wire [31:0] tlb_index;
    wire [31:0] tlb_entrylo0;
    wire [31:0] tlb_entrylo1;
    wire [31:0] tlb_entryhi;
    wire i_refill, i_invalid, d_refill, d_invalid, d_modify;

    wire op_tlbp, op_tlbr, op_tlbwi;
    wire [2:0]  k0;
    wire [31:0] config_o;
    assign k0 = config_o[2:0];
    tlb 
    #(
        .TLBNUM (16)
    )
    u_tlb(
    	.clk           (clk           ),
        .resetn        (~rst          ),
        .k0            (k0            ),

        .we            (op_tlbwi             ),
        .w_index       (cp0_index[3:0]       ),
        .w_hi          (cp0_entryhi          ),
        .w_lo0         (cp0_entrylo0         ),
        .w_lo1         (cp0_entrylo1         ),
        
        .r_index       (cp0_index[3:0]       ),

        .inst_en       (inst_sram_en       ),
        .inst_vaddr    (inst_sram_addr     ),
        .inst_uncached (inst_uncached ),    //  1 - uncached | 0 - cached
        .inst_tag      (inst_tag      ),

        .data_ren      (data_sram_en&~data_sram_wen),
        .data_wen      (data_sram_en& data_sram_wen),
        .data_vaddr    (data_sram_addr    ),
        .data_uncached (data_uncached ),
        .data_tag      (data_tag      ),

        .p_index       (tlb_index       ),

        .i_refill      (i_refill      ),    // excepttype[1]
        .i_invalid     (i_invalid     ),    // excepttype[2]
        .d_refill      (d_refill      ),    // excepttype[3]
        .d_invalid     (d_invalid     ),    // excepttype[4]
        .d_modify      (d_modify      ),    // excepttype[5]

        .op_tlbp       (op_tlbp       ),
        .op_tlbr       (1'b0       ),
        .op_tlbwi      (1'b0      ),
        .op_tlbwr      (1'b0      ),

        .r_hi          (tlb_entryhi          ),
        .r_lo0         (tlb_entrylo0         ),
        .r_lo1         (tlb_entrylo1         )
    );
    

    wire [31:0] inst_sram_addr_mmu;
    assign inst_sram_addr_mmu = {inst_tag,inst_sram_addr[11:0]};
    // mmu u_inst_mmu(
    // 	.addr_i  (inst_sram_addr  ),
    //     .addr_o  (inst_sram_addr_mmu  ),
    //     .cache_v (icache_cached )
    // );
    
    cache_tag_v5 u_icache_tag(
    	.clk                (clk        ),
        .rst                (rst        ),
        .flush              (flush      ),
        .stallreq           (stallreq_from_icache   ),
        .cached             (1'b1     ),
        .sram_en            (inst_sram_en & ~i_refill & ~i_invalid    ),
        // .sram_addr          (inst_sram_addr_mmu),
        .sram_tag           (inst_tag          ),
        .sram_index         (inst_sram_addr[11:6]),
        .refresh            (icache_refresh    ),
        .miss               (icache_miss       ),
        .axi_raddr          (icache_raddr  ),
        .write_back         (icache_write_back),
        .axi_waddr          (icache_waddr  ),
        .hit                (icache_hit       ),
        .lru                (icache_lru       ),

        .index_invalid      (1'b0    ),
        .index_store_tag    (1'b0  ),
        .hit_invalid        (1'b0      ),
        .index_wb_invalid   (1'b0 ),
        .hit_wb_invalid     (1'b0   )
    );

    cache_data_v5 u_icache_data(
    	.clk           (clk           ),
        .rst           (rst           ),
        .write_back    (1'b0    ),
        .hit           (icache_hit           ),
        .lru           (icache_lru           ),
        .cached        (1'b1        ),
        .sram_en       (inst_sram_en & ~i_refill & ~i_invalid),
        .sram_wen      (inst_sram_wen      ),
        .sram_addr     (inst_sram_addr_mmu     ),
        .sram_wdata    (inst_sram_wdata    ),
        .sram_rdata    (inst_sram_rdata    ),
        .refresh       (icache_refresh       ),
        .cacheline_new (icache_cacheline_new ),
        .cacheline_old (icache_cacheline_old )
    );

    wire [31:0] data_sram_addr_mmu;
    wire [31:0] dcache_temp_rdata;
    wire [31:0] uncache_temp_rdata;
    assign data_sram_addr_mmu = {data_tag,data_sram_addr[11:0]};
    // mmu u_data_mmu(
    // 	.addr_i  (data_sram_addr  ),
    //     .addr_o  (data_sram_addr_mmu  ),
    //     .cache_v (dcache_cached )
    // );
    
    cache_tag_v5 u_dcache_tag(
    	.clk                (clk        ),
        .rst                (rst        ),
        .flush              (flush      ),
        .stallreq           (stallreq_from_dcache   ),
        .cached             (~data_uncached     ),
        .sram_en            (data_sram_en & ~d_refill & ~d_invalid & ~d_modify ),
        // .sram_addr          (data_sram_addr_mmu  ),
        .sram_tag           (data_tag         ),
        .sram_index         (data_sram_addr[11:6]),
        .refresh            (dcache_refresh   ),
        .miss               (dcache_miss      ),
        .axi_raddr          (dcache_raddr  ),
        .write_back         (dcache_write_back),
        .axi_waddr          (dcache_waddr     ),
        .hit                (dcache_hit       ),
        .lru                (dcache_lru       ),

        .index_invalid      (1'b0    ),
        .index_store_tag    (1'b0  ),
        .hit_invalid        (1'b0      ),
        .index_wb_invalid   (1'b0 ),
        .hit_wb_invalid     (1'b0   )
    );
    
    cache_data_v5 u_dcache_data(
    	.clk           (clk           ),
        .rst           (rst           ),
        .write_back    (dcache_write_back    ),
        .hit           (dcache_hit           ),
        .lru           (dcache_lru           ),
        .cached        (~data_uncached        ),
        .sram_en       (data_sram_en & ~d_refill & ~d_invalid & ~d_modify       ),
        .sram_wen      ({4{data_sram_wen}}&data_sram_sel),
        .sram_addr     (data_sram_addr_mmu     ),
        .sram_wdata    (data_sram_wdata    ),
        .sram_rdata    (dcache_temp_rdata   ),
        .refresh       (dcache_refresh       ),
        .cacheline_new (dcache_cacheline_new ),
        .cacheline_old (dcache_cacheline_old )
    );
    
    uncache_tag u_uncache_tag(
    	.clk       (clk       ),
        .rst       (rst       ),
        .stallreq  (stallreq_from_uncache  ),
        .cached    (~data_uncached    ),
        .sram_en   (data_sram_en & ~d_refill & ~d_invalid & ~d_modify   ),
        .sram_wen  (data_sram_wen),
        .sram_sel  (data_sram_sel),
        .sram_addr (data_sram_addr_mmu ),
        .refresh   (uncache_refresh   ),
        .axi_en    (uncache_en    ),
        .axi_wen   (uncache_wen   ),
        .axi_sel   (uncache_sel   ),
        .axi_addr  (uncache_addr  ),
        .hit       (uncache_hit   )
    );
    
    uncache_data u_uncache_data(
    	.clk        (clk        ),
        .rst        (rst        ),
        .hit        (uncache_hit        ),
        .cached     (~data_uncached     ),
        .refresh    (uncache_refresh    ),
        .axi_rdata  (uncache_rdata  ),
        .sram_rdata (uncache_temp_rdata )
    );
    
    reg data_uncached_r;
    always @ (posedge clk) begin
        data_uncached_r <= data_uncached;
    end
    assign data_sram_rdata = data_uncached_r ? uncache_temp_rdata : dcache_temp_rdata;

    wire [`PC_TO_IC_WD-1:0] pc_to_ic_bus;
    wire [`IC_TO_ID_WD-1:0] ic_to_id_bus;
    wire [`ID_TO_EX_WD-1:0] id_to_ex_bus;
    wire [`EX_TO_DT_WD-1:0] ex_to_dt_bus;
    wire [`DT_TO_DC_WD-1:0] dt_to_dc_bus;
    wire [`DC_TO_MEM_WD-1:0] dc_to_mem_bus;
    wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus;
    wire [`BR_WD-1:0] br_bus; 
    wire [`DATA_SRAM_WD-1:0] ex_dt_sram_bus;

    


    assign inst_sram_en     = pc_to_ic_bus[32];
    assign inst_sram_wen    = 4'b0;
    assign inst_sram_addr   = pc_to_ic_bus[31:0];
    assign inst_sram_wdata  = 32'b0;
    // assign {
    //     inst_sram_en,
    //     inst_sram_addr
    // } = pc_to_ic_bus[32:0];
    

    wire [`InstBus] ic_inst;
    assign ic_inst = rst ? 32'b0 
                   : ic_to_id_bus[32] ? inst_sram_rdata 
                   : 32'b0;
    
    reg branch_e_r;
    reg [31:0] branch_target_addr_r;
    wire branch_e;
    wire [31:0] branch_target_addr;
    wire [`BR_WD-1:0] bp_bus;
    reg bp_e_r;
    reg [31:0] bp_target_r;
    wire bp_e;
    wire [31:0] bp_target;


    always @ (posedge clk) begin
        if (rst) begin
            branch_e_r <= 1'b0;
            branch_target_addr_r <= 32'b0;
        end
        else if (stall[0]==`NoStop) begin
            branch_e_r <= 1'b0;
            branch_target_addr_r <= 32'b0;
        end
        else if (~branch_e_r) begin
            branch_e_r <= br_bus[32];
            branch_target_addr_r <= br_bus[31:0];
        end
    end

    assign branch_e = br_bus[32]|branch_e_r;
    assign branch_target_addr = br_bus[32] ? br_bus[31:0]
                              : branch_e_r ? branch_target_addr_r
                              : 32'b0;

    always @ (posedge clk) begin
        if (rst) begin
            bp_e_r <= 1'b0;
            bp_target_r <= 32'b0;
        end
        else if (stall[0]==`NoStop) begin
            bp_e_r <= 1'b0;
            bp_target_r <= 32'b0;
        end
        else if (~bp_e_r) begin
            bp_e_r <= bp_bus[32];
            bp_target_r <= bp_bus[31:0];
        end
    end

    assign bp_e = bp_bus[32]|bp_e_r;
    assign bp_target = bp_bus[32] ? bp_bus[31:0] 
                     : bp_e_r ? bp_target_r
                     : 32'b0;
    

    pc u_pc(
    	.clk          (clk          ),
        .rst          (rst          ),
        .stall        (stall        ),
        .flush        (flush        ),
        .new_pc       (new_pc       ),
        .br_bus       ({branch_e,branch_target_addr}       ),
        .bp_bus       ({bp_e,bp_target}),
        .pc_to_ic_bus (pc_to_ic_bus )
    );
    
    
    ic u_ic(
    	.clk          (clk          ),
        .rst          (rst          ),
        .stall        (stall        ),
        .flush        (flush        ),
        .br_e         (branch_e     ),
        .i_refill     (i_refill     ),
        .i_invalid    (i_invalid    ),
        .pc_to_ic_bus (pc_to_ic_bus ),
        .ic_to_id_bus (ic_to_id_bus )
    );

    wire [`BR_WD-1:0] bp_to_ex_bus;
    bpu u_bpu(
    	.clk          (clk          ),
        .rst          (rst          ),
        .stall        (stall        ),
        .flush        (flush        ),
        .if_pc        (pc_to_ic_bus[31:0]        ),
        .br_bus       (br_bus       ),
        .bp_bus       (bp_bus       ),
        .bp_to_ex_bus (bp_to_ex_bus )
    );
    

    wire [`RegAddrBus] rs_rf_raddr;
    wire [`RegAddrBus] rt_rf_raddr;
    wire rf_we;
    wire [`RegAddrBus] rf_waddr;
    wire [`RegBus] rf_wdata;
    wire [4:0] mem_raddr, bypass_raddr;
    wire [31:0] mem_rdata, bypass_rdata;
    
    id u_id(
    	.clk          (clk              ),
        .rst          (rst              ),
        .flush        (flush            ),
        .stall        (stall            ),
        .br_e         (branch_e       ),
        .stallreq     (stallreq         ),
        .ic_to_id_bus (ic_to_id_bus     ),
        .ic_inst      (ic_inst          ),
        .wb_rf_we     (rf_we            ),
        .wb_rf_waddr  (rf_waddr         ),
        .wb_rf_wdata  (rf_wdata         ),
        .id_to_ex_bus (id_to_ex_bus     ),
        .rs_rf_raddr  (rs_rf_raddr      ),
        .rt_rf_raddr  (rt_rf_raddr      ),
        .mem_raddr    (mem_raddr        ),
        .mem_rdata    (mem_rdata        ),
        .bypass_raddr (bypass_raddr     ),
        .bypass_rdata (bypass_rdata     )
    );

    wire [31:0] rs_forward_data;
    wire [31:0] rt_forward_data;
    wire [31:0] hi, lo;
    wire stallreq_for_ex;
    wire [4:0] cp0_reg_raddr;
    wire [2:0] cp0_reg_rsel;
    wire [31:0] cp0_reg_rdata;
    ex u_ex(
        .clk             (clk             ),
        .rst             (rst             ),
        .flush           (flush           ),
        .stall           (stall           ),
        .stallreq_for_ex (stallreq_for_ex ),
        .id_to_ex_bus    (id_to_ex_bus    ),
        .ex_to_dt_bus    (ex_to_dt_bus    ),
        .sel_rs_forward  (sel_rs_forward  ),
        .rs_forward_data (rs_forward_data ),
        .sel_rt_forward  (sel_rt_forward  ),
        .rt_forward_data (rt_forward_data ),
        .br_bus          (br_bus          ),
        .hi_i            (hi              ),
        .lo_i            (lo              ),
        .cp0_reg_raddr   (cp0_reg_raddr   ),
        .cp0_reg_rsel     (cp0_reg_rsel     ),
        .cp0_reg_data_i  (cp0_reg_rdata   ),
        // .is_in_delayslot_i(br_bus[32]     ),
        .ex_dt_sram_bus  (ex_dt_sram_bus  ),
        .bp_to_ex_bus    (bp_to_ex_bus    )
    );

    dt u_dt(
    	.clk             (clk             ),
        .rst             (rst             ),
        .flush           (flush           ),
        .stall           (stall           ),
        .ex_to_dt_bus    (ex_to_dt_bus    ),
        .ex_dt_sram_bus  (ex_dt_sram_bus  ),
        .dt_to_dc_bus    (dt_to_dc_bus    ),
        .data_sram_en    (data_sram_en    ),
        .data_sram_wen   (data_sram_wen   ),
        .data_sram_sel   (data_sram_sel   ),
        .data_sram_addr  (data_sram_addr  ),
        .data_sram_wdata (data_sram_wdata )
    );
    
    dc u_dc(
    	.clk           (clk           ),
        .rst           (rst           ),
        .flush         (flush         ),
        .stall         (stall         ),
        .d_refill      (d_refill      ),
        .d_invalid     (d_invalid     ),
        .d_modify      (d_modify      ),
        .dt_to_dc_bus  (dt_to_dc_bus  ),
        .dc_to_mem_bus (dc_to_mem_bus )
    );

    wire [31:0] cp0_status, cp0_cause, cp0_epc;
    mem u_mem(
    	.clk             (clk             ),
        .rst             (rst             ),
        .flush           (flush           ),
        .stall           (stall           ),
        .dc_to_mem_bus   (dc_to_mem_bus   ),
        .mem_to_wb_bus   (mem_to_wb_bus   ),
        .data_sram_rdata (data_sram_rdata ),
        .cp0_status      (cp0_status      ),
        .cp0_cause       (cp0_cause       ),
        .cp0_epc         (cp0_epc         ),
        .op_tlbp         (op_tlbp         ),
        .op_tlbr         (op_tlbr         ),
        .op_tlbwi        (op_tlbwi        ),
        .rt_rf_raddr     (mem_raddr       ),
        .rt_rf_rdata     (mem_rdata       )
    );
    

    wire [65:0] hilo_bus;
    wire [40:0] cp0_bus;
    assign cp0_bus = mem_to_wb_bus[273:233];

    wb u_wb(
    	.clk               (clk               ),
        .rst               (rst               ),
        .flush             (flush             ),
        .stall             (stall             ),
        .mem_to_wb_bus     (mem_to_wb_bus     ),
        .rf_we             (rf_we             ),
        .rf_waddr          (rf_waddr          ),
        .rf_wdata          (rf_wdata          ),
        .hilo_bus          (hilo_bus          ),

        // .cp0_bus           (cp0_bus           ),
        // .cp0_epc_o         (cp0_epc           ),
        // .is_in_delayslot_o (is_in_delayslot   ),
        // .bad_vaddr_o       (bad_vaddr         ),
        // .excepttype_o      (excepttype_arr    ),
        
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata )
    );
    
    wire stallreq_for_load;
    assign bypass_raddr = dc_to_mem_bus[274:240];
    bypass u_bypass(
        .clk               (clk                   ),
        .rst               (rst                   ),
        .flush             (flush                 ),
        .stall             (stall                 ),
        .stallreq_for_load (stallreq_for_load     ),

    	.rs_rf_raddr       (rs_rf_raddr           ),
        .rt_rf_raddr       (rt_rf_raddr           ),
        .ex_we             (ex_to_dt_bus[37]      ),
        .ex_waddr          (ex_to_dt_bus[36:32]   ),
        .ex_wdata          (ex_to_dt_bus[31:0]    ),
        .ex_ram_ctrl       ({ex_to_dt_bus[43:39],ex_to_dt_bus[267:266]}   ),
        .dt_we             (dt_to_dc_bus[37]      ),
        .dt_waddr          (dt_to_dc_bus[36:32]   ),
        .dt_wdata          (dt_to_dc_bus[31:0]    ),
        .dt_ram_ctrl       ({dt_to_dc_bus[43:39],dt_to_dc_bus[267:266]}   ),
        .dcache_we         (dc_to_mem_bus[37]     ),
        .dcache_waddr      (dc_to_mem_bus[36:32]  ),
        .dcache_wdata      (dc_to_mem_bus[31:0]   ),
        .dc_ram_ctrl       ({dc_to_mem_bus[43:39],dc_to_mem_bus[267:266]} ),
        .dc_mem_op         ({dc_to_mem_bus[269:268],dc_to_mem_bus[146:142]}),
        .data_sram_rdata   (data_sram_rdata       ),
        .dc_rt_rf_raddr    (bypass_raddr          ),
        .dc_rt_rf_rdata       (bypass_rdata          ),
        .mem_we            (mem_to_wb_bus[37]     ),
        .mem_waddr         (mem_to_wb_bus[36:32]  ),
        .mem_wdata         (mem_to_wb_bus[31:0]   ),
        .sel_rs_forward_r  (sel_rs_forward        ),
        .rs_forward_data_r (rs_forward_data       ),
        .sel_rt_forward_r  (sel_rt_forward        ),
        .rt_forward_data_r (rt_forward_data       )
    );

    hilo_reg u_hilo_reg(
    	.clk       (clk       ),
        .rst       (rst       ),
        .stall     (stall     ),
        .ex_hi_we  (ex_to_dt_bus[141]  ),
        .ex_lo_we  (ex_to_dt_bus[140]  ),
        .ex_hi_i   (ex_to_dt_bus[139:108]   ),
        .ex_lo_i   (ex_to_dt_bus[107:76]   ),
        .dt_hi_we  (dt_to_dc_bus[141]  ),
        .dt_lo_we  (dt_to_dc_bus[140]  ),
        .dt_hi_i   (dt_to_dc_bus[139:108]   ),
        .dt_lo_i   (dt_to_dc_bus[107:76]   ),
        .dc_hi_we  (dc_to_mem_bus[141]  ),
        .dc_lo_we  (dc_to_mem_bus[140]  ),
        .dc_hi_i   (dc_to_mem_bus[139:108]   ),
        .dc_lo_i   (dc_to_mem_bus[107:76]   ),
        .mem_hi_we (mem_to_wb_bus[135] ),
        .mem_lo_we (mem_to_wb_bus[134] ),
        .mem_hi_i  (mem_to_wb_bus[133:102]  ),
        .mem_lo_i  (mem_to_wb_bus[101:70]  ),
        .wb_hi_we  (hilo_bus[65]  ),
        .wb_lo_we  (hilo_bus[64]  ),
        .wb_hi_i   (hilo_bus[63:32]   ),
        .wb_lo_i   (hilo_bus[31:0]   ),
        .hi_o      (hi      ),
        .lo_o      (lo      )
    );
    
    cp0_reg u_cp0_reg(
    	.clk               (clk               ),
        .rst               (rst               ),
        .stall             (stall             ),

        .we_i              (cp0_bus[40]       ),
        .waddr_i           (cp0_bus[39:35]    ),
        .wsel_i            (cp0_bus[34:32]    ),
        .raddr_i           (cp0_reg_raddr     ),
        .rsel_i            (cp0_reg_rsel      ),
        .data_i            (cp0_bus[31:0]     ),
        .int_i             (ext_int           ),

        .data_o            (cp0_reg_rdata     ),

        .index_o           (cp0_index),
        .entrylo0_o        (cp0_entrylo0),
        .entrylo1_o        (cp0_entrylo1),
        .entryhi_o         (cp0_entryhi),

        .status_o          (cp0_status        ),
        .cause_o           (cp0_cause         ),
        .epc_o             (cp0_epc           ),
        .config_o          (config_o          ),

        .excepttype_i      (mem_to_wb_bus[167:136]       ),
        .pc_i              (mem_to_wb_bus[69:38]         ),
        .bad_vaddr_i       (mem_to_wb_bus[199:168]       ),
        .is_in_delayslot_i (mem_to_wb_bus[200]           ),

        .ex_cp0_bus        (ex_to_dt_bus[252:212]        ),
        .dt_cp0_bus        (dt_to_dc_bus[252:212]        ),
        .dc_cp0_bus        (dc_to_mem_bus[252:212]       ),
        .mem_cp0_bus       (mem_to_wb_bus[273:233]       ),
        // .wb_cp0_bus        (cp0_bus        )
        .op_tlbp           (op_tlbp         ),
        .op_tlbr           (op_tlbr         ),
        .op_tlbwi          (op_tlbwi        ),
        .tlb_index         (tlb_index       ),
        .tlb_entryhi       (tlb_entryhi     ),
        .tlb_entrylo0      (tlb_entrylo0    ),
        .tlb_entrylo1      (tlb_entrylo1    )
    );
 
    ctrl u_ctrl(
    	.rst              (rst              ),
        .stallreq_for_ex  (stallreq_for_ex ),
        .stallreq_for_load(stallreq_for_load),
        .stallreq_from_icache   (stallreq_from_icache),
        .stallreq_from_dcache   (stallreq_from_dcache),
        .stallreq_from_uncache  (stallreq_from_uncache),
        .excepttype_i     (mem_to_wb_bus[167:136]   ),
        .cp0_epc_i        (mem_to_wb_bus[232:201]   ),
        .current_pc       (mem_to_wb_bus[69:38]     ),
        .flush            (flush            ),
        .new_pc           (new_pc           ),
        .stall            (stall            )
    );
    
    
    
    
    
endmodule 