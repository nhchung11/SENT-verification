module sent_tx_gen_ticks(
	input clk_tx,
	input reset_tx,
	output reg ticks
	);

	localparam divide = 50;
	reg [15:0] counter = 0;

	always @(posedge clk_tx or posedge reset_tx) begin
		if(reset_tx) begin
			ticks <= 0;
			counter <= 0;
		end
		else begin
			if (counter == (divide/2) - 1) begin
				ticks <= ~ticks;
				counter <= 0;
			end
			else counter <= counter + 1;
		end
	end
endmodule
