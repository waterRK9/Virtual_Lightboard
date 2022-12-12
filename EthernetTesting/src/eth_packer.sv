`default_nettype none
`timescale 1ns / 1ps

module eth_packer (
    input wire cancelled,
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

parameter PREAMBLE_DIBITS = 32; // 7 * 4
parameter ADDR_DIBITS = 24 - 1; 
parameter MIN_DATA_DIBITS = 24 - 1; //(320 * 4) - 1;
parameter CRC_DIBITS = 16 - 1;
parameter IFG_PERIOD = 48 -1; // Interpacket-Gap: standard minimum is time to send 96 bits (43 cycles)
parameter LEN_DIBITS = 8 - 1;

logic [3:0] state;

logic [2:0] byte_bit_counter;

logic [12:0] dibit_counter;
logic [8:0] audio_counter;

typedef enum {Idle = 0,
              SendPre = 1, 
              SendSFD = 2,
              SendDestAddr, 
              SendSourceAddr, 
              SendLength,
              SendData, 
              SendTail} States;

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

// ila_0 {
//     .clk(clk),
//     .probe0(phy_txen),  //1
//     .probe1(phy_txd), //2
//     .probe2(cksum), //32
//     .probe3(stall), //1 
//     .probe4(state) //4
// };

always_comb begin
    if (state > 2 && state < 7) begin
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
            if (dibit_counter == 0) phy_txen = 0;
            else phy_txen = 1'b1;
            
            if (dibit_counter < PREAMBLE_DIBITS) phy_txd = 2'b01; 
            else phy_txd = 2'b11;
            stall = 1;
        end
        // SendSFD: begin
        //     phy_txen = 1'b1;
        //     if (dibit_counter == 0) phy_txd = 2'b01;
        //     else if (dibit_counter == 1) phy_txd = 2'b11;
        //     else if (dibit_counter == 2 || dibit_counter == 3) phy_txd = 2'b01;
        //     else phy_txd = 0;
        //     stall = 1;
        // end
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
            // phy_txd = 2'b01; //note: FPGA2 doesn't care about length either right now, we could potentially use it to error check for drops
            if (dibit_counter == 7) phy_txd = 2'b01;
            else if (dibit_counter == 3 || dibit_counter == 4 || dibit_counter == 6) phy_txd = 2'b11;
            else if (dibit_counter == 0 || dibit_counter == 1 || dibit_counter == 2) phy_txd = 2'b10;
            else phy_txd = 2'b0;

            if (dibit_counter > 6) stall = 0;
            else stall = 1;
            // 1010_1011_1100_1101 ABCD
        end
        SendData: begin
            phy_txen = 1'b1;
            phy_txd = axiid; //coming from reverse_bit_order
            stall = 0;
        end
        SendTail: begin
            phy_txen = 1'b1;
            if (dibit_counter <= 3) phy_txd = {cksum[30 - byte_bit_counter], cksum[31 - byte_bit_counter]};
            else if (dibit_counter <= 7) phy_txd = {cksum[22 - byte_bit_counter], cksum[23 - byte_bit_counter]};
            else if (dibit_counter <= 11) phy_txd = {cksum[14 - byte_bit_counter], cksum[15 - byte_bit_counter]};
            else if (dibit_counter <= 15) phy_txd = {cksum[6 - byte_bit_counter], cksum[7 - byte_bit_counter]};
            else phy_txd = {cksum[byte_bit_counter], cksum[1 + byte_bit_counter]}; //to get rid of latch
            stall = 1;
        end
        default: begin
            phy_txen = 1'b0;
            phy_txd = 2'b0;
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
        if (cancelled) state <= Idle;
        else begin 
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
                    $display("Sending SFD Now");
                end
            end
            // SendSFD: begin
            //     if (dibit_counter < 3) begin
            //         dibit_counter <= dibit_counter + 1;
            //     end
            //     else if (dibit_counter == 3) begin
            //         dibit_counter <= 0;
            //         state <= SendDestAddr;
            //         $display("Sending Dest Now");
            //     end
            // end
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
                    state <= Idle;
                    $display("Sending Tail Now");
                    byte_bit_counter <= 0;
                end
            end
            // SendTail: begin
            //     if (byte_bit_counter == 6) byte_bit_counter <= 0;
            //     else byte_bit_counter <= byte_bit_counter + 2;

            //     if (dibit_counter < CRC_DIBITS) begin
            //         crc32rst <= 0;
            //         dibit_counter <= dibit_counter + 1;
            //     end else begin
            //         dibit_counter <= 0;
            //         state <= Idle;
            //         crc32rst <= 1;
            //     end
            // end
        endcase
        end
    end
end

endmodule

`default_nettype wire