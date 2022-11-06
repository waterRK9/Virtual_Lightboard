`timescale 1ns / 1ps
`default_nettype none

module scale(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [15:0] frame_buff_in,
  output logic [15:0] cam_out
);
  //YOUR DESIGN HERE!

  always_comb begin
    if (scale_in == 2'b00) begin
      if (hcount_in < 240 && vcount_in < 320) begin
        cam_out = frame_buff_in;
      end
      else begin
        cam_out = 16'b0;
      end
    end
    else if (scale_in == 2'b01) begin
      if (hcount_in < 480 && vcount_in < 640) begin
        cam_out = frame_buff_in;
      end
      else begin
        cam_out = 16'b0;
      end
    end
    else if (scale_in == 2'b10) begin
      if (hcount_in < 640 && vcount_in < 853) begin
        cam_out = frame_buff_in;
      end
      else begin
        cam_out = 16'b0;
      end
    end
    else begin
      cam_out = 16'b0;
    end
  end
endmodule


`default_nettype wire
