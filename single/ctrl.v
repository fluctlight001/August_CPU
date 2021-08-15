`include "lib/defines.vh"
module ctrl (
    input wire rst,
    input wire stallreq_for_ex,
    input wire stallreq_for_load,
    input wire stallreq_from_icache,
    input wire stallreq_from_dcache,
    input wire stallreq_from_uncache,

    input wire [31:0] excepttype_i,
    input wire [`RegBus] cp0_epc_i,
    input wire [31:0] current_pc,
    
    output reg flush,
    output reg [`RegBus] new_pc,
    output reg [`StallBus] stall
);
    always @ (*) begin
        if (rst) begin
           stall <=  10'b0;
           flush <= `False_v;
           new_pc <= `ZeroWord;
        end
        else if (excepttype_i != `ZeroWord) begin
            stall <= 10'b0;
            flush <= `True_v;
            new_pc <= `ZeroWord;
            case (excepttype_i)
                32'h00000001:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h00000004:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h00000005:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h00000008:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h00000009:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h0000000a:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h0000000d:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h0000000c:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h0000000e:begin
                    new_pc <= cp0_epc_i;
                end
                32'h00000011:begin
                    new_pc <= 32'hbfc00200;
                end
                32'h00000012:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h00000013:begin
                    new_pc <= 32'hbfc00200;
                end
                32'h00000014:begin
                    new_pc <= 32'hbfc00380;
                end
                32'h00000015:begin
                    new_pc <= 32'hbfc00380;
                end
                32'hffffffff:begin
                    new_pc <= current_pc + 32'h4;
                end
                default:begin
                    new_pc <= 32'b0;
                end
            endcase
        end
        else if (stallreq_from_icache|stallreq_from_dcache|stallreq_from_uncache) begin
            stall <= 10'b0111111111;
            flush <= `False_v;
            new_pc <= `ZeroWord;
        end
        else if (stallreq_for_ex) begin
            stall <= 10'b0000011111;
            flush <= `False_v;
            new_pc <= `ZeroWord;
        end
        else if(stallreq_for_load) begin
            stall <= 10'b0000001111;
            flush <= `False_v;
            new_pc <= `ZeroWord;
        end
        else begin
            stall <= 10'b0;
            flush <= 1'b0;
            new_pc <= 32'b0;
        end
    end
    
endmodule