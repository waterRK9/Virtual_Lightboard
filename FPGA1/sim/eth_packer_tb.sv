`default_nettype none

module eth_packer_tb;

    logic clk;
    logic rst;
    logic axiiv;
    logic [1:0] axiid;
    logic kill, done;

    eth_packer eth_packer (
    .clk(clk),
    .rst(rst),
    .axiiv(axiiv),
    .axiid(axiid),
    .done(done), 
    .kill(kill)
    );

    always begin
    #10;
    clk = !clk;
    end

    logic [31:0] cksum1 = 32'h1a3a_ccb2;
    logic [167:0] message1 = 168'h4261_7272_7921_2042_7265_616b_6661_7374_2074_696d65;


    initial begin
        $dumpfile("obj/eth_packer.vcd");
        $dumpvars(0, eth_packer_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;
        #10
        
        //Test 1: Stupid short message (8 dibits)
        for (int i = 0; i < 8; i = i + 1) begin
            axiiv = 1;
            axiid = i;
            #20;
        end
        for (int i = 0; i < 32; i = i + 1) begin
            axiiv = 1;
            axiid = 2'b01;
            #20;
        end
        for (int i = 0; i < 32; i = i + 1) begin
            axiiv = 0;
            axiid = 2'b01;
            #20;
        end
        #20;

        clk = 0;
        rst = 0;
        #20;
        rst = 1;
        #20;
        rst = 0;

        //Test 2: Long Boi w/ CRC
        for (int i = 0; i < 8; i = i + 1) begin
            axiiv = 0;
            axiid = i;
            #20;
        end
        for (int i = 166; i >= 0; i = i -2) begin
            axiiv = 1;
            axiid = {message1[i], message1[i+1]};
            #20;
        end
        for (int i = 30; i >= 0; i = i -2) begin
            axiiv = 1;
            axiid = {cksum1[i], cksum1[i+1]};
            #20;
        end
        for (int i = 0; i < 32; i = i + 1) begin
            axiiv = 0;
            axiid = 2'b01;
            #20;
        end
        #20;

        //Test 2: Long Boi w/o CRC
        for (int i = 0; i < 8; i = i + 1) begin
            axiiv = 0;
            axiid = i;
            #20;
        end
        for (int i = 166; i >= 0; i = i -2) begin
            axiiv = 1;
            axiid = {message1[i], message1[i+1]};
            #20;
        end
        // for (int i = 30; i >= 0; i = i -2) begin
        //     axiiv = 1;
        //     axiid = {cksum1[i], cksum1[i+1]};
        //     #20;
        // end
        for (int i = 0; i < 32; i = i + 1) begin
            axiiv = 0;
            axiid = 2'b01;
            #20;
        end
        #20;

        #40;
        $display("Finishing Sim");
        $finish;
    end

endmodule

`timescale 1ns / 1ps
`default_nettype wire