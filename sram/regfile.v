`include "lib/defines.vh"
module regfile(
    input wire clk,
    input wire [4:0] raddr1,
    output wire [31:0] rdata1,
    input wire [4:0] raddr2,
    output wire [31:0] rdata2,
    input wire [4:0] raddr3,
    output wire [31:0] rdata3,
    input wire [4:0] raddr4,
    output wire [31:0] rdata4,
    
    input wire we,
    input wire [4:0] waddr,
    input wire [31:0] wdata
);
    reg [31:0] reg_array [31:0];
    // write
    always @ (posedge clk) begin
        if (we && waddr!=5'b0) begin
            reg_array[waddr] <= wdata;
        end
    end

    // read out 1
    assign rdata1 = (raddr1 == 5'b0) ? 32'b0 : reg_array[raddr1];

    // read out 2
    assign rdata2 = (raddr2 == 5'b0) ? 32'b0 : reg_array[raddr2];

    // read out 3
    assign rdata3 = (raddr3 == 5'b0) ? 32'b0 : reg_array[raddr3];

    // read out 4
    assign rdata4 = (raddr4 == 5'b0) ? 32'b0 : reg_array[raddr4];
endmodule