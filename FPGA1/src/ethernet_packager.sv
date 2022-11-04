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

parameter [7:0] premable7 = 8'b01010101; //flip to MSB/ LSb order
parameter [7:0] sfd = 8'b11010101; //leave in MSB/MSb order
parameter [47:0] dest_addr = 48'hFFFFFFFFFFFF; //flip to MSB/ LSb order
parameter [47:0] source_addr = 48'h69695A065491; //flip to MSB/ LSb order

logic [1:0] state;

logic [2:0] byte_bit_counter;

logic [8:0] pixel_counter;
logic [8:0] audio_counter;

typedef enum {Idle, SendHead, SendData, SendTail} States;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= Idle;
        stall <= 1;
        byte_bit_counter <= 0;
        pixel_counter <= 0;
        audio_counter <= 0;
        axiov <= 0;
        axiod <= 0;
    end else if begin
        case(state)
            Idle: begin //
                stall <= 1;
                byte_bit_counter <= 0;
                audio_counter <= 0;
                axiov <= 0;
                axiod <= 0;
                // Interpacket-Gap: standard minimum is time to send 96 bits (43 cycles)
                if (pixel_counter < 50) pixel_counter <= pixel_counter + 1;
                else begin
                    pixel_counter <= 0;
                    state <= SendHead;
                end
            end
            SendHead: begin
            end
            SendData: begin
            end
            SendTail: begin
            end
            default:
        endcase
    end
end

endmodule

`default_nettype wire