`timescale 1ns / 1ps
`default_nettype none

module compare (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in, //all valid points to be added --> this comes from the mask
                         input wire tabulate_in, //to trigger final calculation of average (when frame is over)
                         output logic [10:0] x_com,
                         output logic [9:0] y_com,
                         output logic valid_com);


endmodule

`default_nettype wire
