`timescale 1ns / 1ps
`default_nettype none

module scale2(
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [7:0] frame_buff_in,
  output logic [7:0] cam_out
);

  always_comb begin
    // // scale up by 2
    // if (hcount_in < 640 && vcount_in < 480) begin
    //     cam_out = frame_buff_in;
    // end
    // scale up to full screen
    if (hcount_in < 1024 && vcount_in < 768) begin
        cam_out = frame_buff_in;
    end
    else begin
        cam_out = 16'b0;
    end
  end
endmodule


`default_nettype wire
