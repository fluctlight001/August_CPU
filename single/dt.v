`include "lib/defines.vh"
module dt(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus] stall,

    input wire d_refill,
    input wire d_invalid,
    input wire d_modify,

    input wire data_uncached,
    input wire [19:0] data_tag,

    output reg data_uncached_o,
    output reg [19:0] data_tag_o,

    input wire [`DTLB_TO_DT_WD-1:0] dtlb_to_dt_bus,
    input wire [`DATA_SRAM_WD-1:0] dtlb_to_dt_sram_bus,

    output reg [`DT_TO_DC_WD-1:0] dt_to_dc_bus,
    // mem ctrl
    output wire        data_sram_en   ,
    output wire        data_sram_wen  ,
    output wire [ 3:0] data_sram_sel  ,
    output wire [31:0] data_sram_addr ,
    output wire [31:0] data_sram_wdata
);
    reg [`DATA_SRAM_WD-1:0] dtlb_to_dt_sram_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            data_uncached_o <= 1'b0;
            data_tag_o <= 20'b0;
            dt_to_dc_bus <= `DT_TO_DC_WD'b0;
            dtlb_to_dt_sram_bus_r <= `DATA_SRAM_WD'b0;
        end
        else if (flush) begin
            data_uncached_o <= 1'b0;
            data_tag_o <= 20'b0;
            dt_to_dc_bus <= `DT_TO_DC_WD'b0;
            dtlb_to_dt_sram_bus_r <= `DATA_SRAM_WD'b0;
        end
        else if (stall[5] == `Stop && stall[6] == `NoStop) begin
            data_uncached_o <= 1'b0;
            data_tag_o <= 20'b0;
            dt_to_dc_bus <= `DT_TO_DC_WD'b0;
            dtlb_to_dt_sram_bus_r <= `DATA_SRAM_WD'b0;
        end
        else if (stall[5] == `NoStop) begin
            data_uncached_o <= data_uncached;
            data_tag_o <= data_tag;
            dt_to_dc_bus <= {dtlb_to_dt_bus[274:153],d_modify,d_invalid,d_refill,dtlb_to_dt_bus[149:0]};
            dtlb_to_dt_sram_bus_r <= {dtlb_to_dt_sram_bus[`DATA_SRAM_WD-1]&~d_refill&~d_invalid&~d_modify,dtlb_to_dt_sram_bus[`DATA_SRAM_WD-2:0]};
        end
    end

    assign {
        data_sram_en,
        data_sram_wen,
        data_sram_sel,
        data_sram_addr,
        data_sram_wdata
    } = dtlb_to_dt_sram_bus_r;

    
endmodule 