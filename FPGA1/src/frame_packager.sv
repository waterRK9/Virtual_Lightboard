`default_nettype none
`timescale 1ns / 1ps

module frame_packager(
    input wire clk,
    input wire rst,
    input wire addr_axiiv,
    input wire [23:0] addr_axiid,
    input wire pixel_axiiv,
    input wire [7:0] pixel_axiid,

    output logic axiov, //for wea on BRAM
    output logic [23:0] addr_axiod,
    output logic [7:0] pixel_axiod
);

always_ff @(posedge clk) begin
    if (rst) begin
        axiov <= 0;
        addr_axiod <= 0;
        pixel_axiod <= 0;
    end else begin
        if (addr_axiiv) addr_axiod <= addr_axiid - 1; //to offset the +1 for when first pixel is sent in
        else addr_axiod <= addr_axiod + 1;

        if (pixel_axiiv) begin
            pixel_axiod <= pixel_axiid;
            axiov <= 1'b1;
        end else axiov <= 1'b0;
    end
end

endmodule

`default_nettype wire