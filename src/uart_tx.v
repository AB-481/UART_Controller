`timescale 1ns / 1ps
module uart_tx #(
    parameter PARITY_EN = 1
)(
    input wire clk,
    input wire rst,
    input wire baud_tick,

    input wire tx_start,
    input wire [7:0] tx_data,

    output reg tx_line,
    output reg tx_busy
);

    localparam IDLE = 3'd0,
               START = 3'd1,
               DATA = 3'd2,
               PARITY = 3'd3,
               STOP = 3'd4;

    reg [2:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg parity_bit;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_line <= 1'b1;
            tx_busy <= 1'b0;
            bit_cnt <= 0;
            shift_reg <= 0;
            parity_bit <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    tx_line <= 1'b1;
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        parity_bit <= ^tx_data;
                        bit_cnt <= 0;
                        tx_busy <= 1'b1;
                        state <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        tx_line <= 1'b0;
                        state <= DATA;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        tx_line <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        bit_cnt <= bit_cnt + 1;

                        if (bit_cnt == 3'd7) begin
                            if (PARITY_EN)
                                state <= PARITY;
                            else
                                state <= STOP;
                        end
                    end
                end

                PARITY: begin
                    if (baud_tick) begin
                        tx_line <= parity_bit;
                        state <= STOP;
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        tx_line <= 1'b1;
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
