`default_nettype none

// test fir31 module
// input samples are read from fir31.samples
// output samples are written to fir31.output
module fir31_tb;
  logic clk,rst,ready_in;	// fir31 signals
  logic signed [7:0] x;
  logic signed [17:0] y;
  logic [20:0] scount;    // keep track of which sample we're at
  logic [5:0] cycle;      // wait 64 clocks between samples
  integer fin,fout,code;

  fir31 dut(.clk_in(clk),.rst_in(rst),.ready_in(ready_in),
          .x_in(x),.y_out(y));

  always begin
    #10;
    clk = !clk;
  end

  initial begin
    $dumpfile("obj/fir31.vcd");
    $dumpvars(0, fir31_tb);
    $display("Starting Sim");
    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;
    #10;

    x = 0;
    ready_in = 1;
    #20;
    ready_in = 0;
    for (int i = 0; i < 32; i = i + 1) begin
      x = 0;
      #20;
    end
    ready_in = 1;
    x = 1;
    #20;
    ready_in = 0;
    x = 0;
    #20
    for (int i = 0; i < 31; i = i + 1) begin
      x = 0;
      #20;
    end

    #20;
    
    #40;
    $display("Finishing Sim");
    $finish;
  end

endmodule

`timescale 1ns / 1ps
`default_nettype wire