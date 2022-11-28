`timescale 1ns / 1ps
`default_nettype none

module convolution (
    input wire clk_in,
    input wire rst_in,
    input wire [2:0][15:0] data_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,
    input wire data_valid_in,

    output logic data_valid_out,
    output logic [10:0] hcount_out,
    output logic [9:0] vcount_out,
    output logic [15:0] line_out
    );

    localparam RESTING = 2'b00;
    localparam MULTADD = 2'b01;
    localparam SHIFTCHECK = 2'b10;

    logic [1:0] state;

    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [2:0][2:0][15:0] cached_pixels;
    logic signed [7:0] shift;

    logic signed [15:0] red;
    logic signed [15:0] green;
    logic signed [15:0] blue;
    logic signed [2:0][2:0][15:0] pixels_red;
    logic signed [2:0][2:0][15:0] pixels_green;
    logic signed [2:0][2:0][15:0] pixels_blue;

    logic [3:0] data_valid_pipeline;
    logic [3:0][10:0] hcount_pipeline;
    logic [3:0][9:0] vcount_pipeline;
    
    assign data_valid_out = data_valid_pipeline[3];
    assign hcount_out = hcount_pipeline[3] - 2;
    assign vcount_out = vcount_pipeline[3] - 2;

    kernels kernel (
        .rst_in(rst_in),
        .coeffs(coeffs),
        .shift(shift)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= RESTING;
            line_out <= 0;
            cached_pixels[2][2] <= 16'b0;
            cached_pixels[1][2] <= 16'b0;
            cached_pixels[0][2] <= 16'b0;
            cached_pixels[2][1] <= 16'b0;
            cached_pixels[1][1] <= 16'b0;
            cached_pixels[0][1] <= 16'b0;
            cached_pixels[2][0] <= 16'b0;
            cached_pixels[1][0] <= 16'b0;
            cached_pixels[0][0] <= 16'b0;
        end
        else begin
                data_valid_pipeline <= {data_valid_pipeline[2:0], data_valid_in};
                hcount_pipeline <= {hcount_pipeline[2:0], hcount_in};
                vcount_pipeline <= {vcount_pipeline[2:0], vcount_in};
            
            if (data_valid_in) begin
                // feed in new pixels
                cached_pixels[2][2] <= cached_pixels[2][1];
                cached_pixels[1][2] <= cached_pixels[1][1];
                cached_pixels[0][2] <= cached_pixels[0][1];
                cached_pixels[2][1] <= cached_pixels[2][0];
                cached_pixels[1][1] <= cached_pixels[1][0];
                cached_pixels[0][1] <= cached_pixels[0][0];
                cached_pixels[2][0] <= data_in[2];
                cached_pixels[1][0] <= data_in[1];
                cached_pixels[0][0] <= data_in[0];
            end
                pixels_red[0][0] <= $signed({1'b0, cached_pixels[0][0][15:11]})*$signed(coeffs[0][0]);
                pixels_red[0][1] <= $signed({1'b0, cached_pixels[0][1][15:11]})*$signed(coeffs[0][1]);
                pixels_red[0][2] <= $signed({1'b0, cached_pixels[0][2][15:11]})*$signed(coeffs[0][2]);
                pixels_red[1][0] <= $signed({1'b0, cached_pixels[1][0][15:11]})*$signed(coeffs[1][0]);
                pixels_red[1][1] <= $signed({1'b0, cached_pixels[1][1][15:11]})*$signed(coeffs[1][1]);
                pixels_red[1][2] <= $signed({1'b0, cached_pixels[1][2][15:11]})*$signed(coeffs[1][2]);
                pixels_red[2][0] <= $signed({1'b0, cached_pixels[2][0][15:11]})*$signed(coeffs[2][0]);
                pixels_red[2][1] <= $signed({1'b0, cached_pixels[2][1][15:11]})*$signed(coeffs[2][1]);
                pixels_red[2][2] <= $signed({1'b0, cached_pixels[2][2][15:11]})*$signed(coeffs[2][2]);

                pixels_green[0][0] <= $signed({1'b0, cached_pixels[0][0][10:5]})*$signed(coeffs[0][0]);
                pixels_green[0][1] <= $signed({1'b0, cached_pixels[0][1][10:5]})*$signed(coeffs[0][1]);
                pixels_green[0][2] <= $signed({1'b0, cached_pixels[0][2][10:5]})*$signed(coeffs[0][2]);
                pixels_green[1][0] <= $signed({1'b0, cached_pixels[1][0][10:5]})*$signed(coeffs[1][0]);
                pixels_green[1][1] <= $signed({1'b0, cached_pixels[1][1][10:5]})*$signed(coeffs[1][1]);
                pixels_green[1][2] <= $signed({1'b0, cached_pixels[1][2][10:5]})*$signed(coeffs[1][2]);
                pixels_green[2][0] <= $signed({1'b0, cached_pixels[2][0][10:5]})*$signed(coeffs[2][0]);
                pixels_green[2][1] <= $signed({1'b0, cached_pixels[2][1][10:5]})*$signed(coeffs[2][1]);
                pixels_green[2][2] <= $signed({1'b0, cached_pixels[2][2][10:5]})*$signed(coeffs[2][2]);

                pixels_blue[0][0] <= $signed({1'b0, cached_pixels[0][0][4:0]})*$signed(coeffs[0][0]);
                pixels_blue[0][1] <= $signed({1'b0, cached_pixels[0][1][4:0]})*$signed(coeffs[0][1]);
                pixels_blue[0][2] <= $signed({1'b0, cached_pixels[0][2][4:0]})*$signed(coeffs[0][2]);
                pixels_blue[1][0] <= $signed({1'b0, cached_pixels[0][0][4:0]})*$signed(coeffs[1][0]);
                pixels_blue[1][1] <= $signed({1'b0, cached_pixels[0][1][4:0]})*$signed(coeffs[1][1]);
                pixels_blue[1][2] <= $signed({1'b0, cached_pixels[0][2][4:0]})*$signed(coeffs[1][2]);
                pixels_blue[2][0] <= $signed({1'b0, cached_pixels[0][0][4:0]})*$signed(coeffs[2][0]);
                pixels_blue[2][1] <= $signed({1'b0, cached_pixels[0][1][4:0]})*$signed(coeffs[2][1]);
                pixels_blue[2][2] <= $signed({1'b0, cached_pixels[0][2][4:0]})*$signed(coeffs[2][2]);

                red <= $signed(pixels_red[0][0] + pixels_red[0][1] + pixels_red[0][2] + pixels_red[1][0] + pixels_red[1][1] + pixels_red[1][2] + pixels_red[2][0] + pixels_red[2][1] + pixels_red[2][2]) >>> $signed(shift);
                green <= $signed(pixels_green[0][0] + pixels_green[0][1] + pixels_green[0][2] + pixels_green[1][0] + pixels_green[1][1] + pixels_green[1][2] + pixels_green[2][0] + pixels_green[2][1] + pixels_green[2][2]) >>> $signed(shift);
                blue <= $signed(pixels_blue[0][0] + pixels_blue[0][1] + pixels_blue[0][2] + pixels_blue[1][0] + pixels_blue[1][1] + pixels_blue[1][2] + pixels_blue[2][0] + pixels_blue[2][1] + pixels_blue[2][2]) >>> $signed(shift);

                if (red < 0) begin
                    line_out[15:11] <= 5'b00000;
                end
                else begin
                    line_out[15:11] <= red[4:0];
                end
                if (green < 0) begin
                    line_out[10:5] <= 6'b000000;
                end
                else begin
                    line_out[10:5] <= green[5:0];
                end
                if (blue < 0) begin
                    line_out[4:0] <= 5'b00000;
                end
                else begin
                    line_out[4:0] <= blue[4:0];
                end
            
            
        end
    end
endmodule

`default_nettype wire
