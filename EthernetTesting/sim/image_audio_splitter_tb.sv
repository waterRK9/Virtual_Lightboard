`default_nettype none

module image_audio_splitter_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;

    logic ias_addr_axiov;
    logic ias_pixel_axiov;
    logic ias_audio_axiov;

    logic [23:0] ias_addr_out;
    logic [7:0] ias_pixel_out;
    logic [7:0] ias_audio_out;

    image_audio_splitter image_audio_splitter (
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),

    .addr_axiov(ias_addr_axiov),
    .pixel_axiov(ias_pixel_axiov),
    .audio_axiov(ias_audio_axiov),

    .addr(ias_addr_out),
    .pixel(ias_pixel_out),
    .audio(ias_audio_out)
    );

    logic fp_pixel_wea;
    logic [16:0] fp_addr_axiod;
    logic [7:0] fp_written_pixel;

    frame_packager fp(
    .clk(clk),
    .rst(rst),
    .addr_axiiv(ias_addr_axiov),
    .addr_axiid(ias_addr_out),
    .pixel_axiiv(ias_pixel_axiov),
    .pixel_axiid(ias_pixel_out),

    .axiov(fp_pixel_wea), //for wea on BRAM
    .addr_axiod(fp_addr_axiod),
    .pixel_axiod(fp_written_pixel)
    );

    always begin
    #10;
    clk = !clk;
    end

    initial begin
        $dumpfile("obj/image_audio_splitter.vcd");
        $dumpvars(0, image_audio_splitter_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10
        
        //Test 1: outputting addr, and pixels correctly
        for (int i = 0; i < 12; i = i + 1) begin //sending address
            axiiv = 1'b1;
            axiid = 2'b01;
            #20;
        end
        if (!ias_addr_axiov || ias_addr_out != 24'h555555) $display("Test1: Error in addr");
        else $display("Test1: addr looks good!");
        for (int i = 0; i < 4; i = i + 1) begin //2 pixels back to back
            axiiv = 1'b1;
            axiid = i;
            #20;
        end
        for (int i = 0; i < 4; i = i + 1) begin 
            axiiv = 1'b1;
            axiid = i;
            #20;
        end
        if (!ias_pixel_axiov || ias_pixel_out != 8'b11100100) $display("Test2: Error in pixel"); //I should really check both pixels here
        else $display("Test2: pixel looks good!");

        // rst = 1;
        axiiv = 1'b0;
        #80;
        axiiv = 1'b1;
        // rst = 0;

        //Test 2: start packet + interuption + new packet
        for (int i = 0; i < 12; i = i + 1) begin
            axiiv = 1'b1;
            axiid = 2'b01;
            #20;
        end
        for (int i = 0; i < 7; i = i + 1) begin 
            axiiv = 1'b1;
            axiid = i;
            #20;
        end
        axiiv = 1'b0;
        #20;
        for (int i = 0; i < 12; i = i + 1) begin
            axiiv = 1'b1;
            axiid = 2'b10;
            #20;
        end
        for (int i = 0; i < 8; i = i + 1) begin 
            axiiv = 1'b1;
            axiid = i;
            #20;
        end

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire