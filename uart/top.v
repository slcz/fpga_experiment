`timescale 1ns / 1ps

module top(input clk, input rxin, output tx_out);
parameter
idle = 3'b000,
rcvd = 3'b001,
txmt = 3'b010,
inv  = 3'bx;
	reg [1:0] rst_reg = 2'b1;
	wire rst;
	reg[7:0]  data_reg;
	wire[7:0] data;
	wire      rx_rcvd;
	wire      tx_done;
	reg       tx_start;
	reg[2:0]  state;
	wire      uartclk;
	reg[13:0] clkcnt = 6'b0;
	reg[7:0]  buffer;
	reg       buffer_full;

	always@(posedge clk)
		clkcnt <= clkcnt + 302;

	assign uartclk = clkcnt[13];

	assign rst = rst_reg != 0;
	always@(posedge uartclk)
		rst_reg <= rst_reg << 1;

	always@(posedge uartclk)
	begin
		if (rst)
		begin
			data_reg   <= 8'b0;
			tx_start   <= 1'b0;
			state      <= idle;
			buffer <= 8'b0;
			buffer_full <= 1'b0;
		end
		else
		begin
		if (rx_rcvd)
		begin
			buffer_full <= 1'b1;
			buffer <= data;
		end

		case (state)
		idle:
			if (buffer_full)
			begin
				buffer_full <= 1'b0;
				data_reg <= buffer;
				tx_start <= 1'b1;
				state <= txmt;
			end
		txmt:
			if (tx_done)
			begin
				tx_start <= 1'b0;
				state <= idle;
			end
		default:
			begin
				state <= 3'bx;
				tx_start <= 1'bx;
			end
		endcase
		end
	end
	uart UART(
		.clk(uartclk),
		.rst(rst),
		.rxinput(rxin),
		.rx_data(data),
		.rx_rcvd(rx_rcvd),
		.tx_start(tx_start),
		.tx_out(tx_out),
		.tx_done(tx_done),
		.tx_data(data_reg));

endmodule
