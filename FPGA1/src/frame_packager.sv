`default_nettype none
`timescale 1ns / 1ps

module frame_packager(
    input wire clk,
    input wire rst,
    input wire addr_axiov,
    input wire [23:0] addr_axiid,
    input wire pixel_axiiv,
    input wire [7:0] pixel_axiid,

    output logic axiov, //for wea on BRAM
    output logic [23:0] addr_axiod,
    output logic [7:0] pixel_axiod
);

// pass pixel_axiiv right into pixel_axiod
// only increment stored addr value when pixel_axiov high
// don't want to increment addr value for first pixel, either that or subtract one from addr value when we recieve it?
// 

endmodule

`default_nettype wire