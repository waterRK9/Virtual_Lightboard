`default_nettype none

module top_level(
    input wire clk, //clock @ 100 mhz
    input wire btnc, //btnc (used for reset)
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,

    output logic eth_rstn,
    output logic eth_refclk,
    output logic eth_txen,
    output logic [1:0] eth_txd
    );

    //system reset switch linking
    logic sys_rst; //global system reset
    assign sys_rst = btnc; //just done to make sys_rst more obvious
    assign eth_rstn = ~btnc;

    // Generating 50 mhz ethernet clk and 65 mhz camera clk
    ethernet_clk_wiz eth_clk_gen(
        .clk(clk),
        .ethclk(eth_refclk)
    );

    logic clk_65mhz;
    camera_clk_wiz camera_clk_gen(
        .clk(clk_100mhz),
        .clk_out1(clk_65mhz)
    );

    //Two Clock Frame Buffer:
    //Data written on 16.67 MHz (From camera)
    //Data read on 65 MHz (start of video pipeline information)
    //Latency is 2 cycles.
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(16),
        .RAM_DEPTH(320*240))
        frame_buffer (
        //Write Side (16.67MHz)
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

    

endmodule

`timescale 1ns / 1ps
`default_nettype wire