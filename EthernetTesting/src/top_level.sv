`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk, //clock @ 100 mhz
  input wire btnc, //btnc (used for reset)
  input wire btnr, // btnr (used for sending a packet)
  input wire eth_crsdv,

  output logic [15:0] led, //just here for the funs
  output logic ca, cb, cc, cd, ce, cf, cg,
  output logic [7:0] an,

  output logic eth_txen,
  output logic [1:0] eth_txd,
  output logic eth_refclk,
  output logic eth_rstn
  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign eth_rstn = ~sys_rst;
  // assign led = sw; //switches drive LED (change if you want)

  //FINAL PROJECT VARS
  //Clock modules output

  //FINAL PROJECT MODULES
  //CLOCKS: 
  //Ethernet Clock
  ethernet_clk_wiz clk_50mhz_gen(
    .clk(clk),
    .ethclk(eth_refclk)
  );
  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.

  //Ethernet module 
  logic old_txen;
  logic flip;
  logic [24:0] counter;
  logic [7:0] pixel;

  
  always_ff @(posedge eth_refclk) begin

      pixel <= 8'b11111111;
      if (btnr) begin
        flip <= 0;
      end else if (old_txen == 1 && eth_txen == 0) begin
        flip <= 1;
      end
      old_txen <= eth_txen;
  end

  logic stall;
  logic rbo_axiov;
  logic [1:0] rbo_axiod;
  logic [23:0] rbo_pixel_addr;

  //ETHERNET COMPONENTS:
  reverse_bit_order bit_order_reverser(
    .clk(eth_refclk),
    .rst(sys_rst),
    .pixel(pixel),
    .stall(stall), //TODO: make this the correct value for stall logic
    .axiov(rbo_axiov), //TODO: fill this in
    .axiod(rbo_axiod), //TODO: fill this in
    .pixel_addr(rbo_pixel_addr) //TODO: fill this in
  );

  eth_packer packer(
    .cancelled(flip),
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiiv(rbo_axiov), //TODO: fill this in
    .axiid(rbo_axiod), //TODO: fill this in
    .stall(stall), //TODO: fill this in
    .phy_txen(eth_txen), //TODO: fill this in
    .phy_txd(eth_txd) //TODO: fill this in
  );

  logic [31:0] aggregate_axiod;
    logic aggregate_axiov;
    aggregate aggregate (
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiiv(eth_txen),
    .axiid(eth_txd),
    .axiov(aggregate_axiov),
    .axiod(aggregate_axiod)
    );

    logic [31:0] seven_segment_controller_val_in;
    seven_segment_controller seven_segment_controller (
        .clk_in(eth_refclk),
        .rst_in(sys_rst),
        .val_in(seven_segment_controller_val_in),
        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
        .an_out(an)
    );

    logic old_rbo_axiov;

    always_ff @(posedge eth_refclk) begin
        if (sys_rst) begin
            led[13:0] <= 0;
            seven_segment_controller_val_in = 0;

        end else if (rbo_axiov & !old_rbo_axiov) begin
            led[13:0] <= led[13:0] + 1;
        end

        if (aggregate_axiov) begin
            seven_segment_controller_val_in <= aggregate_axiod;
        end

        old_rbo_axiov <= rbo_axiov;

        led[15] <= stall;
    end

endmodule




`default_nettype wire
