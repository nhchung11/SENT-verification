module sent_tx_crc_gen(
	//reset_tx
	input clk_tx,
	input reset_tx,

	//signals to control block
	input [2:0] enable_crc_gen,
	input [23:0] data_gen_crc,
	output reg [5:0] crc_gen,
	output reg [1:0] crc_gen_done
	);

	reg [35:0] temp_data;
	reg [2:0] state;
    	reg [6:0] p;
	reg [4:0] poly4 = 5'b11101;
	reg [6:0] poly6 = 7'b1011001;

	always @(posedge clk_tx or posedge reset_tx) begin
		if(reset_tx) begin
			state <= 0;
			temp_data <= 0;
			p <= 0;
			crc_gen_done <= 0;
		end
		else begin
			case(state)
					0: begin
						temp_data <= 0;
						crc_gen_done <= 0;
						if(enable_crc_gen != 3'b000) begin
							state <= 1;
							
						end
					end
					1: begin
						state <= 2;
						case(enable_crc_gen)
							3'b001: begin
								p <= 31;
        							temp_data <= {4'b0101, data_gen_crc, 4'b0};
							end
							3'b010: begin
								p <= 23;
        							temp_data <= {4'b0101, data_gen_crc[15:0], 4'b0};
							end
							3'b011: begin
								p <= 19;
        							temp_data <= {4'b0101, data_gen_crc[11:0], 4'b0};
							end
							3'b100: begin
								p <= 19;
        							temp_data <= {4'b0101, data_gen_crc[11:0], 4'b0};
							end
							3'b101: begin
								p <= 35;
        							temp_data <= {6'b010101, data_gen_crc, 6'b0};
							end
						endcase
					end
					2: begin
						if(enable_crc_gen == 3'b001 || enable_crc_gen == 3'b010 || enable_crc_gen == 3'b011 ||
							enable_crc_gen == 3'b100 ) begin
							if (p > 3) begin
            							if (temp_data[p] == 1'b1) begin
              	  							temp_data[p-0] <= temp_data[p-0] ^ 1;
                							temp_data[p-1] <= temp_data[p-1] ^ poly4[3];
                							temp_data[p-2] <= temp_data[p-2] ^ poly4[2];
                							temp_data[p-3] <= temp_data[p-3] ^ poly4[1];
                							temp_data[p-4] <= temp_data[p-4] ^ poly4[0];
            							end
            							else begin
                							p <= p - 1;
            							end

        						end
							else begin
								state <= 3;
							end
						end
						else if (enable_crc_gen == 3'b101) begin
							if (p > 5) begin
            							if (temp_data[p] == 1'b1) begin
              	  							temp_data[p-0] <= temp_data[p-0] ^ 1;
                							temp_data[p-1] <= temp_data[p-1] ^ poly6[5];
                							temp_data[p-2] <= temp_data[p-2] ^ poly6[4];
                							temp_data[p-3] <= temp_data[p-3] ^ poly6[3];
                							temp_data[p-4] <= temp_data[p-4] ^ poly6[2];
									temp_data[p-5] <= temp_data[p-5] ^ poly6[1];
									temp_data[p-6] <= temp_data[p-6] ^ poly6[0];
            							end
            							else begin
                							p = p - 1;
            							end

        						end
							else begin
								state <= 3;
							end
						end
					end
					3: begin
						state <= 4;
						if(enable_crc_gen == 3'b001 || enable_crc_gen == 3'b010 || enable_crc_gen == 3'b011) begin
							crc_gen[5:4] <= 2'b00;
        						crc_gen[3] <= temp_data[3];
        						crc_gen[2] <= temp_data[2];
        						crc_gen[1] <= temp_data[1];
        						crc_gen[0] <= temp_data[0];
							crc_gen_done <= 2'b01;
						
						end
						else if (enable_crc_gen == 3'b101) begin
							crc_gen[5] <= temp_data[5];
        						crc_gen[4] <= temp_data[4];
        						crc_gen[3] <= temp_data[3];
        						crc_gen[2] <= temp_data[2];
        						crc_gen[1] <= temp_data[1];
        						crc_gen[0] <= temp_data[0];
							crc_gen_done <= 2'b11;
						end
						else if(enable_crc_gen == 3'b100) begin
							crc_gen[5:4] <= 2'b00;
        						crc_gen[3] <= temp_data[3];
        						crc_gen[2] <= temp_data[2];
        						crc_gen[1] <= temp_data[1];
        						crc_gen[0] <= temp_data[0];
							crc_gen_done <= 2'b10;
						
						end
					end
					4: begin
						state <= 0;
					end
					default: state <= 0;
			endcase
		end
	end
	
endmodule