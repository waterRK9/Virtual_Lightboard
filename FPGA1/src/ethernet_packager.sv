`default_nettype none
`timescale 1ns / 1ps

module reverse_bit_order(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic stall,
    output logic axiov,
    output logic [1:0] axiod
);

logic [1:0] state;

logic [2:0] byte_bit_counter;

logic [8:0] pixel_counter;
logic [8:0] audio_counter;

typedef enum {SendHead, SendData, SendTail} States;

always_ff @(posedge clk) begin
end

endmodule

`default_nettype wire