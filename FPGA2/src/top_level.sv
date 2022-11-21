`default_nettype none

module top_level(
    input wire clk, //clock @ 100 mhz
    input wire btnc, //btnc (used for reset)
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,

    output logic [15:0] led, // note: 7 seg for testing visualization, remove later
    output logic ca, cb, cc, cd, ce, cf, cg,
    output logic [7:0] an

    output logic eth_rstn,
    output logic eth_refclk,
    );

    //system reset switch linking
    logic sys_rst; //global system reset
    assign sys_rst = btnc; //just done to make sys_rst more obvious
    assign eth_rstn = ~btnc;

    /// Module Instianation ///
    // Generating 50 mhz ethernet clk and 65 mhz camera clk
    ethernet_clk_wiz eth_clk_gen(
        .clk(clk),
        .ethclk(eth_refclk));

    logic clk_65mhz;
    camera_clk_wiz camera_clk_gen(
        .clk(clk_100mhz),
        .clk_out1(clk_65mhz)
    );

    logic ether_axiov;
    logic [1:0] ether_axiod;

    ether ether (
    .clk(eth_refclk),
    .rst(sys_rst),
    .rxd(eth_rxd),
    .crsdv(eth_crsdv),
    .axiov(ether_axiov),
    .axiod(ether_axiod)
    );

    logic bitorder_axiov;
    logic [1:0] bitorder_axiod;
    bitorder bitorder (
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiiv(ether_axiov),
    .axiid(ether_axiod),
    .axiov(bitorder_axiov), 
    .axiod(bitorder_axiod)
    );

    logic firewall_axiov;
    logic [1:0] firewall_axiod;
    firewall firewall (
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiid(bitorder_axiod),
    .axiiv(bitorder_axiov),
    .axiov(firewall_axiov), 
    .axiod(firewall_axiod)
    );

    logic done;
    cksum cksum (
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiid(ether_axiod),
    .axiiv(ether_axiov),
    .done(done), //compiled incoming data
    .kill(led[15]) //high if crc32 calculation fails
    );
    assign led[14] = done;

    

    //FRAME BUFFER FOR IMAGE + WRITING
    //Two Clock Frame Buffer:
    //Data written on 50Hz (From ethernet)
    //Data read on 65 MHz (start of video pipeline information)
    //Latency is 2 cycles.
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(320*240))
        frame_buffer (
        //Write Side (50MHz)
        .addra(pixel_addr_in),
        .clka(clk_65mhz),
        .wea(valid_pixel_rotate),
        .dina(pixel_rotate),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(sys_rst),
        .douta(),
        //Read Side (65 MHz)
        .addrb(pixel_addr_out),
        .dinb(16'b0),
        .clkb(clk_65mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(frame_buff)
    );

    //note: keep for testing so we can see what we are sent
    logic [31:0] seven_segment_controller_val_in;
    seven_segment_controller seven_segment_controller (
        .clk_in(eth_refclk),
        .rst_in(sys_rst),
        .val_in(seven_segment_controller_val_in),
        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
        .an_out(an)
    );

    logic old_firewall_axiov;
    always_ff @(posedge eth_refclk) begin
        if (sys_rst) begin
            led[13:0] <= 0;
            seven_segment_controller_val_in = 0;

        end else if (firewall_axiov & !old_firewall_axiov) begin
            led[13:0] <= led[13:0] + 1;
        end

        if (aggregate_axiov) begin
            seven_segment_controller_val_in <= aggregate_axiod;
        end

        old_firewall_axiov <= firewall_axiov;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire