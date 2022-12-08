`default_nettype none

module cksum (
    input wire clk,
    input wire rst,
    input wire [1:0] axiid,
    input wire axiiv,
    output logic done, //compiled incoming data
    output logic kill //high if crc32 calculation fails
);

logic axiov;
logic [31:0] axiod;
logic crc32rst;

crc32 cksum (
    .clk(clk), 
    .rst(crc32rst),

	.axiiv(axiiv),
	.axiid(axiid),

	.axiov(axiov),
	.axiod(axiod)
);

logic [1:0] state;
typedef enum {Initial, Recieving, Idle} State;

always_ff @(posedge clk) begin
    if (rst) begin
        done <= 0;
        kill <= 0;
        crc32rst <= 1;
        state <= Initial;
    end else begin
        case(state)
        Initial: begin
            if (axiiv) begin
                state <= Recieving;
            end
            crc32rst <= 0;
            done <= 0;
            kill <= 0;
        end
        Recieving: begin
            if (axiiv == 1) begin
                state <= Recieving;
                crc32rst <= 0;
                done <= 0;
                kill <= 0;
            end else begin
                if (axiod != 32'h38_fb_22_84) begin
                    kill <= 1;
                end
                done <= 1;
                crc32rst <= 1;
                state <= Idle;
            end
        end
        Idle: begin
            if (axiiv) begin
                state <= Recieving;
                kill <= 0;
                done <= 0;
            end
            crc32rst <= 0;
        end
        endcase
    end 

end


endmodule

`timescale 1ns / 1ps
`default_nettype wire