// Quartus Prime Verilog Template
// Simple Dual Port RAM with separate read/write addresses and
// separate read/write clocks

module MEMORIADEDADOS
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=6)
(
	input [(DATA_WIDTH-1):0] data,
	input [(ADDR_WIDTH-1):0] read_addr, write_addr,
	input we, clk,
	output reg [(DATA_WIDTH-1):0] q
);
	
	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	always @ (posedge clk)
	begin
		// Write
		if (we)
			ram[write_addr] <= data;
	end
	
	always @ (negedge clk)
	begin
		// Read 
		q <= ram[read_addr];
	end
	
endmodule
