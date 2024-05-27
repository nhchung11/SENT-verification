module sent_tx_top(
	//clk_tx and reset_tx
	input clk_tx,	
	input reset_tx,
	input channel_format, //0: serial, 1: enhanced
	input optional_pause,
	input config_bit,
	input enable,
	input [7:0] id,
	input [15:0] data_bit_field,
	input [11:0] data_in,
	input fifo_tx_empty,
	output read_enable_tx,
	output data_pulse
	);

	//----------SENT TX------------------//
	//control block <-> crc block
	wire [2:0] enable_crc_gen;
	wire [23:0] data_gen_crc;
	wire [5:0] crc_gen;
	wire [1:0] crc_gen_done;

	//gen ticks block <-> pulse gen block
	wire ticks;

	//control block <-> pulse gen block
	wire [3:0] data_nibble;
	wire pulse;
	wire sync;
	wire pause;
	wire pulse_done;
	wire idle;

	//data reg block <-> control block
	wire [2:0] load_bit;
	wire done;
	wire [15:0] data_f1;
	wire [11:0] data_f2;
	//----------SENT TX------------------//
	
	sent_tx_data_reg sent_tx_data_reg(
		//clk_tx and reset_tx
		.clk_tx(clk_tx),
		.reset_tx(reset_tx),

		//signals to control block
		.load_bit(load_bit),
		.done(done),
		.data_f1(data_f1),
		.data_f2(data_f2),

		//signals to fifo
		.data_in(data_in),
		.read_enable_tx(read_enable_tx),
		.fifo_tx_empty(fifo_tx_empty)
	);

	sent_tx_control sent_tx_control(
		//clk_tx and reset_tx
		.clk_tx(clk_tx),
		.reset_tx(reset_tx),

		//normal input
		.channel_format(channel_format), //0: serial(), 1: enhanced
		.optional_pause(optional_pause),
		.config_bit(config_bit),
		.enable(enable),
		.id(id),
		.data_bit_field(data_bit_field),

		//signals to crc block
		.enable_crc_gen(enable_crc_gen),
		.data_gen_crc(data_gen_crc),
		.crc_gen_done(crc_gen_done),
		.crc_gen(crc_gen),

		//signals to pulse gen block
		.pulse_done(pulse_done),
		.data_nibble(data_nibble),
		.pulse(pulse),
		.sync(sync),
		.pause(pause),
		.idle(idle),
	
		//signals to data reg block
		.data_f1(data_f1),
		.data_f2(data_f2),
		.load_bit(load_bit),
		.done(done)
	);

	sent_tx_pulse_gen sent_tx_pulse_gen(
		//clk_tx and reset_tx
		.ticks(ticks),
		.reset_tx(reset_tx),

		//signals to control
		.data_nibble(data_nibble),
		.pulse(pulse),
		.sync(sync),
		.pause(pause),
		.idle(idle),
		.pulse_done(pulse_done),

		//output
		.data_pulse(data_pulse)
	);

	sent_tx_gen_ticks sent_tx_gen_ticks(
		.clk_tx(clk_tx),
		.reset_tx(reset_tx),
		.ticks(ticks)
	);

	sent_tx_crc_gen sent_tx_crc_gen(
		.clk_tx(clk_tx),
		.reset_tx(reset_tx),
		.crc_gen(crc_gen),
		.enable_crc_gen(enable_crc_gen),
		.data_gen_crc(data_gen_crc),
		.crc_gen_done(crc_gen_done)
	);
endmodule
