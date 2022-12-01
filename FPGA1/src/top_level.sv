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
  output logic caa,cab,cac,cad,cae,caf,cag

  );

  //system reset switch linking
  logic sys_rst; //global system reset
  assign sys_rst = btnc; //just done to make sys_rst more obvious
  assign led = sw; //switches drive LED (change if you want)

  //pipelining vars
  logic [10:0] hcount_pipe [7:0];
  logic [9:0] vcount_pipe [7:0];
  logic blank_pipe [7:0];
  logic hsync_pipe [7:0];
  logic vsync_pipe [7:0];
  logic [15:0] pixel_data_filtered_pipe; 
  logic [11:0] mux_pixel_pipe;

  //Pipelining
  always_ff @(posedge clk_65mhz)begin
    hcount_pipe[0] <= hcount;
    vcount_pipe[0] <= vcount;
    blank_pipe[0] <= blank;
    hsync_pipe[0] <= hsync;
    vsync_pipe[0] <= vsync;
    mux_pixel_pipe <= mux_pixel;
    pixel_data_filtered_pipe <= pixel_data_filtered;
    for (int i=1; i<8; i = i+1)begin
      hcount_pipe[i] <= hcount_pipe[i-1];
      vcount_pipe[i] <= vcount_pipe[i-1];
      blank_pipe[i] <= blank_pipe[i-1];
      hsync_pipe[i] <= hsync_pipe[i-1];
      vsync_pipe[i] <= vsync_pipe[i-1];
    end
  end

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
  logic [9:0] y, cr, cb; //ycrcb conversion of full pixel

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
  logic [16:0] pixel_addr_portb;
  logic [7:0] pixel_in_porta;
  logic [16:0] pixel_addr_porta;
  logic pixel_valid_porta;

  //BRAM module output
  logic [8:0] pixel_out_porta;
  logic [8:0] pixel_out_portb;

  //VGA GEN module output
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic hsync, vsync, blank; //control signals for vga
  logic hsync_t, vsync_t, blank_t; //control signals out of transform

  //Scale module output
  logic [7:0] scaled_pixel_to_display;//mirrored and scaled 565 pixel

  //VGA mux module output
  logic [7:0] mux_pixel;

  //FINAL PROJECT MODULES
  //CLOCKS: 
  //Generate 65 MHz
  clk_wiz_65mhz clk_65mhz_gen(
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)
  );
  //Generate Ethernet Clock
  ethernet_clk_wiz clk_50mhz_gen(
    .clk(clk_100mhz),
    .ethclk(clk_50mhz)
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
  //Convert RGB of filtered pixel data to YCrCb
  //See lecture 04 for YCrCb discussion.
  //Module has a 3 cycle latency
  rgb_to_ycrcb rgbtoycrcb_m(
    .clk_in(clk_65mhz),
    .r_in({pixel_data_filtered[15:11], 5'b0}), //all five of red
    .g_in({pixel_data_filtered[10:5],4'b0}), //all six of green
    .b_in({pixel_data_filtered[4:0], 5'b0}), //all five of blue
    .y_out(y),
    .cr_out(cr),
    .cb_out(cb)
  );

  //THRESHOLD:
  //Thresholder: Takes in the full RGB and YCrCb information and
  //based on upper and lower bounds masks
  //module has 0 cycle latency
  threshold(.sel_in(sw[5:3]), //will leave this functionality for now, don't actually need it...
     .r_in(pixel_data_filtered_pipe[15:12]), 
     .g_in(pixel_data_filtered_pipe[10:7]), 
     .b_in(pixel_data_filtered_pipe[4:1]), 
     .y_in(y[9:6]),
     .cr_in(cr[9:6]),
     .cb_in(cb[9:6]),
     .lower_bound_in(sw[12:10]),
     .upper_bound_in(sw[15:13]),
     .mask_out(mask),
     .channel_out(sel_channel)
  );

  //CENTER OF MASS:
  center_of_mass com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount_pipe[6]),  //TODO: needs to use pipelined signal! (PS3)
    .y_in(vcount_pipe[6]), //TODO: needs to use pipelined signal! (PS3)
    .valid_in(mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .valid_out(new_com)
  );

  //COMPARE: 
  compare comparer(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_com_in(x_com_calc),
    .y_com_in(y_com_calc),
    .com_valid_in(new_com),
    .hcount(hcount_pipe[]), // TODO: finish pipelining
    .vcount(vcount_pipe[]), // TODO: finish pipelining
    .y_pixel(y), // TODO: finish pipelining
    .color_select(sw[2:1]),
    .write_erase_select(sw[0]),
    .pixel_from_bram(pixel_out_porta_compare), // current pixel from BRAM (PORT B)
    .pixel_for_bram(pixel_in_porta_compare),
    .pixel_out_forbram(pixel_in_porta_compare),
    .pixel_addr_forbram(pixel_addr_porta_compare),
    .valid_pixel_forbram(pixel_valid_porta_compare),
    .pixelread_forvga_valid(vgareadpixel),
    .pixeladdr_forvga_valid(vgasndaddr)
  );

  //BRAM MANAGER: combinational logic to handle what is wired to BRAM
  always_comb begin
    if (vgasndaddr == 1 || vgareadpixel == 1) begin
      pixel_addr_porta = pixel_addr_vga; // TODO: use this pixel in vga
      pixel_valid_porta = 0;
      pixel_in_porta = 8'b0;
      pixel_out_porta = pixel_out_vga; // TODO: use this pixel in vga
    end
    else begin
      pixel_addr_porta = pixel_addr_porta_compare;
      pixel_valid_porta = pixel_valid_porta_compare;
      pixel_in_porta = pixel_in_porta_compare;
      pixel_out_porta = pixel_out_porta_compare;
    end
  end
  
  //FRAME BUFFER FOR IMAGE + WRITING
  //Two Clock Frame Buffer:
  //Data written on 16.67 MHz (From camera)
  //Data read on 65 MHz (start of video pipeline information)
  //Latency is 2 cycles.
  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(8),
    .RAM_DEPTH(320*240))
    frame_buffer (
    //Write Side (65MHz) -- FOR FPGA 1 COMPARE AND VGA
    .addra(pixel_addr_porta),
    .clka(clk_65mhz),
    .wea(pixel_valid_porta),
    .dina(pixel_in_porta),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(sys_rst),
    .douta(pixel_out_porta),
    //Read Side (50 MHz) -- FOR ETHERNET
    .addrb(pixel_addr_portb),
    .dinb(16'b0),
    .clkb(clk_50mhz),
    .web(1'b0), // never write using port B
    .enb(1'b1),
    .regceb(1'b1),
    .rstb(sys_rst),
    .doutb(pixel_out_portb)
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
  //Based on hcount and vcount as well as scaling
  //gate the release of frame buffer information
  //Latency: 0
  scale scale_m(
    .scale_in(2'b01),
    .hcount_in(hcount_pipe[3]), //TODO: needs to use pipelined signal (PS2)
    .vcount_in(vcount_pipe[3]), //TODO: needs to use pipelined signal (PS2)
    .frame_buff_in(pixel_out_vga),
    .cam_out(scaled_pixel_to_display)
  );
  //Based on current hcount and vcount as well as
  //scaling and mirror information requests correct pixel
  //from BRAM (on 65 MHz side).
  //latency: 2 cycles
  //IMPORTANT: this module is "start" of Output pipeline
  //hcount and vcount are fine here.
  //however latency in the image information starts to build up starting here
  //and we need to make sure to continue to use screen location information
  //that is "delayed" the right amount of cycles!
  //AS A RESULT, most downstream modules after this will need to use appropriately
  //pipelined versions of hcount, vcount, hsync, vsync, blank as needed
  //these The pipelining of these stages will need to be determined
  //for CHECKOFF 3!
  mirror mirror_m(
    .clk_in(clk_65mhz),
    .scale_in(2'b01),
    .mirror_in(1'b1),
    .hcount_in(hcount), 
    .vcount_in(vcount),
    .pixel_addr_out(pixel_addr_vga)
  );
  //VGA mux
  vga_mux (
    scaled_pixel_in(scaled_pixel_to_display),
    pixel_out(mux_pixel)
  );
  //blanking logic.
  //latency 1 cycle
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank?mux_pixel_pipe[11:8]:0; //TODO: needs to use pipelined signal (PS6)
    vga_g <= ~blank?mux_pixel_pipe[7:4]:0;  //TODO: needs to use pipelined signal (PS6)
    vga_b <= ~blank?mux_pixel_pipe[3:0]:0;  //TODO: needs to use pipelined signal (PS6)
  end

  assign vga_hs = ~hsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)
  assign vga_vs = ~vsync_pipe[7];  //TODO: needs to use pipelined signal (PS7)

  //ETHERNET COMPONENTS:
  reverse_bit_order bit_order_reverser(
    .clk(clk_50mhz),
    .rst(sys_rst),
    .pixel(pixel_out_portb),
    .stall(1'b0), //TODO: make this the correct value for stall logic
    .axiov(), //TODO: fill this in
    .axiod(), //TODO: fill this in
    .pixel_addr() //TODO: fill this in
  );
  eth_packer packer(
    .clk(clk_50mhz),
    .rst(sys_rst),
    .axiiv(), //TODO: fill this in
    .axiid(), //TODO: fill this in
    .stall(), //TODO: fill this in
    .phy_txen(), //TODO: fill this in
    .phy_txd() //TODO: fill this in
  );


endmodule




`default_nettype wire
