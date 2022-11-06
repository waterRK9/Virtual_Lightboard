`default_nettype none
`timescale 1ns / 1ps

module ethernet_packager (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,

    output logic stall,
    output logic phy_txen,
    output logic [1:0] phy_txd
);
// Value declarations
parameter DEST_ADDR_DIBIT = 2'b11; 
parameter SOURCE_ADDR = 48'h69695A065491; //note: flip to MSB/ LSb order if using

parameter PREAMBLE_DIBITS = 32;
parameter ADDR_DIBITS = 24;
parameter MIN_DATA_DIBITS = 320 * 4;
parameter CRC_DIBITS = 16;
parameter IFG_PERIOD = 48; // Interpacket-Gap: standard minimum is time to send 96 bits (43 cycles)

logic [3:0] state;

logic [2:0] byte_bit_counter;

logic [12:0] dibit_counter;
logic [8:0] audio_counter;

typedef enum {Idle, SendPre, SendDestAddr, SendSourceAddr, SendData, SendTail} States;

// All modules (& associated logic) here
logic cksum_axiiv;
logic [31:0] cksum;
logic cksum_calculated;
crc32 crc32 (
    .clk(clk),
    .rst(rst),
    .axiiv(cksum_axiiv), //note: want to omit preamble, and sfd
    .axiid(phy_txd), 
    .axiov(cksum_calculated),
    .axiod(cksum)
);

// FSM below
always_ff @(posedge clk) begin
    if (rst) begin
        state <= Idle;
        stall <= 1'b1;
        byte_bit_counter <= 3'b0;
        audio_counter <= 9'b0;
        phy_txen <= 1'b0;
        phy_txd <= 2'b0;
        cksum_axiiv <= 0;
        dibit_counter <= 0;
    end else if begin
        case(state)
            Idle: begin //
                stall <= 1;
                byte_bit_counter <= 4'b0;
                audio_counter <= 9'b0;
                phy_txen <= 1'b0;
                phy_txd <= 2'b0;
                cksum_axiiv <= 1'b0;
                
                if (dibit_counter < IFG_PERIOD) dibit_counter <= dibit_counter + 1;
                else begin
                    dibit_counter <= 0;
                    state <= SendHead;
                end
            end
            SendPre: begin
                phy_txen <= 1;
                stall <= 1;
                cksum_axiiv <= 0;
                if (dibit_counter < PREAMBLE_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                    phy_txd <= 2'b01;
                end
                else if (dibit_counter == PREAMBLE_DIBITS) begin
                    phy_txd <= 2'b11;
                    dibit_counter <= 0;
                    state <= SendDestAddr;
                end
            end
            SendDestAddr: begin
                phy_txen <= 1;
                stall <= 1;
                cksum_axiiv <= 1;
                if (dibit_counter < ADDR_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                    phy_txd <= 2'b11;
                end
                else begin
                    dibit_counter <= 0;
                    state <= SendSourceAddr;
                end
            end
            SendSourceAddr: begin //note: lowkey, we don't look at the source_addr in the existing code, this is kind of a waste to actually format rn
                phy_txen <= 1;
                cksum_axiiv <= 1;
                if (dibit_counter < ADDR_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                    phy_txd <= 2'b00;        
                end else begin
                    dibit_counter <= 0;
                    state <= SendData;
                    stall <= 0;
                end
            end
            SendData: begin
                phy_txen <= 1;
                cksum_axiiv <= 1;
                stall <= 0;
                if (dibit_counter < MIN_DATA_DIBITS) begin
                    phy_txd <= axiid; //question: i sent out an axiiv signal from reverse_bit_order, what should I do with that?
                end else begin
                    phy_txd <= axiid;
                    dibit_counter <= 0;
                    state <= SendTail;
                    byte_bit_counter <= 0;
                end
            end
            SendTail: begin
                phy_txen <= 1;
                cksum_axiiv <= 0;
                stall <= 1;
                if (dibit_counter <= 6) begin 
                    phy_txd <= {cksum[25 + byte_bit_counter], cksum[24 + byte_bit_counter]};
                end else if (dibit_counter <= 14) begin 
                    phy_txd <= {cksum[17 + byte_bit_counter], cksum[16 + byte_bit_counter]};
                end else if (dibit_counter <= 22) begin 
                    phy_txd <= {cksum[9 + byte_bit_counter], cksum[8 + byte_bit_counter]};
                end else if (dibit_counter <= 30) begin
                    phy_txd <= {cksum[1 + byte_bit_counter], cksum[byte_bit_counter]};
                end

                if (byte_bit_counter == 6) byte_bit_counter <= 0;
                else byte_bit_counter <= byte_bit_counter + 2;

                if (dibit_counter < 30) dibit_counter <= dibit_counter + 1;
                else begin
                    dibit_counter <= 0;
                    state <= Idle;
                end

            end
            default:
        endcase
    end
end

endmodule

`default_nettype wire