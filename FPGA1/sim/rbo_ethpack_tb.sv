`default_nettype none

module rbo_ethpack_tb;

    logic clk;
    logic rst;
    logic [7:0] pixel;
    logic stall;

    logic rbo_axiov;
    logic [1:0] rbo_axiod;
    logic [23:0] pixel_addr;

    logic stall, phy_txen;
    logic [1:0] phy_txd;

    reverse_bit_order reverse_bit_order (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .stall(stall),
    .axiov(axiov), 
    .axiod(axiod),
    .pixel_addr(pixel_addr)
    );

    eth_packer eth_packer (
    .clk(clk),
    .rst(rst),
    .axiiv(rbo_axiov),
    .axiid(rbo_axiod),
    .stall(stall),
    .phy_txen(phy_txen),
    .phy_txd(phy_txd)
    );

    always begin
    #10;
    clk = !clk;
    end

    initial begin
        $dumpfile("obj/rbo_ethpack_tb.vcd");
        $dumpvars(0, rbo_ethpack_tb_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10
        
        //Test 1: Feeding in 2 pixels from "BRAM"
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

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire