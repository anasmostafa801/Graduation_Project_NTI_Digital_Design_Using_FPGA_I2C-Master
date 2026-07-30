module counter #(parameter MAX = 255, UP = 1) (
    input wire clk,
    input wire rst,
	input wire en,
    output reg [$clog2(MAX+1)-1:0] cnt
 );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= (UP ?  0 : MAX);
        end 
        else if (en) begin
            if (UP) begin
                if (cnt == MAX)
                    cnt <= 0;
                else
                    cnt <= cnt + 1;
            end 
            else begin
                if (cnt == 0)
                    cnt <= MAX;
                else
                    cnt <= cnt - 1;
            end
        end
    end
endmodule
