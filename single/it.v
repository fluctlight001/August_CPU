`include "lib/defines.vh"
module it(
    input wire clk,
    input wire rst,
    input wire [`StallBus] stall,
    input wire flush,
    input wire br_e,

    input wire i_refill,
    input wire i_invalid,

    input wire inst_uncached,
    input wire [19:0] inst_tag,

    output reg inst_uncached_o,
    output reg [19:0] inst_tag_o,

    input wire [`PC_TO_IT_WD-1:0] pc_to_it_bus,
    output reg [`IT_TO_IC_WD-1:0] it_to_ic_bus
);

    always @ (posedge clk) begin
        if (rst) begin
            inst_uncached_o <= 1'b0;
            inst_tag_o <= 20'b0;
            it_to_ic_bus <= `IT_TO_IC_WD'b0;
        end
        else if (flush || br_e) begin
            inst_uncached_o <= 1'b0;
            inst_tag_o <= 20'b0;
            it_to_ic_bus <= `IT_TO_IC_WD'b0;
        end
        else if (stall[1]==`Stop&&stall[2]==`NoStop) begin
            inst_uncached_o <= 1'b0;
            inst_tag_o <= 20'b0;
            it_to_ic_bus <= `IT_TO_IC_WD'b0;
        end
        else if (stall[1]==`NoStop) begin
            inst_uncached_o <= inst_uncached;
            inst_tag_o <= inst_tag;
            it_to_ic_bus <= {pc_to_it_bus[64:36],i_invalid,i_refill,pc_to_it_bus[33],pc_to_it_bus[32]&~i_refill&~i_invalid,pc_to_it_bus[31:0]};
        end
    end
endmodule