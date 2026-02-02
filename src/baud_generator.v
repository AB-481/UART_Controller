`timescale 1ns / 1ps
module baud_generator #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD = 115200*16
)
(
    input  wire clk,
    input  wire rst,
    output reg  baud_tick
);

    localparam integer BAUD_DIV = CLK_FREQ/BAUD;
    integer count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            baud_tick <= 0;
        end
        else begin
            if (count == BAUD_DIV - 1) begin
                count <= 0;
                baud_tick <= 1;
            end
            else begin
                count <= count + 1;
                baud_tick <= 0;
            end
        end
    end

endmodule
