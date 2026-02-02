`timescale 1ns / 1ps
module uart_rx_oversampled #(
    parameter PARITY_EN = 1
)(
    input wire clk,
    input wire rst,
    input wire os_tick,
    input wire rx_line,

    output reg [7:0] rx_data,
    output reg rx_done,
    output reg parity_error
);

    localparam IDLE = 3'd0,
               START = 3'd1,
               DATA = 3'd2,
               PARITY = 3'd3,
               STOP = 3'd4;

    reg [2:0] state;
    reg [3:0] os_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            os_cnt <= 0;
            bit_cnt <= 0;
            shift_reg <= 0;
            rx_data <= 0;
            rx_done <= 0;
            parity_error <= 0;
        end
        else begin
            rx_done <= 0;

            if (os_tick) begin
                case (state)

                    IDLE: begin
                        parity_error <= 0;
                        if (rx_line == 0) begin
                            os_cnt <= 0;
                            state <= START;
                        end
                    end

                    START: begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd7) begin
                            if (rx_line == 0) begin
                                os_cnt <= 0;
                                bit_cnt <= 0;
                                state <= DATA;
                            end
                            else begin
                                state <= IDLE;
                            end
                        end
                    end

                    DATA: begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            shift_reg <= {rx_line, shift_reg[7:1]};
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
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            if ((^shift_reg) != rx_line)
                                parity_error <= 1;
                            state <= STOP;
                        end
                    end

                    STOP: begin
                        os_cnt <= os_cnt + 1;
                        if (os_cnt == 4'd15) begin
                            os_cnt <= 0;
                            if (rx_line == 1) begin
                                rx_data <= shift_reg;
                                rx_done <= 1;
                            end
                            state <= IDLE;
                        end
                    end

                endcase
            end
        end
    end

endmodule
