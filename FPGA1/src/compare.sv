`timescale 1ns / 1ps
`default_nettype none

module compare (
                input wire clk_in,
                input wire rst_in,
                input wire [10:0] x_com_in, // from COM module
                input wire [9:0]  y_com_in, // from COM module
                input wire com_valid_in,
                input wire tabulate_in,
                input wire [10:0] hcount, // from filter
                input wire [9:0]  vcount, // from filter 
                input wire [5:0] y_pixel, // from rgb_to_ycrcb
                input wire [7:0] curr_pixel, // current pixel at that spot in BRAM
                input wire [1:0] color_select, // from switches, routed in toplevel
                input wire write_erase_select, // from switches, routed in toplevel
                input wire [7:0] pixel_from_bram,
                output logic [16:0] pixel_addr_bram_check,
                output logic [7:0] pixel_out_forbram,
                output logic [16:0] pixel_addr_forbram, // TODO: check this width
                output logic valid_pixel_forbram);

    //state params
    localparam RESTING = 2'b00;
    localparam COM_RECEIVED = 2'b01;
    localparam COMPARING = 2'b10;

    //color params
    localparam YELLOW = 8'b11000000; // 11 is MSBs indicates that it is written on
    localparam PINK = 8'b11000001;
    localparam GREEN = 8'b11000010;
    localparam RED = 8'b11000011;
    
    logic [2:0] state;

    logic [3:0][5:0] pixel_buffer;
    logic [3:0][16:0] address_buffer;

    logic [10:0] x_com_current;
    logic [9:0] y_com_current;
    logic [16:0] com_address;
    logic [8:0][16:0] com_addresses_around;
    logic com_received_flag;

    assign pixel_addr_bram_check = address_buffer[0];
    assign pixel_out_forbram = pixel_buffer[3];
    assign pixel_addr_forbram = address_buffer[3];

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= RESTING;
            valid_pixel <= 0;
            pixel_buffer[3] <= 0;
            pixel_buffer[2] <= 0;
            pixel_buffer[1] <= 0;
            pixel_buffer[0] <= 0;
            address_buffer[3] <= 0;
            address_buffer[2] <= 0;
            address_buffer[1] <= 0;
            address_buffer[0] <= 0;
        end
        else begin
            case (state)
                RESTING: begin
                    valid_pixel <= 0;
                    pixel_buffer[3] <= 0;
                    pixel_buffer[2] <= 0;
                    pixel_buffer[1] <= 0;
                    pixel_buffer[0] <= 0;
                    address_buffer[3] <= 0;
                    address_buffer[2] <= 0;
                    address_buffer[1] <= 0;
                    address_buffer[0] <= 0;
                    if (com_valid_in) begin
                        state <= COM_RECEIVED;
                        com_received_flag <= 1;
                        x_com_current <= x_com_in;
                        y_com_current <= y_com_in;
                        com_address <= (y_com_in)*320 + x_com_in;
                    end
                end
                COM_RECEIVED: begin
                    if (hcount == 0 && vcount == 0) begin
                        state <= COMPARING;
                    end
                    if (com_received_flag) begin // find the 9 ixels around the COM
                        com_received_flag <= 0;
                        if (x_com_in > 0 && x_com_in < 319) begin
                            if (y_com_in > 0 && y_com_in < 239) begin
                                com_addresses_around[0] <= (y_com_in -1)*320 + (x_com_in -1);
                                com_addresses_around[1] <= (y_com_in -1)*320 + (x_com_in);
                                com_addresses_around[2] <= (y_com_in -1)*320 + (x_com_in +1);
                                com_addresses_around[3] <= (y_com_in)*320 + (x_com_in -1);
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= (y_com_in)*320 + (x_com_in +1);
                                com_addresses_around[6] <= (y_com_in +1)*320 + (x_com_in -1);
                                com_addresses_around[7] <= (y_com_in +1)*320 + (x_com_in);
                                com_addresses_around[8] <= (y_com_in +1)*320 + (x_com_in +1);
                            end
                            else if (y_com_in == 0) begin
                                com_addresses_around[0] <= 16'h12C01; // pixel outside frame
                                com_addresses_around[1] <= 16'h12C01;
                                com_addresses_around[2] <= 16'h12C01;
                                com_addresses_around[3] <= (y_com_in)*320 + (x_com_in -1);
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= (y_com_in)*320 + (x_com_in +1);
                                com_addresses_around[6] <= (y_com_in +1)*320 + (x_com_in -1);
                                com_addresses_around[7] <= (y_com_in +1)*320 + (x_com_in);
                                com_addresses_around[8] <= (y_com_in +1)*320 + (x_com_in +1);
                            end
                            else if (y_com_in == 239) begin
                                com_addresses_around[0] <= (y_com_in -1)*320 + (x_com_in -1);
                                com_addresses_around[1] <= (y_com_in -1)*320 + (x_com_in);
                                com_addresses_around[2] <= (y_com_in -1)*320 + (x_com_in +1);
                                com_addresses_around[3] <= (y_com_in)*320 + (x_com_in -1);
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= (y_com_in)*320 + (x_com_in +1);
                                com_addresses_around[6] <= 16'h12C01;
                                com_addresses_around[7] <= 16'h12C01;
                                com_addresses_around[8] <= 16'h12C01;
                            end
                        end else if (x_com_in == 319) begin // this means we are in the rightmost line
                            if (y_com_in > 0 && y_com_in < 239) begin
                                com_addresses_around[0] <= (y_com_in -1)*320 + (x_com_in -1);
                                com_addresses_around[1] <= (y_com_in -1)*320 + (x_com_in);
                                com_addresses_around[2] <= 16'h12C01;
                                com_addresses_around[3] <= (y_com_in)*320 + (x_com_in -1);
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= 16'h12C01;
                                com_addresses_around[6] <= (y_com_in +1)*320 + (x_com_in -1);
                                com_addresses_around[7] <= (y_com_in +1)*320 + (x_com_in);
                                com_addresses_around[8] <= 16'h12C01;
                            end
                            else if (y_com_in == 0) begin
                                com_addresses_around[0] <= 16'h12C01; // pixel outside frame
                                com_addresses_around[1] <= 16'h12C01;
                                com_addresses_around[2] <= 16'h12C01;
                                com_addresses_around[3] <= (y_com_in)*320 + (x_com_in -1);
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= 16'h12C01;
                                com_addresses_around[6] <= (y_com_in +1)*320 + (x_com_in -1);
                                com_addresses_around[7] <= (y_com_in +1)*320 + (x_com_in);
                                com_addresses_around[8] <= 16'h12C01;
                            end
                            else if (y_com_in == 239) begin
                                com_addresses_around[0] <= (y_com_in -1)*320 + (x_com_in -1);
                                com_addresses_around[1] <= (y_com_in -1)*320 + (x_com_in);
                                com_addresses_around[2] <= 16'h12C01;
                                com_addresses_around[3] <= (y_com_in)*320 + (x_com_in -1);
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= 16'h12C01;
                                com_addresses_around[6] <= 16'h12C01;
                                com_addresses_around[7] <= 16'h12C01;
                                com_addresses_around[8] <= 16'h12C01;
                            end
                        end else if (x_com_in == 0) begin // this means we are in the leftmost line
                            if (y_com_in > 0 && y_com_in < 239) begin
                                com_addresses_around[0] <= 16'h12C01;
                                com_addresses_around[1] <= (y_com_in -1)*320 + (x_com_in);
                                com_addresses_around[2] <= (y_com_in -1)*320 + (x_com_in +1);
                                com_addresses_around[3] <= 16'h12C01;
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= (y_com_in)*320 + (x_com_in +1);
                                com_addresses_around[6] <= 16'h12C01;
                                com_addresses_around[7] <= (y_com_in +1)*320 + (x_com_in);
                                com_addresses_around[8] <= (y_com_in +1)*320 + (x_com_in +1);
                            end
                            else if (y_com_in == 0) begin
                                com_addresses_around[0] <= 16'h12C01; // pixel outside frame
                                com_addresses_around[1] <= 16'h12C01;
                                com_addresses_around[2] <= 16'h12C01;
                                com_addresses_around[3] <= 16'h12C01;
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= (y_com_in)*320 + (x_com_in +1);
                                com_addresses_around[6] <= 16'h12C01;
                                com_addresses_around[7] <= (y_com_in +1)*320 + (x_com_in);
                                com_addresses_around[8] <= (y_com_in +1)*320 + (x_com_in +1);
                            end
                            else if (y_com_in == 239) begin
                                com_addresses_around[0] <= 16'h12C01;
                                com_addresses_around[1] <= (y_com_in -1)*320 + (x_com_in);
                                com_addresses_around[2] <= (y_com_in -1)*320 + (x_com_in +1);
                                com_addresses_around[3] <= 16'h12C01;
                                com_addresses_around[4] <= (y_com_in)*320 + (x_com_in);
                                com_addresses_around[5] <= (y_com_in)*320 + (x_com_in +1);
                                com_addresses_around[6] <= 16'h12C01;
                                com_addresses_around[7] <= 16'h12C01;
                                com_addresses_around[8] <= 16'h12C01;
                            end
                        end
                    end
                end
                COMPARING: begin
                    if (com_valid_in) begin // new COM received, need to calculate with the new one instead
                        state <= COM_RECEIVED;
                        com_received_flag <= 1;
                        x_com_current <= x_com_in;
                        y_com_current <= y_com_in;
                        com_address <= (y_com_in)*320 + x_com_in;
                    end
                    // PIPELINE
                    address_buffer[1] <= address_buffer[0];
                    address_buffer[2] <= address_buffer[1];
                    address_buffer[3] <= address_buffer[2];

                    // CALCULATE
                    address_buffer[0] <= (hcount)*320 + vcount;

                    // CHECK PIXEL - request current pixel from BRAM and check with COM
                    // assign pixel_addr_bram_check = address_buffer[0]; this is declared above to send the pixel to the bram
                    pixel_buffer[2] <= pixel_buffer[1];
                    if (address_buffer[1] == com_addresses_around[0] || address_buffer[1] == com_addresses_around[1] || address_buffer[1] == com_addresses_around[2] || address_buffer[1] == com_addresses_around[3] || address_buffer[1] == com_addresses_around[4] || address_buffer[1] == com_addresses_around[5] || address_buffer[1] == com_addresses_around[6] || address_buffer[1] == com_addresses_around[7] || address_buffer[1] == com_addresses_around[8]) begin
                        address_in_com_flag <= 1;
                    end else begin
                        address_in_com_flag <= 0;
                    end

                    // RECEIVE pixel_from_bram
                    if (write_erase_select == 0) begin // write mode
                        if (pixel_from_bram[7:6] == 2'b11) begin // colored pixel - don't write over it!
                            valid_pixel_forbram <= 0; 
                            pixel_buffer[3] <= pixel_buffer[2];
                        end
                        else begin
                            valid_pixel_forbram <= 1;
                            if (address_in_com_flag) begin // write colored pixel
                                case (color_select)
                                    2'b00: begin
                                        pixel_buffer[3] <= YELLOW;
                                    end
                                    2'b01: begin
                                        pixel_buffer[3] <= PINK;
                                    end
                                    2'b10: begin
                                        pixel_buffer[3] <= GREEN;
                                    end
                                    2'b11: begin
                                        pixel_buffer[3] <= RED;
                                    end
                                endcase
                            end
                            else begin // write regular pixel
                                pixel_buffer[3] <= pixel_buffer[2];
                            end
                        end
                        pixel_buffer[3] <= pixel_buffer[2];
                    end else begin // erase mode
                        if (pixel_from_bram[7:6] == 2'b11) begin // colored pixel, either erase it or leave it
                            if (address_in_com_flag) begin // erase it
                                valid_pixel_forbram <= 1;
                                pixel_buffer[3] <= pixel_buffer[2];
                            end
                            else begin // leave it
                                valid_pixel_forbram <= 0;
                                pixel_buffer[3] <= pixel_buffer[2];
                            end
                        end
                        else begin
                            valid_pixel_forbram <= 1;
                            pixel_buffer[3] <= pixel_buffer[2];
                        end
                    end

                    // STORE these assignments were made above, stores from the last spot in the buffers with the valid value set before!
                    // assign pixel_out_forbram = pixel_buffer[3];
                    // assign pixel_addr_forbram = address_buffer[3];

                end
            endcase          
        end
        
        
    end

endmodule

`default_nettype wire
