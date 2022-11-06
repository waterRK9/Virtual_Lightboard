`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module image_sprite #(
  parameter WIDTH=256, HEIGHT=256) (
  input wire pixel_clk_in,
  input wire rst_in,
  input wire [10:0] x_in, hcount_in,
  input wire [9:0]  y_in, vcount_in,
  output logic [11:0] pixel_out);

  logic [10:0] hcount_pipe [3:0];
  logic [9:0] vcount_pipe [3:0];

  always_ff @(posedge pixel_clk_in)begin
    hcount_pipe[0] <= hcount_in;
    vcount_pipe[0] <= vcount_in;
    for (int i=1; i<4; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
    end
  end

  // calculate rom address
  logic [$clog2(WIDTH*HEIGHT)-1:0] image_addr;
  assign image_addr = (hcount_in - x_in) + ((vcount_in - y_in) * WIDTH);

  logic in_sprite;
  assign in_sprite = ((hcount_pipe[3] >= x_in && hcount_pipe[3] < (x_in + WIDTH)) &&
                      (vcount_pipe[3] >= y_in && vcount_pipe[3] < (y_in + HEIGHT)));

  // logic in_sprite;
  // assign in_sprite = ((hcount_in >= x_in && hcount_in < (x_in + WIDTH)) &&
  //                     (vcount_in >= y_in && vcount_in < (y_in + HEIGHT)));

  
  logic [7:0] palette_loc;
  logic [7:0] palette_loc_b;
  logic [11:0] pixel_color;
  logic [11:0] pixel_color_b;

  //  Xilinx True Dual Port RAM, Read First, Dual Clock
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(image.mem))                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) popcat_image (
    .addra(image_addr),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(image_addr),   // Port B address bus, width determined from RAM_DEPTH
    .dina(8'b0),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(8'b0),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),     // Port A clock
    .clkb(pixel_clk_in),     // Port B clock
    .wea(1'b0),       // Port A write enable
    .web(1'b0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(palette_loc),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(palette_loc_b)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(12),                       // Specify RAM data width
    .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(palette.mem))                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) popcat_palette (
    .addra(palette_loc),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(palette_loc),   // Port B address bus, width determined from RAM_DEPTH
    .dina(8'b0),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(8'b0),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(pixel_clk_in),     // Port A clock
    .clkb(pixel_clk_in),     // Port B clock
    .wea(1'b0),       // Port A write enable
    .web(1'b0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(pixel_color),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(pixel_color_b)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  // //  Xilinx Single Port Read First RAM
  // xilinx_single_port_ram_read_first #(
  //   .RAM_WIDTH(8),                       // Specify RAM data width
  //   .RAM_DEPTH(65536),                     // Specify RAM depth (number of entries)
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  //   .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  // ) popcat_image (
  //   .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
  //   .dina(8'b0),       // RAM input data, width determined from RAM_WIDTH
  //   .clka(pixel_clk_in),       // Clock
  //   .wea(1'b0),         // Write enable
  //   .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
  //   .rsta(rst_in),       // Output reset (does not affect memory contents)
  //   .regcea(1'b1),   // Output register enable
  //   .douta(palette_loc)      // RAM output data, width determined from RAM_WIDTH
  // );

  // //  Xilinx Single Port Read First RAM
  // xilinx_single_port_ram_read_first #(
  //   .RAM_WIDTH(12),                       // Specify RAM data width
  //   .RAM_DEPTH(256),                     // Specify RAM depth (number of entries)
  //   .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  //   .INIT_FILE(`FPATH(palette.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  // ) popcat_palette (
  //   .addra(palette_loc),     // Address bus, width determined from RAM_DEPTH
  //   .dina(12'b0),       // RAM input data, width determined from RAM_WIDTH
  //   .clka(pixel_clk_in),       // Clock
  //   .wea(1'b0),         // Write enable
  //   .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
  //   .rsta(rst_in),       // Output reset (does not affect memory contents)
  //   .regcea(1'b1),   // Output register enable
  //   .douta(pixel_color)      // RAM output data, width determined from RAM_WIDTH
  // );

  // Modify the line below to use your BRAMs!
  assign pixel_out = in_sprite ? pixel_color : 0;

endmodule

`default_nettype none
