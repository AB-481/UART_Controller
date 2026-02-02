`timescale 1ns / 1ps

module uart_tb_oversampled;

    reg clk;
    reg rst;

    always #5 clk = ~clk;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_line;
    wire tx_busy;
    wire [7:0] rx_data;
    wire rx_done;
    wire parity_error;
    
    wire baud_tick;
    wire os_tick;

    baud_generator #(
        .CLK_FREQ(100_000_000),
        .BAUD(1_000_000)
    ) baud_tx (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick)
    );

    baud_generator #(
        .CLK_FREQ(100_000_000),
        .BAUD(1_000_000*16)
    ) baud_rx (
        .clk(clk),
        .rst(rst),
        .baud_tick(os_tick)
    );

    uart_tx #(
        .PARITY_EN(1)
    ) tx_inst (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx_line(tx_line),
        .tx_busy(tx_busy)
    );

    reg inject_error;
    wire rx_line;

    assign rx_line = inject_error ? ~tx_line : tx_line;

    uart_rx_oversampled #(
        .PARITY_EN(1)
    ) rx_inst (
        .clk(clk),
        .rst(rst),
        .os_tick(os_tick),
        .rx_line(rx_line),
        .rx_data(rx_data),
        .rx_done(rx_done),
        .parity_error(parity_error)
    );

    wire [7:0] rx_fifo_data;
    wire rx_fifo_empty;
    wire rx_fifo_full;
    reg rx_fifo_rd_en;

    uart_rx_fifo rx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(rx_done),
        .wr_data(rx_data),
        .rd_en(rx_fifo_rd_en),
        .rd_data(rx_fifo_data),
        .fifo_empty(rx_fifo_empty),
        .fifo_full(rx_fifo_full)
    );

    reg tx_fifo_wr_en;
    reg [7:0] tx_fifo_wr_data;
    wire [7:0] tx_fifo_data;
    wire tx_fifo_empty;
    wire tx_fifo_full;
    reg tx_fifo_rd_en;

    uart_rx_fifo tx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(tx_fifo_wr_en),
        .wr_data(tx_fifo_wr_data),
        .rd_en(tx_fifo_rd_en),
        .rd_data(tx_fifo_data),
        .fifo_empty(tx_fifo_empty),
        .fifo_full(tx_fifo_full)
    );

    always @(posedge clk) begin
        tx_start <= 0;
        tx_fifo_rd_en <= 0;

        if (!tx_fifo_empty && !tx_busy) begin
            tx_fifo_rd_en <= 1;
            tx_start <= 1;
            tx_data <= tx_fifo_data;
        end
    end


    always @(posedge clk) begin
        rx_fifo_rd_en <= !rx_fifo_empty;

        if (rx_fifo_rd_en && !rx_fifo_empty)
            $display("[%0t ns] RX FIFO DATA = %h",
                     $time, rx_fifo_data);
    end

    initial begin
        clk = 0;
        rst = 1;
        inject_error = 0;

        tx_fifo_wr_en = 0;
        tx_fifo_wr_data = 0;

        #100;
        rst = 0;

        // ---------------------------------------------
        // TEST 1: Normal transmission
        // ---------------------------------------------
        #200;
        tx_fifo_wr_data = 8'hA5;
        tx_fifo_wr_en = 1;
        #10 tx_fifo_wr_en = 0;

        #200;
        tx_fifo_wr_data = 8'h3C;
        tx_fifo_wr_en = 1;
        #10 tx_fifo_wr_en = 0;

        // ---------------------------------------------
        // TEST 2: Parity error injection
        // ---------------------------------------------
        #2000;
        inject_error = 1;

        tx_fifo_wr_data = 8'hF0;
        tx_fifo_wr_en = 1;
        #10 tx_fifo_wr_en = 0;

        #2000;
        inject_error = 0;

        #20000;
        $finish;
    end

endmodule
