`timescale 1ns / 1ps

`define PARSE_STATE_TRANSITION(state_from, state_to, idx) \
	``state_from``: begin \
		if (s_axis_tvalid) begin \
			tdata_segs_next[idx*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata; \
			if (s_axis_tlast) begin \
				segs_valid_next = 1; \
				state_next = WAIT_1ST_SEG; \
			end \
			else begin \
				state_next = ``state_to``; \
			end \
		end \
	end \

module parser_wait_segs #(
	parameter C_AXIS_DATA_WIDTH = 256,
	parameter C_AXIS_TUSER_WIDTH = 128,
	parameter C_NUM_SEGS = 16,
	parameter PARSER_MOD_ID = 3'b0,
	parameter C_PARSER_RAM_WIDTH = 24*64
)
(
	input											axis_clk,
	input											aresetn,
	
	//
	input [C_AXIS_DATA_WIDTH-1:0]					s_axis_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]					s_axis_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]					s_axis_tkeep,
	input											s_axis_tvalid,
	input											s_axis_tlast,
	output reg										s_axis_tready,
	
	//
	
	//
	output reg[C_NUM_SEGS*C_AXIS_DATA_WIDTH-1:0]	tdata_segs,
	output reg[C_AXIS_TUSER_WIDTH-1:0]				tuser_1st,
	output reg										segs_valid,
	output reg [C_PARSER_RAM_WIDTH-1:0]				parser_bram_out,
	// ctrl path
	input [C_AXIS_DATA_WIDTH-1:0]					ctrl_s_axis_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]					ctrl_s_axis_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]					ctrl_s_axis_tkeep,
	input											ctrl_s_axis_tvalid,
	input											ctrl_s_axis_tlast,

	output reg [C_AXIS_DATA_WIDTH-1:0]				ctrl_m_axis_tdata,
	output reg [C_AXIS_TUSER_WIDTH-1:0]				ctrl_m_axis_tuser,
	output reg [C_AXIS_DATA_WIDTH/8-1:0]			ctrl_m_axis_tkeep,
	output reg										ctrl_m_axis_tvalid,
	output reg										ctrl_m_axis_tlast
);

localparam	WAIT_1ST_SEG=0,
			WAIT_2ND_SEG=1,
			WAIT_3RD_SEG=2,
			WAIT_4TH_SEG=3,
			WAIT_5TH_SEG=4,
			WAIT_6TH_SEG=5,
			WAIT_7TH_SEG=6,
			WAIT_8TH_SEG=7,
			WAIT_9TH_SEG=8,
			WAIT_10_SEG=9,
			WAIT_11_SEG=10,
			WAIT_12_SEG=11,
			WAIT_13_SEG=12,
			WAIT_14_SEG=13,
			WAIT_15_SEG=14,
			WAIT_16_SEG=15,
			OUTPUT_SEGS=16,
			EMPTY_1CYCLE=17,
			EMPTY_2CYCLE=18,
			WAIT_TILL_LAST=19;

reg [4:0]	state, state_next;
reg [C_NUM_SEGS*C_AXIS_DATA_WIDTH-1:0] tdata_segs_next;
reg [C_AXIS_TUSER_WIDTH-1:0] tuser_1st_next;
reg segs_valid_next;
reg s_axis_tready_next;

wire [C_PARSER_RAM_WIDTH-1:0] bram_out;
reg [C_PARSER_RAM_WIDTH-1:0] parser_bram_out_next;


wire [11:0] vlan_id;
assign vlan_id = s_axis_tdata[116+:12];

always @(*) begin

	state_next = state;

	tdata_segs_next = tdata_segs;
	tuser_1st_next = tuser_1st;

	parser_bram_out_next = parser_bram_out;

	segs_valid_next = 0;

	s_axis_tready_next = s_axis_tready;

	case (state)
		// at least 2 segs
		// VLAN ID is determined at 1st state
		WAIT_1ST_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[0*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;
				tuser_1st_next = s_axis_tuser;
			
				//
				state_next = WAIT_2ND_SEG;
			end
		end
		WAIT_2ND_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[1*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;

				if (s_axis_tlast) begin
					state_next = EMPTY_1CYCLE;
					s_axis_tready_next = 0;
				end
				else begin
					state_next = WAIT_3RD_SEG;
				end
			end
		end
		EMPTY_1CYCLE: begin
			parser_bram_out_next = bram_out;
			s_axis_tready_next = 0;
			state_next = EMPTY_2CYCLE;
		end
		EMPTY_2CYCLE: begin
			segs_valid_next = 1;
			s_axis_tready_next = 1;
			state_next = WAIT_1ST_SEG;
		end
		WAIT_3RD_SEG: begin
			parser_bram_out_next = bram_out;
			if (s_axis_tvalid) begin
				tdata_segs_next[2*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;

				if (s_axis_tlast) begin
					s_axis_tready_next = 0;
					state_next = EMPTY_2CYCLE;
				end
				else begin
					state_next = WAIT_4TH_SEG;
				end
			end
		end

		`PARSE_STATE_TRANSITION(WAIT_4TH_SEG, WAIT_5TH_SEG, 3)
		`PARSE_STATE_TRANSITION(WAIT_5TH_SEG, WAIT_6TH_SEG, 4)
		`PARSE_STATE_TRANSITION(WAIT_6TH_SEG, WAIT_7TH_SEG, 5)
		`PARSE_STATE_TRANSITION(WAIT_7TH_SEG, WAIT_8TH_SEG, 6)
		`PARSE_STATE_TRANSITION(WAIT_8TH_SEG, WAIT_9TH_SEG, 7)
		`PARSE_STATE_TRANSITION(WAIT_9TH_SEG, WAIT_10_SEG, 8)
		`PARSE_STATE_TRANSITION(WAIT_10_SEG, WAIT_11_SEG, 9)
		`PARSE_STATE_TRANSITION(WAIT_11_SEG, WAIT_12_SEG, 10)
		`PARSE_STATE_TRANSITION(WAIT_12_SEG, WAIT_13_SEG, 11) 
		`PARSE_STATE_TRANSITION(WAIT_13_SEG, WAIT_14_SEG, 12)
		`PARSE_STATE_TRANSITION(WAIT_14_SEG, WAIT_15_SEG, 13)
		`PARSE_STATE_TRANSITION(WAIT_15_SEG, WAIT_16_SEG, 14)

		WAIT_16_SEG: begin
			if (s_axis_tvalid) begin
				tdata_segs_next[15*C_AXIS_DATA_WIDTH+:C_AXIS_DATA_WIDTH] = s_axis_tdata;

				segs_valid_next = 1;
				if (s_axis_tlast) begin
					state_next = WAIT_1ST_SEG;
				end
				else begin
					state_next = WAIT_TILL_LAST;
				end
			end
		end
		WAIT_TILL_LAST: begin
			if (s_axis_tlast && s_axis_tvalid) begin
				state_next = WAIT_1ST_SEG;
			end
		end
	endcase
end


always @(posedge axis_clk) begin
	if (~aresetn) begin

		state <= WAIT_1ST_SEG;

		tdata_segs <= {C_NUM_SEGS*C_AXIS_DATA_WIDTH{1'b0}};
		tuser_1st <= {C_AXIS_TUSER_WIDTH{1'b0}};
		segs_valid <= 0;

		parser_bram_out <= 0;

		s_axis_tready <= 1;
	end
	else begin
		state <= state_next;

		tdata_segs <= tdata_segs_next;
		tuser_1st <= tuser_1st_next;

		segs_valid <= segs_valid_next;

		parser_bram_out <= parser_bram_out_next;

		s_axis_tready <= s_axis_tready_next;
	end
end

/*================Control Path====================*/
reg [C_AXIS_DATA_WIDTH-1:0]		ctrl_m_axis_tdata_next;
reg [C_AXIS_TUSER_WIDTH-1:0]	ctrl_m_axis_tuser_next;
reg [C_AXIS_DATA_WIDTH/8-1:0]	ctrl_m_axis_tkeep_next;
reg								ctrl_m_axis_tlast_next;
reg								ctrl_m_axis_tvalid_next;

wire [C_AXIS_DATA_WIDTH-1:0]	ctrl_s_axis_tdata_swapped;

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


reg	[7:0]						ctrl_wr_ram_addr_next;
reg [7:0]						ctrl_wr_ram_addr;
reg	[C_PARSER_RAM_WIDTH-1:0]					ctrl_wr_ram_data;
reg	[C_PARSER_RAM_WIDTH-1:0]					ctrl_wr_ram_data_next;
reg								ctrl_wr_ram_en_next;
reg								ctrl_wr_ram_en;
wire [7:0]						ctrl_mod_id;

assign ctrl_mod_id = ctrl_s_axis_tdata[112+:8];

localparam	WAIT_1_PKT = 0,
			WAIT_2_PKT = 1,
			WAIT_3_PKT = 2,
			WAIT_4_PKT = 3,
			WAIT_5_PKT = 4,
			WAIT_6_PKT = 5,
			WAIT_7_PKT = 6,
			WAIT_8_PKT = 7,
			WAIT_9_PKT = 8,
			WAIT_10_PKT = 9,
			WAIT_11_PKT = 10,
			WAIT_12_PKT = 11,
			WRITE_RAM = 12,
			FLUSH_REST_C = 13;

reg [4:0] ctrl_state, ctrl_state_next;

`define GET_CTRL_WR_RAM_DATA(state_from, state_to, idx) \
		``state_from``: begin \
			if (ctrl_s_axis_tvalid) begin \
				ctrl_state_next = ``state_to``; \
				ctrl_wr_ram_data_next[C_PARSER_RAM_WIDTH-1-idx*256 -: 256] = ctrl_s_axis_tdata_swapped; \
			end \
		end \

always @(*) begin
	ctrl_m_axis_tdata_next = ctrl_s_axis_tdata;
	ctrl_m_axis_tuser_next = ctrl_s_axis_tuser;
	ctrl_m_axis_tkeep_next = ctrl_s_axis_tkeep;
	ctrl_m_axis_tlast_next = ctrl_s_axis_tlast;
	ctrl_m_axis_tvalid_next = ctrl_s_axis_tvalid;

	ctrl_state_next = ctrl_state;
	ctrl_wr_ram_addr_next = ctrl_wr_ram_addr;
	ctrl_wr_ram_data_next = ctrl_wr_ram_data;
	ctrl_wr_ram_en_next = 0;

	case (ctrl_state)
		WAIT_1_PKT: begin
			// 1st ctrl packet
			if (ctrl_s_axis_tvalid) begin
				ctrl_state_next = WAIT_2_PKT;
			end
		end
		WAIT_2_PKT: begin
			// 2nd ctrl packet, we can check module ID
			if (ctrl_s_axis_tvalid) begin
				if (ctrl_mod_id[2:0]==PARSER_MOD_ID) begin
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

		WAIT_8_PKT: begin
			if (ctrl_s_axis_tvalid) begin
				ctrl_state_next = WRITE_RAM;
				ctrl_wr_ram_data_next[0+:256] = ctrl_s_axis_tdata_swapped;
			end
		end

		WRITE_RAM: begin // second half of ctrl_wr_ram_data
			if (ctrl_s_axis_tvalid) begin
				if (ctrl_s_axis_tlast) 
					ctrl_state_next = WAIT_1_PKT;
				else
					ctrl_state_next = FLUSH_REST_C;
				ctrl_wr_ram_en_next = 1;
			end
		end
		FLUSH_REST_C: begin
			if (ctrl_s_axis_tvalid && ctrl_s_axis_tlast) begin
				ctrl_state_next = WAIT_1_PKT;
			end
		end
	endcase
end

always @(posedge axis_clk) begin
	if (~aresetn) begin
		//
		ctrl_state <= WAIT_1_PKT;

		ctrl_m_axis_tdata <= 0;
		ctrl_m_axis_tuser <= 0;
		ctrl_m_axis_tkeep <= 0;
		ctrl_m_axis_tvalid <= 0;
		ctrl_m_axis_tlast <= 0;

		//
		ctrl_wr_ram_addr <= 0;
		ctrl_wr_ram_data <= 0;
		ctrl_wr_ram_en <= 0;
	end
	else begin
		ctrl_state <= ctrl_state_next;

		ctrl_m_axis_tdata <= ctrl_m_axis_tdata_next;
		ctrl_m_axis_tuser <= ctrl_m_axis_tuser_next;
		ctrl_m_axis_tkeep <= ctrl_m_axis_tkeep_next;
		ctrl_m_axis_tlast <= ctrl_m_axis_tlast_next;
		ctrl_m_axis_tvalid <= ctrl_m_axis_tvalid_next;
		//
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
	.clka		(axis_clk),
	.addra		(ctrl_wr_ram_addr[4:0]),
	.dina		(ctrl_wr_ram_data),
	.ena		(1'b1),
	.wea		(ctrl_wr_ram_en),

	//
	.clkb		(axis_clk),
	.addrb		(vlan_id[8:4]), // [NOTICE:] note that we may change due to little or big endian
	.doutb		(bram_out),
	.enb		(1'b1) // always set to 1
);
endmodule

