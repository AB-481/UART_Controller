`timescale 1ns / 1ps
module uart_rx_fifo (
    input wire clk,
    input wire rst,

    input wire wr_en,
    input wire [7:0] wr_data,

    input wire rd_en,
    output reg [7:0] rd_data,

    output wire fifo_empty,
    output wire fifo_full
);

    reg [7:0] mem [0:3];
    reg [1:0] wptr, rptr;
    reg [2:0] count;

    assign fifo_empty = (count == 0);
    assign fifo_full = (count == 4);

    always @(posedge clk) begin
        if (rst) begin
            wptr <= 0;
            rptr <= 0;
            count <= 0;
            rd_data <= 0;
        end
        else begin
            if (wr_en && !fifo_full) begin
                mem[wptr] <= wr_data;
                wptr <= wptr + 1;
                count <= count + 1;
            end
            
            if (rd_en && !fifo_empty) begin
                rd_data <= mem[rptr];
                rptr <= rptr + 1;
                count <= count - 1;
            end
        end
    end

endmodule
