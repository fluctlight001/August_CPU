`include "lib/defines.vh"
module ic(
    input wire clk,
    input wire rst,
    input wire [`StallBus] stall,
    input wire flush,
    input wire br_e,

    input wire [`IT_TO_IC_WD-1:0] it_to_ic_bus,

    output reg [`IC_TO_ID_WD-1:0] ic_to_id_bus
);
    wire [`InstAddrBus] pc_pc;
    wire pc_ce;
    wire [31:0] excepttype_i;

    assign {
        excepttype_i,
        pc_ce,
        pc_pc
    } = it_to_ic_bus;

    always @ (posedge clk) begin
        if (rst) begin
            ic_to_id_bus <= `IC_TO_ID_WD'b0;
        end
        else if (flush || br_e) begin
            ic_to_id_bus <= `IC_TO_ID_WD'b0;
        end
        else if (stall[1] == `Stop && stall[2] == `NoStop)begin
            ic_to_id_bus <= `IC_TO_ID_WD'b0;
        end
        else if (stall[1] == `NoStop) begin
            ic_to_id_bus <= it_to_ic_bus;
        end
    end

endmodule 