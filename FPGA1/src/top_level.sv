`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camera
  output logic jblock, //signal for resetting camera

  output logic [15:0] led, //just here for the funs

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,
  output logic [7:0] an,
  output logic caa,cab,cac,cad,cae,caf,cag,

  output logic eth_txen,
  output logic eth_txd,
  output logic eth_refclk,
  output logic eth_rstn
  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign led = sw; //switches drive LED (change if you want)

  //FINAL PROJECT VARS
  //Clock modules output
  logic clk_50mhz; //50 MHz ethernet clocks

  //FINAL PROJECT MODULES
  //CLOCKS: 
  //Ethernet Clock
  ethernet_clk_wiz clk_50mhz_gen(
    .clk(clk_100mhz),
    .ethclk(eth_refclk)
  );
  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.

  //Ethernet module 
  logic flip;
  logic [7:0] pixel;

  always_ff @(posedge clk_50mhz) begin
    flip <= !flip;
    if (flip) pixel <= 8'b11111111;
    else pixel <= 8'b0;
  end

  logic stall;
  logic rbo_axiov;
  logic rbo_axiod;
  logic rbo_pixel_addr;

  //ETHERNET COMPONENTS:
  reverse_bit_order bit_order_reverser(
    .clk(clk_50mhz),
    .rst(sys_rst),
    .pixel(pixel),
    .stall(stall), //TODO: make this the correct value for stall logic
    .axiov(rbo_axiov), //TODO: fill this in
    .axiod(rbo_axiod), //TODO: fill this in
    .pixel_addr(rbo_pixel_addr) //TODO: fill this in
  );
  eth_packer packer(
    .clk(clk_50mhz),
    .rst(sys_rst),
    .axiiv(rbo_axiov), //TODO: fill this in
    .axiid(rbo_axiod), //TODO: fill this in
    .stall(stall), //TODO: fill this in
    .phy_txen(eth_txen), //TODO: fill this in
    .phy_txd(eth_txd) //TODO: fill this in
  );


endmodule




`default_nettype wire
