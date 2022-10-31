`default_nettype none

module top_level(
    input wire clk, //clock @ 100 mhz
    input wire btnc, //btnc (used for reset)
    );

    //system reset switch linking
    logic sys_rst; //global system reset
    assign sys_rst = btnc; //just done to make sys_rst more obvious
    assign eth_rstn = ~btnc;

    divider clk_gen(
        .clk(clk),
        .ethclk(eth_refclk));

endmodule

`timescale 1ns / 1ps
`default_nettype wire