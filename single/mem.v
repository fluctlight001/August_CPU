`include "lib/defines.vh"
module mem(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus] stall,

    input wire [`DC_TO_MEM_WD-1:0] dc_to_mem_bus,

    output wire [`MEM_TO_WB_WD-1:0] mem_to_wb_bus,

    input wire [31:0] data_sram_rdata,

    input wire [`RegBus] cp0_status,
    input wire [`RegBus] cp0_cause,
    input wire [`RegBus] cp0_epc,

    // tlb
    output wire op_tlbp,
    output wire op_tlbr,
    output wire op_tlbwi,

    // lwl&lwr
    output wire [4:0] rt_rf_raddr,
    input wire [31:0] rt_rf_rdata
);

    reg [`DC_TO_MEM_WD-1:0] dc_to_mem_bus_r;
    reg [31:0] data_sram_rdata_r;
    reg flag;
    reg [31:0] data_sram_rdata_buffer;

    always @ (posedge clk) begin
        if (rst) begin
            dc_to_mem_bus_r <= `DC_TO_MEM_WD'b0;
            data_sram_rdata_r <= 32'b0;
            flag <= 1'b0;
        end
        else if (flush) begin
            dc_to_mem_bus_r <= `DC_TO_MEM_WD'b0;
            data_sram_rdata_r <= 32'b0;
            flag <= 1'b0;
        end
        else if (stall[6] == `Stop && stall[7] == `NoStop) begin
            dc_to_mem_bus_r <= `DC_TO_MEM_WD'b0;
            data_sram_rdata_r <= 32'b0;
            flag <= 1'b0;
        end
        else if (stall[6] == `NoStop&&flag) begin
            dc_to_mem_bus_r <= dc_to_mem_bus;
            data_sram_rdata_r <= data_sram_rdata_buffer;
            flag <= 1'b0;
        end
        else if (stall[6] == `NoStop&&~flag) begin
            dc_to_mem_bus_r <= dc_to_mem_bus;
            data_sram_rdata_r <= data_sram_rdata;
            flag <= 1'b0;
        end
        else if(~flag) begin
            data_sram_rdata_buffer <= data_sram_rdata;
            flag <= 1'b1;
        end
    end

    wire [65:0] hilo_bus;
    wire [31:0] pc;
    wire sel_rf_res;
    wire rf_we;
    wire [4:0] rf_waddr;
    wire [31:0] rf_wdata;
    wire [4:0] mem_op;
    wire data_ram_en;
    wire [3:0] data_ram_wen;
    wire [31:0] alu_result;
    wire [31:0] mem_result;
    wire [31:0] excepttype_arr;
    wire [31:0] bad_vaddr;
    wire is_in_delayslot;
    wire [46:0] cp0_bus;
    wire [6:0] cache_op;
    wire [3:0] extra_mem_op;
    
    assign {
        rt_rf_raddr,    // 274:270
        extra_mem_op,   // 269:266
        cache_op,       // 265:259
        cp0_bus,        // 258:212
        is_in_delayslot,// 211
        bad_vaddr,      // 210:179
        excepttype_arr, // 178:147
        mem_op,         // 146:142
        hilo_bus,       // 141:76
        pc,             // 75:44        
        data_ram_en,    // 43
        data_ram_wen,   // 42:39
        sel_rf_res,     // 38
        rf_we,          // 37
        rf_waddr,       // 36:32
        alu_result      // 31:0
    } = dc_to_mem_bus_r;

    wire inst_lb, inst_lbu, inst_lh, inst_lhu, inst_lw;
    assign {
        inst_lb,
        inst_lbu,
        inst_lh,
        inst_lhu,
        inst_lw
    } = mem_op;

    wire inst_lwl, inst_lwr, inst_swl, inst_swr;
    assign {
        inst_lwl,
        inst_lwr,
        inst_swl,
        inst_swr
    } = extra_mem_op;

    wire op_load, op_store;
    assign op_load = |mem_op | inst_lwl | inst_lwr;
    assign op_store = |data_ram_wen | inst_swl | inst_swr;

        
    reg [31:0] excepttype_o;
    wire [31:0] cp0_epc_o;
    wire is_in_delayslot_o;
    wire [31:0] bad_vaddr_o;
    assign is_in_delayslot_o = is_in_delayslot;
    wire [40:0] cp0_bus_o;
    assign cp0_bus_o = cp0_bus[40:0];

    wire i_refill, i_invalid, d_refill, d_invalid, d_modify;
    assign {d_modify,d_invalid,d_refill,i_invalid,i_refill} = excepttype_arr[5:1];
    assign bad_vaddr_o = (i_refill|i_invalid) ? pc 
                       : (d_refill|d_invalid|d_modify) ? alu_result 
                       : bad_vaddr;

    assign mem_to_wb_bus = {
        cp0_bus_o,      // 273:233
        cp0_epc_o,      // 232:201
        is_in_delayslot_o,// 200
        bad_vaddr_o,    // 199:168
        excepttype_o,   // 167:136
        hilo_bus,       // 135:70
        pc,             // 69:38
        rf_we,          // 37
        rf_waddr,       // 36:32
        rf_wdata        // 31:0
    };

// load part
    reg [31:0] mem_result_r;
    always @ (*) begin
        case(1'b1)
            inst_lb:begin
                case(alu_result[1:0])
                    2'b00:begin
                        mem_result_r = {{24{data_sram_rdata_r[7]}},data_sram_rdata_r[7:0]};
                    end
                    2'b01:begin
                        mem_result_r = {{24{data_sram_rdata_r[15]}},data_sram_rdata_r[15:8]};
                    end
                    2'b10:begin
                        mem_result_r = {{24{data_sram_rdata_r[23]}},data_sram_rdata_r[23:16]};
                    end
                    2'b11:begin
                        mem_result_r = {{24{data_sram_rdata_r[31]}},data_sram_rdata_r[31:24]};
                    end
                    default:begin
                        mem_result_r = 32'b0;
                    end
                endcase
            end
            inst_lbu:begin
                case(alu_result[1:0])
                    2'b00:begin
                        mem_result_r = {{24{1'b0}},data_sram_rdata_r[7:0]};
                    end
                    2'b01:begin
                        mem_result_r = {{24{1'b0}},data_sram_rdata_r[15:8]};
                    end
                    2'b10:begin
                        mem_result_r = {{24{1'b0}},data_sram_rdata_r[23:16]};
                    end
                    2'b11:begin
                        mem_result_r = {{24{1'b0}},data_sram_rdata_r[31:24]};
                    end
                    default:begin
                        mem_result_r = 32'b0;
                    end
                endcase
            end
            inst_lh:begin
                case(alu_result[1:0])
                    2'b00:begin
                        mem_result_r = {{16{data_sram_rdata_r[15]}},data_sram_rdata_r[15:0]};
                    end
                    
                    2'b10:begin
                        mem_result_r = {{16{data_sram_rdata_r[31]}},data_sram_rdata_r[31:16]};
                    end
                    default:begin
                        mem_result_r = 32'b0;
                    end
                endcase
            end
            inst_lhu:begin
                case(alu_result[1:0])
                    2'b00:begin
                        mem_result_r = {{16{1'b0}},data_sram_rdata_r[15:0]};
                    end
                    
                    2'b10:begin
                        mem_result_r = {{16{1'b0}},data_sram_rdata_r[31:16]};
                    end
                    default:begin
                        mem_result_r = 32'b0;
                    end
                endcase
            end
            inst_lw:begin
                mem_result_r = data_sram_rdata_r;
            end
            inst_lwl:begin
                case(alu_result[1:0])
                    2'b00:begin
                        mem_result_r = {data_sram_rdata_r[7:0],rt_rf_rdata[23:0]};
                    end
                    2'b01:begin
                        mem_result_r = {data_sram_rdata_r[15:0],rt_rf_rdata[15:0]};
                    end
                    2'b10:begin
                        mem_result_r = {data_sram_rdata_r[23:0],rt_rf_rdata[7:0]};
                    end
                    2'b11:begin
                        mem_result_r = data_sram_rdata_r;
                    end
                    default:begin
                        mem_result_r = 32'b0;
                    end
                endcase
            end
            inst_lwr:begin
                case(alu_result[1:0])
                    2'b00:begin
                        mem_result_r = data_sram_rdata_r;
                    end
                    2'b01:begin
                        mem_result_r = {rt_rf_rdata[31:24],data_sram_rdata_r[23:0]};
                    end
                    2'b10:begin
                        mem_result_r = {rt_rf_rdata[31:16],data_sram_rdata_r[15:0]};
                    end
                    2'b11:begin
                        mem_result_r = {rt_rf_rdata[31:8],data_sram_rdata_r[7:0]};
                    end
                    default:begin
                        mem_result_r = 32'b0;
                    end
                endcase
            end
            default:begin
                mem_result_r = 32'b0;
            end
        endcase
    end
    // assign mem_result = data_sram_rdata_r;
    assign rf_wdata = sel_rf_res ? mem_result_r : alu_result;

// tlb part
    wire inst_mfc0,inst_mtc0, inst_cache, inst_tlbp, inst_tlbr, inst_tlbwi;
    assign {
        inst_cache,
        inst_tlbp,
        inst_tlbr,
        inst_tlbwi,
        inst_mfc0,
        inst_mtc0
    } = cp0_bus[46:41];

    assign op_tlbp = inst_tlbp;
    assign op_tlbr = inst_tlbr;
    assign op_tlbwi = inst_tlbwi;

// excepttype part
    // wire [31:0] cp0_status;
    // wire [31:0] cp0_cause;
    // wire [31:0] cp0_epc;
    assign cp0_epc_o = cp0_epc;

    always @ (*) begin
        if (rst == `RstEnable) begin
            excepttype_o <= `ZeroWord;
        end
        else begin
            excepttype_o <= `ZeroWord;
            if (pc != `ZeroWord) begin
                if (((cp0_cause[15:8] & cp0_status[15:8]) != 8'b0) && (cp0_status[1] == 1'b0) && (cp0_status[0] == 1'b1)) begin
                    excepttype_o <= 32'h00000001;         //interrupt
                end
                else if (excepttype_arr[16] == 1'b1) begin // ft_adel
                    excepttype_o <= 32'h00000004;
                end
                else if (excepttype_arr[9] == 1'b1) begin // inst_invalid
                    excepttype_o <= 32'h0000000a;
                end
                else if (excepttype_arr[1] == 1'b1) begin // tlb i_refill
                    excepttype_o <= 32'h00000011;
                end
                else if (excepttype_arr[2] == 1'b1) begin // tlb i_invalid
                    excepttype_o <= 32'h00000012;
                end
                else if (excepttype_arr[8] == 1'b1) begin // syscall
                    excepttype_o <= 32'h00000008;
                end
                else if (excepttype_arr[13] == 1'b1) begin // break
                    excepttype_o <= 32'h00000009;
                end
                else if (excepttype_arr[10] == 1'b1) begin // trap
                    excepttype_o <= 32'h0000000d;
                end
                else if (excepttype_arr[11] == 1'b1) begin // ov
                    excepttype_o <= 32'h0000000c;
                end
                else if (excepttype_arr[12] == 1'b1) begin // eret
                    excepttype_o <= 32'h0000000e;
                end
                else if (excepttype_arr[14] == 1'b1) begin // storeassert
                    excepttype_o <= 32'h00000005;
                end
                else if (excepttype_arr[15] == 1'b1) begin // loadassert
                    excepttype_o <= 32'h00000004;
                end
                else if (excepttype_arr[3] & op_load) begin // tlb d_refill r
                    excepttype_o <= 32'h00000011;
                end
                else if (excepttype_arr[3] & op_store) begin // tlb d_refill w
                    excepttype_o <= 32'h00000013;
                end
                else if (excepttype_arr[4] & op_load) begin // tlb d_invalid r
                    excepttype_o <= 32'h00000012;
                end
                else if (excepttype_arr[4] & op_store) begin // tlb d_invalid w
                    excepttype_o <= 32'h00000014;
                end 
                else if (excepttype_arr[5] == 1'b1) begin // tlb d_modify
                    excepttype_o <= 32'h00000015;
                end
                else if (excepttype_arr[0] == 1'b1) begin // again_flag :  re execute the current instruction
                    excepttype_o <= 32'hffffffff;
                end
            end
        end
  end


endmodule 