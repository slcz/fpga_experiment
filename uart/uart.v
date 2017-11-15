`timescale 1ns / 1ps
module uart(
	input  clk,
	input  tx_start,
	output tx_done,
	input  [7:0] tx_data,
	output tx_out,
	input  rst,
	input  rxinput,
	output [7:0] rx_data,
	output rx_rcvd);

parameter
	idle        = 4'b1111,
	tx_req      = 4'b1010,
	start       = 4'b1001,
	stop        = 4'b1000,
	b0          = 4'b0000,
	b1          = 4'b0001,
	b2          = 4'b0010,
	b3          = 4'b0011,
	b4          = 4'b0100,
	b5          = 4'b0101,
	b6          = 4'b0110,
	b7          = 4'b0111,
	inv         = 4'bx;
reg[3:0] state_tx;

reg[3:0] state_rx;
// clk is 16x the baudrate
wire baudrate_clock;
reg[4:0] clock_shift;
reg [3:0] rxcnt;
reg rxin_bit;
reg [7:0]rx_data_reg = 8'b0;
reg [2:0] rxinput_sync;

assign rx_data = rx_data_reg;
assign tx_out =
	(~state_tx[3] & tx_data[state_tx[2:0]]) |
	(state_tx == idle)                      |
	(state_tx == stop);
assign baudrate_clock = clock_shift[4];
assign tx_done = (state_tx == stop);
reg rst_state;

always @(posedge clk)
begin
	if (rst)
	begin
		clock_shift      <= 5'b0;
		rxcnt            <= 4'b1000;
		rxin_bit         <= 1'b1;
		rxinput_sync     <= 3'b111;
		rst_state        <= 1'b1;
	end
	else
	begin
		if (baudrate_clock)
			rst_state <= 1'b0;
		rxinput_sync <= {rxinput_sync[1:0], rxinput};
		clock_shift <= clock_shift[3:0] + 1;
		rxcnt <= rxinput_sync[2] ? ((rxcnt << 1) | (rxcnt[3] << 3)) :
			                   ((rxcnt >> 1) | (rxcnt[0]));
		if (rxcnt[3]) 
			rxin_bit <= 1'b1;
		else
		if (rxcnt[0])
			rxin_bit <= 1'b0;
	end
end

wire sampling_tick;
reg [3:0] sampling_cnt;

always @(posedge clk)
	if (rst)
		sampling_cnt <= 4'b1000;
	else
		if (state_rx == idle)
			sampling_cnt <= 4'b0;
		else
			sampling_cnt <= sampling_cnt + 1'b1;
assign sampling_tick = (sampling_cnt == 8);

always @(posedge baudrate_clock)
begin
	if (rst_state)
		state_tx         <= idle;
	else
	case(state_tx)
		idle:
			if (tx_start)
				state_tx <= start;
		start:
			state_tx <= b0;
		b0, b1, b2, b3, b4, b5, b6, b7:
			state_tx <= state_tx + 1;
		stop:
			if (tx_start)
				state_tx <= start;
			else
				state_tx <= idle;
		default:
			state_tx <= inv;
	endcase
end

always @(posedge clk)
begin
	if (rst)
		state_rx         <= idle;
	else
	case(state_rx)
		idle:
			if (~rxin_bit)
				state_rx <= start;
		start:
			if (sampling_tick)
				state_rx <= b0;
		b0,b1,b2,b3,b4,b5,b6,b7:
			if (sampling_tick)
			begin
				state_rx <= state_rx + 1;
				rx_data_reg <= {rxin_bit, rx_data_reg[7:1]};
			end
		stop:
			if (sampling_tick)
				if (~rxin_bit)
					state_rx <= start;
				else
					state_rx <= idle;
		default:
			state_rx <= inv;
	endcase
end
assign rx_rcvd = state_rx == stop;

endmodule
