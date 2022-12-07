`timescale 1ns / 1ps
`default_nettype none

module mirror2(
  input wire clk_in,
  input wire mirror_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  output logic [16:0] pixel_addr_out);
  
  logic [10:0] hcount_temp;
  logic [9:0] vcount_temp;

  always_ff @(posedge clk_in) begin
    // // scale up by 2
    // hcount_temp <= hcount_in >> 1;
    // vcount_temp <= vcount_in >> 1;
    // pixel_addr_out <= 320*vcount_temp + (320-hcount_temp);
    // scale up to full size of screen
    hcount_temp <= (hcount_in>>4) + (hcount_in>>2);
    vcount_temp <= (vcount_in>>4) + (vcount_in>>2);
    pixel_addr_out <= (320*vcount_temp) + (320-hcount_temp);
    // hcount_temp <= mirror_in?(1024-hcount_in):hcount_in;
    // pixel_addr_out <= (hcount_temp>>4 + hcount_temp>>2) + 320*(vcount_pip>>4 + vcount_pip>>2);
    // pixel_addr_out <= hcount_temp + 320*vcount_pip;
  end

endmodule

`default_nettype wire
