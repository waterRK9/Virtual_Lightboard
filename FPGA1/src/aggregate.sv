`default_nettype none

module aggregate (
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire [1:0] axiid,
    output logic axiov, 
    output logic [31:0] axiod
);


logic [31:0] buffer1, buffer2;
logic [8:0] counter1, counter2;
logic done;

always_comb begin
    if (rst) begin
        axiov = 0;
        axiod = 0;
    end if (axiiv) begin
        if (counter2 == 16) begin
            axiov = 1;
        end else begin
            axiov = 0;
        end
    end else begin
        axiov = 0;
    end
    axiod = buffer1;
end

always_ff @(posedge clk) begin
    if (rst) begin
        buffer1 <= 0;
        buffer2 <= 0;
        counter1 <= 0;
        counter2 <= 0;
        done <= 0;
    end else begin
        if (axiiv) begin
            if (counter1 < 16 && !done) begin
                buffer1 <= {buffer1, axiid};
                counter1 <= counter1 + 1;
            end else if (counter2 < 15) begin
                buffer2 <= {buffer2, axiid};
                counter2 <= counter2 + 1;
            end else if (counter2 == 15) begin
                buffer2 <= {buffer2, axiid};
                counter2 <= counter2 + 1;
                done <= 1;
            end else if (counter2 == 16) begin
                counter2 <= 17;
            end
        end else begin
            buffer1 <= 0;
            buffer2 <= 0;
            counter1 <= 0;
            counter2 <= 0;
            done <= 0;
        end
    end
end

endmodule

`timescale 1ns / 1ps
`default_nettype wire