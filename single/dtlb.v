`include "lib/defines.vh"
module dtlb(
    input wire clk,
    input wire rst,
    input wire flush,
    input wire [`StallBus] stall,

    input wire [`EX_TO_DTLB_WD-1:0] ex_to_dtlb_bus,
    input wire [`DATA_SRAM_WD-1:0] ex_to_dtlb_sram_bus,

    output reg [`DTLB_TO_DT_WD-1:0] dtlb_to_dt_bus,
    output reg [`DATA_SRAM_WD-1:0] dtlb_to_dt_sram_bus,

    output wire        dtlb_data_sram_en   ,
    output wire        dtlb_data_sram_wen  ,
    output wire [ 3:0] dtlb_data_sram_sel  ,
    output wire [31:0] dtlb_data_sram_addr ,
    output wire [31:0] dtlb_data_sram_wdata

    // dcache ctrl
    // output wire d_index_wb_invalid, 
    // output wire d_index_store_tag, 
    // output wire d_hit_invalid,
    // output wire d_hit_wb_invalid
);
    // reg [`DATA_SRAM_WD-1:0] ex_to_dtlb_sram_bus_r;

    always @ (posedge clk) begin
        if (rst) begin
            dtlb_to_dt_bus <= `DTLB_TO_DT_WD'b0;
            dtlb_to_dt_sram_bus <= `DATA_SRAM_WD'b0;
        end
        else if (flush) begin
            dtlb_to_dt_bus <= `DTLB_TO_DT_WD'b0;
            dtlb_to_dt_sram_bus <= `DATA_SRAM_WD'b0;
        end
        else if (stall[4] == `Stop && stall[5] == `NoStop) begin
            dtlb_to_dt_bus <= `DTLB_TO_DT_WD'b0;
            dtlb_to_dt_sram_bus <= `DATA_SRAM_WD'b0;
        end
        else if (stall[4] == `NoStop) begin
            dtlb_to_dt_bus <= ex_to_dtlb_bus;
            dtlb_to_dt_sram_bus <= ex_to_dtlb_sram_bus;
        end
    end

    assign {
        dtlb_data_sram_en,
        dtlb_data_sram_wen,
        dtlb_data_sram_sel,
        dtlb_data_sram_addr,
        dtlb_data_sram_wdata
    } = dtlb_to_dt_sram_bus;

    // assign {
    //     d_index_wb_invalid,
    //     d_index_store_tag,
    //     d_hit_invalid,
    //     d_hit_wb_invalid
    // } = dtlb_to_dt_bus[262:259];

endmodule