module sent_rx_top(
	input clk_rx,
	input reset_rx,
	input data_pulse,
	output write_enable_rx,
	output [7:0] id_received,
	output [15:0] data_received,
	output [11:0] data_to_fifo_rx
	);
	
	//----------SENT RX------------------//
	//pulse check block <-> crc check block
	wire [27:0] data_fast_check_crc;
	wire [29:0] data_channel_check_crc;

	//pulse check block <-> store fifo
	wire [11:0] data_out;
	wire write_enable_store;

	//pulse check block <-> rx control
	wire [2:0] done_pre_data;
	wire [7:0] id_decode;
	wire [15:0] data_decode;
	wire config_bit_decode;
	wire channel_format_decode;

	//rx control <-> store fifo
	wire [11:0] data_fast_in;
	wire read_enable_store;

	//rx control <-> crc check
	wire [2:0] enable_crc_check;
	wire valid_data_serial;
	wire valid_data_enhanced;
	wire valid_data_fast;
	wire [1:0] crc_check_done;
	

	sent_rx_pulse_check sent_rx_pulse_check(
		.clk_rx(clk_rx),
		.reset_rx(reset_rx),
		.data_pulse(data_pulse),
		.data_fast_check_crc(data_fast_check_crc),
		.data_channel_check_crc(data_channel_check_crc),
		.done_pre_data(done_pre_data),
		.id_decode(id_decode),
		.config_bit_decode(config_bit_decode),
		.data_decode(data_decode),
		.write_enable_store(write_enable_store),
		.data_out(data_out),
		.channel_format_decode(channel_format_decode)
	);

	async_fifo store_fifo(
		.write_enable(write_enable_store), 
		.write_clk(clk_rx), 
		.write_reset(reset_rx),
		.read_enable(read_enable_store), 
		.read_clk(clk_rx), 
		.read_reset(reset_rx),
		.write_data(data_out),
		.read_data(data_fast_in),
		.write_full(write_full),
		.read_empty(read_empty)
	);

	sent_rx_crc_check sent_rx_crc_check(
		.clk_rx(clk_rx),
		.reset_rx(reset_rx),
		//signals to control block
		.enable_crc_check(enable_crc_check),
		.data_fast_check_crc(data_fast_check_crc),
		.data_channel_check_crc(data_channel_check_crc),
		.valid_data_serial(valid_data_serial),
		.valid_data_enhanced(valid_data_enhanced),
		.valid_data_fast(valid_data_fast),
		.crc_check_done(crc_check_done)

	);
	
	sent_rx_control sent_rx_control(
		.clk_rx(clk_rx),
		.reset_rx(reset_rx),
		.done_pre_data(done_pre_data),
		.enable_crc_check(enable_crc_check),
		.valid_data_serial(valid_data_serial),
		.valid_data_enhanced(valid_data_enhanced),
		.valid_data_fast(valid_data_fast),
		.id_decode(id_decode),
		.config_bit_decode(config_bit_decode),
		.data_decode(data_decode),
		.read_enable_store(read_enable_store),
		.data_fast_in(data_fast_in),
		.write_enable_rx(write_enable_rx),
		.data_to_fifo_rx(data_to_fifo_rx),
		.id_received(id_received),
		.data_received(data_received),
		.crc_check_done(crc_check_done),
		.channel_format_decode(channel_format_decode)
	);

endmodule
