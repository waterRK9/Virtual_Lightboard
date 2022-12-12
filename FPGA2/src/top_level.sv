`timescale 1ns / 1ps
`default_nettype none

module top_level(
    input wire clk, //clock @ 100 mhz
    input wire btnc, //btnc (used for reset)
    input wire eth_crsdv,
    input wire [1:0] eth_rxd,

    output logic [15:0] led, // note: 7 seg for testing visualization, remove later
    output logic ca, cb, cc, cd, ce, cf, cg,
    output logic [7:0] an,

    output logic eth_rstn,
    output logic eth_refclk,

    output logic [3:0] vga_r, vga_g, vga_b,
    output logic vga_hs, vga_vs
    );

    //system reset switch linking
    logic sys_rst; //global system reset
    assign sys_rst = btnc; //just done to make sys_rst more obvious
    assign eth_rstn = ~btnc;

    /// Module Instianation ///
    // Generating 50 mhz ethernet clk and 65 mhz camera clk
    // ethernet_clk_wiz eth_clk_gen(
    //     .clk(clk),
    //     .ethclk(eth_refclk));

    // logic clk_65mhz;
    // camera_clk_wiz camera_clk_gen(
    //     .clk(clk_100mhz),
    //     .clk_out1(clk_65mhz)
    // );

    logic clk_65mhz;
    // GENERATE CLOCKS
    clk_wiz_0_clk_wiz clk_gen(
        .clk_100mhz(clk),
        .eth_clk(eth_refclk),
        .vga_clk(clk_65mhz)
    );

    logic ether_axiov;
    logic [1:0] ether_axiod;

    // Delay: 
    ether ether (
        .clk(eth_refclk),
        .rst(sys_rst),
        .rxd(eth_rxd),
        .crsdv(eth_crsdv),
        .axiov(ether_axiov),
        .axiod(ether_axiod)
    );

    // Delay: 
    logic bitorder_axiov;
    logic [1:0] bitorder_axiod;
    bitorder bitorder (
        .clk(eth_refclk),
        .rst(sys_rst),
        .axiiv(ether_axiov),
        .axiid(ether_axiod),
        .axiov(bitorder_axiov), 
        .axiod(bitorder_axiod)
    );

    // Delay:
    logic firewall_axiov;
    logic [1:0] firewall_axiod;
    firewall firewall (
        .clk(eth_refclk),
        .rst(sys_rst),
        .axiid(bitorder_axiod),
        .axiiv(bitorder_axiov),
        .axiov(firewall_axiov), 
        .axiod(firewall_axiod)
    );

    // Delay
    logic done;
    cksum cksum (
        .clk(eth_refclk),
        .rst(sys_rst),
        .axiid(ether_axiod),
        .axiiv(ether_axiov),
        .done(done), //compiled incoming data
        .kill(led[15]) //high if crc32 calculation fails
    );
    assign led[14] = done;

   //Delay: 
   logic valid_addr_in, valid_pixel_in, valid_audio_in;
   logic [16:0] pixel_addr_in;
   logic [7:0] pixel_in, audio_in;
   image_audio_splitter image_audio_splitter(
       .clk(eth_refclk),
       .rst(sys_rst),
       .axiiv(firewall_axiov), 
       .axiid(firewall_axiod), 

       .addr_axiov(valid_addr_in),
       .pixel_axiov(valid_pixel_in), 
       .audio_axiov(valid_audio_in), 

       .addr(pixel_addr_in),
       .pixel(pixel_in),
       .audio(audio_in)
    );

    //Delay: 1 cycle
    logic pixel_write_enable;
    logic [7:0] pixel_written;
    logic [16:0] addr_written;
    frame_packager fp(
        .clk(eth_refclk),
        .rst(sys_rst),
        .addr_axiiv(valid_addr_in),
        .addr_axiid(pixel_addr_in),
        .pixel_axiiv(valid_pixel_in),
        .pixel_axiid(pixel_in),

        .axiov(pixel_write_enable),
        .addr_axiod(addr_written),
        .pixel_axiod(pixel_written)
    );

    //FRAME BUFFER FOR IMAGE + WRITING
    //Two Clock Frame Buffer:
    //Data written on 50Hz (From ethernet)
    //Data read on 65 MHz (start of video pipeline information)
    //Latency is 2 cycles.
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH(8),
        .RAM_DEPTH(320*240))
        frame_buffer (
        //Write Side (50MHz)
        .addra(addr_written),
        .clka(eth_refclk),
        .wea(pixel_write_enable), //question: do I need rotate here? What if I read it out without rotating?
        .dina(pixel_written),
        .ena(1'b1),
        .regcea(1'b1),
        .rsta(sys_rst),
        .douta(),
        //Read Side (65 MHz)
        .addrb(pixel_addr_vga),
        .dinb(16'b0),
        .clkb(clk_65mhz),
        .web(1'b0),
        .enb(1'b1),
        .rstb(sys_rst),
        .regceb(1'b1),
        .doutb(pixel_out_portb)
    );

    // port b connections
    logic [16:0] pixel_addr_portb;
    logic [7:0] pixel_out_portb;

    //VGA GEN module output
    logic [10:0] hcount;    // pixel on current line
    logic [9:0] vcount;     // line number
    logic hsync, vsync, blank; //control signals for vga
    logic hsync_t, vsync_t, blank_t; //control signals out of transform

    //Scale module output
    logic [7:0] scaled_pixel_to_display;//mirrored and scaled 565 pixel

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
    logic [11:0] mux_pixel_pipe;

    //Pipelining
    always_ff @(posedge clk_65mhz) begin
        hcount_pipe[0] <= hcount;
        vcount_pipe[0] <= vcount;
        blank_pipe[0] <= blank;
        hsync_pipe[0] <= hsync;
        vsync_pipe[0] <= vsync;
        mux_pixel_pipe <= mux_pixel;
        for (int i=1; i<8; i = i+1)begin
            hcount_pipe[i] <= hcount_pipe[i-1];
            vcount_pipe[i] <= vcount_pipe[i-1];
            blank_pipe[i] <= blank_pipe[i-1];
            hsync_pipe[i] <= hsync_pipe[i-1];
            vsync_pipe[i] <= vsync_pipe[i-1];
        end
    end

    // VGA DISPLAYING:
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
        .frame_buff_in(pixel_out_portb),
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


    //note: keep for testing so we can see what we are sent
    logic [31:0] aggregate_axiod;
    logic aggregate_axiov;
    aggregate aggregate (
    .clk(eth_refclk),
    .rst(sys_rst),
    .axiiv(firewall_axiov),
    .axiid(firewall_axiod),
    .axiov(aggregate_axiov),
    .axiod(aggregate_axiod)
    );

    logic [31:0] seven_segment_controller_val_in;
    seven_segment_controller seven_segment_controller (
        .clk_in(clk_65mhz),
        .rst_in(sys_rst),
        .val_in(seven_segment_controller_val_in),
        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
        .an_out(an)
    );

    logic [13:0] counter;
    always_ff @(posedge clk_65mhz) begin
        if (sys_rst) begin
            counter <= 0;
            seven_segment_controller_val_in <= 0;
        end 

        if (hcount == 0 && vcount == 0 && counter < 16384) counter <= counter + 1;
        else counter <= 0;
        led[13:0] <= counter;

        seven_segment_controller_val_in <= {1'b0, counter , pixel_addr_vga};
    end

    ila_eth ilaeth (
    .clk(eth_refclk),
    .probe0(addr_written),
    .probe1(pixel_written),
    .probe2(pixel_write_enable),
    .probe3(eth_crsdv),
    .probe4(eth_rxd)
    );
    
    ila_vga ilavga (
    .clk(clk_65mhz),
    .probe0(pixel_addr_vga),
    .probe1(pixel_out_portb),
    .probe2(hcount),
    .probe3(vcount)
    );

endmodule

`default_nettype wire

// ila planning

//eth clk
// addr_written 17
// pixel_written 8
// pixel_write_enable 1

//vga clk
//pixel_addr_vga 17
//pixel_out_portb 8
//hcount 11
//vount 10
