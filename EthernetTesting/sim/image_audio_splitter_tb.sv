`default_nettype none

module image_audio_splitter_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;

    logic ias_addr_axiov;
    logic ias_pixel_axiov;
    logic ias_audio_axiov;

    logic [23:0] ias_addr_out;
    logic [7:0] ias_pixel_out;
    logic [7:0] ias_audio_out;

    logic [7:0] pixel, audio;
    logic stall;

    logic rbo_axiov;
    logic [1:0] rbo_axiod;
    logic [23:0] rbo_pixel_addr;

    logic phy_txen;
    logic [1:0] phy_txd;

    reverse_bit_order reverse_bit_order (
    .clk(clk),
    .rst(rst),
    .pixel(pixel),
    .audio(audio),
    .stall(stall),
    .axiov(rbo_axiov), 
    .axiod(rbo_axiod),
    .pixel_addr(rbo_pixel_addr)
    );

    eth_packer eth_packer (
    .cancelled(1'b0),
    .clk(clk),
    .rst(rst),
    .axiiv(rbo_axiov),
    .axiid(rbo_axiod),
    .stall(stall),
    .phy_txen(phy_txen),
    .phy_txd(phy_txd)
    );

    logic ether_axiov;
    logic [1:0] ether_axiod;
    ether uut (
        .clk(clk),
        .rst(rst),
        .rxd(phy_txd),
        .crsdv(phy_txen),
        .axiov(ether_axiov),
        .axiod(ether_axiod)
        );

    logic bitorder_axiov;
    logic [1:0] bitorder_axiod;
    bitorder bitorder (
        .clk(clk),
        .rst(rst),
        .axiiv(ether_axiov),
        .axiid(ether_axiod),
        .axiov(bitorder_axiov), 
        .axiod(bitorder_axiod)
    );

    logic kill, done;

    cksum cksum (
    .clk(clk),
    .rst(rst),
    .axiiv(ether_axiov),
    .axiid({ether_axiod}),
    .done(done), 
    .kill(kill)
    );

    logic firewall_axiov;
    logic [1:0] firewall_axiod;
    firewall firewall (
    .clk(clk),
    .rst(rst),
    .axiid(bitorder_axiod),
    .axiiv(bitorder_axiov),
    .axiov(firewall_axiov), 
    .axiod(firewall_axiod)
    );

    image_audio_splitter image_audio_splitter (
    .clk(clk),
    .rst(rst),
    .axiiv(firewall_axiov),
    .axiid(firewall_axiod),

    .addr_axiov(ias_addr_axiov),
    .pixel_axiov(ias_pixel_axiov),
    .audio_axiov(ias_audio_axiov),

    .addr(ias_addr_out),
    .pixel(ias_pixel_out),
    .audio(ias_audio_out)
    );

    logic fp_pixel_wea;
    logic [16:0] fp_addr_axiod;
    logic [7:0] fp_written_pixel;

    frame_packager fp(
    .clk(clk),
    .rst(rst),
    .addr_axiiv(ias_addr_axiov),
    .addr_axiid(ias_addr_out),
    .pixel_axiiv(ias_pixel_axiov),
    .pixel_axiid(ias_pixel_out),

    .axiov(fp_pixel_wea), //for wea on BRAM
    .addr_axiod(fp_addr_axiod),
    .pixel_axiod(fp_written_pixel)
    );

    always begin
        #10;
        clk = !clk;
    end

    logic [23:0] old_rbo_pixel_addr;
    logic [2:0] pixel_counter;

    initial begin
        $dumpfile("obj/image_audio_splitter.vcd");
        $dumpvars(0, image_audio_splitter_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10

        pixel = 8'b10101010;
        audio = 8'b11111111;
        for (int i = 0; i < 6000; i = i + 1) begin
            #20;
            if (old_rbo_pixel_addr != rbo_pixel_addr) begin
                if (pixel_counter < 3) pixel_counter <= pixel_counter + 1;
                else pixel_counter <= 0;

                case (pixel_counter) 
                3'b001: pixel = 8'b11000000;
                default: pixel = 8'b10101010;
                endcase
            end
            old_rbo_pixel_addr <= rbo_pixel_addr;
        end

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire