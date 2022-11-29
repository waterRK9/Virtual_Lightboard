`default_nettype none
// iverilog -g2012 -o obj/rbo_ethpack_tb.out src/reverse_bit_order.sv src/eth_packer.sv  sim/rbo_ethpack_tb.sv

module rbo_ethpack_tb;

    logic clk;
    logic rst;
    logic [7:0] pixel;
    logic stall;

    logic rbo_axiov;
    logic [1:0] rbo_axiod;
    logic [23:0] pixel_addr;

    logic phy_txen;
    logic [1:0] phy_txd;

    reverse_bit_order reverse_bit_order (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .stall(stall),
    .axiov(rbo_axiov), 
    .axiod(rbo_axiod),
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
        $dumpvars(0, rbo_ethpack_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        pixel = 8'b11111111;
        #10
        
        //Test 1: Send header(56) + data(1280) + tail (16)
        // $display("cycle  txen  txd");
        // $display("Idle");
        for (int i = 0; i < 1000; i = i + 1) begin
            if (!stall) begin
                pixel = 8'b11111111;
                
            end
            #20;
            // $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire