module sent_tx_data_reg(
	//clk_tx and reset_tx
	input clk_tx,
	input reset_tx,

	//signals to control block
	input [2:0] load_bit,
	output reg [15:0] data_f1,
	output reg [11:0] data_f2,
	output reg done,	

	//signals to fifo
	input [11:0] data_in,
	input fifo_tx_empty,
	output reg read_enable_tx
	);

	reg [4:0] count_enable;
	reg [2:0] count_store;

	reg [11:0] saved_data1;
	reg [11:0] saved_data2;


	//CONTROL
	always @(posedge clk_tx or posedge reset_tx) begin
		if(reset_tx) begin
			count_enable <= 0;
			read_enable_tx <= 0;
			saved_data1 <= 0;
			saved_data2 <= 0;
			done <= 0;
			count_store <= 0;
			
		end
		else begin
			if(load_bit == 3'b001 || load_bit == 3'b110 || load_bit == 3'b111) begin
				if(!fifo_tx_empty) begin
				if(count_enable == 6) begin
					read_enable_tx <= 1;
					count_enable <= 0;
					if(!count_store) begin
						saved_data1 <= data_in; 
						count_store <= 1; 
					end else begin 
						saved_data2 <= data_in; 
						count_store <= 0; 
						done <= 1; 
					end
				end
				else begin count_enable <= count_enable + 1; end
				end
				else begin
					saved_data1 <= 0;
					saved_data2 <= 0;
					done <= 1;
				end
			end
			else if(load_bit == 3'b010 || load_bit == 3'b011 || load_bit == 3'b100 || load_bit == 3'b101)begin
				if(!fifo_tx_empty) begin	
				if(count_enable == 6) begin
					read_enable_tx <= 1;
					count_enable <= 0;
					saved_data1 <= data_in; 
					done <= 1; 
				end
				else begin count_enable <= count_enable + 1; end
				end
				else begin
					saved_data1 <= 0;
					done <= 1;
				end
			end
			else begin 
				read_enable_tx <= 0;
				count_enable <= 0;
			end
			
			if(done) done <= 0;
			if(read_enable_tx) read_enable_tx <= 0;
		end
	end

	//DATA
	always @(negedge clk_tx or posedge reset_tx) begin
		if(reset_tx) begin
			data_f1 <= 0;
			data_f2 <= 0;
		end
		else begin
			//data fast channel 1
			if(done) begin 
				case(load_bit)
					3'b001: begin data_f1 <= saved_data1; data_f2 <= saved_data2; end
					3'b010: begin data_f1 <= saved_data1; end
					3'b011: begin data_f1 <= saved_data1; end
					3'b100: begin data_f1 <= saved_data1; end
					3'b101: begin data_f1 <= saved_data1; end
					3'b110: begin data_f1 <= {saved_data1, saved_data2[7:6]}; data_f2 <= saved_data2[5:0]; end
					3'b111: begin data_f1 <= {saved_data1, saved_data2[7:4]}; data_f2 <= saved_data2[3:0]; end
				endcase
			end
		end
	end
endmodule
