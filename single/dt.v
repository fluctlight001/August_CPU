`include "lib/defines.vh"
module dt(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus] stall,

    input wire [`EX_TO_DT_WD-1:0] ex_to_dt_bus,
    input wire [`DATA_SRAM_WD-1:0] ex_dt_sram_bus,

    output reg [`DT_TO_DC_WD-1:0] dt_to_dc_bus,
    // mem ctrl
    output wire        data_sram_en   ,
    output wire        data_sram_wen  ,
    output wire [ 3:0] data_sram_sel  ,
    output wire [31:0] data_sram_addr ,
    output wire [31:0] data_sram_wdata,

    // dcache ctrl
    output wire d_index_wb_invalid, 
    output wire d_index_store_tag, 
    output wire d_hit_invalid,
    output wire d_hit_wb_invalid
);
    reg [`DATA_SRAM_WD-1:0] ex_dt_sram_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            dt_to_dc_bus <= `DT_TO_DC_WD'b0;
            ex_dt_sram_bus_r <= `DATA_SRAM_WD'b0;
        end
        else if (flush) begin
            dt_to_dc_bus <= `DT_TO_DC_WD'b0;
            ex_dt_sram_bus_r <= `DATA_SRAM_WD'b0;
        end
        else if (stall[4] == `Stop && stall[5] == `NoStop) begin
            dt_to_dc_bus <= `DT_TO_DC_WD'b0;
            ex_dt_sram_bus_r <= `DATA_SRAM_WD'b0;
        end
        else if (stall[4] == `NoStop) begin
            dt_to_dc_bus <= ex_to_dt_bus;
            ex_dt_sram_bus_r <= ex_dt_sram_bus;
        end
    end

    assign {
        data_sram_en,
        data_sram_wen,
        data_sram_sel,
        data_sram_addr,
        data_sram_wdata
    } = ex_dt_sram_bus_r;

    assign {
        d_index_wb_invalid,
        d_index_store_tag,
        d_hit_invalid,
        d_hit_wb_invalid
    } = dt_to_dc_bus[262:259];
endmodule 