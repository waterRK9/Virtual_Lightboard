`timescale 1ns / 1ps
`default_nettype none

module compare_tb;

    //make logics for inputs and outputs!
    logic clk_in;
    logic rst_in;
    logic [10:0] x_com_in;
    logic [9:0] y_com_in;
    logic com_valid_in;
    logic [10:0] hcount_in;
    logic [9:0] vcount_in;
    logic [5:0] y_in;
    logic [1:0] color_sel;
    logic write_erase_sel;
    logic [7:0] bram_pixel_in;
    logic [7:0] bram_pixel_out;
    logic [16:0] bram_pixel_addr;
    logic bram_pixelwrite_valid;
    logic vga_pixelread_valid;
    logic vga_pixeladdr_valid;

    compare uut(.clk_in(clk_in), 
                .rst_in(rst_in),
                .x_com_in(x_com_in),
                .y_com_in(y_com_in),
                .com_valid_in(com_valid_in),
                .hcount(hcount_in),
                .vcount(vcount_in),
                .y_pixel(y_in),
                .color_select(color_sel),
                .write_erase_select(write_erase_sel),
                .pixel_from_bram(bram_pixel_in),
                .pixel_for_bram(bram_pixel_out),
                .pixel_addr_forbram(bram_pixel_addr),
                .valid_pixel_forbram(bram_pixelwrite_valid),
                .pixelread_forvga_valid(vga_pixelread_valid),
                .pixeladdr_forvga_valid(vga_pixeladdr_valid)
    );

    always begin
        #5;  //every 5 ns switch...so period of clock is 10 ns...100 MHz clock
        clk_in = !clk_in;
    end

    //initial block...this is our test simulation
    initial begin
        $dumpfile("compare.vcd"); //file to store value change dump (vcd)
        $dumpvars(0,compare_tb); //store everything at the current level and below
        $display("Starting Sim"); //print nice message
        clk_in = 0; //initialize clk (super important)
        rst_in = 0; //initialize rst (super important)
        x_com_in = 11'b0;
        y_com_in = 10'b0;
        com_valid_in = 0;
        hcount_in = 0;
        vcount_in = 0;
        y_in = 0;
        color_sel = 2'b01; // pink
        write_erase_sel = 0; // write mode

        #10  //wait a little bit of time at beginning
        rst_in = 1; //reset system
        #10; //hold high for a few clock cycles
        rst_in = 0;
        #5;
        // $display("Test 1: 9 clock cycles - write mode in pink");
        // for (int i = 0; i<9; i= i+1)begin
        //     if (i == 0) begin // send in valid COM
        //         x_com_in = 150;
        //         y_com_in = 100;
        //         com_valid_in = 1;
        //     end else if (i == 1) begin
        //         hcount_in = 100;
        //         vcount_in = 100;
        //         y_in = 6'b010101;
        //     end else if (i == 4) begin
        //         bram_pixel_in = 8'b00111111; // pixel not written on
        //     end

        //     $display("Cycle %4d values: ", i);
        //     $display("pixel from bram", bram_pixel_in);
        //     $display("pixel for bram", bram_pixel_out);
        //     $display("pixel addr for bram", bram_pixel_addr);
        //     $display("write to bram", bram_pixelwrite_valid);
        //     $display("read pixel vga signal", vga_pixelread_valid);
        //     $display("send address to bram for vga pixel signal", vga_pixeladdr_valid);
        //     $display("______");
        //     #10;
        // end
        
        // $display("Test 2: 17 clock cycles - write mode in pink");
        // for (int i = 0; i<17; i= i+1)begin
        //     if (i == 0) begin // send in valid COM
        //         x_com_in = 150;
        //         y_com_in = 100;
        //         com_valid_in = 1;
        //     end else if (i == 1) begin
        //         hcount_in = 100;
        //         vcount_in = 100;
        //         y_in = 6'b010101;
        //     end else if (i == 4) begin
        //         bram_pixel_in = 8'b00111111; // pixel not written on
        //     end else if (i == 9) begin
        //         hcount_in = 101;
        //         vcount_in = 100;
        //         y_in = 6'b010111;
        //     end else if (i == 12) begin
        //         bram_pixel_in = 8'b00100000; // pixel not written on
        //     end

        //     $display("Cycle %4d values: ", i);
        //     $display("pixel from bram", bram_pixel_in);
        //     $display("pixel for bram", bram_pixel_out);
        //     $display("pixel addr for bram", bram_pixel_addr);
        //     $display("write to bram", bram_pixelwrite_valid);
        //     $display("read pixel vga signal", vga_pixelread_valid);
        //     $display("send address to bram for vga pixel signal", vga_pixeladdr_valid);
        //     $display("______");
        //     #10;
        // end

        $display("Test 3: 17 clock cycles - write mode in pink, second pixel in COM");
        for (int i = 0; i<17; i= i+1)begin
            if (i == 0) begin // send in valid COM
                x_com_in = 150;
                y_com_in = 100;
                com_valid_in = 1;
            end else if (i == 1) begin
                hcount_in = 100;
                vcount_in = 100;
                y_in = 6'b010101;
            end else if (i == 4) begin
                bram_pixel_in = 8'b00111111; // pixel not written on
            end else if (i == 9) begin
                hcount_in = 151;
                vcount_in = 100;
                y_in = 6'b010111;
            end else if (i == 12) begin
                bram_pixel_in = 8'b00100000; // pixel not written on
            end

            $display("Cycle %4d values: ", i);
            $display("pixel from bram", bram_pixel_in);
            $display("pixel for bram", bram_pixel_out);
            $display("pixel addr for bram", bram_pixel_addr);
            $display("write to bram", bram_pixelwrite_valid);
            $display("read pixel vga signal", vga_pixelread_valid);
            $display("send address to bram for vga pixel signal", vga_pixeladdr_valid);
            $display("______");
            #10;
        end

        $display("Finishing Sim"); //print nice message
        $finish;


    end
endmodule //counter_tb

`default_nettype wire
