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
        .ethclk(eth_refclk));

    logic clk_65mhz;
    camera_clk_wiz camera_clk_gen(
        .clk(clk_100mhz),
        .clk_out1(clk_65mhz)
    );

    

endmodule

`timescale 1ns / 1ps
`default_nettype wire