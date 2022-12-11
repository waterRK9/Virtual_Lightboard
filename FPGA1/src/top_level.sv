`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz, //clock @ 100 mhz
  input wire [15:0] sw, //switches
  input wire btnc, //btnc (used for reset)
  input wire btnr,

  input wire [7:0] ja, //lower 8 bits of data from camera
  input wire [2:0] jb, //upper three bits from camera (return clock, vsync, hsync)
  output logic jbclk,  //signal we provide to camera
  output logic jblock, //signal for resetting camera

  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs,

  output logic [15:0] led, //just here for the funs

  output logic ca, cb, cc, cd, ce, cf, cg, // 7-seg display
  output logic [7:0] an,

  output logic eth_txen,
  output logic [1:0] eth_txd,
  output logic eth_refclk,
  output logic eth_rstn,
  input wire eth_crsdv
  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign eth_rstn = ~sys_rst;
  // assign led = sw; //switches drive LED (change if you want)

  //FINAL PROJECT VARS
  //Clock modules output
  logic clk_65mhz; //65 MHz clock line
  logic clk_50mhz; //50 MHz ethernet clock

  //Camera module output
  logic cam_clk_buff, cam_clk_in; //returning camera clock
  logic vsync_buff, vsync_in; //vsync signals from camera
  logic href_buff, href_in; //href signals from camera
  logic [7:0] pixel_buff, pixel_in; //pixel lines from camera
  logic [15:0] cam_pixel; //16 bit 565 RGB image from camera
  logic valid_pixel; //indicates valid pixel from camera
  logic frame_done; //indicates completion of frame from camera

  //Recover module output
  logic [15:0] pixel_data_rec; // pixel data from recovery module
  logic [10:0] hcount_rec; //hcount from recovery module
  logic [9:0] vcount_rec; //vcount from recovery module
  logic  data_valid_rec; //single-cycle (65 MHz) valid data from recovery module

  //Filter module output
  logic [10:0] hcount_filtered;  //hcount from filter modules
  logic [9:0] vcount_filtered; //vcount from filter modules
  logic [15:0] pixel_data_filtered; //pixel data from filter modules
  logic data_valid_filtered; //valid signals for filter modules

  //RGB to YCrCb module output 
  logic [9:0] y, cr, Cb; //ycrcb conversion of full pixel

  //Threshold module output:
  logic mask; //Whether or not thresholded pixel is 1 or 0
  logic [3:0] sel_channel; //selected channels four bit information intensity
  //sel_channel could contain any of the six color channels depend on selection

  //Center of Mass module output
  logic [10:0] x_com, x_com_calc; //long term x_com and output from module, resp
  logic [9:0] y_com, y_com_calc; //long term y_com and output from module, resp
  logic new_com; //used to know when to update x_com and y_com ...
  //using x_com_calc and y_com_calc values

  //Compare module output
  logic [7:0] pixel_in_porta_compare;
  logic [7:0] pixel_out_porta_compare;
  logic [16:0] pixel_addr_porta_compare;
  logic pixel_valid_porta_compare;

  //BRAM module input/output
  logic [7:0] pixel_in_porta;
  logic [16:0] pixel_addr_porta;
  logic pixel_valid_porta;
  logic [16:0] pixel_addr_portb;
  logic [7:0] pixel_out_porta;
  logic [7:0] dummy_douta;
  logic [7:0] pixel_out_portb;
  logic [7:0] pixel_out_portb_vga;
  logic vgareadpixel;
  logic vgasndaddr;

  //VGA GEN module output
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic hsync, vsync, blank; //control signals for vga
  logic hsync_t, vsync_t, blank_t; //control signals out of transform

  //Scale module output
  logic [7:0] scaled_pixel_to_display;//mirrored and scaled 565 pixel
  logic [15:0] pixel_out_vga;

  //Mirror module
  logic [16:0] pixel_addr_vga;

  //VGA mux module output
  logic [11:0] mux_pixel;


  //PIPELINING:
  //pipelining vars
  logic [10:0] hcount_pipe [7:0];
  logic [9:0] vcount_pipe [7:0];
  logic blank_pipe [7:0];
  logic hsync_pipe [7:0];
  logic vsync_pipe [7:0];
  logic [15:0] pixel_data_rec_pipe [3:0]; 
  logic [11:0] mux_pixel_pipe;
  logic [10:0] hcount_rec_pipe [3:0];
  logic [9:0] vcount_rec_pipe [3:0];
  logic data_valid_rec_pipe [3:0];

  //Pipelining
  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    vcount_pipe[0] <= vcount;
    blank_pipe[0] <= blank;
    hsync_pipe[0] <= hsync;
    vsync_pipe[0] <= vsync;
    mux_pixel_pipe <= mux_pixel;
    pixel_data_rec_pipe[0] <= pixel_data_rec;
    hcount_rec_pipe[0] <= hcount_rec;
    vcount_rec_pipe[0] <= vcount_rec;
    data_valid_rec_pipe[0] <= data_valid_rec;
    for (int i=1; i<8; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      blank_pipe[i] <= blank_pipe[i-1];
      hsync_pipe[i] <= hsync_pipe[i-1];
      vsync_pipe[i] <= vsync_pipe[i-1];
    end
    for (int j = 1; j<4; j=j+1)begin
      hcount_rec_pipe[j] <= hcount_rec_pipe[j-1];
      vcount_rec_pipe[j] <= vcount_rec_pipe[j-1];
      pixel_data_rec_pipe[j] <= pixel_data_rec_pipe[j-1];
      data_valid_rec_pipe[j] <= data_valid_rec_pipe[j-1];
    end
  end

  //FINAL PROJECT MODULES
  //CLOCKS: 
  //Generate 65 MHz
  // clk_wiz_lab3 clk_65mhz_gen(
  //   .clk_in1(clk_100mhz),
  //   .clk_out1(clk_65mhz)
  // );
  // //Generate Ethernet Clock
  // ethernet_clk_wiz clk_50mhz_gen(
  //   .clk(clk_100mhz),
  //   .ethclk(clk_50mhz)
  // );
  clk_wiz_0_clk_wiz clk_gen(
    .clk_100mhz(clk_100mhz),
    .eth_clk(eth_refclk),
    .vga_clk(clk_65mhz)
  );
  //Clock domain crossing to synchronize the camera's clock
  //to be back on the 65MHz system clock, delayed by a clock cycle.
  always_ff @(posedge clk_65mhz) begin
    cam_clk_buff <= jb[0]; //sync camera
    cam_clk_in <= cam_clk_buff;
    vsync_buff <= jb[1]; //sync vsync signal
    vsync_in <= vsync_buff;
    href_buff <= jb[2]; //sync href signal
    href_in <= href_buff;
    pixel_buff <= ja; //sync pixels
    pixel_in <= pixel_buff;
  end

  //CAMERA:
  camera camera_m(
    //signal generate to camera:
    .clk_65mhz(clk_65mhz),
    .jbclk(jbclk),
    .jblock(jblock),
    //returned information from camera:
    .cam_clk_in(cam_clk_in),
    .vsync_in(vsync_in),
    .href_in(href_in),
    .pixel_in(pixel_in),
    //output framed info from camera for processing:
    .pixel_out(cam_pixel),
    .pixel_valid_out(valid_pixel),
    .frame_done_out(frame_done)
  );

  //RECOVER:
  //recovers hcount and vcount from camera module:
  //generates data and a valid signal on 65 MHz
  recover recover_m (
    .cam_clk_in(cam_clk_in),
    .valid_pixel_in(valid_pixel),
    .pixel_in(cam_pixel),
    .frame_done_in(frame_done),
    .system_clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .pixel_out(pixel_data_rec),
    .data_valid_out(data_valid_rec),
    .hcount_out(hcount_rec),
    .vcount_out(vcount_rec));

  //FILTER: encompasses kernel, buffer, and convolution
  filter gaussian_filter(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .data_valid_in(data_valid_rec),
    .pixel_data_in(pixel_data_rec),
    .hcount_in(hcount_rec),
    .vcount_in(vcount_rec),
    .data_valid_out(data_valid_filtered),
    .pixel_data_out(pixel_data_filtered),
    .hcount_out(hcount_filtered),
    .vcount_out(vcount_filtered)
  );

  //PIXEL SPLITTING MUX:
  //included into rgb_to_ycrcb directly
  //0 cycle latency
  
  //RGB_TO_YCRCB: 
  //Convert RGB of filtered pixel data to YCrCb
  //See lecture 04 for YCrCb discussion.
  //Module has a 3 cycle latency
  rgb_to_ycrcb rgbtoycrcb_m(
    .clk_in(clk_65mhz),
    .r_in({pixel_data_rec[15:11], 5'b0}), //all five of red
    .g_in({pixel_data_rec[10:5],4'b0}), //all six of green
    .b_in({pixel_data_rec[4:0], 5'b0}), //all five of blue
    .y_out(y),
    .cr_out(cr),
    .cb_out(Cb)
  );

  //THRESHOLD:
  //Thresholder: Takes in the full RGB and YCrCb information and
  //based on upper and lower bounds masks
  //module has 0 cycle latency
  threshold(
     .sel_in(sw[5:3]), //will leave this functionality for now, don't actually need it...
     .r_in(pixel_data_rec_pipe[2][15:12]), 
     .g_in(pixel_data_rec_pipe[2][10:7]), 
     .b_in(pixel_data_rec_pipe[2][4:1]), 
     .y_in(y[9:6]),
     .cr_in(cr[9:6]),
     .cb_in(Cb[9:6]),
     .lower_bound_in(sw[12:10]),
     .upper_bound_in(sw[15:13]),
     .mask_out(mask),
     .channel_out(sel_channel)
  );

  //CENTER OF MASS:
  //module has variable cycle latency from when tabulate is asserted to valid output
  //divider (which is called from within) also has high latency
  //module must receive a full frame of pixels
  center_of_mass com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_rec_pipe[2]),  //PIPELINE
    .y_in(vcount_rec_pipe[2]), //PIPELINE
    .valid_in(mask),
    .tabulate_in((hcount_rec==0 && vcount_rec==0)), //PIPELINE
    .x_com(x_com_calc),
    .y_com(y_com_calc),
    .valid_com(new_com)
  );

  //COMPARE: 
  compare comparer(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_com_in(x_com_calc),
    .y_com_in(y_com_calc),
    .com_valid_in(new_com),
    .hcount(hcount_rec_pipe[2]), //PIPELINE: 3 cycle latency
    .vcount(vcount_rec_pipe[2]), //PIPELINE: 3 cycle latency
    .y_pixel(y[9:4]), //PIPELINE: from rgb_to_ycrcb
    .threshold_in(mask),
    .color_select(sw[2:1]),
    .write_erase_select(sw[0]),
    .pixel_from_bram(pixel_out_porta_compare), // current pixel from BRAM for comparison
    .pixel_for_bram(pixel_in_porta_compare),
    .pixel_addr_forbram(pixel_addr_porta_compare),
    .valid_pixel_forbram(pixel_valid_porta_compare),
    .pixelread_forvga_valid(vgareadpixel),
    .pixeladdr_forvga_valid(vgasndaddr)
  );
  
  //FRAME BUFFER FOR IMAGE + WRITING
  //Two Clock Frame Buffer:
  //Data written on 16.67 MHz (From camera)
  //Data read on 65 MHz (start of video pipeline information)
  //Latency is 2 cycles.
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(320*240))
    frame_buffer_ethernet (
    //Write Side (65MHz) -- FOR FPGA 1 COMPARE AND VGA
    .addra(pixel_addr_porta_compare),
    .clka(clk_65mhz),
    .wea(pixel_valid_porta_compare),
    .dina(pixel_in_porta_compare),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(dummy_douta),
    //Read Side (50 MHz) -- FOR ETHERNET
    .addrb(pixel_addr_rbo[16:0]),
    .dinb(16'b0),
    .clkb(eth_refclk),
    .web(1'b0), // never write using port B
    .enb(1'b1),
    .regceb(1'b1),
    .rstb(sys_rst),
    .doutb(pixel_out_portb)
  );

  //vga testing bram
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(320*240))
    frame_buffer_vga (
    //Write Side (65MHz) -- FOR FPGA 1 COMPARE AND VGA
    .addra(pixel_addr_porta_compare),
    .clka(clk_65mhz),
    .wea(pixel_valid_porta_compare),
    .dina(pixel_in_porta_compare),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(pixel_out_porta_compare),
    //Read Side (65 MHz) -- FOR VGA
    .addrb(pixel_addr_vga),
    .dinb(16'b0),
    .clkb(clk_65mhz),
    .web(1'b0), // never write using port B
    .enb(1'b1),
    .regceb(1'b1),
    .rstb(sys_rst),
    .doutb(pixel_out_portb_vga)
  );

  //VGA COMPONENTS  
  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank)
  );

  //MIRROR:
  // latency 2
  mirror2 mirror2_m(
    .clk_in(clk_65mhz),
    .mirror_in(1'b1),
    .hcount_in(hcount), 
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_vga)
  );

  //SCALE:
  // latency 0
  scale2 scale2_m (
    .hcount_in(hcount),
    .vcount_in(vcount),
    .frame_buff_in(pixel_out_portb_vga), //changed from pixel_out_portb
    .cam_out(scaled_pixel_to_display)
  );
  
  //VGA mux
  vga_mux vga_mux_inst(
    .scaled_pixel_in(scaled_pixel_to_display),
    .pixel_out(mux_pixel)
  );
  //blanking logic.
  //latency 1 cycle
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank?mux_pixel[11:8]:0; //TODO: needs to use pipelined signal (PS6)
    vga_g <= ~blank?mux_pixel[7:4]:0;  //TODO: needs to use pipelined signal (PS6)
    vga_b <= ~blank?mux_pixel[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
  end

  assign vga_hs = ~hsync_pipe[2];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[2];  //TODO: needs to use pipelined signal (PS7)

  // // test pixel generator for ethernet
  // logic [7:0] ethernet_pixel;
  // logic [23:0] prev_rbo_addr;
  // logic [16:0] counter;
  // logic [1:0] color = 2'b00;

  // always_ff @(posedge eth_refclk) begin
  //   prev_rbo_addr <= pixel_addr_rbo;
  //   if (prev_rbo_addr != pixel_addr_rbo) begin
  //     if (counter < 19200) counter <= counter + 1;
  //     else if (counter == 19200) begin
  //       counter <= 0;
  //       if (color < 3) begin
  //         color <= color + 1;
  //       end else begin
  //         color <= 2'b00;
  //       end
  //     end 
  //   end
    
  // end 

  // always_comb begin
  //   ethernet_pixel = {6'b110000, color};
  //   // yellow pink green red
  // end

  //ETHERNET COMPONENTS:
  // logic between ethernet modules
  logic stall;
  logic rbo_axiov;
  logic [1:0] rbo_axiod;
  logic [23:0] pixel_addr_rbo;

  reverse_bit_order bit_order_reverser(
    .clk(eth_refclk),
    .rst(sys_rst),
    .pixel(8'b11111111), // changed from pixel_out_portb for testing
    .stall(stall), 
    .axiov(rbo_axiov), 
    .axiod(rbo_axiod), 
    .pixel_addr(pixel_addr_rbo) 
  );

  eth_packer packer(
    .cancelled(1'b0),
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiiv(rbo_axiov), 
    .axiid(rbo_axiod), 
    .stall(stall), 
    .phy_txen(eth_txen), 
    .phy_txd(eth_txd) 
  );

  // for selecting first 32 bits for displaying on 7seg during testing
  logic [31:0] aggregate_axiod;
  logic aggregate_axiov;
  aggregate aggregate (
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiiv(rbo_axiov),
    .axiid(rbo_axiod),
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

  // variables for testing ethernet transmission
  logic old_txen;
  logic flip;
  logic old_rbo_axiov;

  always_ff @(posedge eth_refclk) begin
      if (sys_rst) begin
          led[13:0] <= 0;
          seven_segment_controller_val_in <= 0;
          old_txen <= 0;
      end else if (rbo_axiov & !old_rbo_axiov) begin
          led[13:0] <= led[13:0] + 1;
      end

      if (aggregate_axiov) begin
          seven_segment_controller_val_in <= aggregate_axiod;
      end

      if (btnr) begin
        flip <= 0;
      end else if (old_txen == 1 && eth_txen == 0) begin
        flip <= 1;
      end

      old_txen <= eth_txen;
      old_rbo_axiov <= rbo_axiov;

      led[15] <= stall;
  end

endmodule




`default_nettype wire
