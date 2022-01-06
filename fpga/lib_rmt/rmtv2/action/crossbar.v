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
    input [ACT_LEN*193-1:0]      action_in,
    input                       action_in_valid,
    output reg                  ready_out,

    //output to the ALU
    output reg                    alu_in_valid,
    output reg [width_4B*64-1:0]   alu_in_4B_1,
    output reg [width_4B*64-1:0]   alu_in_4B_2,
    output reg [width_4B*64-1:0]   alu_in_4B_3,
    output reg [255:0]            phv_remain_data,

    //I have to delay action_in for ALUs for 1 cycle
    output reg [ACT_LEN*193-1:0]   action_out,
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
	for (cont_idx=63; cont_idx>0; cont_idx=cont_idx-1) 
	begin
		assign cont_4B[cont_idx] = phv_in[PHV_LEN-1 - width_4B*(63-cont_idx) -: width_4B];
	end
endgenerate

// Tao: get action for each PHV container
genvar act_idx;
generate 
	for (act_idx=0; act_idx<C_NUM_PHVS; act_idx=act_idx+1) 
	begin
		assign sub_action[act_idx] = action_in[ACT_LEN*C_NUM_PHVS-1 - act_idx*ACT_LEN -: ACT_LEN];
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
        		        casez(sub_action[i+1][24:21])
        		            //be noted that 2 ops need to be the same width
        		            4'b0001, 4'b0010: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[64+i+1][18:16]];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[64+i+1][13:11]];
        		            end
        		            4'b1001, 4'b1010: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[64+i+1][18:16]];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= {16'b0,sub_action[64+i+1][15:0]};
        		            end
							// set operation, operand A set to 0, operand B set to imm
							4'b1110: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= 32'b0;
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= {16'b0,sub_action[64+i+1][15:0]};
							end
        		            //loadd put here
        		            4'b1011, 4'b1000, 4'b0111: begin
        		                alu_in_4B_1[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[64+i+1][18:16]];
        		                alu_in_4B_2[(i+1)*width_4B-1 -: width_4B] <= cont_4B[sub_action[64+i+1][13:11]];
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
