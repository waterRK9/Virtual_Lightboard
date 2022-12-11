`default_nettype none

module image_audio_splitter_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;

    logic addr_axiov;
    logic pixel_axiov;
    logic audio_axiov;

    logic [23:0] addr;
    logic [7:0] pixel;
    logic [7:0] audio;

    image_audio_splitter image_audio_splitter (
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),

    .addr_axiov(addr_axiov),
    .pixel_axiov(pixel_axiov),
    .audio_axiov(audio_axiov),

    .addr(addr),
    .pixel(pixel),
    .audio(audio)
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
        if (!addr_axiov || addr != 24'h555555) $display("Test1: Error in addr");
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
        if (!pixel_axiov || pixel != 8'b11100100) $display("Test2: Error in pixel"); //I should really check both pixels here
        else $display("Test2: pixel looks good!");

        rst = 1;
        #20;
        rst = 0;

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