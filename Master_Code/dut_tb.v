`timescale 1ns/1ps
module dut_tb;
    reg clk = 0, rst;
    reg [7:0] w_data;
    reg [6:0] addr;
    reg r_w, start;
    wire [7:0] r_data;
    wire done, SCL, SDA;

    Top dut (
        .rst(rst), .clk(clk), .w_data(w_data), .addr(addr),
        .r_w(r_w), .start (start), .r_data(r_data), .done(done),
        .SCL(SCL),.SDA (SDA));

    // 100 MHz clock
    always #5 clk = ~clk;

    pullup(SDA);
    initial begin
        rst    = 1'b1;
        start  = 1'b0;
        w_data = 8'h00;
        addr   = 7'h00;
        r_w    = 1'b0;
        @(posedge clk);
        @(posedge clk);
        rst = 1'b0;
        @(posedge clk);
        @(posedge clk);

        // Test 1: Write full byte A5 to address 80
        addr   = 7'd80;
        w_data = 8'hA5;
        r_w    = 1'b0;
        start  = 1'b1;

        // hold start until FSM leaves IDLE (state != 0)
        wait (dut.Master.state != 4'd0);
        start = 1'b0;

        // wait for the full 8-bit transaction to finish
        wait (done == 1'b1);
        #50;

        //Test 2: Read a byte from address 80 
        addr  = 7'd80;
        r_w   = 1'b1;
        start = 1'b1;
        wait (dut.Master.state != 4'd0);
        start = 1'b0;
        wait (done == 1'b1);
        #50;

        // ---- Test 3: WRITE full byte 0x33 to address 0x50 ----
        addr   = 7'd80;
        w_data = 8'h33;
        r_w    = 1'b0;
        start  = 1'b1;
        wait (dut.Master.state != 4'd0);
        start = 1'b0;
        wait (done == 1'b1);
        #50;

        $stop;
    end

    initial begin
        $timeformat(-9, 0, " ns", 6);
        $monitor("time=%t rst=%b start=%b r_w=%b addr=%h w_data=%b SCL=%b SDA=%b done=%b r_data=%b",
                  $time, rst, start, r_w, addr, w_data, SCL, SDA, done, r_data);
    end

endmodule
