`timescale 1ns / 1ps
module key_extract #(
    parameter C_S_AXIS_DATA_WIDTH = 512,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
    parameter STAGE_ID = 0,
    parameter PHV_LEN = 4*8*64+256,
    parameter KEY_LEN = 4*8*8+1,
    // format of KEY_OFF entry: |--3(6B)--|--3(6B)--|--3(4B)--|--3(4B)--|--3(2B)--|--3(2B)--|
    parameter KEY_OFF = 8*6+20,
    parameter KEY_EX_ID = 1,
	parameter C_VLANID_WIDTH = 12
    )(
    input                               clk,
    input                               rst_n,
	//
    input [PHV_LEN-1:0]                 phv_in,
    input                               phv_valid_in,
	output								ready_out,
	// input from vlan fifo
	input								key_offset_valid,
	input [KEY_OFF-1:0]					key_offset_w,
	input [KEY_LEN-1:0]					key_mask_w,
	
	// output PHV and key
    output reg [PHV_LEN-1:0]            phv_out,
    output reg                          phv_valid_out,
    output [KEY_LEN-1:0]	            key_out_masked,
    output reg                          key_valid_out,
	input								ready_in
);


integer i;

// localparam WIDTH_2B = 16;
localparam WIDTH_4B = 32;
// localparam WIDTH_6B = 48;

//reg [KEY_LEN-1:0] key_out;

//24 fields to be retrived from the pkt header
// reg [WIDTH_2B-1:0]		cont_2B [0:63];
reg [WIDTH_4B-1:0]		cont_4B [0:63];
// reg [WIDTH_6B-1:0]		cont_6B [0:63];

// wire [19:0]				com_op;
// wire [47:0]				com_op_1, com_op_2;
// wire [47:0]				com_op_1_val, com_op_2_val;
//
reg [KEY_OFF-1:0]		key_offset_r;
//
reg [KEY_LEN-1:0]		key_mask_out_r;
//


// TODO: we may not need this right now
// assign com_op = key_offset_r[0+:20];
// assign com_op_1 = com_op[17]==1? {40'b0, com_op[16:9]} : com_op_1_val;
// assign com_op_1_val = com_op[13:12]==2?cont_6B[com_op[11:9]][7:0]:
// 						(com_op[13:12]==1?{16'b0, cont_4B[com_op[11:9]][7:0]}:
// 						(com_op[13:12]==0?{32'b0, cont_2B[com_op[11:9]][7:0]}:0));
// 
// assign com_op_2 = com_op[8]==1? {40'b0, com_op[7:0]} : com_op_2_val;
// assign com_op_2_val = com_op[4:3]==2?cont_6B[com_op[2:0]][7:0]:
// 						(com_op[4:3]==1?{16'b0, cont_4B[com_op[2:0]][7:0]}:
// 						(com_op[4:3]==0?{32'b0, cont_2B[com_op[2:0]][7:0]}:0));

localparam	IDLE_S=0,
			CYCLE_1=1;
reg [2:0] state, state_next;

reg [KEY_LEN-1:0] key_out; 
// reg ready_out_next;

assign ready_out = 1;

assign key_out_masked = key_out&(~key_mask_out_r);

always @(posedge clk) begin
	if (~rst_n) begin
		key_out <= 0;

		state <= IDLE_S;


		for (i=0; i<64; i=i+1) begin
//			cont_6B[i] <= 0;
			cont_4B[i] <= 0;
//			cont_2B[i] <= 0;
		end

		phv_out <= 0;
		phv_valid_out <= 0;
		key_valid_out <= 0;

		key_offset_r <= 0;
		key_mask_out_r <= 0;
	end
	else begin
		case (state)
			IDLE_S: begin
				if (phv_valid_in) begin
					key_offset_r <= key_offset_w;
					key_mask_out_r <= key_mask_w;
					phv_out <= phv_in;

					for (i=0; i<64; i=i+1) begin
// 						cont_6B[63-i] <= phv_in[PHV_LEN-1 - i*WIDTH_6B -: WIDTH_6B];
						cont_4B[63-i] <= phv_in[PHV_LEN-1 - i*WIDTH_4B -: WIDTH_4B];
//						cont_2B[64-i] <= phv_in[PHV_LEN-1 - 64*WIDTH_6B - 64*WIDTH_4B - i*WIDTH_2B -: WIDTH_4B];
					end

					state <= CYCLE_1;
				end
				else begin
					phv_valid_out <= 0;
					key_valid_out <= 0;
				end
			end
			CYCLE_1: begin
				for (i=0; i<8; i=i+1) begin
//					key_out[KEY_LEN-1 - i*WIDTH_6B -: WIDTH_6B] <= cont_6B[key_offset_r[KEY_OFF-1 - i*6 -: 6]];
					key_out[KEY_LEN-1 - i*WIDTH_4B -: WIDTH_4B] <= cont_4B[key_offset_r[KEY_OFF-1 - i*6 -: 6]];
//					key_out[KEY_LEN-1 - 32*WIDTH_6B - 32*WIDTH_4B - i*WIDTH_2B -: WIDTH_2B] <= cont_4B[key_offset_r[KEY_OFF-1 - 32*6 - 32*6 - i*6 -: 6]];
				end

				key_out[0] <= 1'b1;
				phv_valid_out <= 1;
				key_valid_out <= 1;

				state <= IDLE_S;
			end
		endcase
	end
end

endmodule
