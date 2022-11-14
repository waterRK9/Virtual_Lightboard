`default_nettype none
`timescale 1ns / 1ps

module image_audio_splitter(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiod,

    output logic adder_axiov,
    output logic pixel_axiov,
    output logic audio_axiov,

    output logic [23:0] addr,
    output logic [7:0] pixel,
    output logic [7:0] audio
);

typedef enum {Idle, RecieveAddr, RecievePixels, RecieveAudio} States;
// since pixels recieved MSB, LSb, I can do something like {axiid, pixel[5:0]} I think
//except for addr, which is 24 long, so i want to keep recieving for 24 and then send out in one cycle, while reading in a new byte
// combinational logic time?

always_ff @(posedge clk) begin
    if (rst) begin
        state <= Idle;

    end else begin
        case(state)
        Idle: state <= Idle;
        endcase
    end
end

endmodule

`default_nettype wire