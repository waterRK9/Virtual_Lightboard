///////////////////////////////////////////////////////////////////////////////
//
// 31-tap FIR filter, 8-bit signed data, 10-bit signed coefficients.
// ready is asserted whenever there is a new sample on the X input,
// the Y output should also be sampled at the same time.  Assumes at
// least 32 clocks between ready assertions.  Note that since the
// coefficients have been scaled by 2**10, so has the output (it's
// expanded from 8 bits to 18 bits).  To get an 8-bit result from the
// filter just divide by 2**10, ie, use Y[17:10].
//
///////////////////////////////////////////////////////////////////////////////

module fir31(
  input  clk_in,rst_in,ready_in,
  input signed [7:0] x_in,
  output logic signed [17:0] y_out
);
  logic signed [9:0] coeff_out;
  logic [7:0] sample [31:0];  // 32 element array each 8 bits wide
  logic [4:0] offset; //pointer for the array! (5 bits because 32 elements in above array! Do not make larger)
  logic [4:0] index; //for accumulator

  logic [4:0] sample_num;
  logic signed [17:0] accumulator;
  logic [4:0] probe;
  coeffs31 coeffs (.index_in(index),.coeff_out(coeff_out));
  
  always_ff @(posedge clk_in) begin
    // if (ready_in) y_out <= {x_in,10'd0};
    if (rst_in) begin
      for (int i = 0; i < 32; i = i+1) begin
        sample[i] <= 8'b0;
      end

      offset <= 0;
      y_out <= 0;
      index <= 0;
      accumulator <= 0;
    end else begin
      if (ready_in) begin
        offset <= offset + 1; //allow this to overflow and wrap
        sample[offset] <= x_in;
        y_out <= y_out;
        index <= 0;
      end else begin
        index <= (index == 30)? index: index + 1;
        sample_num <= offset-index;
        probe <= sample[sample_num];
        accumulator <= (index == 30)? accumulator: accumulator + ($signed(coeff_out) * $signed(sample[sample_num]));
        y_out <= (index == 30)? accumulator: y_out;
      end
    end
  end
endmodule

///////////////////////////////////////////////////////////////////////////////
//
// Coefficients for a 31-tap low-pass FIR filter with Wn=.125 (eg, 3kHz for a
// 48kHz sample rate).  Since we're doing integer arithmetic, we've scaled
// the coefficients by 2**10
// Matlab command: round(fir1(30,.125)*1024)
//
///////////////////////////////////////////////////////////////////////////////

module coeffs31(
  input  [4:0] index_in,
  output logic signed [9:0] coeff_out
);
  logic signed [9:0] coeff;
  assign coeff_out = coeff;
  // tools will turn this into a 31x10 ROM
  always_comb begin
    case (index_in)
      5'd0:  coeff = -10'sd1;
      5'd1:  coeff = -10'sd1;
      5'd2:  coeff = -10'sd3;
      5'd3:  coeff = -10'sd5;
      5'd4:  coeff = -10'sd6;
      5'd5:  coeff = -10'sd7;
      5'd6:  coeff = -10'sd5;
      5'd7:  coeff = 10'sd0;
      5'd8:  coeff = 10'sd10;
      5'd9:  coeff = 10'sd26;
      5'd10: coeff = 10'sd46;
      5'd11: coeff = 10'sd69;
      5'd12: coeff = 10'sd91;
      5'd13: coeff = 10'sd110;
      5'd14: coeff = 10'sd123;
      5'd15: coeff = 10'sd128;
      5'd16: coeff = 10'sd123;
      5'd17: coeff = 10'sd110;
      5'd18: coeff = 10'sd91;
      5'd19: coeff = 10'sd69;
      5'd20: coeff = 10'sd46;
      5'd21: coeff = 10'sd26;
      5'd22: coeff = 10'sd10;
      5'd23: coeff = 10'sd0;
      5'd24: coeff = -10'sd5;
      5'd25: coeff = -10'sd7;
      5'd26: coeff = -10'sd6;
      5'd27: coeff = -10'sd5;
      5'd28: coeff = -10'sd3;
      5'd29: coeff = -10'sd1;
      5'd30: coeff = -10'sd1;
      default: coeff = 10'hXXX;
    endcase
  end
endmodule