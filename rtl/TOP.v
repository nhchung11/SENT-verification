module top
	#(parameter ADDRESSWIDTH= 3,
	parameter DATAWIDTH= 12)
	(
		input PCLK,
		input PRESETn,
		input [ADDRESSWIDTH-1:0]PADDR,
		input [DATAWIDTH-1:0] PWDATA,
		input PWRITE,
		input PSELx,
		input PENABLE,
		output [DATAWIDTH-1:0] PRDATA,
		output PREADY,
		
		input reset_tx,
		input clk_tx,
		input reset_rx,
		input clk_rx,
		input channel_format, //0: serial, 1: enhanced
		input optional_pause,
		input config_bit,
		input enable,
		input [7:0] id,
		input [15:0] data_bit_field,

		output [7:0] id_received,
		output [15:0] data_received
		//output

	);
	
	//signals apb
	wire [7:0] reg_status;
	wire [7:0] reg_command;
	wire [11:0] reg_transmit;
	wire [11:0] reg_receive;
	wire write_enable_tx;
	wire read_enable_rx;
	wire fifo_tx_empty;
	wire [11:0] data_in;
	wire [11:0] data_to_fifo_rx;
	wire reset;
	wire a;
	assign reset = !PRESETn;
	assign fifo_tx_empty = a;
	assign reg_status[6] = a;
	assign reg_status[3:0] = 4'b0000;

	apb_slave apb_slave(
		.PCLK(PCLK),
		.PRESETn(PRESETn),
		.PADDR(PADDR),
		.PWDATA(PWDATA),
		.PWRITE(PWRITE),
		.PSELx(PSELx),
		.PENABLE(PENABLE),
		.PRDATA(PRDATA),
		.PREADY(PREADY),

		//register
		.reg_status(reg_status),  
		.reg_command(reg_command), 
		.reg_transmit(reg_transmit), 
		.reg_receive(reg_receive),
		//output control fifo tx
		.write_enable_tx(write_enable_tx),
		//output control fifo rx
		.read_enable_rx(read_enable_rx)
	);

	async_fifo tx_fifo(
		.write_enable(write_enable_tx), 
		.write_clk(PCLK), 
		.write_reset(reset),
		.read_enable(read_enable_tx), 
		.read_clk(clk_tx), 
		.read_reset(reset),
		.write_data(reg_transmit),
		.read_data(data_in),
		.write_full(reg_status[7]),
		.read_empty(a)
	);
	
	sent_tx_top sent_tx_top(
	//clk and reset
		.clk_tx(clk_tx),	
		.reset_tx(reset_tx),
		.channel_format(channel_format), //0: serial(), 1: enhanced
		.optional_pause(optional_pause),
		.config_bit(config_bit),
		.enable(enable),
		.id(id),
		.data_bit_field(data_bit_field),
		.data_pulse(data_pulse),
		.read_enable_tx(read_enable_tx),
		.data_in(data_in),
		.fifo_tx_empty(fifo_tx_empty)
	);

	sent_rx_top sent_rx_top(
		.clk_rx(clk_rx),
		.reset_rx(reset_rx),
		.data_pulse(data_pulse),
		.write_enable_rx(write_enable_rx),
		.id_received(id_received),
		.data_received(data_received),
		.data_to_fifo_rx(data_to_fifo_rx)
	);
	
	async_fifo rx_fifo(
		.write_enable(write_enable_rx), 
		.write_clk(clk_rx), 
		.write_reset(reset),
		.read_enable(read_enable_rx), 
		.read_clk(PCLK), 
		.read_reset(reset),
		.write_data(data_to_fifo_rx),
		.read_data(reg_receive),
		.write_full(reg_status[5]),
		.read_empty(reg_status[4])
	);

endmodule