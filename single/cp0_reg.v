`include "lib/defines.vh"

module cp0_reg(
    input wire clk,
    input wire rst,
    input wire [`StallBus] stall,

    input wire we_i,
    input wire [4:0] waddr_i,
    input wire [2:0] wsel_i,
    input wire [4:0] raddr_i,
    input wire [2:0] rsel_i,
    input wire [31:0] data_i,

    input wire [5:0] int_i,

    output wire [31:0] data_o,

    output reg [31:0] index_o,
    output reg [31:0] random_o,
    output reg [31:0] entrylo0_o,
    output reg [31:0] entrylo1_o,
    output reg [31:0] wired_o,
    output reg [31:0] badvaddr_o,
    output reg [31:0] count_o,
    output reg [31:0] entryhi_o,
    output reg [31:0] compare_o,
    output reg [31:0] status_o,
    output reg [31:0] cause_o,
    output reg [31:0] epc_o,
    output reg [31:0] prid_o,
    output reg [31:0] ebase_o,
    output reg [31:0] config_o,
    output reg [31:0] config1_o,
    output reg [31:0] taglo_o,
    output reg [31:0] taghi_o,

    output reg [31:0] timer_int_o,

    input wire [31:0] excepttype_i,
    input wire [31:0] pc_i,
    input wire [31:0] bad_vaddr_i,
    input wire is_in_delayslot_i,

    input wire [40:0] ex_cp0_bus,
    input wire [40:0] dtlb_cp0_bus,
    input wire [40:0] dt_cp0_bus,
    input wire [40:0] dc_cp0_bus,
    input wire [40:0] mem_cp0_bus,
    // input wire [37:0] wb_cp0_bus

    // tlb
    input wire        op_tlbp,
    input wire        op_tlbr,
    input wire        op_tlbwi,
    input wire [31:0] tlb_index,
    input wire [31:0] tlb_entryhi,
    input wire [31:0] tlb_entrylo0,
    input wire [31:0] tlb_entrylo1
);
    
    reg [31:0] data_r;

    reg tick;
    always @ (posedge clk) begin
        if (rst) begin
            tick <= 1'b0;
        end
        else begin
            tick <= ~tick;
        end
    end

    reg int_r;
    always @ (posedge clk)  begin
        int_r <= int_i;
    end

    // write 
    always @ (posedge clk) begin
        if (rst) begin
            index_o <= {1'b1,31'b0};
            random_o <= {28'b0,4'b1111};
            entrylo0_o <= 32'b0;
            entrylo1_o <= 32'b0;
            wired_o <= 32'b0;
            badvaddr_o <= 32'b0;
            count_o <= 32'b0;
            entryhi_o <= 32'b0;
            compare_o <= 32'b0;
            status_o <= {4'b0001,28'd0};
            cause_o <= 32'b0;
            epc_o <= 32'b0;
            prid_o <= 32'h00004220; // 0x4E 0x45 "NE"
            ebase_o <= {1'b1,31'b0};
            config_o <= 32'b1_000000000000000_0_00_000_001_0000_011;
            config1_o <= 32'b0_000000_000_100_001_000_100_001_0_0_0_0_0_0_0;
            taglo_o <= 32'b0;
            taghi_o <= 32'b0;
            timer_int_o <= 32'b0;
        end
        else if (stall[7]&stall[8])begin
            
        end
        else begin
            if (tick) begin
                count_o <= count_o + 1'b1;
            end
            cause_o[15:10] <= int_i;
            if (compare_o != 32'b0 && count_o == compare_o) begin
                timer_int_o <= `InterruptAssert;
            end 
            if (op_tlbr) begin
                entryhi_o <= {tlb_entryhi[31:13],5'b0,tlb_entryhi[7:0]};
                entrylo0_o <= {6'b0,tlb_entrylo0[25:0]};
                entrylo1_o <= {6'b0,tlb_entrylo1[25:0]};
            end
            if (op_tlbp) begin
                index_o <= {tlb_index[31],27'b0,tlb_index[3:0]};
            end
            if (we_i) begin
                case (waddr_i)
                    `CP0_REG_INDEX:begin
                        index_o <= {28'b0,data_i[3:0]};
                    end
                    `CP0_REG_ENTRYLO0:begin
                        entrylo0_o <= {6'b0,data_i[25:0]};
                    end
                    `CP0_REG_ENTRYLO1:begin
                        entrylo1_o <= {6'b0,data_i[25:0]};
                    end
                    `CP0_REG_WIRED:begin
                        wired_o[3:0] <= data_i[3:0];
                    end
                    `CP0_REG_BADVADDR:begin
                        badvaddr_o <= data_i;
                    end
                    `CP0_REG_COUNT:begin
                        count_o <= data_i;
                    end
                    `CP0_REG_ENTRYHI:begin
                        entryhi_o <= {data_i[31:13],5'b0,data_i[7:0]};
                    end 
                    `CP0_REG_COMPARE:begin
                        compare_o <= data_i;
                    end
                    `CP0_REG_STATUS:begin
                        status_o <= data_i;
                    end
                    `CP0_REG_EPC:begin
                        epc_o <= data_i;
                    end
                    `CP0_REG_CAUSE:begin
                        cause_o[9:8] <= data_i[9:8];
                        cause_o[23] <= data_i[23];
                        cause_o[22] <= data_i[22];
                    end
                    `CP0_REG_PRID:begin
                        case(wsel_i)
                            3'b1:begin
                                ebase_o[29:12] <= data_i[29:12]; 
                            end
                        endcase 
                    end
                    `CP0_REG_TAGLO:begin
                        taglo_o <= data_i;
                    end
                    `CP0_REG_TAGHI:begin
                        taghi_o <= data_i;
                    end
                    default:begin
                        
                    end
                endcase
            end
            case (excepttype_i)
                32'h00000001:begin // interrupt
                    if (is_in_delayslot_i == `InDelaySlot) begin
                        epc_o <= pc_i - 4;
                        cause_o[31] <= 1'b1;
                    end
                    else begin
                        epc_o <= pc_i;
                        cause_o[31] <= 1'b0;
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00000;
                end
                32'h00000004:begin // loadassert
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00100;
                    badvaddr_o <= bad_vaddr_i;
                end
                32'h00000005:begin // storeassert
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00101;
                    badvaddr_o <= bad_vaddr_i;
                end
                32'h00000008:begin // syscall
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end            
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01000;
                end
                32'h00000009:begin // break
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01001;
                end
                32'h0000000a:begin // inst_invalid
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1; 
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01010;
                end
                32'h0000000d:begin // trap
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01101;
                end
                32'h0000000c:begin // ov
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b01100; 
                end
                32'h0000000e:begin // eret
                    status_o[1] <= 1'b0;
                end
                32'h00000011:begin // tlb r_refill
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00010; 
                    badvaddr_o <= bad_vaddr_i;
                    entryhi_o[31:13] <= bad_vaddr_i[31:13];
                end
                32'h00000012:begin // tlb r_invalid
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00010;
                    badvaddr_o <= bad_vaddr_i;
                    entryhi_o[31:13] <= bad_vaddr_i[31:13];
                end
                32'h00000013:begin // tlb w_refill
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00011;
                    badvaddr_o <= bad_vaddr_i;
                    entryhi_o[31:13] <= bad_vaddr_i[31:13];
                end
                32'h00000014:begin // tlb w_invalid
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00011;
                    badvaddr_o <= bad_vaddr_i;
                    entryhi_o[31:13] <= bad_vaddr_i[31:13];
                end
                32'h00000015:begin // tlb d_modify
                    if (status_o[1] == 1'b0) begin
                        if (is_in_delayslot_i == `InDelaySlot) begin
                            epc_o <= pc_i - 4;
                            cause_o[31] <= 1'b1;
                        end
                        else begin
                            epc_o <= pc_i;
                            cause_o[31] <= 1'b0;
                        end
                    end
                    status_o[1] <= 1'b1;
                    cause_o[6:2] <= 5'b00001;
                    badvaddr_o <= bad_vaddr_i;
                    entryhi_o[31:13] <= bad_vaddr_i[31:13];
                end
                default:begin
                
                end
            endcase
        end
    end

    always @ (*) begin
        if (rst == `RstEnable) begin
            data_r <= `ZeroWord;
        end
        else begin
            case (raddr_i)
                `CP0_REG_INDEX:begin
                    data_r <= index_o;
                end
                `CP0_REG_RANDOM:begin
                    data_r <= random_o;
                end
                `CP0_REG_ENTRYLO0:begin
                    data_r <= entrylo0_o;
                end
                `CP0_REG_ENTRYLO1:begin
                    data_r <= entrylo1_o;
                end
                `CP0_REG_WIRED:begin
                    data_r <= wired_o;
                end
                `CP0_REG_BADVADDR:begin
                    data_r <= badvaddr_o;
                end
                `CP0_REG_COUNT:begin
                    data_r <= count_o;
                end
                `CP0_REG_ENTRYHI:begin
                    data_r <= entryhi_o;
                end
                `CP0_REG_COMPARE:begin
                    data_r <= compare_o;
                end
                `CP0_REG_STATUS:begin
                    data_r <= status_o;
                end
                `CP0_REG_CAUSE:begin
                    data_r <= cause_o;
                end
                `CP0_REG_EPC:begin
                    data_r <= epc_o;
                end
                `CP0_REG_PRID:begin
                    case(rsel_i)
                        3'b0:begin
                            data_r <= prid_o;
                        end
                        3'b1:begin
                            data_r <= ebase_o;
                        end
                    endcase
                end
                `CP0_REG_CONFIG:begin
                    case(rsel_i)
                        3'b0:begin
                            data_r <= config_o;
                        end
                        3'b1:begin
                            data_r <= config1_o;
                        end
                        default:begin
                            data_r <= `ZeroWord;
                        end
                    endcase
                end
                `CP0_REG_TAGLO:begin
                    data_r <= taglo_o;
                end
                `CP0_REG_TAGHI:begin
                    data_r <= taghi_o;
                end
                default:begin
                    data_r <= `ZeroWord;
                end
            endcase 
        end
    end

// bypass
    wire [31:0] cp0_data_temp;
    wire ex_ok, dtlb_ok, dt_ok, dc_ok, mem_ok, wb_ok;
    reg [40:0] ex_buffer, dtlb_buffer, dt_buffer, dc_buffer, mem_buffer;

    always @ (posedge clk ) begin
        if (rst) begin
            {ex_buffer,dtlb_buffer,dt_buffer,dc_buffer,mem_buffer} <= {41'b0,41'b0,41'b0,41'b0,41'b0};
        end
        else if(stall[3] == `Stop && stall[4] == `NoStop) begin
            {ex_buffer,dtlb_buffer,dt_buffer,dc_buffer,mem_buffer} <= {41'b0,41'b0,41'b0,41'b0,41'b0};
        end
        else if (stall[3] == `NoStop) begin
            {ex_buffer,dtlb_buffer,dt_buffer,dc_buffer,mem_buffer}<= {ex_cp0_bus,dtlb_cp0_bus,dt_cp0_bus,dc_cp0_bus,mem_cp0_bus};
        end
    end

    assign ex_ok = ex_buffer[40] & (raddr_i==ex_buffer[39:35] & rsel_i == ex_buffer[34:32]);
    assign dtlb_ok = dtlb_buffer[40] & (raddr_i==dtlb_buffer[39:35] &rsel_i == dtlb_buffer[34:32]);
    assign dt_ok = dt_buffer[40] & (raddr_i==dt_buffer[39:35] & rsel_i == dt_buffer[34:32]);
    assign dc_ok = dc_buffer[40] & (raddr_i==dc_buffer[39:35] & rsel_i == dc_buffer[34:32]);
    assign mem_ok = mem_buffer[40] & (raddr_i==mem_buffer[39:35] & rsel_i == mem_buffer[34:32]);
    // assign wb_ok = wb_cp0_bus[37] & (raddr_i==wb_cp0_bus[36:32]);

    wire [31:0] ex_wdata,dtlb_wdata,dt_wdata,dc_wdata,mem_wdata;

    assign ex_wdata = raddr_i == `CP0_REG_INDEX ? {28'b0,ex_buffer[3:0]} 
                    : raddr_i == `CP0_REG_ENTRYLO0 ? {6'b0,ex_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYLO1 ? {6'b0,ex_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYHI ? {ex_buffer[31:13],5'b0,ex_buffer[7:0]}
                    : ex_buffer[31:0];
    assign dtlb_wdata = raddr_i == `CP0_REG_INDEX ? {28'b0,dtlb_buffer[3:0]}
                      : raddr_i == `CP0_REG_ENTRYLO0 ? {6'b0,dtlb_buffer[25:0]}
                      : raddr_i == `CP0_REG_ENTRYLO1 ? {6'b0,dtlb_buffer[25:0]}
                      : raddr_i == `CP0_REG_ENTRYHI ? {dtlb_buffer[31:13],5'b0,dtlb_buffer[7:0]}
                      : dtlb_buffer[31:0];
    assign dt_wdata = raddr_i == `CP0_REG_INDEX ? {28'b0,dt_buffer[3:0]} 
                    : raddr_i == `CP0_REG_ENTRYLO0 ? {6'b0,dt_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYLO1 ? {6'b0,dt_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYHI ? {dt_buffer[31:13],5'b0,dt_buffer[7:0]}
                    : dt_buffer[31:0];
    assign dc_wdata = raddr_i == `CP0_REG_INDEX ? {28'b0,dc_buffer[3:0]} 
                    : raddr_i == `CP0_REG_ENTRYLO0 ? {6'b0,dc_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYLO1 ? {6'b0,dc_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYHI ? {dc_buffer[31:13],5'b0,dc_buffer[7:0]}
                    : dc_buffer[31:0];
    assign mem_wdata = raddr_i == `CP0_REG_INDEX ? {28'b0,mem_buffer[3:0]} 
                    : raddr_i == `CP0_REG_ENTRYLO0 ? {6'b0,mem_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYLO1 ? {6'b0,mem_buffer[25:0]}
                    : raddr_i == `CP0_REG_ENTRYHI ? {mem_buffer[31:13],5'b0,mem_buffer[7:0]}
                    : mem_buffer[31:0];

    assign cp0_data_temp = ex_ok ? ex_wdata
                         : dtlb_ok ? dtlb_wdata
                         : dt_ok ? dt_wdata
                         : dc_ok ? dc_wdata
                         : mem_ok ? mem_wdata
                        //  : wb_ok ? wb_cp0_bus[31:0]
                         : data_r;
    assign data_o = cp0_data_temp;
    // assign ex_ok = ex_cp0_bus[37] & (raddr_i==ex_cp0_bus[36:32]);
    // assign dc_ok = dc_cp0_bus[37] & (raddr_i==dc_cp0_bus[36:32]);
    // assign mem_ok = mem_cp0_bus[37] & (raddr_i==mem_cp0_bus[36:32]);
    // // assign wb_ok = wb_cp0_bus[37] & (raddr_i==wb_cp0_bus[36:32]);

    // assign cp0_data_temp = ex_ok ? ex_cp0_bus[31:0]
    //                      : dc_ok ? dc_cp0_bus[31:0]
    //                      : mem_ok ? mem_cp0_bus[31:0]
    //                     //  : wb_ok ? wb_cp0_bus[31:0]
    //                      : data_r;

    // always @ (posedge clk) begin
    //     if(rst) begin
    //         data_o <= 32'b0;
    //     end
    //     else if(stall[3] == `Stop && stall[4] == `NoStop) begin
    //         data_o <= 32'b0;
    //     end
    //     else if (stall[3] == `NoStop) begin
    //         data_o <= cp0_data_temp;
    //     end
    // end

endmodule