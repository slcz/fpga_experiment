`timescale 1ns / 1ps

module top(input clk, input rxin, output tx_out);
parameter
idle = 3'b000,
rcvd = 3'b001,
txmt = 3'b010,
done = 3'b011,
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
	reg[1:0]  buffer_state;

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
			buffer_state <= 2'b0;
			data_reg   <= 8'b0;
			tx_start   <= 1'b0;
			state      <= idle;
			buffer <= 8'b0;
			buffer_full <= 1'b0;
		end
		else
		begin
		case (buffer_state)
		2'b00:
			if (rx_rcvd)
			begin
				buffer_full <= 1'b1;
				buffer <= data;
				buffer_state <= 2'b10;
			end
		default:
			if (!rx_rcvd)
				buffer_state <= 2'b00;
		endcase

		case (state)
		idle:
			if (buffer_full)
			begin
				buffer_full <= 1'b0;
				data_reg <= buffer;
				tx_start <= 1'b1;
				if (tx_done)
					state <= rcvd;
				else
					state <= txmt;
			end
		rcvd:
			if (!tx_done)
				state <= txmt;
		txmt:
			if (tx_done)
			begin
				tx_start <= 1'b0;
				state <= idle;
			end
		/*
		done:
			if (~tx_done)
				state <= idle;
		*/
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
