`timescale 1ns / 1ps

module alu_2 #(
    parameter STAGE_ID = 0,
    parameter ACTION_LEN = 64,
    parameter DATA_WIDTH = 32,  //data width of the ALU
    parameter ACTION_ID = 3,

	parameter C_S_AXIS_DATA_WIDTH = 256,
	parameter C_S_AXIS_TUSER_WIDTH = 128
)
(
    input clk,
    input rst_n,

    //input from sub_action
    input [ACTION_LEN-1:0]            action_in,
    input                             action_valid,
    input [DATA_WIDTH-1:0]            operand_1_in,
    input [DATA_WIDTH-1:0]            operand_2_in,
    input [DATA_WIDTH-1:0]            operand_3_in,
    input [DATA_WIDTH-1:0]            operand_4_in,
	output reg 						  ready_out,

	input [15:0]						page_tbl_out,
	input								page_tbl_out_valid,

    //output to form PHV
    output [DATA_WIDTH-1:0]				container_out_w,
    output reg							container_out_valid,
	input								ready_in

);

function integer addition (input integer in_a, in_b);
	addition = in_a + in_b;
endfunction : addition

function integer sub (input integer in_a, in_b);
	sub = in_b - in_a;
endfunction : sub

function integer equal_func (input integer in_a, in_b);
	equal_func = (in_a == in_b);
endfunction : equal_func

function integer not_equal_func (input integer in_a, in_b);
	not_equal_func = (in_b != in_a);
endfunction : not_equal_func

function integer geq_func (input integer in_a, in_b);
	geq_func = (in_a >= in_b);
endfunction : geq_func

function integer less_func (input integer in_a, in_b);
	less_func = (in_a < in_b);
endfunction : less_func

function integer ite_func (input integer in_a, in_b, in_c);
	if (in_a != 0)
	begin
		ite_func = in_b;
	end
	else
	begin
		ite_func = in_c;
	end
endfunction : ite_func

function integer temp_func(input integer in_a, in_b);
	if (geq_func(in_a, in_b))
	begin
		temp_func = 0;
	end
	else
	begin
		temp_func = in_a + 1;
	end
endfunction : temp_func

reg  [7:0]           action_type, action_type_next;

//regs for RAM access
reg                         store_en, store_en_next;
reg  [4:0]                  store_addr, store_addr_next;
wire [31:0]					store_din_w;
reg  [31:0]                 store_din, store_din_next;

wire [31:0]                 load_data;
wire [31:0]                 load_data_w;
wire [4:0]					load_addr;
// reg [4:0]                  load_addr, load_addr_next;

assign load_data_w = load_data;

reg  [2:0]                  alu_state, alu_state_next;
reg [DATA_WIDTH-1:0]		container_out, container_out_next;
reg							container_out_valid_next;

//regs/wires for isolation
wire [7:0]                  base_addr;
wire [7:0]                  addr_len;

assign {addr_len, base_addr} = page_tbl_out;

reg                         overflow, overflow_next;
reg 						ready_out_next;


/********intermediate variables declared here********/

//support tenant isolation
// assign load_addr = store_addr[4:0] + base_addr;
//assign load_addr = operand_2_in[4:0] + base_addr;
assign load_addr = operand_2_in[4:0];

assign store_din_w = (action_type==8'b00001100)?(temp_func(load_data, operand_3_in)):((action_type==8'b00001000)?store_din:
						((action_type==8'b00000111)?(load_data+1):0));

assign container_out_w = (action_type==8'b00001100)?(temp_func(load_data, operand_3_in)):((action_type==8'b00001011||action_type==8'b00001100)?load_data:
							(action_type==8'b00000111)?(load_data+1):
							container_out);

/*
7 operations to support:

1,2. add/sub:   00000001/00000010
              extract 2 operands from pkt header, add(sub) and write back.

3,4. addi/subi: 00001001/00001010
              extract op1 from pkt header, op2 from action, add(sub) and write back.

5: load:      00000101
              load data from RAM, write to pkt header according to addr in action.

6. store:     00000110
              read data from pkt header, write to ram according to addr in action.

7. loadd:     00000111
              load data from RAM, increment by 1 write it to container, and write it
              back to the RAM. 
8. set:	      00001110
	      set to an immediate value
*/

localparam  IDLE_S = 3'd0,
            EMPTY1_S = 3'd1,
            OB_ADDR_S = 3'd2,
            EMPTY2_S = 3'd3,
            OUTPUT_S = 3'd4,
	    HALT_S = 3'd5,
	    EMPTY2_S1 = 3'd6;

always @(*) begin
	alu_state_next = alu_state;

	action_type_next = action_type;
	container_out_next = container_out;

	store_addr_next = store_addr;
	store_din_next = store_din;
	store_en_next = 0;
	// load_addr_next = load_addr;
    overflow_next = overflow;

	container_out_valid_next = 0;

	ready_out_next = ready_out;
	
	case (alu_state)
		IDLE_S: begin
			
            if (action_valid) begin
				action_type_next = action_in[63:63-7];
                overflow_next = 0;
				alu_state_next = EMPTY1_S;
				ready_out_next = 1'b0;

                
                case(action_in[63:63-7])
                    //add/addi ops 
                    8'b00000001, 8'b00001001: begin
                        container_out_next = addition(operand_1_in, operand_2_in);
                    end 
                    //sub/subi ops
                    8'b00000010, 8'b00001010: begin
                        container_out_next = sub(operand_2_in, operand_1_in);
                    end
		    // TODO: add if-else ALU
		    8'b00001100: begin
			container_out_next = operand_3_in;
			store_addr_next = operand_2_in[4:0];
		    end
                    //store op (interact with RAM)
                    8'b00001000: begin
                        container_out_next = operand_3_in;
                        //store_en_r = 1;
                        store_addr_next = operand_2_in[4:0];
                        store_din_next = operand_1_in;
                    end
                    // load op (interact with RAM)
                    8'b00001011: begin
                        container_out_next = operand_3_in;
                    end
					// loadd op
                    8'b00000111: begin
                        // do nothing now
                        //checkme
                        container_out_next = operand_3_in;
                        store_addr_next = operand_2_in[4:0];
                    end
		    // set operation
		    8'b00001110: begin
		        container_out_next = operand_2_in;
		    end
                    8'b00000011: begin
			container_out_next = sub(operand_1_in, operand_2_in);
		    end
		    8'b00000100: begin
			container_out_next = not_equal_func(operand_1_in, operand_2_in);
		    end
		    8'b00000101: begin
			container_out_next = not_equal_func(operand_1_in, operand_2_in);
		    end
		    8'b00000110: begin
			container_out_next = equal_func(operand_1_in, operand_2_in);
		    end
		    8'b00010111: begin
			container_out_next = equal_func(operand_1_in, operand_2_in);
		    end
		    8'b00011000: begin
			container_out_next = geq_func(operand_1_in, operand_2_in);
		    end
		    8'b00011011: begin
			container_out_next = geq_func(operand_1_in, operand_2_in);
		    end
		    8'b00011100, 8'b00011101: begin
			container_out_next = less_func(operand_1_in, operand_2_in);
		    end
		    8'b00010100: begin
			container_out_next = not_equal_func(operand_1_in, 0);
		    end
		    8'b00010011: begin
			container_out_next = (not_equal_func(operand_1_in, 0) && not_equal_func(operand_2_in, 0));
		    end
		    8'b00010010: begin
			container_out_next = (not_equal_func(operand_1_in, 0) || not_equal_func(operand_2_in, 0));
		    end
		    8'b00010001, 8'b00010000: begin
			container_out_next = ite_func(operand_1_in, operand_2_in, operand_3_in);
		    end
                    //cannot go back to IDLE since this
                    //might be a legal action.
                    default: begin
                        container_out_next = operand_3_in;
                    end
				endcase

				//ok, if its `load` op, needs to check overflow.
            	if(action_in[63:63-7] == 8'b00001011 || action_in[63:63-7] == 8'b00000111 || action_in[63:63-7] == 8'b00001000 || action_in[63:63-7] == 8'b00001100) begin
            	    if(operand_2_in[4:0] > addr_len) begin
            	        overflow_next = 1'b1;
            	    end
            	    else begin
            	        overflow_next = 1'b0;
            	        //its the right time to write for `store`
            	        if(action_in[63:63-7] == 8'b00001000 || action_in[63:63-7] == 8'b00000111 || action_in[63:63-7] == 8'b00001100) begin
            	            //store_addr_next = base_addr + operand_2_in[4:0];
			    store_addr_next = operand_2_in[4:0];
            	            //store_din_r = operand_1_in;
            	            //store_en_next = 1'b1;
            	        end
            	    end
            	end
				// 
				// load_addr_next = operand_2_in[4:0] + base_addr;
				alu_state_next = EMPTY2_S;
			end
		end
        EMPTY2_S: begin
            //wait for the result of RAM
			if (ready_in) begin
				alu_state_next = IDLE_S;
				container_out_valid_next = 1;
				ready_out_next = 1;

				// action_type
				if ((action_type==8'b00001000 || action_type==8'b00000111 || action_type==8'b00001100) &&
						overflow==0) begin
					store_en_next = 1'b1;
				end
			end
			else begin
				alu_state_next = HALT_S;
			end
        end
		HALT_S: begin
			if (ready_in) begin
				alu_state_next = IDLE_S;
				container_out_valid_next = 1;
				ready_out_next = 1;

				// action_type
				if ((action_type==8'b00001000 || action_type==8'b00000111 || action_type==8'b00001100) &&
						overflow==0) begin
					store_en_next = 1'b1;
				end
			end
		end
	endcase
end

always @(posedge clk) begin
	if (~rst_n) begin
		alu_state <= IDLE_S;

		action_type <= 0;
		container_out <= 0;
		container_out_valid <= 0;

		store_en <= 0;
		store_addr <= 0;
		store_din <= 0;
		// load_addr <= 0;

        overflow <= 0;

		ready_out <= 1'b1;

	end
	else begin
		alu_state <= alu_state_next;
		action_type <= action_type_next;
		container_out <= container_out_next;
		container_out_valid <= container_out_valid_next;

		store_en <= store_en_next;
		store_addr <= store_addr_next;
		store_din <= store_din_next;
		// load_addr <= load_addr_next;

        overflow <= overflow_next;

		ready_out <= ready_out_next;

	end
end



blk_mem_gen_0
data_ram_32w_32d
(
    //store-related
    .addra(store_addr),
    .clka(clk),
    .dina(store_din_w),
    .ena(1'b1),
    .wea(store_en),

    //load-related
    .addrb(load_addr),
    .clkb(clk),
    .doutb(load_data),
    .enb(1'b1)
);


endmodule
