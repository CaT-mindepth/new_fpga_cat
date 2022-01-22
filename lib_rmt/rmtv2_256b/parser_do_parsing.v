`timescale 1ns / 1ps

`define DEF_MAC_ADDR	48
`define DEF_VLAN		32
`define DEF_ETHTYPE		16

`define TYPE_IPV4		16'h0008
`define TYPE_ARP		16'h0608

`define PROT_ICMP		8'h01
`define PROT_TCP		8'h06
`define PROT_UDP		8'h11

// 01 --> 2B, 10 --> 4B, 11 --> 6B
`define SUB_PARSE(idx) \
	case(sub_parse_val_out_type[idx]) \
		2'b01: ; \
		2'b10: val_4B_nxt[sub_parse_val_out_seq[idx]] = sub_parse_val_out[idx][31:0]; \
		2'b11: ; \
		default: ; \
	endcase \

`define SWAP_BYTE_ORDER(idx) \
	assign val_4B_swapped[idx] = {	val_4B[idx][0+:8], \
									val_4B[idx][8+:8], \
									val_4B[idx][16+:8], \
									val_4B[idx][24+:8]}; \

module parser_do_parsing #(
	parameter C_AXIS_DATA_WIDTH = 256,
	parameter C_AXIS_TUSER_WIDTH = 128,
	parameter PKT_HDR_LEN = 4*8*64+256, // check with the doc
	parameter PARSER_MOD_ID = 3'b0,
	parameter C_NUM_SEGS = 16,
	parameter C_VLANID_WIDTH = 12,
	parameter C_NUM_PARSE_ACTION = 64,
	parameter C_WIDTH_PARSE_ACTION = 24
)
(
	input														axis_clk,
	input														aresetn,

	input [C_NUM_SEGS*C_AXIS_DATA_WIDTH-1:0]					tdata_segs,
	input [C_AXIS_TUSER_WIDTH-1:0]								tuser_1st,
	input														segs_valid,
	input [C_NUM_PARSE_ACTION*C_WIDTH_PARSE_ACTION-1:0]			bram_out,


	input											stg_ready_in,
	// output

	// phv output
	output reg										parser_valid,
	output reg [PKT_HDR_LEN-1:0]					pkt_hdr_vec,

	output reg [C_VLANID_WIDTH-1:0]					out_vlan,
	output reg										out_vlan_valid,
	input											out_vlan_ready

);

localparam			IDLE=0,
					WAIT_1CYCLE_RAM=1,
					START_SUB_PARSE=2,
					FINISH_SUB_PARSE=3,
					GET_PHV_OUTPUT=4,
					OUTPUT=5;
					

//
reg [PKT_HDR_LEN-1:0]	pkt_hdr_vec_next;
reg parser_valid_next;
reg [3:0] state, state_next;
reg [C_VLANID_WIDTH-1:0]	out_vlan_next;
reg							out_vlan_valid_next;

// parsing actions
wire [C_WIDTH_PARSE_ACTION-1:0] parse_action [0:C_NUM_PARSE_ACTION-1];		// we have 10 parse action

genvar parse_action_idx;

generate
	for (parse_action_idx=0; parse_action_idx<C_NUM_PARSE_ACTION; parse_action_idx=parse_action_idx+1)
	begin
		assign parse_action[C_NUM_PARSE_ACTION-1-parse_action_idx] = bram_out[(parse_action_idx)*C_WIDTH_PARSE_ACTION+:C_WIDTH_PARSE_ACTION];
	end
endgenerate

reg [C_NUM_PARSE_ACTION-1:0] sub_parse_act_valid;
// reg [C_WIDTH_PARSE_ACTION-1:0] sub_parse_act [0:C_NUM_PARSE_ACTION-1];
wire [47:0] sub_parse_val_out [0:C_NUM_PARSE_ACTION-1];
wire [C_NUM_PARSE_ACTION-1:0] sub_parse_val_out_valid;
wire [1:0] sub_parse_val_out_type [0:C_NUM_PARSE_ACTION-1];
wire [2:0] sub_parse_val_out_seq [0:C_NUM_PARSE_ACTION-1];

reg [31:0] val_4B [0:63];
reg [31:0] val_4B_nxt [0:63];

wire [31:0] val_4B_swapped [0:63];

genvar swap_con_idx;
generate 
	for (swap_con_idx=0; swap_con_idx<64; swap_con_idx=swap_con_idx+1)
	begin
		`SWAP_BYTE_ORDER(swap_con_idx)
	end
endgenerate

integer con_idx, sub_parse_idx;

always @(*) begin
	state_next = state;
	//
	parser_valid_next = 0;
	pkt_hdr_vec_next = pkt_hdr_vec;
	//
	out_vlan_next = out_vlan;
	out_vlan_valid_next = 0;
	//
	for (con_idx=0; con_idx<64; con_idx=con_idx+1)
	begin
		val_4B_nxt[con_idx]=val_4B[con_idx];
	end
	//
	sub_parse_act_valid = {C_NUM_PARSE_ACTION{1'b0}};
	//

	case (state)
		IDLE: begin
			if (segs_valid) begin
				out_vlan_next = tdata_segs[116+:12];
				sub_parse_act_valid = {C_NUM_PARSE_ACTION{1'b1}};
				state_next = FINISH_SUB_PARSE;
			end
		end
		FINISH_SUB_PARSE: begin
			state_next = GET_PHV_OUTPUT;

			for (sub_parse_idx=0; sub_parse_idx<C_NUM_PARSE_ACTION; sub_parse_idx=sub_parse_idx+1)
			begin
				`SUB_PARSE(sub_parse_idx)
			end
		end
		GET_PHV_OUTPUT: begin
			if (out_vlan_ready) begin
				out_vlan_valid_next = 1;
			end
			state_next = OUTPUT;
			pkt_hdr_vec_next ={
							val_4B_swapped[63], val_4B_swapped[62], val_4B_swapped[61], val_4B_swapped[60], val_4B_swapped[59], val_4B_swapped[58], val_4B_swapped[57], val_4B_swapped[56],
							val_4B_swapped[55], val_4B_swapped[54], val_4B_swapped[53], val_4B_swapped[52], val_4B_swapped[51], val_4B_swapped[50], val_4B_swapped[49], val_4B_swapped[48],
							val_4B_swapped[47], val_4B_swapped[46], val_4B_swapped[45], val_4B_swapped[44], val_4B_swapped[43], val_4B_swapped[42], val_4B_swapped[41], val_4B_swapped[40],
							val_4B_swapped[39], val_4B_swapped[38], val_4B_swapped[37], val_4B_swapped[36], val_4B_swapped[35], val_4B_swapped[34], val_4B_swapped[33], val_4B_swapped[32],
							val_4B_swapped[31], val_4B_swapped[30], val_4B_swapped[29], val_4B_swapped[28], val_4B_swapped[27], val_4B_swapped[26], val_4B_swapped[25], val_4B_swapped[24],
							val_4B_swapped[23], val_4B_swapped[22], val_4B_swapped[21], val_4B_swapped[20], val_4B_swapped[19], val_4B_swapped[18], val_4B_swapped[17], val_4B_swapped[16],
							val_4B_swapped[15], val_4B_swapped[14], val_4B_swapped[13], val_4B_swapped[12], val_4B_swapped[11], val_4B_swapped[10], val_4B_swapped[9], val_4B_swapped[8],
							val_4B_swapped[7], val_4B_swapped[6], val_4B_swapped[5], val_4B_swapped[4], val_4B_swapped[3], val_4B_swapped[2], val_4B_swapped[1], val_4B_swapped[0],
							// Tao: manually set output port to 1 for eazy test
							// {115{1'b0}}, vlan_id, 1'b0, tuser_1st[127:32], 8'h04, tuser_1st[23:0]};
							{115{1'b0}}, out_vlan, 1'b0, tuser_1st[127:32], 8'h04, tuser_1st[23:0]};
							// {115{1'b0}}, vlan_id, 1'b0, tuser_1st};
							// {128{1'b0}}, tuser_1st[127:32], 8'h04, tuser_1st[23:0]};
		end
		OUTPUT: begin
			if (stg_ready_in) begin
				parser_valid_next = 1;
				state_next = IDLE;
				
				// zero out
				for (con_idx=0; con_idx<64; con_idx=con_idx+1) begin
					val_4B_nxt[con_idx]=0;
				end
			end
		end
	endcase
end



always @(posedge axis_clk) begin
	if (~aresetn) begin
		state <= IDLE;
		//
		pkt_hdr_vec <= 0;
		parser_valid <= 0;
		//
		out_vlan <= 0;
		out_vlan_valid <= 0;
		//
		for (con_idx=0; con_idx<64; con_idx=con_idx+1)
		begin
			val_4B[con_idx] <= 0;
		end
	end
	else begin
		state <= state_next;
		//
		pkt_hdr_vec <= pkt_hdr_vec_next;
		parser_valid <= parser_valid_next;
		//
		out_vlan <= out_vlan_next;
		out_vlan_valid <= out_vlan_valid_next;
		//
		for (con_idx=0; con_idx<64; con_idx=con_idx+1)
		begin
			val_4B[con_idx] <= val_4B_nxt[con_idx];
		end
	end
end

// =============================================================== //
// sub parser
generate
	genvar index;
	for (index=0; index<C_NUM_PARSE_ACTION; index=index+1) begin:
		sub_op
		sub_parser #(
			.PKTS_HDR_LEN(),
			.PARSE_ACT_LEN(),
			.VAL_OUT_LEN()
		)
		sub_parser (
			.clk				(axis_clk),
			.aresetn			(aresetn),

			.parse_act_valid	(sub_parse_act_valid[index]),
			// .parse_act			(sub_parse_act[index]),
			.parse_act			(parse_action[index]),

			.pkts_hdr			(tdata_segs),
			.val_out_valid		(sub_parse_val_out_valid[index]),
			.val_out			(sub_parse_val_out[index]),
			.val_out_type		(sub_parse_val_out_type[index]),
			.val_out_seq		(sub_parse_val_out_seq[index])
		);
	end
endgenerate


endmodule
