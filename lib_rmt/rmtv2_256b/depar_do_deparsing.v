`timescale 1ns / 1ps

`define SUB_DEPARSE(idx) \
	if(parse_action[idx][0]) begin \
		case(sub_depar_val_out_type[idx]) \
			2'b01: ; \
			2'b10: pkts_tdata_stored_next[parse_action_ind_10b[idx]<<3 +: 32] = sub_depar_val_out_swapped[idx][16+:32]; \
			2'b11: ; \
			default: ; \
		endcase \
	end \

`define SWAP_BYTE_ORDER(idx) \
	assign sub_depar_val_out_swapped[idx] = {	sub_depar_val_out[idx][0+:8], \
												sub_depar_val_out[idx][8+:8], \
												sub_depar_val_out[idx][16+:8], \
												sub_depar_val_out[idx][24+:8], \
												sub_depar_val_out[idx][32+:8], \
												sub_depar_val_out[idx][40+:8]}; \

module depar_do_deparsing #(
	parameter	C_AXIS_DATA_WIDTH = 256,
	parameter	C_AXIS_TUSER_WIDTH = 128,
	parameter	C_PKT_VEC_WIDTH = 4*64*8+256,
	parameter	DEPARSER_MOD_ID = 3'b101,
	parameter	C_NUM_SEGS = 4,
	parameter	C_VLANID_WIDTH = 12,
	parameter	C_WIDTH_PARSE_ACTION = 24,
	parameter	C_NUM_PARSE_ACTION = 64,
	parameter	C_PARSER_RAM_WIDTH = C_WIDTH_PARSE_ACTION * C_NUM_PARSE_ACTION
)
(
	input													clk,
	input													aresetn,

	// phv
	input [C_PKT_VEC_WIDTH-1:0]								phv_fifo_out,
	input													phv_fifo_empty,
	output reg												phv_fifo_rd_en,

	//
	input [C_AXIS_DATA_WIDTH-1:0]							pkt_fifo_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]							pkt_fifo_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]							pkt_fifo_tkeep,
	input													pkt_fifo_tlast,
	input													pkt_fifo_empty,
	output reg												pkt_fifo_rd_en,

	// output
	output reg [C_AXIS_DATA_WIDTH-1:0]						depar_out_tdata,
	output reg [C_AXIS_DATA_WIDTH/8-1:0]					depar_out_tkeep,
	output reg [C_AXIS_TUSER_WIDTH-1:0]						depar_out_tuser,
	output reg												depar_out_tvalid,
	output reg												depar_out_tlast,
	input													depar_out_tready,

	// control path
	input [C_AXIS_DATA_WIDTH-1:0]							ctrl_s_axis_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]							ctrl_s_axis_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]							ctrl_s_axis_tkeep,
	input													ctrl_s_axis_tvalid,
	input													ctrl_s_axis_tlast
);

reg [C_AXIS_DATA_WIDTH-1:0]						depar_out_tdata_next;
reg [C_AXIS_DATA_WIDTH/8-1:0]					depar_out_tkeep_next;
reg [C_AXIS_TUSER_WIDTH-1:0]					depar_out_tuser_next;
reg												depar_out_tvalid_next;
reg												depar_out_tlast_next;

wire [C_PARSER_RAM_WIDTH-1:0] bram_out;
wire [8:0] parse_action_ind [0:C_NUM_PARSE_ACTION-1];
wire [11:0] parse_action_ind_10b [0:C_NUM_PARSE_ACTION-1];


wire [C_WIDTH_PARSE_ACTION-1:0] parse_action [0:C_NUM_PARSE_ACTION-1];		// we have 10 parse action

genvar parse_act_idx;
generate
	for (parse_act_idx=0; parse_act_idx<C_NUM_PARSE_ACTION; parse_act_idx=parse_act_idx+1)
	begin
		assign parse_action[parse_act_idx] = bram_out[C_PARSER_RAM_WIDTH -1 -parse_act_idx*C_WIDTH_PARSE_ACTION -: C_WIDTH_PARSE_ACTION];
		assign parse_action_ind[parse_act_idx] = parse_action[parse_act_idx][17:9];
		assign parse_action_ind_10b[parse_act_idx] = parse_action_ind[parse_act_idx];
	end
endgenerate

reg	[C_NUM_PARSE_ACTION-1:0]					sub_depar_act_valid;

wire [47:0]					sub_depar_val_out [0:C_NUM_PARSE_ACTION-1];
wire [47:0]					sub_depar_val_out_swapped [0:C_NUM_PARSE_ACTION-1];
wire [1:0]					sub_depar_val_out_type [0:C_NUM_PARSE_ACTION-1];
wire [C_NUM_PARSE_ACTION-1:0]					sub_depar_val_out_valid;


genvar idx;
generate
	for (idx=0; idx<C_NUM_PARSE_ACTION; idx=idx+1)
	begin
		`SWAP_BYTE_ORDER(idx)
	end
endgenerate

wire discard_signal;
assign discard_signal = phv_fifo_out[128];

localparam		IDLE=0,
				WAIT_1CYCLE_RAM=1,
				START_SUB_DEPARSE=2,
				FINISH_SUB_DEPARSER_0=3,
				FINISH_SUB_DEPARSER_1=4,
				FINISH_SUB_DEPARSER_2=5,
				FLUSH_PKT_0=6,
				FLUSH_PKT_1=7,
				FLUSH_PKT_2=8,
				FLUSH_PKT_3=9,
				FLUSH_PKT=10,
				DROP_PKT=11,
				DROP_PKT_REMAINING=12,
				WAIT_1CYCLE = 13,
				WAIT_2CYCLE = 14,
				WAIT_3CYCLE = 15,
				WAIT_4CYCLE = 16,
				WAIT_5CYCLE = 17,
				WAIT_6CYCLE = 18,
				WAIT_7CYCLE = 19,
				WAIT_8CYCLE = 20,
				WAIT_9CYCLE = 21,
				WAIT_10CYCLE = 22,
				WAIT_11CYCLE = 23,
				WAIT_12CYCLE = 24,
				WAIT_13CYCLE = 25,
				WAIT_14CYCLE = 26,
				WAIT_15CYCLE = 27,
				FLUSH_PKT_4 = 28,
				FLUSH_PKT_5 = 29,
				FLUSH_PKT_6 = 30,
				FLUSH_PKT_7 = 31,
				FLUSH_PKT_8 = 32,
				FLUSH_PKT_9 = 33,
				FLUSH_PKT_10 = 34,
				FLUSH_PKT_11 = 35,
				FLUSH_PKT_12 = 36,
				FLUSH_PKT_13 = 37,
				FLUSH_PKT_14 = 38,
				FLUSH_PKT_15 = 39;

reg [16*C_AXIS_DATA_WIDTH-1:0]		pkts_tdata_stored;
reg [16*C_AXIS_TUSER_WIDTH-1:0]		pkts_tuser_stored;
reg [16*(C_AXIS_DATA_WIDTH/8)-1:0]	pkts_tkeep_stored;
reg [15:0]							pkts_tlast_stored;
reg [16*C_AXIS_DATA_WIDTH-1:0]		pkts_tdata_stored_next;
reg [16*C_AXIS_TUSER_WIDTH-1:0]		pkts_tuser_stored_next;
reg [16*(C_AXIS_DATA_WIDTH/8)-1:0]	pkts_tkeep_stored_next;
reg [15:0]							pkts_tlast_stored_next;

reg [6:0] state, state_next;
reg if_last_seen, if_last_seen_next;

wire [11:0] vlan_id;

assign vlan_id = phv_fifo_out[140:129];

`define DEPARSE_WAIT(state_from, state_to, idx) \
	``state_from``: begin \
		if (!pkt_fifo_empty) begin \
			pkts_tdata_stored_next[idx*C_AXIS_DATA_WIDTH +: C_AXIS_DATA_WIDTH] = pkt_fifo_tdata; \
			pkts_tuser_stored_next[idx*C_AXIS_TUSER_WIDTH +: C_AXIS_TUSER_WIDTH] = pkt_fifo_tuser; \
			pkts_tkeep_stored_next[idx*C_AXIS_DATA_WIDTH/8 +: C_AXIS_DATA_WIDTH/8] = pkt_fifo_tkeep; \
			pkts_tlast_stored_next[idx] = pkt_fifo_tlast; \
			pkt_fifo_rd_en = 1; \
			if (pkt_fifo_tlast != 1) begin \
				state_next = ``state_to``; \
			end \
			else begin \
				state_next = START_SUB_DEPARSE; \
				if_last_seen_next = 1; \
			end \
		end \
	end \

integer i;

`define FLUSH_OUT_PKT(state_from, state_to, idx) \
		``state_from``: begin \
			depar_out_tdata_next = pkts_tdata_stored[(C_AXIS_DATA_WIDTH*idx)+:C_AXIS_DATA_WIDTH]; \
			depar_out_tuser_next = pkts_tuser_stored[(C_AXIS_TUSER_WIDTH*idx)+:C_AXIS_TUSER_WIDTH]; \
			depar_out_tkeep_next = pkts_tkeep_stored[(C_AXIS_DATA_WIDTH/8*idx)+:(C_AXIS_DATA_WIDTH/8)]; \
			depar_out_tlast_next = pkts_tlast_stored[idx]; \
			if (depar_out_tready) begin \
				depar_out_tvalid_next = 1; \
				if (pkts_tlast_stored[idx]) begin \
					state_next = IDLE; \
				end \
				else begin \
					state_next = ``state_to``; \
				end \
			end \
		end \

always @(*) begin

	pkt_fifo_rd_en = 0;
	phv_fifo_rd_en = 0;
	// output
	depar_out_tdata_next = depar_out_tdata;
	depar_out_tuser_next = depar_out_tuser;
	depar_out_tkeep_next = depar_out_tkeep;
	depar_out_tlast_next = depar_out_tlast;
	depar_out_tvalid_next = 0;

	sub_depar_act_valid = 10'b0;

	state_next = state;
	if_last_seen_next = if_last_seen;
	//
	pkts_tdata_stored_next = pkts_tdata_stored;
	pkts_tuser_stored_next = pkts_tuser_stored;
	pkts_tkeep_stored_next = pkts_tkeep_stored;
	pkts_tlast_stored_next = pkts_tlast_stored;

	case (state) 
		IDLE: begin
			if (!pkt_fifo_empty && !phv_fifo_empty) begin
				state_next = WAIT_1CYCLE;

				pkts_tdata_stored_next[0*C_AXIS_DATA_WIDTH +: C_AXIS_DATA_WIDTH] = pkt_fifo_tdata;
				pkts_tuser_stored_next[0*C_AXIS_TUSER_WIDTH +: C_AXIS_TUSER_WIDTH] = phv_fifo_out[127:0];
				pkts_tkeep_stored_next[0*C_AXIS_DATA_WIDTH/8 +: C_AXIS_DATA_WIDTH/8] = pkt_fifo_tkeep;
				pkts_tlast_stored_next[0] = pkt_fifo_tlast;

				pkt_fifo_rd_en = 1;
			end
		end
		`DEPARSE_WAIT(WAIT_1CYCLE, WAIT_2CYCLE, 1)
		`DEPARSE_WAIT(WAIT_2CYCLE, WAIT_3CYCLE, 2)
		`DEPARSE_WAIT(WAIT_3CYCLE, WAIT_4CYCLE, 3)
		`DEPARSE_WAIT(WAIT_4CYCLE, WAIT_5CYCLE, 4)
		`DEPARSE_WAIT(WAIT_5CYCLE, WAIT_6CYCLE, 5)
		`DEPARSE_WAIT(WAIT_6CYCLE, WAIT_7CYCLE, 6)
		`DEPARSE_WAIT(WAIT_7CYCLE, WAIT_8CYCLE, 7)
		`DEPARSE_WAIT(WAIT_8CYCLE, WAIT_9CYCLE, 8)
		`DEPARSE_WAIT(WAIT_9CYCLE, WAIT_10CYCLE, 9)
		`DEPARSE_WAIT(WAIT_10CYCLE, WAIT_11CYCLE, 10)
		`DEPARSE_WAIT(WAIT_11CYCLE, WAIT_12CYCLE, 11)
		`DEPARSE_WAIT(WAIT_12CYCLE, WAIT_13CYCLE, 12)
		`DEPARSE_WAIT(WAIT_13CYCLE, WAIT_14CYCLE, 13)
		`DEPARSE_WAIT(WAIT_14CYCLE, WAIT_15CYCLE, 14)
		WAIT_15CYCLE: begin
			pkt_fifo_rd_en = 1;
			pkts_tdata_stored_next[15*C_AXIS_DATA_WIDTH +: C_AXIS_DATA_WIDTH] = pkt_fifo_tdata;
			pkts_tuser_stored_next[15*C_AXIS_TUSER_WIDTH +: C_AXIS_TUSER_WIDTH] = pkt_fifo_tuser;
			pkts_tkeep_stored_next[15*C_AXIS_DATA_WIDTH/8 +: C_AXIS_DATA_WIDTH/8] = pkt_fifo_tkeep;
			pkts_tlast_stored_next[15] = pkt_fifo_tlast;

			state_next = START_SUB_DEPARSE;
		end
		START_SUB_DEPARSE: begin
			if (discard_signal == 1) begin
				state_next = DROP_PKT;
				phv_fifo_rd_en = 1;
			end
			else begin
				sub_depar_act_valid = {C_NUM_PARSE_ACTION{1'b1}};

				state_next = FINISH_SUB_DEPARSER_0;
			end
		end
		FINISH_SUB_DEPARSER_0: begin
			for (i=0; i<C_NUM_PARSE_ACTION; i=i+1) 
			begin
				`SUB_DEPARSE(i)
			end

			state_next = FLUSH_PKT_0;
		end
		FLUSH_PKT_0: begin
			depar_out_tdata_next = pkts_tdata_stored[0+:C_AXIS_DATA_WIDTH];
			depar_out_tuser_next = pkts_tuser_stored[0+:C_AXIS_TUSER_WIDTH];
			depar_out_tkeep_next = pkts_tkeep_stored[0+:(C_AXIS_DATA_WIDTH/8)];
			depar_out_tlast_next = pkts_tlast_stored[0];
			if (depar_out_tready) begin
				phv_fifo_rd_en = 1;
				depar_out_tvalid_next = 1;
				if (pkts_tlast_stored[0]) begin
					state_next = IDLE;
				end
				else begin
					state_next = FLUSH_PKT_1;
				end
			end
		end

		`FLUSH_OUT_PKT(FLUSH_PKT_1, FLUSH_PKT_2, 1)
		`FLUSH_OUT_PKT(FLUSH_PKT_2, FLUSH_PKT_3, 2)
		`FLUSH_OUT_PKT(FLUSH_PKT_3, FLUSH_PKT_4, 3)
		`FLUSH_OUT_PKT(FLUSH_PKT_4, FLUSH_PKT_5, 4)
		`FLUSH_OUT_PKT(FLUSH_PKT_5, FLUSH_PKT_6, 5)
		`FLUSH_OUT_PKT(FLUSH_PKT_6, FLUSH_PKT_7, 6)
		`FLUSH_OUT_PKT(FLUSH_PKT_7, FLUSH_PKT_8, 7)
		`FLUSH_OUT_PKT(FLUSH_PKT_8, FLUSH_PKT_9, 8)
		`FLUSH_OUT_PKT(FLUSH_PKT_9, FLUSH_PKT_10, 9)
		`FLUSH_OUT_PKT(FLUSH_PKT_10, FLUSH_PKT_11, 10)
		`FLUSH_OUT_PKT(FLUSH_PKT_11, FLUSH_PKT_12, 11)
		`FLUSH_OUT_PKT(FLUSH_PKT_12, FLUSH_PKT_13, 12)
		`FLUSH_OUT_PKT(FLUSH_PKT_13, FLUSH_PKT_14, 13)
		`FLUSH_OUT_PKT(FLUSH_PKT_14, FLUSH_PKT_15, 14)
		`FLUSH_OUT_PKT(FLUSH_PKT_15, FLUSH_PKT, 15)

		// FLUSH_PKT_15: begin
		// 	depar_out_tdata_next = pkts_tdata_stored[(C_AXIS_DATA_WIDTH*15)+:C_AXIS_DATA_WIDTH];
		// 	depar_out_tuser_next = pkts_tuser_stored[(C_AXIS_TUSER_WIDTH*15)+:C_AXIS_TUSER_WIDTH];
		// 	depar_out_tkeep_next = pkts_tkeep_stored[(C_AXIS_DATA_WIDTH/8*15)+:(C_AXIS_DATA_WIDTH/8)];
		// 	depar_out_tlast_next = pkts_tlast_stored[idx];
		// 	if (depar_out_tready) begin
		// 		depar_out_tvalid_next = 1;
		// 		if (pkts_tlast_stored[15]) begin
		// 			state_next = IDLE;
		// 		end
		// 		else begin
		// 			state_next = FLUSH_PKT;
		// 		end
		// 	end
		// end


		FLUSH_PKT: begin
			if (!pkt_fifo_empty) begin
				depar_out_tdata_next = pkt_fifo_tdata;
				depar_out_tuser_next =  pkt_fifo_tuser;
				depar_out_tkeep_next =  pkt_fifo_tkeep;
				depar_out_tlast_next =  pkt_fifo_tlast;
				if (depar_out_tready) begin
					pkt_fifo_rd_en = 1;
					depar_out_tvalid_next = 1;
					if (pkt_fifo_tlast) begin
						state_next = IDLE;
					end
				end
			end
		end
		DROP_PKT: begin
			if (if_last_seen) begin
				state_next = IDLE;
				if_last_seen_next = 0;
			end
			else begin
				state_next = DROP_PKT_REMAINING;
			end
		end
		DROP_PKT_REMAINING: begin
			pkt_fifo_rd_en = 1;
			if (pkt_fifo_tlast) begin
				state_next = IDLE;
				if_last_seen_next = 1;
			end
		end
	endcase
end

always @(posedge clk) begin
	if (~aresetn) begin
		state <= IDLE;
		if_last_seen <= 0;
		//
		pkts_tdata_stored <= 0;
		pkts_tuser_stored <= 0;
		pkts_tkeep_stored <= 0;
		pkts_tlast_stored <= 0;
		//
		depar_out_tdata <= 0;
		depar_out_tkeep <= 0;
		depar_out_tuser <= 0;
		depar_out_tlast <= 0;
		depar_out_tvalid <= 0;
	end
	else begin
		state <= state_next;
		if_last_seen <= if_last_seen_next;
		//
		pkts_tdata_stored <= pkts_tdata_stored_next;
		pkts_tuser_stored <= pkts_tuser_stored_next;
		pkts_tkeep_stored <= pkts_tkeep_stored_next;
		pkts_tlast_stored <= pkts_tlast_stored_next;
		//
		depar_out_tdata <= depar_out_tdata_next;
		depar_out_tkeep <= depar_out_tkeep_next;
		depar_out_tuser <= depar_out_tuser_next;
		depar_out_tlast <= depar_out_tlast_next;
		depar_out_tvalid <= depar_out_tvalid_next;
	end
end


//===================== sub deparser
generate
	genvar index;
	for (index=0; index<C_NUM_PARSE_ACTION; index=index+1) 
	begin: sub_op
		sub_deparser #(
			.C_PKT_VEC_WIDTH(),
			.C_PARSE_ACT_LEN()
		)
		sub_deparser (
			.clk				(clk),
			.aresetn			(aresetn),
			.parse_act_valid	(sub_depar_act_valid[index]),
			.parse_act			(parse_action[index][8:0]),
			.phv_in				(phv_fifo_out),
			.val_out_valid		(sub_depar_val_out_valid[index]),
			.val_out			(sub_depar_val_out[index]),
			.val_out_type		(sub_depar_val_out_type[index])
		);
	end
endgenerate


/*================Control Path====================*/
wire [C_AXIS_DATA_WIDTH-1:0] ctrl_s_axis_tdata_swapped;

assign ctrl_s_axis_tdata_swapped = {	ctrl_s_axis_tdata[0+:8],
										ctrl_s_axis_tdata[8+:8],
										ctrl_s_axis_tdata[16+:8],
										ctrl_s_axis_tdata[24+:8],
										ctrl_s_axis_tdata[32+:8],
										ctrl_s_axis_tdata[40+:8],
										ctrl_s_axis_tdata[48+:8],
										ctrl_s_axis_tdata[56+:8],
										ctrl_s_axis_tdata[64+:8],
										ctrl_s_axis_tdata[72+:8],
										ctrl_s_axis_tdata[80+:8],
										ctrl_s_axis_tdata[88+:8],
										ctrl_s_axis_tdata[96+:8],
										ctrl_s_axis_tdata[104+:8],
										ctrl_s_axis_tdata[112+:8],
										ctrl_s_axis_tdata[120+:8],
										ctrl_s_axis_tdata[128+:8],
										ctrl_s_axis_tdata[136+:8],
										ctrl_s_axis_tdata[144+:8],
										ctrl_s_axis_tdata[152+:8],
										ctrl_s_axis_tdata[160+:8],
										ctrl_s_axis_tdata[168+:8],
										ctrl_s_axis_tdata[176+:8],
										ctrl_s_axis_tdata[184+:8],
										ctrl_s_axis_tdata[192+:8],
										ctrl_s_axis_tdata[200+:8],
										ctrl_s_axis_tdata[208+:8],
										ctrl_s_axis_tdata[216+:8],
										ctrl_s_axis_tdata[224+:8],
										ctrl_s_axis_tdata[232+:8],
										ctrl_s_axis_tdata[240+:8],
										ctrl_s_axis_tdata[248+:8]};


reg	[7:0]						ctrl_wr_ram_addr, ctrl_wr_ram_addr_next;
reg	[C_PARSER_RAM_WIDTH-1:0]	ctrl_wr_ram_data, ctrl_wr_ram_data_next;
reg								ctrl_wr_ram_en, ctrl_wr_ram_en_next;
wire [7:0]						ctrl_mod_id;

assign ctrl_mod_id = ctrl_s_axis_tdata[112+:8];

localparam	WAIT_FIRST_PKT = 0,
			WAIT_SECOND_PKT = 1,
			WAIT_THIRD_PKT = 2,
			WRITE_RAM = 3,
			FLUSH_REST_C = 4,
			WAIT_3_PKT = 5,
			WAIT_4_PKT = 6,
			WAIT_5_PKT = 7,
			WAIT_6_PKT = 8,
			WAIT_7_PKT = 9,
			WAIT_8_PKT = 10,
			WAIT_9_PKT = 11,
			WAIT_10_PKT = 12,
			WAIT_11_PKT = 13,
			WAIT_12_PKT = 14;

reg [6:0] ctrl_state, ctrl_state_next;

`define GET_CTRL_WR_RAM_DATA(state_from, state_to, idx) \
		``state_from``: begin \
			if (ctrl_s_axis_tvalid) begin \
				ctrl_state_next = ``state_to``; \
				ctrl_wr_ram_data_next[C_PARSER_RAM_WIDTH-1-idx*256 -: 256] = ctrl_s_axis_tdata_swapped; \
			end \
		end \


always @(*) begin
	ctrl_state_next = ctrl_state;
	ctrl_wr_ram_addr_next = ctrl_wr_ram_addr;
	ctrl_wr_ram_data_next = ctrl_wr_ram_data;
	ctrl_wr_ram_en_next = 0;

	case (ctrl_state)
		WAIT_FIRST_PKT: begin
			// 1st ctrl packet
			if (ctrl_s_axis_tvalid && ~ctrl_s_axis_tlast) begin
				ctrl_state_next = WAIT_SECOND_PKT;
			end
		end
		WAIT_SECOND_PKT: begin
			// 2nd ctrl packet, we can check module ID
			if (ctrl_s_axis_tvalid) begin
				if (ctrl_mod_id[2:0]==DEPARSER_MOD_ID) begin
					ctrl_state_next = WAIT_3_PKT;

					ctrl_wr_ram_addr_next = ctrl_s_axis_tdata[128+:8];
				end
				else begin
					ctrl_state_next = FLUSH_REST_C;
				end
			end
		end
		`GET_CTRL_WR_RAM_DATA(WAIT_3_PKT, WAIT_4_PKT, 0)
		`GET_CTRL_WR_RAM_DATA(WAIT_4_PKT, WAIT_5_PKT, 1)
		`GET_CTRL_WR_RAM_DATA(WAIT_5_PKT, WAIT_6_PKT, 2)
		`GET_CTRL_WR_RAM_DATA(WAIT_6_PKT, WAIT_7_PKT, 3)
		`GET_CTRL_WR_RAM_DATA(WAIT_7_PKT, WAIT_8_PKT, 4)

		WAIT_8_PKT: begin // first half of ctrl_wr_ram_data
			if (ctrl_s_axis_tvalid) begin
				ctrl_state_next = WRITE_RAM;
				ctrl_wr_ram_data_next[0+:256] = ctrl_s_axis_tdata_swapped;
			end
		end
		WRITE_RAM: begin // second half of ctrl_wr_ram_data
			if (ctrl_s_axis_tvalid) begin
				if (ctrl_s_axis_tlast)
					ctrl_state_next = WAIT_FIRST_PKT;
				else
					ctrl_state_next = FLUSH_REST_C;
				ctrl_wr_ram_en_next = 1;
			end
		end
		FLUSH_REST_C: begin
			if (ctrl_s_axis_tvalid && ctrl_s_axis_tlast)
				ctrl_state_next = WAIT_FIRST_PKT;
		end
	endcase
end

always @(posedge clk) begin
	if (~aresetn) begin
		ctrl_state <= WAIT_FIRST_PKT;

		ctrl_wr_ram_addr <= 0;
		ctrl_wr_ram_data <= 0;
		ctrl_wr_ram_en <= 0;
	end
	else begin
		ctrl_state <= ctrl_state_next;

		ctrl_wr_ram_addr <= ctrl_wr_ram_addr_next;
		ctrl_wr_ram_data <= ctrl_wr_ram_data_next;
		ctrl_wr_ram_en <= ctrl_wr_ram_en_next;
	end
end

// =============================================================== //
parse_act_ram_ip
parse_act_ram
(
	// write port
	.clka		(clk),
	.addra		(ctrl_wr_ram_addr[4:0]),
	.dina		(ctrl_wr_ram_data),
	.ena		(1'b1),
	.wea		(ctrl_wr_ram_en),

	//
	.clkb		(clk),
	.addrb		(vlan_id[8:4]),
	.doutb		(bram_out),
	.enb		(1'b1) // always set to 1
);

endmodule

