module sent_rx_control(
	//clk and reset_rx
	input clk_rx,
	input reset_rx,
	
	//signals to pulse check block
	input [2:0] done_pre_data,

	//signals to crc check
	output reg [2:0] enable_crc_check,
	input [1:0] crc_check_done,
	input valid_data_serial,
	input valid_data_enhanced,
	input valid_data_fast,

	input [7:0] id_decode,
	input [15:0] data_decode,
	input config_bit_decode,
	input channel_format_decode,
	output reg read_enable_store,
	input [11:0] data_fast_in,

	output reg [7:0] id_received,
	output reg [15:0] data_received,
	output reg write_enable_rx,
	output reg [11:0] data_to_fifo_rx
	);

	//frame format of fast channels
	localparam TWO_FAST_CHANNELS_12_12 = 1;
	localparam ONE_FAST_CHANNELS_12 = 2;
	localparam HIGH_SPEED_ONE_FAST_CHANNEL_12 = 3;
	localparam SECURE_SENSOR = 4;
	localparam SINGLE_SENSOR_12_0 = 5;
	localparam TWO_FAST_CHANNELS_14_10 = 6;
	localparam TWO_FAST_CHANNELS_16_8 = 7;
	
	reg valid_data_fast_channel;
	reg [11:0] data_fast1_decode;
	reg [11:0] data_fast2_decode;
	reg [2:0] a;
	
	reg [17:0] saved;
	reg [2:0] count_enable;
	reg count_store;
	reg [5:0] count_frame;
	reg done;
	reg count_rx;
	reg [2:0] count_enable_rx;
	reg done_sent;
 	reg valid;
	reg [2:0] frame_format;
	reg [5:0] count_check_done;
	reg [1:0] q;
	reg done_all;
		

	always @(negedge clk_rx or posedge reset_rx) begin
		if(reset_rx) begin
			enable_crc_check <= 0;
			a <= 0;
			read_enable_store <= 0;
			saved <= 0;
			count_store <= 0;
			count_enable <= 0;
			data_fast1_decode <= 0;
			data_fast2_decode <= 0;
			valid_data_fast_channel <= 0;
			count_frame <= 0;
			write_enable_rx <= 0;
			data_to_fifo_rx <= 0;
			done <= 0;
			data_fast1_decode <= 0;
			data_fast2_decode <= 0;
			data_to_fifo_rx <= 0;
			id_received <= 0;
			data_received <= 0;
			valid <= 0;
			q <= 0;
			done_all <= 0;
		end
		else begin
			a <= done_pre_data;
	
			if(done_pre_data == 3'b000 && a == 3'b001) begin enable_crc_check <= 3'b001; end
			else if(done_pre_data == 3'b000 && a == 3'b010) begin enable_crc_check <= 3'b010; end
			else if(done_pre_data == 3'b000 && a == 3'b011) begin enable_crc_check <= 3'b011; end
			else if(done_pre_data == 3'b000 && a == 3'b100) begin enable_crc_check <= 3'b100; q <= 2'b01; end
			else if(done_pre_data == 3'b000 && a == 3'b101) begin enable_crc_check <= 3'b101; q <= 2'b10; end
			if(crc_check_done != 2'b00)  begin count_check_done <= count_check_done + 1; enable_crc_check <= 0; end
			
			if(valid_data_serial || valid_data_enhanced) begin
				id_received <= id_decode;
				data_received <= data_decode;
				valid <= 1;
			end

			if(done_all) begin
			if(data_decode == 12'h001 || data_decode == 16'h001 ) begin frame_format = TWO_FAST_CHANNELS_12_12; end
			else if(data_decode == 12'h002 || data_decode == 16'h002) begin frame_format = ONE_FAST_CHANNELS_12; end
			else if(data_decode == 12'h003 || data_decode == 16'h003) begin frame_format = HIGH_SPEED_ONE_FAST_CHANNEL_12; end
			else if(data_decode == 12'h004 || data_decode == 16'h004) begin frame_format = SECURE_SENSOR; end
			else if(data_decode == 12'h005 || data_decode == 16'h005) begin frame_format = SINGLE_SENSOR_12_0; end
			else if(data_decode == 12'h006 || data_decode == 16'h006) begin frame_format = TWO_FAST_CHANNELS_14_10; end
			else if(data_decode == 12'h007 || data_decode == 16'h007) begin frame_format = TWO_FAST_CHANNELS_16_8; end	
			else frame_format = 0;
			end
			else frame_format = 0;
		end
	end
	
	//transmit data to fifo rx
	always @(posedge clk_rx or posedge reset_rx) begin
		if(reset_rx) begin
			enable_crc_check <= 0;
			count_rx <= 0;
			count_enable_rx <= 0;
			done_sent <= 0;
			count_check_done <= 0;
		end
		else begin
			
			if(enable_crc_check == 3'b001 || enable_crc_check == 3'b010 || enable_crc_check == 3'b011) begin saved <= {saved[16:0], valid_data_fast}; end
			if(q == 2'b01 && count_check_done == 17) begin done_all <= 1; count_check_done <= 0; end
			else if(q == 2'b10 && count_check_done == 19) begin done_all <= 1; count_check_done <= 0; end

			case(frame_format)
				TWO_FAST_CHANNELS_12_12: begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							if(!count_rx) begin
								data_to_fifo_rx <= data_fast1_decode; 
								count_rx <= 1; 
							end else begin 
								data_to_fifo_rx <= {data_fast2_decode[3:0],data_fast2_decode[7:4],data_fast2_decode[11:8]}; 
								count_rx <= 0; 
								done <= 0;
								done_sent <= 0;
							end
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end

				ONE_FAST_CHANNELS_12 : begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							data_to_fifo_rx <= data_fast1_decode[11:0]; 
							done <= 0;
							done_sent <= 0;
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end

				HIGH_SPEED_ONE_FAST_CHANNEL_12: begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							data_to_fifo_rx <= data_fast1_decode[11:0]; 
							done <= 0;
							done_sent <= 0;
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end

				SECURE_SENSOR: begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							if(!count_rx) begin
								data_to_fifo_rx <= data_fast1_decode; 
								count_rx <= 1; 
							end else begin 
								count_rx <= 0; 
								done <= 0;
								done_sent <= 0;
							end
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end

				SINGLE_SENSOR_12_0: begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							if(!count_rx) begin
								data_to_fifo_rx <= data_fast1_decode; 
								count_rx <= 1; 
							end else begin 
								count_rx <= 0; 
								done <= 0;
								done_sent <= 0;
							end
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end

				TWO_FAST_CHANNELS_14_10: begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							if(!count_rx) begin
								data_to_fifo_rx <= {data_fast1_decode}; 
								count_rx <= 1; 
							end else begin 
								data_to_fifo_rx <= {data_fast2_decode[3:0],data_fast2_decode[7:4],data_fast2_decode[9:8]}; 
								count_rx <= 0; 
								done <= 0;
								done_sent <= 0;
							end
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end
				
				TWO_FAST_CHANNELS_16_8: begin
					if(done) begin
						if(count_enable_rx == 6) begin
							write_enable_rx <= 1;
							count_enable_rx <= 0;
							if(!count_rx) begin
								data_to_fifo_rx <= data_fast1_decode; 
								count_rx <= 1; 
							end else begin 
								data_to_fifo_rx <= {data_fast2_decode[11:8],data_fast2_decode[3:0],data_fast2_decode[7:4]}; 
								count_rx <= 0; 
								done <= 0;
								done_sent <= 0;
							end
						end
						else begin count_enable_rx <= count_enable_rx + 1; end
					end
				end
			endcase
			
			if(write_enable_rx) write_enable_rx <= 0;
		end
	end

	//read data from store fifo
	always @(negedge clk_rx or posedge reset_rx) begin
		if(reset_rx) begin

		end
		else begin
			if(read_enable_store) begin read_enable_store <= 0; end
			if(done_all) begin
			 if( (frame_format == TWO_FAST_CHANNELS_12_12) || (frame_format == SECURE_SENSOR) || (frame_format == SINGLE_SENSOR_12_0) ||
				(frame_format == TWO_FAST_CHANNELS_14_10) || (frame_format == TWO_FAST_CHANNELS_16_8) ) begin
					if(!done_sent) begin
						if(q == 2'b10 && count_frame != 17) begin
							if(count_enable ==1) begin
								count_enable <= 0;
								read_enable_store <= 1;
								if(!count_store) begin
									data_fast1_decode <= data_fast_in;
									count_store <= 1;
								end
								else begin
									data_fast2_decode <= data_fast_in; 
									count_store <= 0; 
									valid_data_fast_channel <= saved[17];
									saved <= {saved[16:0], valid_data_fast};
									count_frame <= count_frame + 1;
									done <= 1;
									done_sent <= 1;
								end
							end else count_enable <= count_enable + 1;
						end 
						else if(q == 2'b01 && count_frame != 15) begin
							if(count_enable ==1) begin
								count_enable <= 0;
								read_enable_store <= 1;
								if(!count_store) begin
									data_fast1_decode <= data_fast_in;
									count_store <= 1;
								end
								else begin
									data_fast2_decode <= data_fast_in; 
									count_store <= 0; 
									valid_data_fast_channel <= saved[17];
									saved <= {saved[16:0], valid_data_fast};
									count_frame <= count_frame + 1;
									done <= 1;
									done_sent <= 1;
								end
							end else count_enable <= count_enable + 1;
						end 
						
						else begin read_enable_store <= 0; valid_data_fast_channel <= 0; valid <= 0; count_frame <= 0; done_all <= 0; end
					end	
				end
			else if ( (frame_format == ONE_FAST_CHANNELS_12) || (frame_format == HIGH_SPEED_ONE_FAST_CHANNEL_12) )  begin
					if(!done_sent) begin
						if(q == 2'b10 && count_frame != 17) begin
							if(count_enable ==1) begin
								count_enable <= 0;
								read_enable_store <= 1;
								data_fast1_decode <= data_fast_in;
								valid_data_fast_channel <= saved[17];
								saved <= {saved[16:0], valid_data_fast};
								count_frame <= count_frame + 1;
								done <= 1;
								done_sent <= 1;
							end else count_enable <= count_enable + 1;
						end 
						else if(q == 2'b10 && count_frame != 17) begin
							if(count_enable ==1) begin
								count_enable <= 0;
								read_enable_store <= 1;
								data_fast1_decode <= data_fast_in;
								valid_data_fast_channel <= saved[17];
								saved <= {saved[16:0], valid_data_fast};
								count_frame <= count_frame + 1;
								done <= 1;
								done_sent <= 1;
							end else count_enable <= count_enable + 1;
						end
						else begin read_enable_store <= 0; valid_data_fast_channel <= 0; valid <= 0; count_frame <= 0; done_all <= 0; end
					end	
				end
			else read_enable_store <= 0;
			end
		end
	end
endmodule
