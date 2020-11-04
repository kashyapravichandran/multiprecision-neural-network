module MyDesign (dut_run, dut_busy, reset_b, clk, dut_sram_write_address,
		 dut_sram_write_data, dut_sram_write_enable, 
		 dut_sram_read_address,	sram_dut_read_data,
		 dut_wmem_read_address, wmem_dut_read_data);

// Inputs to the data path 

input clk;
input signed [15:0] sram_dut_read_data, wmem_dut_read_data;

// Inputs to the control path 
input dut_run, reset_b;

// Outputs from the data path 
output signed [15:0] dut_sram_write_data;
output [11:0] dut_sram_write_address;
output dut_sram_write_enable;

wire signed [15:0] dut_sram_write_data;
wire [11:0] dut_sram_write_address;
wire dut_sram_write_enable;

// Outputs from the control path 

output [11:0] dut_sram_read_address, dut_wmem_read_address;
output dut_busy;

wire [11:0] dut_sram_read_address, dut_wmem_read_address;
wire dut_busy;
// registers for pipeline stage 1

//reg [11:0] output_address_stage1;
reg signed [15:0] input_stage1, weight_stage1;
reg enable_write_stage1, select_adder_stage1;//busy_stage1;
reg [2:0] select_input, select_weight;

// wires and reg for datapath stage 1

reg signed [7:0] input_mul_1, input_mul_2, weight_mul_1, weight_mul_2;
wire signed [15:0] output_mul_1, output_mul_2;

// registers for pipeline stage 2

//reg [11:0] output_address_stage2;
reg signed [15:0] output_mul_1_stage2, output_mul_2_stage2;
reg select_adder_stage2, enable_write_stage2;//busy_stage2;

//wires for the datapath stage 2

wire signed [15:0] adder_input_1, adder_input_2, adder_input_3;
wire signed [16:0] output_adder;

// registers for pipeline stage 3

//reg[11:0] output_address_stage3;
reg enable_write_stage3;// busy_stage3;
reg signed [16:0] output_adder_stage3;

// Registers for Address 

reg [11:0] register_address_input, register_address_weight, register_address_output;
reg [1:0] address_input_select, address_weight_select, address_output_select;

reg [11:0] address_input, address_weight, address_output;
reg [3:0] control_input_shift;

// Register and Wire for the control path. 

reg [7:0] count_input_column, count_weight_column, count_input_row, count_weight_row;
reg [7:0] size_input, size_weight;
reg busy;
reg size_input_control, size_weight_control;
reg [1:0] input_column_control, weight_column_control;
reg [1:0] input_row_control, weight_row_control;
reg [7:0] input_column_subtract, weight_column_subtract;

wire [7:0] size_input_mux_output, size_weight_mux_output;
reg [7:0] count_input_column_mux_output, count_input_row_mux_output;
reg [7:0] count_weight_column_mux_output, count_weight_row_mux_output;

// Number of bits - wires and registers 
reg [3:0] bits_input, bits_weight;
reg bits_input_control, bits_weight_control;
wire [3:0] bits_input_mux_output, bits_weight_mux_output;

// Busy 

reg register_busy;

//reg busy_reg;

// control block parameters and states

parameter [3:0]	// synopsys enum states
	S0 = 4'b0000,
	S1 = 4'b0001,
	S2 = 4'b0010,
	S3 = 4'b0011,
	S4 = 4'b0100,
	S5 = 4'b0101,
	S6 = 4'b0110,
	S7 = 4'b0111,
	S8 = 4'b1000,
	S9 = 4'b1001,
	S10 = 4'b1010,
	S11 = 4'b1011,
	S12 = 4'b1100,
	S13 = 4'b1101;

reg [3:0] /* synopsys enum states */ current_state_input, current_state_weight, next_state_input, next_state_weight; // synopsys state_vector current_state

// need to add adress_control, enable_write_control, select_input_control,
// select_output_control

reg[2:0] select_input_control, select_weight_control;
reg adder_control, enable_write_control;

// registers pipeline stage 1

always @ (posedge clk)
begin 
	if(!reset_b)
	begin 
		//output_address_stage1 <= 12'b0;
		input_stage1 <= 16'b0;
		weight_stage1 <= 16'b0;
		enable_write_stage1 <= 1'b0;
		select_adder_stage1 <= 1'b0;
		select_input <= 3'b0;
		select_weight <= 3'b0;
		//busy_stage <= 1'b0;
	end
	else 
	begin
		//output_address_stage1 <= register_address_output;
		input_stage1 <= sram_dut_read_data;
		weight_stage1 <=wmem_dut_read_data;
		select_adder_stage1 <= adder_control;
		select_input <= select_input_control;
		select_weight <= select_weight_control;
		enable_write_stage1 <= enable_write_control; 
		//busy_stage1 <= busy; 
	end

end

// Datapath stage 1

// Steering muxes

always @ (*)
begin
	case(select_input)
		3'b000: begin
			input_mul_1 = 8'b0;
			input_mul_2 = 8'b0;
			end 
		3'b001: begin 
			input_mul_1 = {{6{input_stage1[1]}},input_stage1[1:0]};
			input_mul_2 = {{6{input_stage1[3]}},input_stage1[3:2]};
			end
		3'b010: begin 
			input_mul_1 = {{6{input_stage1[5]}},input_stage1[5:4]};
			input_mul_2 = {{6{input_stage1[7]}},input_stage1[7:6]};
			end
		3'b011: begin 
			input_mul_1 = {{6{input_stage1[9]}},input_stage1[9:8]};	
			input_mul_2 = {{6{input_stage1[11]}},input_stage1[11:10]};
			end
		3'b100: begin 
			input_mul_1 = {{6{input_stage1[13]}},input_stage1[13:12]};
			input_mul_2 = {{6{input_stage1[15]}},input_stage1[15:14]};
			end
		3'b101: begin 
			input_mul_1 = {{4{input_stage1[3]}},input_stage1[3:0]};
			input_mul_2 = {{4{input_stage1[7]}},input_stage1[7:4]};
			end 
		3'b110: begin 
			input_mul_1 = {{4{input_stage1[11]}},input_stage1[11:8]};
			input_mul_2 = {{4{input_stage1[15]}},input_stage1[15:12]};
 			end 
		3'b111:begin 
			input_mul_1 = input_stage1[7:0];
			input_mul_2 = input_stage1[15:8];
			end
	endcase
	case(select_weight)
		3'b000: begin 
			weight_mul_1 = 8'b0;
			weight_mul_2 = 8'b0;
			end
		3'b001: begin 
			weight_mul_1 = {{6{weight_stage1[1]}},weight_stage1[1:0]};
			weight_mul_2 = {{6{weight_stage1[3]}},weight_stage1[3:2]};
			end
		3'b010: begin 
			weight_mul_1 = {{6{weight_stage1[5]}},weight_stage1[5:4]};
			weight_mul_2 = {{6{weight_stage1[7]}},weight_stage1[7:6]};
			end
		3'b011: begin 
			weight_mul_1 = {{6{weight_stage1[9]}},weight_stage1[9:8]};
			weight_mul_2 = {{6{weight_stage1[11]}},weight_stage1[11:10]};
			end
		3'b100: begin 
			weight_mul_1 = {{6{weight_stage1[13]}},weight_stage1[13:12]};
			weight_mul_2 = {{6{weight_stage1[15]}},weight_stage1[15:14]};
			end
		3'b101: begin 
			weight_mul_1 = {{4{weight_stage1[3]}},weight_stage1[3:0]};
			weight_mul_2 = {{4{weight_stage1[7]}},weight_stage1[7:4]};
			end 
		3'b110: begin 
			weight_mul_1 = {{4{weight_stage1[11]}},weight_stage1[11:8]};
			weight_mul_2 = {{4{weight_stage1[15]}},weight_stage1[15:12]};
 			end 
		3'b111:begin 
			weight_mul_1 = weight_stage1[7:0];
			weight_mul_2 = weight_stage1[15:8];
			end
	endcase
end

// 2 8x8 multipliers

assign output_mul_1 = input_mul_1 * weight_mul_1;
assign output_mul_2 = input_mul_2 * weight_mul_2;


// register pipeline stage 2

always @ (posedge clk)
begin 
	if(!reset_b)
	begin
		select_adder_stage2 <= 1'b0;
		//output_address_stage2 <= 12'b0;
		enable_write_stage2 <= 1'b0;
		output_mul_1_stage2 <= 16'b0;
		output_mul_2_stage2 <= 16'b0; 
		//busy_stage2 <= 1'b0;
	end 
	else
	begin
		select_adder_stage2 <= select_adder_stage1;
		//output_address_stage2 <= output_address_stage1;
		enable_write_stage2 <= enable_write_stage1;
		output_mul_1_stage2 <= output_mul_1;
		output_mul_2_stage2 <= output_mul_2; 
		//busy_stage2 <= busy_stage1;
	end 
end

// datapath stage 2

// adding 3 18 bit numbers 

assign adder_input_1 = output_mul_1_stage2;
assign adder_input_2 = output_mul_2_stage2;
assign adder_input_3 = select_adder_stage2? output_adder_stage3 : 16'b0;

assign output_adder = (adder_input_1+adder_input_2)+adder_input_3; 



// register pipline stage 3

always @ (posedge clk)
begin 
	if(!reset_b)
	begin
		//output_address_stage3 <= 12'b0;
		enable_write_stage3 <= 1'b0;
		output_adder_stage3 <= 17'b0;
		//busy_stage3 <= 1'b0;  
	end 
	else 
	begin
		//output_address_stage3 <= output_address_stage2;
		enable_write_stage3 <= enable_write_stage2;
		output_adder_stage3 <= output_adder; 
		//busy_stage3 <= busy_stage2;
	end	
end 

// datapath of stage 3

assign dut_sram_write_address = register_address_output;
assign dut_sram_write_enable = enable_write_stage3;
assign dut_sram_write_data = output_adder_stage3[15:0];


// Address Registers for input, weight and output

always @ (posedge clk)
begin
	if(!reset_b)
	begin 
		register_address_weight <= 12'b0;
		register_address_input <= 12'b0;
		register_address_output <= 12'b111111111111;
	end
	else
	begin
		register_address_weight <=address_weight;
		register_address_input <= address_input;
		register_address_output <= address_output; 
	end
end 

// Address lines that we have 
always @ (*)
begin 
	address_weight = register_address_weight;
	case(address_weight_select)
	2'b00: address_weight = register_address_weight;
	2'b01: address_weight = register_address_weight+12'b1;
	2'b10: address_weight = 12'b0;
	endcase 
end

always @ (*)
begin 
	case(address_input_select)
	2'b00: address_input = register_address_input;
	2'b01: address_input = register_address_input+12'b1;
	2'b10: address_input = (register_address_input+12'b1)-(size_input>>control_input_shift);
	2'b11: address_input = 12'b0;
	//default: address_input = register_address_input;
	endcase
end

assign dut_sram_read_address = address_input;
assign dut_wmem_read_address = address_weight;

always @ (*)
begin
	address_output = register_address_output;
	case(address_output_select)
	2'b00: address_output = register_address_output;
	2'b01: address_output = register_address_output+12'b1;
	2'b10: address_output = 12'hfff;
	endcase
	
end 

// Stuff for the size block

assign size_input_mux_output = size_input_control?sram_dut_read_data:size_input;
assign size_weight_mux_output = size_weight_control?wmem_dut_read_data:size_weight;

always @ (posedge clk)
begin
	if(!reset_b)
	begin 
		size_input <= 8'b0;
		size_weight <= 8'b0;
	end 
	else
	begin
		size_input <= size_input_mux_output;
		size_weight <= size_weight_mux_output; 
	end
end


// Stuff needed for count block 

always @ (posedge clk)
begin
	if(!reset_b)
	begin 
		count_input_column <= 8'b0;
		count_input_row <= 8'b0;
		count_weight_column <= 8'b0;
		count_weight_row <= 8'b0;
	end 
	else
	begin 
	 	count_input_column <= count_input_column_mux_output;
		count_input_row <= count_input_row_mux_output;
		count_weight_column <= count_weight_column_mux_output;
		count_weight_row <= count_weight_row_mux_output;
	end 
end 

// input stuff
always @ (*)
begin 
	case(input_column_control)
		2'b00: count_input_column_mux_output = size_input_mux_output;
		2'b01: count_input_column_mux_output = count_input_column;
		2'b10: count_input_column_mux_output = count_input_column - input_column_subtract;
		2'b11: count_input_column_mux_output = count_input_column;
		//default: count_input_column_mux_output = count_input_column;
	endcase
	case(input_row_control)
		2'b00: count_input_row_mux_output = size_input_mux_output;
		2'b01: count_input_row_mux_output = count_input_row;
		2'b10: count_input_row_mux_output = count_input_row - 8'b1;
		2'b11: count_input_row_mux_output = count_input_row;
		//default: count_input_row_mux_output = count_input_row;
	endcase
end

//weight stuff 

always @ (*)
begin 
	case(weight_column_control)
		2'b00: count_weight_column_mux_output = size_weight_mux_output;
		2'b01: count_weight_column_mux_output = count_weight_column;
		2'b10: count_weight_column_mux_output = count_weight_column - weight_column_subtract;
		2'b11: count_weight_column_mux_output = count_weight_column;
		//default: count_weight_column_mux_output = count_weight_column;
	endcase
	case(weight_row_control)
		2'b00: count_weight_row_mux_output = size_weight_mux_output;
		2'b01: count_weight_row_mux_output = count_weight_row;
		2'b10: count_weight_row_mux_output = count_weight_row - 8'b1;
		2'b11: count_weight_row_mux_output = count_weight_row;
		//default: count_weight_row_mux_output = count_weight_row;
	endcase
end

// bits and thing 

always @(posedge clk)
begin 
	if(!reset_b)
	begin
		bits_input <= 4'b0;
		bits_weight <= 4'b0; 
	end
	else
	begin
		bits_input <= bits_input_mux_output;
		bits_weight <= bits_weight_mux_output; 
	end
end 

assign bits_input_mux_output = bits_input_control?sram_dut_read_data:bits_input;
assign bits_weight_mux_output = bits_weight_control?wmem_dut_read_data:bits_weight;


// FSM state register 

always @ (posedge clk)
begin 
	if(!reset_b)
	begin
		current_state_input <= S0;
		current_state_weight <= S0;
		//busy_reg <= 0; 
	end
	else
	begin 
		current_state_input <= next_state_input;
		current_state_weight <= next_state_weight;
		//busy_reg<=busy;
	end
	
end 

always @ (posedge clk)
begin
	if(!reset_b)
		register_busy <= 1'b0;
	else
		register_busy <= busy; 
end

always @ (*)
begin
	// Input side FSM 	
	input_column_subtract = 4'b0;
	control_input_shift = 4'b0;
	bits_input_control = 1'b0;
	input_column_control = 2'b0;
	input_row_control = 2'b0;
	size_input_control = 1'b0;
	address_input_select = 2'b0;
	address_output_select = 2'b0;
	adder_control = 1'b0;
	select_input_control = 3'b0;
	enable_write_control = 1'b0;
	next_state_input = S0;
	
	//weight side FSM 
	weight_column_subtract = 4'b0;
	bits_weight_control = 1'b0;
	weight_column_control = 2'b0;
	weight_row_control = 2'b0;
	size_weight_control = 1'b0;
	address_weight_select = 1'b0;
	select_weight_control = 3'b0;
	next_state_weight = S0;

	busy = 1'b1;
	
	case(current_state_input) // synopsys full_case parallel_case 
		S0:
			begin
				//busy = 1'b0;
				if(dut_run)
				begin 
					address_input_select = 2'b11;
					address_output_select = 2'b10;
					next_state_input = S1;
				end
				else
				begin 
					busy = 1'b0;
					next_state_input = S0;
				end 
			end
		S1:
			begin
				size_input_control = 1'b1;
				address_input_select = 2'b1;
				next_state_input = S2;
				if(sram_dut_read_data[7:0]==8'hff)
				begin 
					//busy=1'b0;
					next_state_input=S10;
				end	
			end
		S2: 
			begin
				bits_input_control = 1'b1;
				input_column_control = 2'b1;
				input_row_control = 2'b1;
				address_input_select = 2'b1;
				if(sram_dut_read_data[3:0]== 4'b0010)
					next_state_input = S3;
				else if(sram_dut_read_data[3:0]==4'b0100)
					next_state_input = S7;
				else if(sram_dut_read_data[3:0]==4'b1000)
					next_state_input = S9;
			end
		S3:
			begin 
				input_column_control = 2'b1;
				input_row_control = 2'b1;
				select_input_control = 3'b1;
				if(count_input_column == size_input)
					adder_control=1'b0;
				else
					adder_control=1'b1;
				next_state_input=S4;		
			end
		S4:
			begin
				input_column_control = 2'b1;
				input_row_control = 2'b1;
				adder_control=1'b1;
				select_input_control = 3'b10;
				next_state_input = S5;			 
			end
		S5:
			begin 
				input_column_control = 2'b1;
				input_row_control = 2'b1;
				adder_control=1'b1;
				select_input_control = 3'b11;
				next_state_input = S6;
			end
		S6:
			begin
				input_column_subtract = 8'b1000;
				control_input_shift = 8'b11;
				adder_control = 1'b1;
				select_input_control = 3'b100;
				address_input_select = 2'b01;
				next_state_input = S3;
				input_row_control = 2'b1;
				if(count_input_column == 8'b1000)
				begin 
					input_column_control = 2'b00;
					enable_write_control = 1'b1;
					address_output_select = 2'b1;
					if(count_input_row == 8'b1)
					begin
						next_state_input=S1; 
					end
					else
					begin
						address_input_select = 2'b10;
						input_row_control = 2'b10; 
					end
				end
				else
					input_column_control = 2'b10; 
			end
		S7:
			begin
				input_column_control = 2'b1;
				input_row_control = 2'b1;
				select_input_control = 3'b101;
				if(count_input_column == size_input)
					adder_control = 1'b0;
				else
					adder_control = 1'b1;
				next_state_input = S8;
			end	
		S8: 
			begin 
				input_column_subtract = 8'b0100;
				control_input_shift = 8'b10;
				adder_control = 1'b1;
				select_input_control = 3'b110;
				address_input_select = 2'b01;
				next_state_input = S7;
				input_row_control = 2'b1;
				if(count_input_column == 8'b0100)
				begin 
					input_column_control = 2'b00;
					enable_write_control = 1'b1;
					address_output_select = 2'b01;			
					if(count_input_row == 8'b1)
					begin
						next_state_input = S1; 
					end
					else
					begin 
						address_input_select = 2'b10;
						input_row_control = 2'b10;		
					end
				end 
				else
					input_column_control = 2'b10;
			end
		S9:
			begin 
				input_column_subtract = 8'b0010;
				control_input_shift = 8'b001;
				if(count_input_column == size_input)
					adder_control = 1'b0;
				else 
					adder_control = 1'b1;
				select_input_control = 3'b111;
				address_input_select = 2'b01;
				next_state_input = S9;
				input_row_control = 2'b1;
				if(count_input_column == 8'b0010)
				begin 
					input_column_control = 2'b00;
					enable_write_control = 1'b1;
					address_output_select = 2'b1;
					if(count_input_row == 8'b1)
						next_state_input = S1;
					else
					begin 
						address_input_select = 2'b10;
						input_row_control = 2'b10;
					end
				end
				else 
					input_column_control = 2'b10;
					
				
			end
		S10: 
			begin 
			next_state_input = S11;
			end
		S11: 
			begin 
				busy = 1'b0;
				next_state_input = S0; 
			end

		default : next_state_input = S0;
	endcase

	case(current_state_weight) //synopsys full_case parallel_case
	
	S0: begin
			if(dut_run)
			begin
				address_weight_select = 2'b10;
				next_state_weight = S1; 
			end 
			else
			begin 
				next_state_weight = S0;
			end 
	     end 
	S1:
		begin
			size_weight_control = 1'b1;
			address_weight_select = 1'b1;
			next_state_weight = S2;
			if(sram_dut_read_data[7:0]==8'hff)
				next_state_weight = S10;
		end
	S2:
		begin 
			bits_weight_control = 1'b1;
			weight_column_control = 2'b1;
			weight_row_control = 2'b1;
			address_weight_select = 1'b1;
			if(wmem_dut_read_data[3:0]==4'b1000)
				next_state_weight = S9;
			else if(wmem_dut_read_data[3:0] == 4'b0100)
				next_state_weight = S7;
			else 
				next_state_weight = S3;
		end
	S3: 	
		begin 
			weight_column_control = 2'b1;
			weight_row_control = 2'b1;
			select_weight_control = 3'b1;
			next_state_weight = S4;
		end
	S4: 
		begin 
			weight_column_control = 2'b1;
			weight_row_control = 2'b1;
			select_weight_control = 3'b10;
			next_state_weight = S5;
		end
	S5: 
		begin 
			weight_column_control = 2'b1;
			weight_row_control = 2'b1;
			select_weight_control = 3'b11;
			next_state_weight = S6;
		end 
	S6: 
		begin 
			weight_column_subtract = 8'b1000;
			address_weight_select = 1'b1;
			next_state_weight = S3;
			select_weight_control = 3'b100;
			if(count_weight_column==8'b1000)
			begin 
				weight_column_control = 2'b00;
				weight_row_control = 2'b10;
				if(count_weight_row==8'b1)
					next_state_weight = S1;
			end
			else
			begin
				weight_column_control = 2'b10;
				weight_row_control = 2'b01;
			end
		end
	S7: 
		begin 
			weight_column_control = 2'b01;
			weight_row_control = 2'b01;
			select_weight_control = 3'b101;
			next_state_weight = S8;
		end
	S8: 
		begin 
			weight_column_subtract = 8'b0100;
			address_weight_select = 1'b1;
			select_weight_control = 3'b110;
			next_state_weight = S7;
			if(count_weight_column==8'b0100)
			begin
				weight_column_control=2'b00;
				weight_row_control = 2'b10;
				if(count_weight_row==8'b1)
					next_state_weight = S1; 
			end
			else
			begin
				weight_column_control = 2'b10;
				weight_row_control = 2'b01; 
			end
		end
	S9: 
		begin 
			weight_column_subtract = 8'b0010;
			address_weight_select = 1'b1;
			select_weight_control = 3'b110;
			next_state_weight = S9;
			if(count_weight_column==8'b0010)
			begin
				weight_column_control=2'b00;
				weight_row_control = 2'b10;
				if(count_weight_row==8'b1)
					next_state_weight = S1; 
			end
			else
			begin
				weight_column_control = 2'b10;
				weight_row_control = 2'b01; 
			end

		end
	S10: next_state_weight = S11;
	S11: next_state_weight = S0;
	default: next_state_weight = S0;	
	endcase

	//$display("\nValue of busy : %d ",busy);

end



assign dut_busy = register_busy;

endmodule
