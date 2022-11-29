`default_nettype none

module bitorder (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,
    output logic axiov, 
    output logic [1:0] axiod
);

logic [1:0] state;
logic [4:0] bitCounter1, bitCounter2;
logic [7:0] buffer1;
logic [7:0] buffer2;
logic flag;

typedef enum {RecieveNull=0, SendRecieve, RecieveSend, SendNull} states;

always @(posedge clk) begin
    if (rst) begin
        axiov <= 0;
        axiod <= 0;
        bitCounter1 <= 0;
        bitCounter2 <= 0;
        buffer1 <= 0;
        buffer2 <= 0;
        state <= RecieveNull;
        flag <= 0;
    end else begin
        case (state) 
        RecieveNull: begin
            axiov <= 0;
            if (axiiv == 1) begin
                case(bitCounter1) 
                0: begin
                    buffer1[1:0] <= axiid;
                    bitCounter1 <= 2;
                end
                2: begin
                    buffer1[3:2] <= axiid;
                    bitCounter1 <= 4;
                end
                4: begin
                    buffer1[5:4] <= axiid;
                    bitCounter1 <= 6;
                end
                6: begin
                    buffer1[7:6] <= axiid;
                    bitCounter1 <= 0;
                    state <= SendRecieve;
                end
                endcase
            end 
        end
        SendRecieve: begin
            axiov <= 1;
            if (axiiv == 1) begin
                case(bitCounter1) 
                0: begin
                    axiod <= buffer1[7:6];
                    buffer2[1:0] <= axiid;
                    bitCounter1 <= 2;
                    bitCounter2 <= 2;
                end
                2: begin
                    axiod <= buffer1[5:4];
                    buffer2[3:2] <= axiid;
                    bitCounter1 <= 4;
                    bitCounter2 <= 4;
                end
                4: begin
                    axiod <= buffer1[3:2];
                    buffer2[5:4] <= axiid;
                    bitCounter1 <= 6;
                    bitCounter2 <= 6;
                end
                6: begin
                    axiod <= buffer1[1:0];
                    buffer2[7:6] <= axiid;
                    bitCounter1 <= 0;
                    bitCounter2 <= 0;
                    state <= RecieveSend;
                end
                endcase
            end else begin
                case(bitCounter1) 
                0: begin
                    axiod <= buffer1[7:6];
                    bitCounter1 <= 2;
                    state <= SendNull;
                end
                2: begin
                    axiod <= buffer1[5:4];
                    bitCounter1 <= 4;
                    state <= SendNull;
                end
                4: begin
                    axiod <= buffer1[3:2];
                    bitCounter1 <= 6;
                    state <= SendNull;
                end
                6: begin
                    axiod <= buffer1[1:0];
                    bitCounter1 <= 0;
                    state <= RecieveNull;
                end
                endcase
                bitCounter2 <= 0;
                flag <= 1'b0;
            end
        end
        RecieveSend: begin
            axiov <= 1;
            if (axiiv == 1) begin
                case(bitCounter1) 
                0: begin
                    axiod <= buffer2[7:6];
                    buffer1[1:0] <= axiid;
                    bitCounter1 <= 2;
                    bitCounter2 <= 2;
                end
                2: begin
                    axiod <= buffer2[5:4];
                    buffer1[3:2] <= axiid;
                    bitCounter1 <= 4;
                    bitCounter2 <= 4;
                end
                4: begin
                    axiod <= buffer2[3:2];
                    buffer1[5:4] <= axiid;
                    bitCounter1 <= 6;
                    bitCounter2 <= 6;
                end
                6: begin
                    axiod <= buffer2[1:0];
                    buffer1[7:6] <= axiid;
                    bitCounter1 <= 0;
                    bitCounter2 <= 0;
                    state <= SendRecieve;
                end
                endcase
            end else begin
                case(bitCounter2) 
                0: begin
                    axiod <= buffer2[7:6];
                    bitCounter2 <= 2;
                    state <= SendNull;
                end
                2: begin
                    axiod <= buffer2[5:4];
                    bitCounter2 <= 4;
                    state <= SendNull;
                end
                4: begin
                    axiod <= buffer2[3:2];
                    bitCounter2 <= 6;
                    state <= SendNull;
                end
                6: begin
                    axiod <= buffer2[1:0];
                    bitCounter2 <= 0;
                    state <= RecieveNull;
                end
                endcase
                bitCounter1 <= 0;
                flag <= 1'b1;
            end
        end
        SendNull: begin
            if (flag == 0) begin
                case(bitCounter1) 
                0: begin
                    axiod <= buffer1[7:6];
                    bitCounter1 <= 2;
                end
                2: begin
                    axiod <= buffer1[5:4];
                    bitCounter1 <= 4;
                end
                4: begin
                    axiod <= buffer1[3:2];
                    bitCounter1 <= 6;
                end
                6: begin
                    axiod <= buffer1[1:0];
                    bitCounter1 <= 0;
                    state <= RecieveNull;
                end
                endcase
            end else if (flag == 1) begin
                case(bitCounter2) 
                0: begin
                    axiod <= buffer2[7:6];
                    bitCounter2 <= 2;
                end
                2: begin
                    axiod <= buffer2[5:4];
                    bitCounter2 <= 4;
                end
                4: begin
                    axiod <= buffer2[3:2];
                    bitCounter2 <= 6;
                end
                6: begin
                    axiod <= buffer2[1:0];
                    bitCounter2 <= 0;
                    state <= RecieveNull;
                end
                endcase
            end else begin
                axiov <= 0;
                state <= RecieveNull;
            end
        end
        endcase
    end
end

endmodule
`timescale 1ns / 1ps
`default_nettype wire