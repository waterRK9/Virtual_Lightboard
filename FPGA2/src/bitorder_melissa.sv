`timescale 1ns / 1ps
`default_nettype none

module bitorder (
    input wire clk,
    input wire rst,

    input wire axiiv,
    input wire [1:0] axiid,

    output logic axiov, //valid signal
    output logic [1:0] axiod //data bus
);

    logic [2:0] state;

    localparam RESTING = 3'b000;
    localparam LOADINGBYTE1 = 3'b001;
    localparam LOADINGBYTE2 = 3'b010;
    localparam FINISHINGRET1 = 3'b011;
    localparam FINISHINGRET2 = 3'b100;
    
    logic [5:0] buffer1;
    logic [5:0] buffer2;

    logic [1:0] b1counter;
    logic [1:0] b2counter;

    logic byteone;

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= RESTING;
            axiov <= 1'b0;
            axiod <= 2'b00;
            buffer1 <= 8'b0;
            buffer2 <= 8'b0;
            b1counter <= 0;
            b2counter <= 0;
            byteone <= 1;
        end
        else begin
            case (state)
                RESTING: begin
                    axiov <= 1'b0;
                    axiod <= 2'b00;
                    byteone <= 1;
                    if (axiiv) begin
                        state <= LOADINGBYTE1;
                        buffer1 <= {buffer1[3:0], axiid}; // load in first value
                        b1counter <= b1counter + 1;
                    end
                    else begin // if no valid inpit
                        buffer1 <= 8'b0;
                        buffer2 <= 8'b0;
                        b1counter <= 0;
                        b2counter <= 0;
                    end
                end
                LOADINGBYTE1: begin
                    b2counter <= 0;
                    if (axiiv) begin
                        if (b1counter == 3) begin // state change
                            state <= LOADINGBYTE2;
                            axiov <= 1;
                            axiod <= axiid; 
                            if (byteone) begin // no longer on first byte
                                byteone <= 0;
                            end
                        end
                        else begin
                            buffer1 <= {buffer1[3:0], axiid}; // no matter what, load the next 2 bits in
                            b1counter <= b1counter + 1; // increment counter every time new val loaded in 
                            if (byteone == 0) begin //we've already loaded in a first byte into BYTE2
                                axiov <= 1;
                                case (b1counter) // need to produce output axiod
                                    2'b00: axiod <= buffer2[1:0];
                                    2'b01: axiod <= buffer2[3:2];
                                    2'b10: axiod <= buffer2[5:4];
                                    // 2'b11: axiod <= buffer2[7:6];
                                endcase
                            end
                        end
                        
                    end
                    else begin // axiiv == 0
                        if (byteone && b1counter < 3) begin // nothing to return
                            state <= RESTING;
                        end
                        else if (byteone == 0 && b1counter < 3) begin // need to finish returning buffer2 values 
                            b1counter <= b1counter + 1;
                            case (b1counter) // need to produce output axiod
                                2'b00: axiod <= buffer2[1:0];
                                2'b01: axiod <= buffer2[3:2];
                                2'b10: axiod <= buffer2[5:4];
                            endcase
                            if (b1counter == 2) begin
                                state <= RESTING;
                            end
                        end
                        else begin // need to finish returning buffer2 values and then return buffer1 values -- THIS CASE CANT HAPPEN
                            
                        end
                    end
                end
                LOADINGBYTE2: begin
                    b1counter <= 0;
                    if (axiiv) begin
                        if (b2counter == 3) begin
                            state <= LOADINGBYTE1;
                            axiov <= 1;
                            axiod <= axiid;
                        end
                        else begin
                            buffer2 <= {buffer2[3:0], axiid}; // no matter what, load the next 2 bits in
                            b2counter <= b2counter + 1; // increment counter every time new val loaded in 
                            case (b2counter) // need to produce output axiod
                                2'b00: axiod <= buffer1[1:0];
                                2'b01: axiod <= buffer1[3:2];
                                2'b10: axiod <= buffer1[5:4];
                                // 2'b11: axiod <= buffer1[7:6];
                            endcase
                        end
                        
                        if (b2counter == 3) begin // state change
                            state <= LOADINGBYTE1;
                        end
                    end
                    else begin // axiiv == 0
                        if (b2counter < 3) begin // need to finish returning byte 1
                            b2counter <= b2counter + 1;
                            case (b2counter) // need to produce output axiod
                                2'b00: axiod <= buffer1[1:0];
                                2'b01: axiod <= buffer1[3:2];
                                2'b10: axiod <= buffer1[5:4];
                                // 2'b11: axiod <= buffer1[7:6];
                            endcase
                            if (b2counter == 2) begin
                                state <= RESTING;
                            end
                        end
                    end
                end
            endcase
        end
        
    end
    


endmodule

`default_nettype wire