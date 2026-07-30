
module Master #(parameter DIVIDER = 255)(
	input wire clk,
	input wire rst,
	input wire [7:0] w_data,
	input wire [6:0] addr,
	input wire r_w,
	input wire start,
	output wire [7:0] r_data,
	output wire done,
	output wire scl,
	inout sda 
);
	localparam IDLE = 4'd0, 
               START = 4'd1, 
               STOP = 4'd2, 
               ACK_I = 4'd3, 
               DATA_W = 4'd4, 
               ADDR_W = 4'd5, 
               ADDR_R = 4'd6, 
               ACK_O = 4'd7, 
               DATA_R = 4'd8,
	           RESTART = 4'd9;

    reg sda_en, sda_out;
    reg cnt_rst, scl_out, scl_en;
	reg [3:0] state, next_state;
    reg [1:0] ack_in_ctr;
    reg in_flag;
	reg dataw_flag;
	reg restart_out;
	reg  [7:0] rdata_temp;
	wire [$clog2(DIVIDER+1)-1:0] clk_div;	
    wire [2:0] bit_cnt;
    wire bit_cnt_a;
    wire rst_true = rst || (state == STOP);
    wire [7:0] addrw = {addr,{1'b0}};
	wire [7:0] addrr = {addr,{1'b1}};


    //The clock Divider Counter
	counter #(.MAX(DIVIDER), .UP(1)) clk_div_cnt (
	          .clk(clk), .rst(rst_true), .en(1'b1), .cnt(clk_div));
   //The 8_bit down Counter
	counter #(.MAX(4'd8), .UP(0)) eight_bit_dn_cnt (
	        .clk(!scl), .rst(rst_true || cnt_rst),
	        .en((state == ADDR_W) || (state == DATA_W) || (state == ADDR_R) || (state == DATA_R)),
	        .cnt({bit_cnt_a,bit_cnt}));
   //Tri_State_Logic(Open_Drain)
   assign sda = sda_en ? sda_out : 1'bz;
	
    //SCL generator Logic
	always @(posedge clk, posedge rst_true) begin
	if(rst_true)
		scl_out <= 1'b1;
	else if((clk_div == 0) && scl_en)
		scl_out <= !scl_out;
    end
	assign scl = scl_out;
	
    //State_Registers_FSM
	always @(posedge clk, posedge rst) begin
	if  (rst) 
		state <= IDLE;
	else if (clk_div == 0)
		state <= next_state;
    end
   
   //next_state_logic
	always @(*)begin
	case(state)
		IDLE:  next_state = start ? START : IDLE;
		START: next_state = ADDR_W;
		ADDR_W:next_state = ((bit_cnt == 3'b0) && scl) ? ACK_I : ADDR_W;
		ACK_I: begin
		    case(ack_in_ctr)
			    2'b00: next_state = scl ? DATA_W : ACK_I;
			    2'b01: next_state = scl ? STOP : ACK_I;
			    2'b10: next_state = scl ? RESTART : ACK_I;
			    2'b11: next_state = scl ? DATA_R : ACK_I;
	        endcase
	    end
		DATA_W:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_I : DATA_W;
		STOP:	next_state = IDLE;
		ADDR_R:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_I : ADDR_R;
		DATA_R:	next_state = ((bit_cnt == 3'b0) && scl) ? ACK_O : DATA_R;
		ACK_O:	next_state = scl ? STOP : ACK_O;
		RESTART:next_state = scl ? ADDR_R : RESTART;
		default:next_state = IDLE;
    endcase
end

  //output_moore_logic
	always @(*)begin
	    ack_in_ctr = 2'b00;
	    cnt_rst = 1'b0;
	    case(state)
		    IDLE: begin 
		        scl_en = 1'b0;
		        sda_en = 1'b1;
		        sda_out = 1'b1;
	        end	
		    START: begin
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = 1'b0;
		    end
		    ADDR_W: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = addrw[bit_cnt];
	        end	
		    ACK_I: begin 
		        cnt_rst = 1'b1;
		        scl_en = 1'b1;
		        sda_en = 1'b0;
		        ack_in_ctr = (sda) ? 2'b01 : (r_w ? (in_flag ? 2'b11 : 2'b10) : (dataw_flag ? 2'b01 : 2'b00));
	        end	
		    DATA_W: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = w_data[bit_cnt];
	        end	
		    STOP: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = 1'b0;
	        end
		    ADDR_R: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = addrr[bit_cnt];
	        end	
		    DATA_R: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b0;
	        end	
		    ACK_O: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = 1'b0;
	        end	
		    RESTART: begin 
		        scl_en = 1'b1;
		        sda_en = 1'b1;
		        sda_out = !restart_out;
	        end	
        endcase
    end
    

    //moore logic for associated with the protocol
	always @(negedge scl,posedge rst_true) begin
		if(rst_true) 
            rdata_temp<= 8'b0;
		else if(state == DATA_R)	
            rdata_temp[bit_cnt]<= sda;
    end
	always @(negedge clk,posedge rst_true) begin
		if(rst_true) 
            restart_out <= 1'b0;
		else if(state == RESTART && (clk_div == ((DIVIDER+1) >> 1)) && scl)	
            restart_out <= 1'b1;
        end
	always @(negedge scl,posedge rst_true) begin
		if(rst_true) 
            in_flag <= 1'b0;
		else if(state == ADDR_R)	
            in_flag <= 1'b1;
    end
	always @(negedge scl,posedge rst_true) begin
		if(rst_true) 
            dataw_flag <= 1'b0;
		else if(state == DATA_W)	
            dataw_flag <= 1'b1;
end
	assign done = (state == STOP);
	assign r_data = rdata_temp;

endmodule
