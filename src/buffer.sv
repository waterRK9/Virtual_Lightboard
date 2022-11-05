`timescale 1ns / 1ps
`default_nettype none


module buffer (
    input wire clk_in, //system clock
    input wire rst_in, //system reset

    input wire [10:0] hcount_in, //current hcount being read
    input wire [9:0] vcount_in, //current vcount being read
    input wire [15:0] pixel_data_in, //incoming pixel
    input wire data_valid_in, //incoming  valid data signal

    output logic [2:0][15:0] line_buffer_out, //output pixels of data (blah make this packed)
    output logic [10:0] hcount_out, //current hcount being read
    output logic [9:0] vcount_out, //current vcount being read
    output logic data_valid_out //valid data out signal
  );

  //state params
  localparam RESTING = 2'b01;
  localparam PULLING = 2'b10;
  localparam RETURNING = 2'b11;

  logic [1:0] state;

  logic [15:0] pixel0_out;
  logic [15:0] pixel1_out;
  logic [15:0] pixel2_out;
  logic [15:0] pixel3_out;
  logic [15:0] pixel0_out2;
  logic [15:0] pixel1_out2;
  logic [15:0] pixel2_out2;
  logic [15:0] pixel3_out2;

  logic [3:0] current_line;

  // logic [2:0][10:0] hcount_pipe;
  // logic [2:0] data_valid_pipe;

  // assign hcount_out = hcount_pipe[2];

  logic [2:0] data_valid_pipeline;
  logic [2:0][10:0] hcount_pipeline;
  logic [1:0][9:0] vcount_pipeline;

  logic[9:0] vcount_buff;

  
  
  assign data_valid_out = data_valid_pipeline[2];
  assign hcount_out = hcount_pipeline[2];
  assign vcount_out = vcount_pipeline[1];

  logic we0;
  logic we1;
  logic we2;
  logic we3;

  assign we0 = current_line[0]&data_valid_in;
  assign we1 = current_line[1]&data_valid_in;
  assign we2 = current_line[2]&data_valid_in;
  assign we3 = current_line[3]&data_valid_in;

  // Your code here!
  always_ff @ (posedge clk_in) begin
    if (rst_in) begin // RESET
      line_buffer_out[0] <= 16'b0; // reset all array values to zero
      line_buffer_out[1] <= 16'b0;
      line_buffer_out[2] <= 16'b0;
      current_line <= 4'b1000;
      // data_valid_pipeline[0] <= 0;
      // data_valid_pipeline[1] = 0;
      // data_valid_pipeline[2] = 0;
      // state <= RESTING;
    end
    else begin
      data_valid_pipeline <= {data_valid_pipeline[1:0], data_valid_in};
      hcount_pipeline <= {hcount_pipeline[1:0], hcount_in};
      vcount_pipeline <= {vcount_pipeline[0], vcount_buff};
      if (data_valid_in) begin
      // case (state)
        // RESTING: begin
        //   data_valid_out <= 0;

          // if (data_valid_in) begin
            // state <= PULLING;
            // hcount_out <= hcount_in;
            if (hcount_in == 0) begin // working in a new line
              current_line <= {current_line[0], current_line[3:1]};
            end
            if (vcount_in < 2) begin
              vcount_buff <= 239 - vcount_in;
            end
            else begin
              vcount_buff <= vcount_in - 2;
            end
                      
          // end
        // end
        // PULLING: begin
        //   state <= RETURNING;
        // end
        // RETURNING: begin
        //   state <= RESTING;
          // data_valid_out <= 1;
          
        // end
      // endcase
      end

      if (current_line[0]) begin
        line_buffer_out[0] <= pixel1_out;
        line_buffer_out[1] <= pixel2_out;
        line_buffer_out[2] <= pixel3_out;
      end
      else if (current_line[1]) begin
        line_buffer_out[0] <= pixel2_out;
        line_buffer_out[1] <= pixel3_out;
        line_buffer_out[2] <= pixel0_out;
      end
      else if (current_line[2]) begin
        line_buffer_out[0] <= pixel3_out;
        line_buffer_out[1] <= pixel0_out;
        line_buffer_out[2] <= pixel1_out;
      end
      else begin
        line_buffer_out[0] <= pixel0_out;
        line_buffer_out[1] <= pixel1_out;
        line_buffer_out[2] <= pixel2_out;
      end
    end
  end


  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_0 (
    .addra(hcount_in),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(hcount_in),   // Port B address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(pixel_data_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Clock
    .wea(we0),       // Port A write enable (set to 1 because we want to write to RAM)
    .web(we0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(pixel0_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(pixel0_out2)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_1 (
    .addra(hcount_in),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(hcount_in),   // Port B address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(pixel_data_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Clock
    .wea(we1),       // Port A write enable
    .web(we1),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(pixel1_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(pixel1_out2)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_2 (
    .addra(hcount_in),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(hcount_in),   // Port B address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(pixel_data_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Clock
    .wea(we2),       // Port A write enable
    .web(we2),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(pixel2_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(pixel2_out2)    // Port B RAM output data, width determined from RAM_WIDTH
  );

  xilinx_true_dual_port_read_first_1_clock_ram #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(320),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE") // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  ) line_3 (
    .addra(hcount_in),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(hcount_in),   // Port B address bus, width determined from RAM_DEPTH
    .dina(pixel_data_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(pixel_data_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),     // Clock
    .wea(we3),       // Port A write enable
    .web(we3),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),     // Port A output reset (does not affect memory contents)
    .rstb(rst_in),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(pixel3_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb(pixel3_out2)    // Port B RAM output data, width determined from RAM_WIDTH
  );



endmodule


`default_nettype wire
