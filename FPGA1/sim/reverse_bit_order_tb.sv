`default_nettype none

module reverse_bit_order_tb;

    logic clk;
    logic rst;
    logic [7:0] pixel;
    logic stall;

    logic axiov;
    logic [1:0] axiod;
    logic [23:0] pixel_addr;

    logic change_pixel;

    reverse_bit_order reverse_bit_order (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .stall(stall),
    .axiov(axiov), 
    .axiod(axiod),
    .pixel_addr(pixel_addr)
    );

    always begin
    #10;
    clk = !clk;
    end

    initial begin
        $dumpfile("obj/reverse_bit_order.vcd");
        $dumpvars(0, reverse_bit_order_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10
        
        //Test 1: sending two pixels with no audio
        // Ignoring 2-cycle BRAM lag, manually clocking that in for now
        stall = 0;
        // sending 11 for address for error detection
        $display("pixel_adder     axiod");
        for (int i = 0; i < 12; i = i + 1) begin
            pixel = 8'b11111111;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end
        //sending pixel 1 10 pattern
        for (int i = 0; i < 4; i = i + 1) begin
            pixel = 8'b11100100;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end
        //sending pixel 2 01 pattern
        for (int i = 0; i < 4; i = i + 1) begin
            pixel = 8'b11100100;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end
        stall = 1;
        #20;
        for (int i = 0; i < 12; i = i + 1) begin
            pixel = 8'b11111111;
            #20;
        end

        //Test 2: Sending second packet, making sure we pick up from where we left off
        stall = 0;
        // sending 11 for address for error detection
        $display("pixel_adder     axiod");
        for (int i = 0; i < 12; i = i + 1) begin
            pixel = 8'b11111111;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end
        //sending pixel 1
        for (int i = 0; i < 4; i = i + 1) begin
            pixel = 8'b11100100;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end
        //sending pixel 2
        for (int i = 0; i < 4; i = i + 1) begin
            pixel = 8'b11100100;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end
        //sending pixel 3 & 4
        for (int i = 0; i < 8; i = i + 1) begin
            pixel = 8'b11100100;
            #20;
            $display("%b            %2b", pixel_addr[3:0], axiod);
        end

        stall = 1;
        #20;
        for (int i = 0; i < 12; i = i + 1) begin
            pixel = 8'b11111111;
            #20;
        end

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire