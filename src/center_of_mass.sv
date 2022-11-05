`timescale 1ns / 1ps
`default_nettype none

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  //state params
  localparam SUMMING = 3'b000;
  localparam INITIALIZING = 3'b001;
  localparam WAITING = 3'b010;
  localparam RETURNING = 3'b011;
  localparam RESTARTING = 3'b100;
  localparam WAITING_FOR_Y = 3'b101;
  localparam WAITING_FOR_X = 3'b110;
  
  logic [19:0] valid_pixels_count;
  logic [28:0] x_pixel_locs;
  logic [28:0] y_pixel_locs;

  logic calculate_x;
  logic calculate_y;

  logic [31:0] remainder_holder_x;
  logic [31:0] remainder_holder_y;

  logic [31:0] x_value_out;
  logic [31:0] y_value_out;

  logic x_loc_found;
  logic y_loc_found;

  logic calculating_x;
  logic calculating_y;

  logic error_x;
  logic error_y;

  logic [2:0] state;

  always_ff @(posedge clk_in ) begin
    if (rst_in) begin
      state <= SUMMING;
      // x_out <= 0;
      // y_out <= 0;
      valid_out <= 0;
      valid_pixels_count <= 0;
      x_pixel_locs <= 0;
      y_pixel_locs <= 0;
      calculate_x <= 0;
      calculate_y <= 0;
    end
    else begin
      case (state)
        RESTARTING: begin
          state <= SUMMING;
          // x_out <= 0;
          // y_out <= 0;
          valid_out <= 0;
          valid_pixels_count <= 0;
          x_pixel_locs <= 0;
          y_pixel_locs <= 0;
          calculate_x <= 0;
          calculate_y <= 0;
        end
        SUMMING: begin
          if (valid_in) begin
            state <= SUMMING;
            x_pixel_locs <= x_pixel_locs + x_in;
            y_pixel_locs <= y_pixel_locs + y_in;
            valid_pixels_count <= valid_pixels_count + 1;
          end
          else if (tabulate_in) begin
            state <= INITIALIZING;
          end
        end
        INITIALIZING: begin
          if (valid_pixels_count > 0) begin
            state <= WAITING;
            calculate_x <= 1; // sets data_valid_in to 1 to start calculation
            calculate_y <= 1;
          end
          else begin
            state <= SUMMING;
          end
        end
        WAITING: begin
          calculate_x <= 0;
          calculate_y <= 0;
          if (error_x == 1 || error_y == 1) begin
            state <= RESTARTING;
          end
          else if (calculating_x == 0 && calculating_y == 0) begin // no longer busy
            state <= RETURNING;
          end
          // else if (x_loc_found) begin //dividing is done!
          //   state <= WAITING_FOR_Y;
          // end
          // else if (y_loc_found) begin //dividing is done!
          //   state <= WAITING_FOR_X;
          // end
        end
        // WAITING_FOR_Y: begin
        //   if (y_loc_found) begin
        //     state <= RETURNING;
        //   end
        // end
        // WAITING_FOR_X: begin
        //   if (x_loc_found) begin
        //     state <= RETURNING;
        //   end
        // end
        RETURNING: begin
          state <= RESTARTING;
          // x_out <= x_value_out[10:0];
          // y_out <= y_value_out[9:0];
          valid_out <= 1;
        end
      endcase
    end
  end

  divider x_com_finder(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .dividend_in(x_pixel_locs),
    .divisor_in(valid_pixels_count),
    .data_valid_in(calculate_x),
    .quotient_out(x_out),
    .remainder_out(remainder_holder_x),
    .data_valid_out(x_loc_found),
    .error_out(error_x),
    .busy_out(calculating_x)
  );

  divider y_com_finder(
    .clk_in(clk_in),
    .rst_in(rst_in),
    .dividend_in(y_pixel_locs),
    .divisor_in(valid_pixels_count),
    .data_valid_in(calculate_y),
    .quotient_out(y_out),
    .remainder_out(remainder_holder_y),
    .data_valid_out(y_loc_found),
    .error_out(error_y),
    .busy_out(calculating_y)
  );

endmodule

`default_nettype wire
