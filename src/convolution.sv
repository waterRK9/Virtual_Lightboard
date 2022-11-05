`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter K_SELECT=0)(
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

    kernels #(
        .K_SELECT(K_SELECT) // kernel to select
    ) kernel (
        .rst_in(rst_in),
        .coeffs(coeffs),
        .shift(shift)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= RESTING;
            // data_valid_out <= 0;
            // hcount_out <= 0;
            // vcount_out <= 0;
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
            
            // case (state)
            //     RESTING: begin
            //         data_valid_out <= 0;
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
                // state <= MULTADD;
            
                        // work with old pixels that we already have
                        // CHANNEL MULTIPLY
                        // for (int i = 0; i < 3; i = i + 1) begin
                        //     for (int j = 0; j < 3; j = j + 1) begin
                        //         pixels_red[i][j] <= $signed({1'b0, cached_pixels[i][j][15:11]})*$signed({1'b0, coeffs[i][j]});
                        //         pixels_green[i][j] <= $signed({1'b0, cached_pixels[i][j][10:5]})*$signed({1'b0, coeffs[i][j]});
                        //         pixels_blue[i][j] <= $signed({1'b0, cached_pixels[i][j][4:0]})*$signed({1'b0, coeffs[i][j]});
                        //     end
                        // end
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

            
                            // shift in new pixel values
                            
                        //     hcount_out <= hcount_in - 2;
                        //     vcount_out <= vcount_in - 2;
                        // end
                    // end
                    // MULTADD: begin
                    //     state <= SHIFTCHECK;
                        // ADD ALL THE PIXELS FROM EACH ARRAY TOGETHER
                red <= $signed(pixels_red[0][0] + pixels_red[0][1] + pixels_red[0][2] + pixels_red[1][0] + pixels_red[1][1] + pixels_red[1][2] + pixels_red[2][0] + pixels_red[2][1] + pixels_red[2][2]) >>> $signed(shift);
                green <= $signed(pixels_green[0][0] + pixels_green[0][1] + pixels_green[0][2] + pixels_green[1][0] + pixels_green[1][1] + pixels_green[1][2] + pixels_green[2][0] + pixels_green[2][1] + pixels_green[2][2]) >>> $signed(shift);
                blue <= $signed(pixels_blue[0][0] + pixels_blue[0][1] + pixels_blue[0][2] + pixels_blue[1][0] + pixels_blue[1][1] + pixels_blue[1][2] + pixels_blue[2][0] + pixels_blue[2][1] + pixels_blue[2][2]) >>> $signed(shift);
                    // end
                    // SHIFTCHECK: begin
                    //     state <= RESTING;
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
    // Your code here!

    /* Note that the coeffs output of the kernels module
     * is packed in all dimensions, so coeffs should be 
     * defined as `logic signed [2:0][2:0][7:0] coeffs`
     *
     * This is because iVerilog seems to be weird about passing 
     * signals between modules that are unpacked in more
     * than one dimension - even though this is perfectly
     * fine Verilog.
     */
    

    // always_ff @(posedge clk_in) begin
    //   // Make sure to have your output be set with registered logic!
    //   // Otherwise you'll have timing violations.
    //   line_out <= {r, g, 1'b0, b};
    // end
endmodule

`default_nettype wire
