`default_nettype none

module ether (
    input wire clk,
    input wire rst,
    input wire [1:0] rxd,
    input wire crsdv,
    output logic axiov, // is this two bit or one bit?
    output logic [1:0] axiod
);

logic [5:0] counter;
logic [2:0] state;
typedef enum {Initial=0, VerifyPre=1, VerifyLast=2, Transmitting=3, Waiting=4} states;
always_ff @(posedge clk) begin
    if (rst) begin
        axiov <= 0;
        axiod <= 0;
        state <= Initial;
        counter <= 0;
    end else begin
        case (state) 
        Initial: begin
            if (crsdv == 1 && rxd == 2'b01) state <= VerifyPre;
            counter <= 1;
        end
        VerifyPre: begin
            if (rxd == 2'b01) begin
                if (counter < 30) begin
                    counter <= counter + 1;
                end else if (counter >= 30) begin
                    counter <= 0;
                    state <= VerifyLast;
                end
            end else state <= Waiting;
        end
        VerifyLast: begin
            if (rxd == 2'b11) begin
                state <= Transmitting;
            end
            else state <= Waiting;
        end
        Transmitting: begin
            if (crsdv) begin
                axiov <= crsdv;
                axiod <= rxd;
            end else begin
                axiov <= 0;
                axiod <= 0;
                state <= Initial;
            end
        end
        Waiting: begin
            if (crsdv == 0) state <= Initial;
        end
        endcase
    end
end

endmodule

`timescale 1ns / 1ps
`default_nettype wire