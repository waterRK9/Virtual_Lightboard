module vga_mux (
  input wire [7:0] scaled_pixel_in, //pixel from the BRAM
  output logic [11:0] pixel_out
);

  //indicator pixel if it's drawn on or not
  logic [1:0] pixel_type;
  assign pixel_type = scaled_pixel_in[7:6];

  always_comb begin
    case (pixel_type)
        2'b11: begin // pixel was drawn on
          case (scaled_pixel_in[5:0]) 
            6'b000001: pixel_out = 12'hA26; // magenta color
            6'b000010: pixel_out = 12'h0F0; // green
            6'b000011: pixel_out = 12'hF00; // red
            6'b000000: pixel_out = 12'hFF0; // yellow
            default: pixel_out = 12'hFFF; // default white - this shouldn't happen
          endcase
        end
        2'b10: begin // threshold pixel
          pixel_out = 12'hA26;
        end
        2'b01: begin // crosshair pixel
          pixel_out = 12'h0F0; // draw in green 
        end 
        default: begin
          pixel_out = {scaled_pixel_in[5:2], scaled_pixel_in[5:2], scaled_pixel_in[5:2]};
        end
      endcase
  end

endmodule
