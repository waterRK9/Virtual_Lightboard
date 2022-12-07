`default_nettype none

// scans ethernet header's destination address and verifies it matches the FPGA's MAC address
module firewall (
    input wire clk,
    input wire rst,
    input wire [1:0] axiid,
    input wire axiiv,
    output logic axiov, 
    output logic [1:0] axiod
);

parameter [47:0] DEFMAC = 48'hFFFFFFFFFFFF;
parameter [47:0] FPGAMAC = 48'h69695A065491;

logic [47:0] macAddress;
logic transmitting;
logic [7:0]counter;

always_comb begin
    if (rst) begin
        axiov = 0;
        axiod = 0;
    end else if (axiiv == 1) begin
        // counting through source address and label before passing through axii
        if (counter >= 56 && ({macAddress} == DEFMAC || {macAddress} == FPGAMAC)) axiov = 1;
        else axiov = 0;
    end else begin
        axiov = 0;
    end
    axiod = axiid;
end

always_ff @(posedge clk) begin
    if (rst) begin
        counter <= 0;
        macAddress <= 0;
    end else if (axiiv) begin
        if (counter < 24) macAddress <= {macAddress, axiid};

        if (counter <= 56) counter <= counter + 1;;
    end
    else begin
        macAddress <= 0;
        counter <= 0;
    end
end


endmodule

`timescale 1ns / 1ps
`default_nettype wire