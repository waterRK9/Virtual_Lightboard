`timescale 1ns / 1ps
`default_nettype none

module compare (
                input wire clk_in,
                input wire rst_in,
                input wire [10:0] x_com_in, // from COM module
                input wire [9:0]  y_com_in, // from COM module
                input wire com_valid_in,
                input wire [10:0] hcount, // from filter
                input wire [9:0]  vcount, // from filter 
                input wire [5:0] y_pixel, // from rgb_to_ycrcb
                input wire [1:0] color_select, // from switches, routed in toplevel
                input wire write_erase_select, // from switches, routed in toplevel
                input wire [7:0] pixel_from_bram, // current pixel at that spot in BRAM
                input wire threshold_in,
                //output logic [16:0] pixel_addr_bram_check,
                output logic [7:0] pixel_for_bram, // pixel to write into the BRAM
                output logic [16:0] pixel_addr_forbram, // either the pixel that we want to check or the pixel that we want to store (depends on valid signal)
                output logic valid_pixel_forbram,
                //output logic [7:0] pixel_out_forvga,
                output logic pixelread_forvga_valid, // tells vga to read output of BRAM request because it is ready
                output logic pixeladdr_forvga_valid // tells vga to send address to read
            );

    //state params (outer FSM)
    localparam RESTING = 2'b00;
    localparam COM_RECEIVED = 2'b01;
    localparam COMPARING = 2'b10;

    //state params (inner FSM)
    localparam CALCULATE = 3'b000;
    localparam CHECK = 3'b001;
    localparam WAIT1 = 3'b010;
    localparam RECEIVE = 3'b011;
    localparam STORE = 3'b100;
    localparam WAIT2 = 3'b101;
    localparam VGAREAD = 3'b110;
    localparam WAIT3 = 3'b111;

    //color params
    localparam YELLOW = 8'b11000000; // 11 is MSBs indicates that it is written on
    localparam PINK = 8'b11000001;
    localparam GREEN = 8'b11000010;
    localparam RED = 8'b11000011;

    //for drawing threshold and crosshair
    localparam THRESHOLD_PIXEL = 8'b10000000;
    localparam CROSSHAIR_PIXEL = 8'b01000000;
    
    logic [1:0] outer_state;
    logic [2:0] inner_state;

    logic [10:0] x_com_current;
    logic [9:0] y_com_current;
    logic [16:0] com_address;
    logic [8:0][16:0] com_addresses_around;
    logic com_received_flag;
    logic address_in_com_flag;

    logic [10:0] curr_hcount;
    logic [9:0] curr_vcount;
    logic [7:0] pixel_yvalue;

    logic crosshair;
    assign crosshair = ((hcount == x_com_in) || (vcount == y_com_in));

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            inner_state <= CALCULATE;
            valid_pixel_forbram <= 0;
            curr_hcount <= 0;
            curr_vcount <= 0;
            pixel_yvalue <= 0;
            // resets com_addresses to the top left corner since no COM has been received yet
            com_addresses_around[0] <= 0;
            com_addresses_around[1] <= 0;
            com_addresses_around[2] <= 0;
            com_addresses_around[3] <= 0;
            com_addresses_around[4] <= 0;
            com_addresses_around[5] <= 0;
            com_addresses_around[6] <= 0;
            com_addresses_around[7] <= 0;
            com_addresses_around[8] <= 0;
            // com_addresses_around[9] <= 0;
            // com_addresses_around[10] <= 0;
            // com_addresses_around[11] <= 0;
            // com_addresses_around[12] <= 0;
            // com_addresses_around[13] <= 0;
            // com_addresses_around[14] <= 0;
            // com_addresses_around[15] <= 0;
            // com_addresses_around[16] <= 0;
            // com_addresses_around[17] <= 0;
            // com_addresses_around[18] <= 0;
            // com_addresses_around[19] <= 0;
            // com_addresses_around[20] <= 0;
            // com_addresses_around[21] <= 0;
            // com_addresses_around[22] <= 0;
            // com_addresses_around[23] <= 0;
            // com_addresses_around[24] <= 0;
        end
        else begin
            if (com_valid_in) begin // new COM received, need to calculate with the new one instead -- not sure about this?
                com_received_flag <= 1;
                x_com_current <= x_com_in;
                y_com_current <= y_com_in;
                com_address <= (y_com_in)*320 + x_com_in;
            end
            if (com_received_flag) begin // find the 9 pixels around the COM
                com_received_flag <= 0;
                if (x_com_in > 0 && x_com_in < 319) begin
                    if (y_com_in > 0 && y_com_in < 239) begin
                        com_addresses_around[0] <= com_address - 321;
                        com_addresses_around[1] <= com_address - 320;
                        com_addresses_around[2] <= com_address - 319;
                        com_addresses_around[3] <= com_address - 1;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= com_address + 1;
                        com_addresses_around[6] <= com_address + 319;
                        com_addresses_around[7] <= com_address + 320;
                        com_addresses_around[8] <= com_address + 321;
                    end
                    else if (y_com_in == 0) begin
                        com_addresses_around[0] <= 17'h12C01; // pixel outside frame
                        com_addresses_around[1] <= 17'h12C01;
                        com_addresses_around[2] <= 17'h12C01;
                        com_addresses_around[3] <= com_address - 1;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= com_address + 1;
                        com_addresses_around[6] <= com_address + 319;
                        com_addresses_around[7] <= com_address + 320;
                        com_addresses_around[8] <= com_address + 321;
                    end
                    else if (y_com_in == 239) begin
                        com_addresses_around[0] <= com_address - 321;
                        com_addresses_around[1] <= com_address - 320;
                        com_addresses_around[2] <= com_address - 319;
                        com_addresses_around[3] <= com_address - 1;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= com_address + 1;
                        com_addresses_around[6] <= 17'h12C01;
                        com_addresses_around[7] <= 17'h12C01;
                        com_addresses_around[8] <= 17'h12C01;
                    end
                end else if (x_com_in == 319) begin // this means we are in the rightmost line
                    if (y_com_in > 0 && y_com_in < 239) begin
                        com_addresses_around[0] <= com_address - 321;
                        com_addresses_around[1] <= com_address - 320;
                        com_addresses_around[2] <= 17'h12C01;
                        com_addresses_around[3] <= com_address - 1;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= 17'h12C01;
                        com_addresses_around[6] <= com_address + 319;
                        com_addresses_around[7] <= com_address + 320;
                        com_addresses_around[8] <= 17'h12C01;
                    end
                    else if (y_com_in == 0) begin
                        com_addresses_around[0] <= 17'h12C01; // pixel outside frame
                        com_addresses_around[1] <= 17'h12C01;
                        com_addresses_around[2] <= 17'h12C01;
                        com_addresses_around[3] <= com_address - 1;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= 17'h12C01;
                        com_addresses_around[6] <= com_address + 319;
                        com_addresses_around[7] <= com_address + 320;
                        com_addresses_around[8] <= 17'h12C01;
                    end
                    else if (y_com_in == 239) begin
                        com_addresses_around[0] <= com_address - 321;
                        com_addresses_around[1] <= com_address - 320;
                        com_addresses_around[2] <= 17'h12C01;
                        com_addresses_around[3] <= com_address - 1;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= 17'h12C01;
                        com_addresses_around[6] <= 17'h12C01;
                        com_addresses_around[7] <= 17'h12C01;
                        com_addresses_around[8] <= 17'h12C01;
                    end
                end else if (x_com_in == 0) begin // this means we are in the leftmost line
                    if (y_com_in > 0 && y_com_in < 239) begin
                        com_addresses_around[0] <= 17'h12C01;
                        com_addresses_around[1] <= com_address - 320;
                        com_addresses_around[2] <= com_address - 319;
                        com_addresses_around[3] <= 17'h12C01;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= com_address + 1;
                        com_addresses_around[6] <= 17'h12C01;
                        com_addresses_around[7] <= com_address + 320;
                        com_addresses_around[8] <= com_address + 321;
                    end
                    else if (y_com_in == 0) begin
                        com_addresses_around[0] <= 17'h12C01; // pixel outside frame
                        com_addresses_around[1] <= 17'h12C01;
                        com_addresses_around[2] <= 17'h12C01;
                        com_addresses_around[3] <= 17'h12C01;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= com_address + 1;
                        com_addresses_around[6] <= 17'h12C01;
                        com_addresses_around[7] <= com_address + 320;
                        com_addresses_around[8] <= com_address + 321;
                    end
                    else if (y_com_in == 239) begin
                        com_addresses_around[0] <= 17'h12C01;
                        com_addresses_around[1] <= com_address - 320;
                        com_addresses_around[2] <= com_address - 319;
                        com_addresses_around[3] <= 17'h12C01;
                        com_addresses_around[4] <= com_address;
                        com_addresses_around[5] <= com_address + 1;
                        com_addresses_around[6] <= 17'h12C01;
                        com_addresses_around[7] <= 17'h12C01;
                        com_addresses_around[8] <= 17'h12C01;
                    end
                end
            end
            case(inner_state) 
                
                CALCULATE: begin
                    
                    // calculate address
                    
                    if (curr_hcount != hcount || curr_vcount != vcount) begin // this means that we have received a new pixel 
                        inner_state <= CHECK;
                        pixel_yvalue <= {2'b00, y_pixel}; // save the pixel throughout a full loop
                        curr_hcount <= hcount;
                        curr_vcount <= vcount;
                        pixel_addr_forbram <= (vcount)*320 + hcount;
                    end
                    
                    // read pixel for VGA -- this will happen in top level and be synced to this FSM
                    pixelread_forvga_valid <= 0;
                end
                CHECK: begin
                    inner_state <= WAIT1;
                    if (pixel_addr_forbram == com_addresses_around[0] || pixel_addr_forbram == com_addresses_around[1] || pixel_addr_forbram == com_addresses_around[2] || pixel_addr_forbram == com_addresses_around[3] || pixel_addr_forbram == com_addresses_around[4] || pixel_addr_forbram == com_addresses_around[5] || pixel_addr_forbram == com_addresses_around[6] || pixel_addr_forbram == com_addresses_around[7] || pixel_addr_forbram == com_addresses_around[8]) begin
                        address_in_com_flag <= 1;
                    end else begin
                        address_in_com_flag <= 0;
                    end
                end
                WAIT1: begin
                    inner_state <= RECEIVE;
                end
                RECEIVE: begin
                    inner_state <= STORE;
                    if (write_erase_select == 0) begin // write mode
                        if (pixel_from_bram[7:6] == 2'b11) begin // colored pixel - don't write over it!
                            valid_pixel_forbram <= 0; 
                            pixel_for_bram <= pixel_from_bram;
                        end
                        else begin
                            valid_pixel_forbram <= 1;
                            if (address_in_com_flag) begin // write colored pixel
                                case (color_select)
                                    2'b00: begin
                                        pixel_for_bram <= YELLOW;
                                    end
                                    2'b01: begin
                                        pixel_for_bram <= PINK;
                                    end
                                    2'b10: begin
                                        pixel_for_bram <= GREEN;
                                    end
                                    2'b11: begin
                                        pixel_for_bram <= RED;
                                    end
                                endcase
                            end
                            else begin // write regular pixel
                                pixel_for_bram <= (threshold_in == 1)? THRESHOLD_PIXEL: (crosshair == 1)? CROSSHAIR_PIXEL: pixel_yvalue;
                            end
                        end
                    end else begin // erase mode
                        if (pixel_from_bram[7:6] == 2'b11) begin // colored pixel, either erase it or leave it
                            if (threshold_in == 1) begin // erase it
                                valid_pixel_forbram <= 1;
                                pixel_for_bram <= (threshold_in == 1)? THRESHOLD_PIXEL: (crosshair == 1)? CROSSHAIR_PIXEL: pixel_yvalue;
                            end
                            else begin // leave it
                                valid_pixel_forbram <= 0;
                                pixel_for_bram <= pixel_from_bram;
                            end
                        end
                        else begin // write regular pixel
                            valid_pixel_forbram <= 1;
                            pixel_for_bram <= (threshold_in == 1)? THRESHOLD_PIXEL: (crosshair == 1)? CROSSHAIR_PIXEL: pixel_yvalue;
                        end
                    end
                end
                STORE: begin
                    // pixel for BRAM is written in this state
                    inner_state <= WAIT2;
                    valid_pixel_forbram <= 0;
                end
                WAIT2: begin
                    inner_state <= VGAREAD;
                    pixeladdr_forvga_valid <= 1;
                end
                VGAREAD: begin
                    inner_state <= WAIT3;
                    pixeladdr_forvga_valid <= 0;
                end
                WAIT3: begin
                    inner_state <= CALCULATE;
                    pixelread_forvga_valid <= 1; // tells vga module to read the pixel for the VGA
                end
            endcase        
        end
    end

endmodule

`default_nettype wire
