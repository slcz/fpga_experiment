`timescale 1ns / 1ps

module uart_sim;
	reg[7:0] rx_input;
	reg  rxin;
	reg  clk;
	wire tx_out;
	integer i;
	always
		#5 clk = ~clk;
	initial begin
		clk       = 1'b0; rxin = 1'b1;
		rx_input  = 8'b10101010;
		rxin      = 1'b1;
		#12000 rxin  = 1'b0;
		for (i = 0; i < 8; i = i + 1) begin
			#8680
			rxin     = rx_input[0];
			rx_input = rx_input >> 1;
		end
		#8680 rxin = 1'b1;
		      rx_input  = 8'b00110010;
		#8680 rxin  = 1'b0;
		for (i = 0; i < 8; i = i + 1) begin
			#8680
			rxin     = rx_input[0];
			rx_input = rx_input >> 1;
		end
		#8680 rxin = 1'b1;
		      rx_input  = 8'b11001100;
		#8680 rxin  = 1'b0;
		for (i = 0; i < 8; i = i + 1) begin
			#8680
			rxin     = rx_input[0];
			rx_input = rx_input >> 1;
		end
		#8680 rxin = 1'b1;
		#200000 $finish;
	end
	top UARTDEMO(
		.clk(clk),
		.rxin(rxin),
		.tx_out(tx_out));
endmodule
