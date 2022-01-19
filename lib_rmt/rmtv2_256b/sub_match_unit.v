`timescale 1ns / 1ps

module sub_match_unit #(
	parameter C_S_AXIS_DATA_WIDTH = 256,
	parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter STAGE_ID = 0,
	parameter INDIRECTION_ID = 6,
	parameter PHV_LEN = 4*8*64+256,
	parameter KEY_LEN = 8*32+1,
	parameter KEY_OFF = 8*6+20,
	parameter C_NUM_PHVS = 64+1,
    parameter ACT_LEN = 64*C_NUM_PHVS,
	parameter C_VLANID_WIDTH = 12,
	parameter SUB_UNIT_ID = 1
)
(
	input				clk,
	input				rst_n,

	input [PHV_LEN-1:0]   phv_in,
    input                               phv_valid_in,
	output								ready_out,
	// input from vlan fifo
	input [C_VLANID_WIDTH-1:0]			vlan_in,
	input								vlan_in_valid,
	output								vlan_ready,

	// output PHV and corresponding VLIW actions
    // output [PHV_LEN-1:0]				phv_out,
    // output					            phv_valid_out,
    // output [KEY_LEN-1:0]	            key_out_masked,
    // output								key_valid_out,
	// input								ready_in,
    // output to the action engine
    output [ACT_LEN-1:0]						action,
    output										action_valid,
    output [PHV_LEN-1:0]						phv_out, 
	input										ready_in,

	// output vlan to the action engine
	output [C_VLANID_WIDTH-1:0]					act_vlan_out,
	output										act_vlan_out_valid,
	input										act_vlan_ready,

    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]			c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		c_s_axis_tkeep,
	input									c_s_axis_tvalid,
	input									c_s_axis_tlast,

    output reg [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output reg [C_S_AXIS_DATA_WIDTH/8-1:0]		c_m_axis_tkeep,
	output reg								    c_m_axis_tvalid,
	output reg								    c_m_axis_tlast
);

// ctrl path
wire [C_S_AXIS_DATA_WIDTH-1:0]		ctrl_key_axis_tdata;
wire [C_S_AXIS_TUSER_WIDTH-1:0]		ctrl_key_axis_tuser;
wire [C_S_AXIS_DATA_WIDTH/8-1:0]	ctrl_key_axis_tkeep;
wire								ctrl_key_axis_tlast;
wire								ctrl_key_axis_tvalid;

wire [C_S_AXIS_DATA_WIDTH-1:0]		ctrl_cam_axis_tdata;
wire [C_S_AXIS_TUSER_WIDTH-1:0]		ctrl_cam_axis_tuser;
wire [C_S_AXIS_DATA_WIDTH/8-1:0]	ctrl_cam_axis_tkeep;
wire								ctrl_cam_axis_tlast;
wire								ctrl_cam_axis_tvalid;

wire [C_S_AXIS_DATA_WIDTH-1:0]		ctrl_ram_axis_tdata;
wire [C_S_AXIS_TUSER_WIDTH-1:0]		ctrl_ram_axis_tuser;
wire [C_S_AXIS_DATA_WIDTH/8-1:0]	ctrl_ram_axis_tkeep;
wire								ctrl_ram_axis_tlast;
wire								ctrl_ram_axis_tvalid;

//
wire [PHV_LEN-1:0]					key_phv_out;
wire 								key_phv_out_valid;
wire [KEY_LEN-1:0]					key_key_out_masked;
wire								key_key_valid_out;

wire								cam_ready_in;
wire [PHV_LEN-1:0]					cam_phv_out;
wire								cam_phv_out_valid;
wire [7:0]							cam_match_addr_out;
wire								cam_if_match;

wire								lke_ram_ready_out;

// basically, we have C_NUM_SUBMATCH match modules (key extractor + CAM part)
genvar idx;

key_extract_top #(
	.STAGE_ID(STAGE_ID),
	.SUB_UNIT_ID(SUB_UNIT_ID)
)
extractor (
	.clk			(clk),
	.rst_n			(rst_n),

	.phv_in			(phv_in),
	.phv_valid_in	(phv_valid_in),
	.ready_out		(ready_out),
	.vlan_in		(vlan_in),
	.vlan_in_valid	(vlan_in_valid),
	.vlan_ready		(vlan_ready),

	// 
	.phv_out		(key_phv_out),
	.phv_valid_out	(key_phv_out_valid),
	.key_out_masked	(key_key_out_masked),
	.key_valid_out	(key_key_valid_out),
	.ready_in		(cam_ready_in),

	// ctrl path
	.c_s_axis_tdata		(c_s_axis_tdata),
	.c_s_axis_tuser		(c_s_axis_tuser),
	.c_s_axis_tkeep		(c_s_axis_tkeep),
	.c_s_axis_tvalid	(c_s_axis_tvalid),
	.c_s_axis_tlast		(c_s_axis_tlast),

	.c_m_axis_tdata		(ctrl_key_axis_tdata),
	.c_m_axis_tuser		(ctrl_key_axis_tuser),
	.c_m_axis_tkeep		(ctrl_key_axis_tkeep),
	.c_m_axis_tvalid	(ctrl_key_axis_tvalid),
	.c_m_axis_tlast		(ctrl_key_axis_tlast)
);

lke_cam_part #(
	.STAGE_ID(STAGE_ID),
	.SUB_UNIT_ID(SUB_UNIT_ID)
)
lke_cam_0
(
	.clk			(clk),
	.rst_n			(rst_n),
	
	.extract_key	(key_key_out_masked),
	.key_valid		(key_key_valid_out),
	.phv_valid		(key_phv_out_valid),
	.phv_in			(key_phv_out),

	.ready_out		(cam_ready_in),

	.phv_out		(cam_phv_out),
	.phv_out_valid	(cam_phv_out_valid),
	.match_addr_out	(cam_match_addr_out),
	.if_match		(cam_if_match),

	.ready_in		(lke_ram_ready_out),

	// ctrl path
	.c_s_axis_tdata		(ctrl_key_axis_tdata),
	.c_s_axis_tuser		(ctrl_key_axis_tuser),
	.c_s_axis_tkeep		(ctrl_key_axis_tkeep),
	.c_s_axis_tvalid	(ctrl_key_axis_tvalid),
	.c_s_axis_tlast		(ctrl_key_axis_tlast),

	.c_m_axis_tdata		(ctrl_cam_axis_tdata),
	.c_m_axis_tuser		(ctrl_cam_axis_tuser),
	.c_m_axis_tkeep		(ctrl_cam_axis_tkeep),
	.c_m_axis_tvalid	(ctrl_cam_axis_tvalid),
	.c_m_axis_tlast		(ctrl_cam_axis_tlast)
);

localparam	WAIT_CAM_RESULT = 0;

reg[2:0]				state, state_next;
reg[PHV_LEN-1:0]		ram_phv_in, ram_phv_in_next;
reg						ram_phv_in_valid, ram_phv_in_valid_next;
reg[10:0]				ram_match_addr_in, ram_match_addr_in_next; // 3-bit cam, 8-bit addr
reg						ram_if_match_in, ram_if_match_in_next;


// get match resutl from CAM
always @(*) begin

	state_next = state;

	ram_phv_in_next = ram_phv_in;
	ram_phv_in_valid_next = 0;
	ram_if_match_in_next = 0;

	case (state)
		WAIT_CAM_RESULT: begin
			if (cam_phv_out_valid) begin
				ram_phv_in_next = cam_phv_out;
				ram_phv_in_valid_next = 1;
				//
				if (cam_if_match) begin

					ram_if_match_in_next = 1;
				end
				// prepare addr input to indirection table
				if (cam_if_match) begin
					ram_match_addr_in_next = cam_match_addr_out;
				end
				else begin
					ram_match_addr_in_next = 11'h7ff;
				end
			end
		end
	endcase
end

localparam		WAIT_IND_OUTPUT = 0,
				WAIT_IND_OUTPUT_1C = 1;

reg[2:0]					ind_state, ind_state_next;
reg[PHV_LEN-1:0]			ind_to_ram_phv, ind_to_ram_phv_next, ind_to_ram_phv_d1;
reg							ind_to_ram_phv_valid, ind_to_ram_phv_valid_next, ind_to_ram_phv_valid_d1;
wire [7:0]					ind_to_ram_match_addr;
reg							ind_to_ram_if_match, ind_to_ram_if_match_next, ind_to_ram_if_match_d1;


// get ram addr from indirection table
always @(*) begin
	ind_state_next = ind_state;

	ind_to_ram_phv_next = ind_to_ram_phv;
	ind_to_ram_phv_valid_next = 0;
	ind_to_ram_if_match_next = 0;

	case (ind_state)
		WAIT_IND_OUTPUT: begin
			if (ram_phv_in_valid) begin
				ind_state_next = WAIT_IND_OUTPUT_1C;

				ind_to_ram_phv_next = ram_phv_in;
				ind_to_ram_phv_valid_next = ram_phv_in_valid;
				ind_to_ram_if_match_next = ram_match_addr_in;
			end
		end
		WAIT_IND_OUTPUT_1C: begin

			ind_state_next = WAIT_IND_OUTPUT;
		end
	endcase
end


always @(posedge clk) begin
	if (~rst_n) begin
		state <= WAIT_CAM_RESULT;

		ram_phv_in <= 0;
		ram_phv_in_valid <= 0;
		ram_match_addr_in <= 0;
		ram_if_match_in <= 0;
		//
		ind_state <= WAIT_IND_OUTPUT;
		ind_to_ram_phv <= 0;
		ind_to_ram_phv_d1 <= 0;
		ind_to_ram_phv_valid <= 0;
		ind_to_ram_phv_valid_d1 <= 0;
		ind_to_ram_if_match <= 0;
		ind_to_ram_if_match_d1 <= 0;
	end
	else begin
		state <= state_next;
		ram_phv_in <= ram_phv_in_next;
		ram_phv_in_valid <= ram_phv_in_valid_next;
		ram_match_addr_in <= ram_match_addr_in_next;
		ram_if_match_in <= ram_if_match_in_next;
		//
		ind_state <= ind_state_next;
		ind_to_ram_phv <= ind_to_ram_phv_next;
		ind_to_ram_phv_d1 <= ind_to_ram_phv;
		ind_to_ram_phv_valid <= ind_to_ram_phv_valid_next;
		ind_to_ram_phv_valid_d1 <= ind_to_ram_phv_valid;
		ind_to_ram_if_match <= ind_to_ram_if_match_next;
		ind_to_ram_if_match_d1 <= ind_to_ram_if_match;
	end
end

// put the lke ram part
lke_ram_part #(
	.STAGE_ID (STAGE_ID),
	.SUB_UNIT_ID(SUB_UNIT_ID)
)
lke_ram (
	.clk				(clk),
	.rst_n				(rst_n),

	.phv_in				(ind_to_ram_phv_d1),
	.phv_valid			(ind_to_ram_phv_valid_d1),
	.match_addr			(ind_to_ram_match_addr),
	.if_match			(ind_to_ram_if_match_d1),
	.ready_out			(lke_ram_ready_out),
	//
	.action				(action),
	.action_valid		(action_valid),
	.phv_out			(phv_out),
	.ready_in			(ready_in),

	.act_vlan_out		(act_vlan_out),
	.act_vlan_out_valid	(act_vlan_out_valid),
	.act_vlan_ready		(act_vlan_ready),
	// ctrl path
	.c_s_axis_tdata		(ctrl_cam_axis_tdata),
	.c_s_axis_tuser		(ctrl_cam_axis_tuser),
	.c_s_axis_tkeep		(ctrl_cam_axis_tkeep),
	.c_s_axis_tlast		(ctrl_cam_axis_tlast),
	.c_s_axis_tvalid	(ctrl_cam_axis_tvalid),

	.c_m_axis_tdata		(ctrl_ram_axis_tdata),
	.c_m_axis_tuser		(ctrl_ram_axis_tuser),
	.c_m_axis_tkeep		(ctrl_ram_axis_tkeep),
	.c_m_axis_tlast		(ctrl_ram_axis_tlast),
	.c_m_axis_tvalid	(ctrl_ram_axis_tvalid)
);


/***********************************************************/
// ctrl path to insert entries in indirection ram
wire [7:0]          mod_id; //module ID
//4'b0 for tcam entry;
//NOTE: we don't need tcam entry mask
//4'b2 for action table entry;
wire [3:0]          resv; //recog between tcam and action
wire [3:0]			sub_unit_id;
wire [15:0]         control_flag; //dst udp port num

reg  [7:0]          c_index_ind;
reg                 c_wr_en_ind;

reg [9:0]           c_state;


localparam IDLE_C = 0,
           PARSE_C = 1,
		   IND_ENTRY = 2,
		   FLUSH_REST_C = 3;

wire[C_S_AXIS_DATA_WIDTH-1:0] c_s_axis_tdata_swapped;
assign c_s_axis_tdata_swapped = {	ctrl_ram_axis_tdata[0+:8],
									ctrl_ram_axis_tdata[8+:8],
									ctrl_ram_axis_tdata[16+:8],
									ctrl_ram_axis_tdata[24+:8],
									ctrl_ram_axis_tdata[32+:8],
									ctrl_ram_axis_tdata[40+:8],
									ctrl_ram_axis_tdata[48+:8],
									ctrl_ram_axis_tdata[56+:8],
									ctrl_ram_axis_tdata[64+:8],
									ctrl_ram_axis_tdata[72+:8],
									ctrl_ram_axis_tdata[80+:8],
									ctrl_ram_axis_tdata[88+:8],
									ctrl_ram_axis_tdata[96+:8],
									ctrl_ram_axis_tdata[104+:8],
									ctrl_ram_axis_tdata[112+:8],
									ctrl_ram_axis_tdata[120+:8],
									ctrl_ram_axis_tdata[128+:8],
									ctrl_ram_axis_tdata[136+:8],
									ctrl_ram_axis_tdata[144+:8],
									ctrl_ram_axis_tdata[152+:8],
									ctrl_ram_axis_tdata[160+:8],
									ctrl_ram_axis_tdata[168+:8],
									ctrl_ram_axis_tdata[176+:8],
									ctrl_ram_axis_tdata[184+:8],
									ctrl_ram_axis_tdata[192+:8],
									ctrl_ram_axis_tdata[200+:8],
									ctrl_ram_axis_tdata[208+:8],
									ctrl_ram_axis_tdata[216+:8],
									ctrl_ram_axis_tdata[224+:8],
									ctrl_ram_axis_tdata[232+:8],
									ctrl_ram_axis_tdata[240+:8],
									ctrl_ram_axis_tdata[248+:8]};

assign mod_id = ctrl_ram_axis_tdata[112+:8];
assign resv = ctrl_ram_axis_tdata[120+:4];
assign sub_unit_id = ctrl_ram_axis_tdata[124+:4];
assign control_flag = ctrl_ram_axis_tdata[64+:16];
// 
reg [9:0] c_state_next;
reg [C_S_AXIS_DATA_WIDTH-1:0]		r_tdata, c_s_axis_tdata_d1;
reg [C_S_AXIS_TUSER_WIDTH-1:0]		r_tuser, c_s_axis_tuser_d1;
reg [C_S_AXIS_DATA_WIDTH/8-1:0]		r_tkeep, c_s_axis_tkeep_d1;
reg									r_tlast, c_s_axis_tlast_d1;
reg									r_tvalid, c_s_axis_tvalid_d1;

reg [C_S_AXIS_DATA_WIDTH-1:0]		r_1st_tdata, r_1st_tdata_next;
reg [C_S_AXIS_TUSER_WIDTH-1:0]		r_1st_tuser, r_1st_tuser_next;
reg [C_S_AXIS_DATA_WIDTH/8-1:0]		r_1st_tkeep, r_1st_tkeep_next;
reg									r_1st_tlast, r_1st_tlast_next;
reg									r_1st_tvalid, r_1st_tvalid_next;

reg [7:0]							c_index_ind_next;
reg									c_wr_en_ind_next;
reg [7:0]							c_wr_ind_data, c_wr_ind_data_next;

always @(*) begin 
	c_state_next = c_state;

	r_tdata = 0;
	r_tkeep = 0;
	r_tuser = 0;
	r_tlast = 0;
	r_tvalid = 0;

	r_1st_tdata_next = r_1st_tdata;
	r_1st_tkeep_next = r_1st_tkeep;
	r_1st_tuser_next = r_1st_tuser;
	r_1st_tlast_next = r_1st_tlast;
	r_1st_tvalid_next = r_1st_tvalid;

	c_index_ind_next = c_index_ind;
	c_wr_en_ind_next = 0;
	c_wr_ind_data_next = c_wr_ind_data;

	case (c_state) 
		IDLE_C: begin // 1st segment
			r_tvalid = 0;
			if (ctrl_ram_axis_tvalid) begin
				// store 1st segment
				r_1st_tdata_next = ctrl_ram_axis_tdata;
				r_1st_tuser_next = ctrl_ram_axis_tuser;
				r_1st_tkeep_next = ctrl_ram_axis_tkeep;
				r_1st_tlast_next = ctrl_ram_axis_tlast;
				r_1st_tvalid_next = ctrl_ram_axis_tvalid;

				c_state_next = PARSE_C;
			end
		end
		PARSE_C: begin // 2nd segment
			if (mod_id[7:3] == STAGE_ID && mod_id[2:0] == INDIRECTION_ID && sub_unit_id == SUB_UNIT_ID &&
				control_flag == 16'hf2f1 && ctrl_ram_axis_tvalid && resv!=4'b0) begin
				// should not emit segment
				c_index_ind_next = ctrl_ram_axis_tdata[128+:8];
				c_state_next = IND_ENTRY;
			end
			else if (!ctrl_ram_axis_tvalid) begin
			end
			else begin
				// emit
				r_tdata = r_1st_tdata;
				r_tkeep = r_1st_tkeep;
				r_tuser = r_1st_tuser;
				r_tlast = r_1st_tlast;
				r_tvalid = r_1st_tvalid;
				c_state_next = FLUSH_REST_C;
			end
		end
		IND_ENTRY: begin
			if (ctrl_ram_axis_tvalid) begin
				c_wr_en_ind_next = 1; // next clk to write
				c_wr_ind_data_next = c_s_axis_tdata_swapped[255-:8];
				c_state_next = IDLE_C;
			end
		end
		FLUSH_REST_C: begin
			c_wr_en_ind_next = 0;
			r_tdata = c_s_axis_tdata_d1;
			r_tkeep = c_s_axis_tkeep_d1;
			r_tuser = c_s_axis_tuser_d1;
			r_tlast = c_s_axis_tlast_d1;
			r_tvalid = c_s_axis_tvalid_d1;
			if (c_s_axis_tvalid_d1 && c_s_axis_tlast_d1) begin
				c_state_next = IDLE_C;
			end
		end
	endcase
end

always @(posedge clk) begin
	if (~rst_n) begin
		c_state <= IDLE_C;

		// control output
		c_m_axis_tdata <= 0;
		c_m_axis_tuser <= 0;
		c_m_axis_tkeep <= 0;
		c_m_axis_tlast <= 0;
		c_m_axis_tvalid <= 0;
		//
		c_index_ind <= 0;
		c_wr_en_ind <= 0;
		c_wr_ind_data <= 0;
	end
	else begin
		c_state <= c_state_next;


		// output ctrl master signals
		c_m_axis_tdata <= r_tdata;
		c_m_axis_tkeep <= r_tkeep;
		c_m_axis_tuser <= r_tuser;
		c_m_axis_tlast <= r_tlast;
		c_m_axis_tvalid <= r_tvalid;
		//
		c_index_ind <= c_index_ind_next;
		c_wr_en_ind <= c_wr_en_ind_next;
		c_wr_ind_data <= c_wr_ind_data_next;
	end
end

always @(posedge clk) begin
	if (~rst_n) begin
		// delayed 1 clk
		c_s_axis_tdata_d1 <= 0;
		c_s_axis_tuser_d1 <= 0;
		c_s_axis_tkeep_d1 <= 0;
		c_s_axis_tlast_d1 <= 0;
		c_s_axis_tvalid_d1 <= 0;
		//
		r_1st_tdata <= 0;
		r_1st_tkeep <= 0;
		r_1st_tuser <= 0;
		r_1st_tlast <= 0;
		r_1st_tvalid <= 0;
	end
	else begin
		// delayed 1 clk
		c_s_axis_tdata_d1 <= ctrl_ram_axis_tdata;
		c_s_axis_tuser_d1 <= ctrl_ram_axis_tuser;
		c_s_axis_tkeep_d1 <= ctrl_ram_axis_tkeep;
		c_s_axis_tlast_d1 <= ctrl_ram_axis_tlast;
		c_s_axis_tvalid_d1 <= ctrl_ram_axis_tvalid;
		// 
		r_1st_tdata <= r_1st_tdata_next;
		r_1st_tkeep <= r_1st_tkeep_next;
		r_1st_tuser <= r_1st_tuser_next;
		r_1st_tlast <= r_1st_tlast_next;
		r_1st_tvalid <= r_1st_tvalid_next;
	end
end

// we need a indirection RAM to index VLIW RAM
blk_mem_gen_4
indirection_ram_2048d_8w
(
	// write
	.addra				(c_index_ind),
	.clka				(clk),
	.dina				(c_wr_ind_data),
	.ena				(1'b1),
	.wea				(c_wr_en_ind),
	// read
	.addrb				(ram_match_addr_in),
	.clkb				(clk),
	.doutb				(ind_to_ram_match_addr),
	.enb				(1'b1)
);

endmodule // module multi_match
