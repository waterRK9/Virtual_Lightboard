`default_nettype none
`timescale 1ns / 1ps

module eth_packer (
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

parameter PREAMBLE_DIBITS = 32 - 1;
parameter ADDR_DIBITS = 24 - 1;
parameter MIN_DATA_DIBITS = 20 - 1; //(320 * 4) - 1;
parameter CRC_DIBITS = 16 - 1;
parameter IFG_PERIOD = 48 -1; // Interpacket-Gap: standard minimum is time to send 96 bits (43 cycles)
parameter LEN_DIBITS = 8 - 1;

logic [3:0] state;

logic [2:0] byte_bit_counter;

logic [12:0] dibit_counter;
logic [8:0] audio_counter;

typedef enum {Idle = 0,
              SendPre = 1, 
              SendDestAddr = 2, 
              SendSourceAddr = 3, 
              SendLength = 4,
              SendData = 5, 
              SendTail = 6} States;

// All modules (& associated logic) here
logic crc32rst;
logic cksum_axiiv;
logic [31:0] cksum;
logic cksum_calculated;
crc32 crc32 (
    .clk(clk),
    .rst(crc32rst),
    .axiiv(cksum_axiiv), //note: want to omit preamble, and sfd
    .axiid(phy_txd), 
    .axiov(cksum_calculated),
    .axiod(cksum)
);
always_comb begin
    if (state > 1 && state < 6) begin
        cksum_axiiv = 1;
    end else begin
        cksum_axiiv = 0;
    end

    case(state)
        Idle:begin
            phy_txen = 1'b0;
            phy_txd = 2'b0;
            stall = 1;
        end
        SendPre: begin
            phy_txen = 1'b1;
            if (dibit_counter < PREAMBLE_DIBITS) phy_txd = 2'b01; 
            else if (dibit_counter == PREAMBLE_DIBITS) phy_txd = 2'b11; 
            stall = 1;
        end
        SendDestAddr: begin
            phy_txen = 1'b1;
            phy_txd = 2'b11; //broadcast all
            stall = 1;
        end
        SendSourceAddr: begin
            phy_txen = 1'b1;
            phy_txd = 2'b10; //hardcode to random source address, FPGA2 doesn't care
            stall = 1;
        end
        SendLength: begin
            phy_txen = 1'b1;
            phy_txd = 2'b01; //note: FPGA2 doesn't care about length either right now, we could potentially use it to error check for drops
            stall = 1;
        end
        SendData: begin
            phy_txen = 1'b1;
            phy_txd = axiid; //coming from reverse_bit_order
            stall = 0;
        end
        SendTail: begin
            phy_txen = 1'b1;
            if (dibit_counter <= 3) begin 
                phy_txd = {cksum[25 + byte_bit_counter], cksum[24 + byte_bit_counter]};
            end else if (dibit_counter <= 7) begin 
                phy_txd = {cksum[17 + byte_bit_counter], cksum[16 + byte_bit_counter]};
            end else if (dibit_counter <= 11) begin 
                phy_txd = {cksum[9 + byte_bit_counter], cksum[8 + byte_bit_counter]};
            end else if (dibit_counter <= 15) begin
                phy_txd = {cksum[1 + byte_bit_counter], cksum[byte_bit_counter]};
            end
            stall = 1;
        end
    endcase
end

// FSM below
always_ff @(posedge clk) begin
    if (rst) begin
        state <= Idle;
        byte_bit_counter <= 3'b0;
        audio_counter <= 9'b0;
        crc32rst <= 1;
        dibit_counter <= 0;
    end else begin
        case(state)
            Idle: begin //
                byte_bit_counter <= 4'b0;
                audio_counter <= 9'b0;
                crc32rst <= 0;
                
                if (dibit_counter < IFG_PERIOD) begin
                    dibit_counter <= dibit_counter + 1;
                end else begin
                    dibit_counter <= 0;
                    state <= SendPre;
                    $display("Sending Pre Now");
                end
            end
            SendPre: begin
                if (dibit_counter < PREAMBLE_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                end
                else if (dibit_counter == PREAMBLE_DIBITS) begin
                    dibit_counter <= 0;
                    state <= SendDestAddr;
                    $display("Sending Dest Now");
                end
            end
            SendDestAddr: begin
                crc32rst <= 0;
                if (dibit_counter < ADDR_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                end else begin
                    dibit_counter <= 0;
                    state <= SendSourceAddr;
                    $display("Sending Source Now");
                end
            end
            SendSourceAddr: begin //note: lowkey, we don't look at the source_addr in the existing code, this is kind of a waste to actually format rn
                crc32rst <= 0;
                if (dibit_counter < ADDR_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                end else begin
                    dibit_counter <= 0;
                    state <= SendLength;
                    $display("Sending Length Now");
                end
            end
            SendLength: begin //question: do I actually want to send anything here? I don't use this field
                crc32rst <= 0;
                if (dibit_counter < LEN_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                end else begin
                    dibit_counter <= 0;
                    state <= SendData;
                    $display("Sending Data Now");
                end
            end
            SendData: begin
                crc32rst <= 0;
                if (dibit_counter < MIN_DATA_DIBITS) begin
                    dibit_counter <= dibit_counter + 1;
                end else begin
                    dibit_counter <= 0;
                    state <= SendTail;
                    $display("Sending Tail Now");
                    byte_bit_counter <= 0;
                end
            end
            SendTail: begin
                if (byte_bit_counter == 6) byte_bit_counter <= 0;
                else byte_bit_counter <= byte_bit_counter + 2;

                if (dibit_counter < CRC_DIBITS) begin
                    crc32rst <= 0;
                    dibit_counter <= dibit_counter + 1;
                end else begin
                    dibit_counter <= 0;
                    state <= Idle;
                    crc32rst <= 1;
                end

            end
        endcase
    end
end

endmodule

`default_nettype wire