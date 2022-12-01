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
          6'b111111: pixel_out = 12'hA26; // magenta color
          6'b101010: pixel_out = 12'hFF0; // yellow color
          6'b000000: pixel_out = 12'h00F; // blue color
        endcase
      end
      default: begin
        pixel_out = {scaled_pixel_in[5:2], scaled_pixel_in[5:2], scaled_pixel_in[5:2]}; // want same values in RGB fields 
      end
    endcase
  end

endmodule
