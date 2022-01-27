`timescale 1ns / 1ps
module crossbar #(
    parameter STAGE_ID = 0,
    parameter PHV_LEN = 4*8*64+256,
    parameter ACT_LEN = 64,
	parameter C_NUM_PHVS = 64+1,
    parameter width_4B = 32
)
(
    input clk,
    input rst_n,

    //input from PHV
    input [PHV_LEN-1:0]         phv_in,
    input                       phv_in_valid,

    //input from action
    input [ACT_LEN*65-1:0]      action_in,
    input                       action_in_valid,
    output reg                  ready_out,

    //output to the ALU
    output reg                    alu_in_valid,
    output reg [width_4B*64-1:0]   alu_in_4B_1,
    output reg [width_4B*64-1:0]   alu_in_4B_2,
    output reg [width_4B*64-1:0]   alu_in_4B_3,
    output reg [width_4B*64-1:0]   alu_in_4B_4,

    output reg [255:0]            phv_remain_data,

    //I have to delay action_in for ALUs for 1 cycle
    output reg [ACT_LEN*65-1:0]   action_out,
    output reg                    action_valid_out,
    input                         ready_in
);

/********intermediate variables declared here********/
integer i;

wire [width_4B-1:0]      cont_4B [0:63];

wire [ACT_LEN-1:0]       sub_action [C_NUM_PHVS-1:0];


/********intermediate variables declared here********/

genvar cont_idx;
generate
	for (cont_idx=63; cont_idx>=0; cont_idx=cont_idx-1) 
	begin
		assign cont_4B[cont_idx] = phv_in[PHV_LEN-1 - width_4B*(63-cont_idx) -: width_4B];
	end
endgenerate

// Tao: get action for each PHV container
genvar act_idx;
generate 
	for (act_idx=0; act_idx<C_NUM_PHVS; act_idx=act_idx+1) 
	begin
		assign sub_action[act_idx] = action_in[act_idx*ACT_LEN +: ACT_LEN];
	end
endgenerate
//assign inputs for ALUs 

always @(posedge clk) begin
	action_out <= action_in;
	action_valid_out <= action_in_valid;
end

localparam IDLE = 0,
			PROCESS = 1,
			HALT = 2;

reg [2:0] state;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        // phv_reg <= 1124'b0;
        // action_full_reg <= 625'b0;
        // phv_valid_reg <= 1'b0;
        // action_valid_reg <= 1'b0;
        //reset outputs
        alu_in_valid <= 1'b0;
        phv_remain_data <= 256'b0;
        //reset all the outputs
        alu_in_4B_1 <= 256'b0;
        alu_in_4B_2 <= 256'b0;
        alu_in_4B_3 <= 256'b0;
        alu_in_4B_4 <= 256'b0;

		state <= IDLE;
		ready_out <= 1;
    end

    else begin
		case (state) 
			IDLE: begin

				if(phv_in_valid == 1'b1) begin
					if (ready_in) begin
						alu_in_valid <= 1'b1;
					end
					else begin
						ready_out <= 0;
						state <= HALT;
					end
        		    //assign values one by one (of course need to consider act format)
        		    //4B is a bit of differernt from 2B and 6B
        		    for(i=63; i>=0; i=i-1) begin
        		        alu_in_4B_3[(i+1)*width_4B-1 -: width_4B] <= cont_4B[i];
				alu_in_4B_4[(i+1)*width_4B-1 -: width_4B] <= cont_4B[i];
        		        casez(sub_action[i+1][63:63-7])
        		            //be noted that 2 ops need to be the same width
        		            8'b00000001, 8'b00000010: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
        		            end
        		            8'b00001001, 8'b00001010: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
        		            end
				    // set operation, operand A set to 0, operand B set to imm
				    8'b00001110: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= 32'b0;
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
				    end
        		            //loadd put here
        		            8'b00001011, 8'b00001000, 8'b00010111: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
        		            end
				    // const - pkt0
				    8'b00000011: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
				    end
				    // pkt0 != pkt1
				    8'b00000100: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
   				    end
				    // pkt_0 != const
				    8'b00000101: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
				    end
				    // pkt0 == pkt1
				    8'b00000110: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
				    end
				    // pkt0 == const
				    8'b00000111: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
				    end
				    // pkt0 >= pkt1, pkt0 < pkt1, pkt0 != 0 && pkt1 != 0, pkt0 != 0 || pkt1 != 0
				    8'b00011000, 8'b00011100, 8'b00010011, 8'b00010010: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
				    end
				    // pkt0 >= const, pkt0 < const
                                    8'b00011011, 8'b00011101: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
				    end
				    // pkt0 == 0
                                    8'b00010100: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
				    end
				    // pkt0 != 0 ? Pkt1 : pkt2
                                    8'b00010000: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
					alu_in_4B_3[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][43:43-5]];
				    end
				    // pkt0 != 0 ? Pkt1 : const
                                    8'b00010001: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
                                        alu_in_4B_3[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][31:0];
				    end
                                    // stateful if-else
				    8'b00001100: begin
					alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][55:55-5]];
					alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][49:49-5]];
					alu_in_4B_3[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[i+1][43:43-5]];
					// alu_in_4B_4: constant1-3: 6 + 6 + 6 = 18; 
					// sel1, sel2, sel3, sel4, sel5, sel6, rel_opcode: 1 + 2 + 1 + 2 + 1 + 2 + 2 = 11
					alu_in_4B_4[(i+1)*width_4B-1 -: width_4B] <= sub_action[i+1][37:37-31];
				    end
        		            //if there is no action to take, output the original value
        		            default: begin
        		                //alu_1 should be set to the phv value
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[i];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= 32'b0;
        		            end
        		        endcase
        		    end
        		    //the left is metadata & conditional ins, no need to modify
        		    phv_remain_data <= phv_in[255:0];
        		end 

        		else begin
        		    alu_in_valid <= 1'b0;
        		end
			end
			HALT: begin
				if (ready_in) begin
					alu_in_valid <= 1'b1;
					state <= IDLE;
					ready_out <= 1'b1;
				end
			end
		endcase
    end
end

endmodule
