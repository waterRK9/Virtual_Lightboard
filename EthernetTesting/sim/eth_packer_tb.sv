`default_nettype none

module eth_packer_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;
    logic stall, phy_txen;
    logic [1:0] phy_txd;

    eth_packer eth_packer (
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),
    .stall(stall),
    .phy_txen(phy_txen),
    .phy_txd(phy_txd)
    );

    always begin
    #10;
    clk = !clk;
    end

    logic [31:0] cksum1 = 32'h1a3a_ccb2;
    logic [167:0] message1 = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;


    initial begin
        $dumpfile("obj/eth_packer.vcd");
        $dumpvars(0, eth_packer_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10
        
        //Test 1: Send header(56) + data(1280) + tail (16)
        $display("cycle  txen  txd");
        $display("Idle");
        for (int i = 0; i < 47; i = i + 1) begin
            axiiv = 1;
            axiid = 2'b00;
            #20;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        $display("Preamble");
        for (int i = 0; i < 31; i = i + 1) begin
            axiiv = 1;
            axiid = 2'b01;
            #20;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        axiiv = 1;
        axiid = 2'b11;
        #20;
        $display("Dest Addr");
        for (int i = 0; i < 24; i = i + 1) begin
            axiiv = 1;
            axiid = 2'b11;
            #20;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        $display("Source Addr");
        for (int i = 0; i < 24; i = i + 1) begin
            axiiv = 1;
            axiid = 2'b10;
            #20;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        $display("Len");
        for (int i = 0; i < 8; i = i + 1) begin
            axiiv = 1;
            axiid = 2'b01;
            #20;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        $display("Data");
        for (int i = 0; i < 20; i = i + 1) begin //1280
            axiiv = 1;
            axiid = 2'b11;
            #20;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
        end
        $display("CRC32");
        for (int i = 0; i < 16; i = i + 1) begin
            axiiv = 0;
            axiid = 2'b10;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
            #20;
        end
        $display("Idle");
        for (int i = 0; i < 16; i = i + 1) begin
            axiiv = 0;
            axiid = 2'b00;
            $display("%d     %1b       %2b", i[10:0], phy_txen, phy_txd);
            #20;
        end
        #20;

        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire