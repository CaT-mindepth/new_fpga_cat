`timescale 1ns / 1ps

module stage #(
    parameter C_S_AXIS_DATA_WIDTH = 256,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
    parameter STAGE_ID = 0,  // valid: 0-4
    parameter PHV_LEN = 32*64+256,
    parameter KEY_LEN = 8*32+1,
    parameter ACT_LEN = 64,
    parameter KEY_OFF = 8*6+20,
	parameter C_VLANID_WIDTH = 12,
	parameter NUM_PHV_CONT = 65,
	parameter NUM_SUB_UNIT = 8
)
(
    input									axis_clk,
    input									aresetn,

    input [PHV_LEN-1:0]						phv_in,
    input									phv_in_valid,
    output									stage_ready_out,
	output									vlan_ready_out,

	input [C_VLANID_WIDTH-1:0]				vlan_in,
	input									vlan_valid_in,

	//
    output [PHV_LEN-1:0]					phv_out,
    output									phv_out_valid,
	input									stage_ready_in,
	output [C_VLANID_WIDTH-1:0]				vlan_out,
	output									vlan_valid_out,
	input									vlan_out_ready,

    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]			c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		c_s_axis_tkeep,
	input									c_s_axis_tvalid,
	input									c_s_axis_tlast,

    output [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output [C_S_AXIS_DATA_WIDTH/8-1:0]		c_m_axis_tkeep,
	output									c_m_axis_tvalid,
	output									c_m_axis_tlast

);

//
wire [C_S_AXIS_DATA_WIDTH-1:0]				c_s_axis_tdata_1;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		c_s_axis_tkeep_1;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				c_s_axis_tuser_1;
wire 										c_s_axis_tlast_1;
wire 										c_s_axis_tvalid_1;

//lookup_engine to action_engine
wire [ACT_LEN*NUM_PHV_CONT-1:0]				match2action_action[NUM_SUB_UNIT-1:0];
wire										match2action_action_valid[NUM_SUB_UNIT-1:0];

wire [PHV_LEN-1:0]							match2action_phv;
reg [PHV_LEN-1:0]							match2action_phv_r;
wire										action2match_ready;

wire [ACT_LEN*NUM_PHV_CONT-1:0]				match2action_action_all;
reg [ACT_LEN*NUM_PHV_CONT-1:0]				match2action_action_all_r;
wire										match2action_action_valid_all;
reg											match2action_action_valid_all_r;

assign match2action_action_all = match2action_action[0] |
									match2action_action[1] |
									match2action_action[2] |
									match2action_action[3] |
									match2action_action[4] |
									match2action_action[5] |
									match2action_action[6] |
									match2action_action[7];

assign match2action_action_valid_all = match2action_action_valid[0] |
										match2action_action_valid[1] |
										match2action_action_valid[2] |
										match2action_action_valid[3] |
										match2action_action_valid[4] |
										match2action_action_valid[5] |
										match2action_action_valid[6] |
										match2action_action_valid[7];

wire [C_VLANID_WIDTH-1:0]	act_vlan_out;
wire						act_vlan_out_valid;
reg [C_VLANID_WIDTH-1:0]	act_vlan_out_r;
reg							act_vlan_out_valid_r;
wire						act_vlan_ready;

always @(posedge axis_clk) begin
	if (~aresetn) begin
		match2action_action_all_r <= 0;
		match2action_action_valid_all_r <= 0;
		match2action_phv_r <= 0;

		act_vlan_out_r <= 0;
		act_vlan_out_valid_r <= 0;
	end
	else begin
		match2action_action_all_r <= match2action_action_all;
		match2action_action_valid_all_r <= match2action_action_valid_all;
		match2action_phv_r <= match2action_phv;

		act_vlan_out_r <= act_vlan_out;
		act_vlan_out_valid_r <= act_vlan_out_valid;
	end
end

sub_match_unit #(
    .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
    .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
    .STAGE_ID(STAGE_ID),
	.SUB_UNIT_ID(0)
) sub_match_ins0 (
    .clk			(axis_clk),
    .rst_n			(aresetn),
    .phv_in			(phv_in),
    .phv_valid_in	(phv_in_valid),
    .ready_out		(stage_ready_out),

	.vlan_in		(vlan_in),
	.vlan_in_valid	(vlan_valid_in),
	.vlan_ready		(vlan_ready_out),

	//
    // .phv_out(key2lookup_phv),
    // .phv_valid_out(key2lookup_phv_valid),
    // .key_out_masked(key2lookup_key),
    // .key_valid_out(key2lookup_key_valid),
    // .ready_in(lookup2key_ready),
	.action				(match2action_action[0]),
	.action_valid		(match2action_action_valid[0]),
	.phv_out			(match2action_phv),
	.ready_in			(action2match_ready),

	.act_vlan_out		(act_vlan_out),
	.act_vlan_out_valid	(act_vlan_out_valid),
	.act_vlan_ready		(act_vlan_ready),

    //control path
    .c_s_axis_tdata(c_s_axis_tdata),
	.c_s_axis_tuser(c_s_axis_tuser),
	.c_s_axis_tkeep(c_s_axis_tkeep),
	.c_s_axis_tvalid(c_s_axis_tvalid),
	.c_s_axis_tlast(c_s_axis_tlast),

    .c_m_axis_tdata(c_s_axis_tdata_1),
	.c_m_axis_tuser(c_s_axis_tuser_1),
	.c_m_axis_tkeep(c_s_axis_tkeep_1),
	.c_m_axis_tvalid(c_s_axis_tvalid_1),
	.c_m_axis_tlast(c_s_axis_tlast_1)
);
//
genvar idx;

generate 
	for (idx=1; idx<NUM_SUB_UNIT; idx=idx+1) begin:
		sub_match
		sub_match_unit #(
		    .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
		    .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH),
		    .STAGE_ID(STAGE_ID),
			.SUB_UNIT_ID(idx)
		) sub_match_ins (
		    .clk			(axis_clk),
		    .rst_n			(aresetn),
		    .phv_in			(phv_in),
		    .phv_valid_in	(phv_in_valid),
		    .ready_out		(stage_ready_out),
		
			.vlan_in		(vlan_in),
			.vlan_in_valid	(vlan_valid_in),
			.vlan_ready		(vlan_ready_out),
		
			//
		    // .phv_out(key2lookup_phv),
		    // .phv_valid_out(key2lookup_phv_valid),
		    // .key_out_masked(key2lookup_key),
		    // .key_valid_out(key2lookup_key_valid),
		    // .ready_in(lookup2key_ready),
			.action				(match2action_action[idx]),
			.action_valid		(match2action_action_valid[idx]),
			.phv_out			(),
			.ready_in			(action2match_ready),
		
			.act_vlan_out		(),
			.act_vlan_out_valid	(),
			.act_vlan_ready		(),
		
		    //control path
		    .c_s_axis_tdata(c_s_axis_tdata),
			.c_s_axis_tuser(c_s_axis_tuser),
			.c_s_axis_tkeep(c_s_axis_tkeep),
			.c_s_axis_tvalid(c_s_axis_tvalid),
			.c_s_axis_tlast(c_s_axis_tlast),
		
		    .c_m_axis_tdata(),
			.c_m_axis_tuser(),
			.c_m_axis_tkeep(),
			.c_m_axis_tvalid(),
			.c_m_axis_tlast()
		);
	end
endgenerate

action_engine #(
    .STAGE_ID(STAGE_ID),
	.C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
    .PHV_LEN(),
    .ACT_LEN(),
    .ACTION_ID()
)action_engine(
    .clk(axis_clk),
    .rst_n(aresetn),

    //signals from lookup to ALUs
    .phv_in						(match2action_phv_r),
    .phv_valid_in				(match2action_action_valid_all_r),
    .action_in					(match2action_action_all_r),
    .action_valid_in			(match2action_action_valid_all_r),
    .ready_out					(action2match_ready),

    //signals output from ALUs
    .phv_out					(phv_out),
    .phv_valid_out				(phv_out_valid),
    .ready_in					(stage_ready_in),
	.act_vlan_in				(act_vlan_out_r),
	.act_vlan_valid_in			(act_vlan_out_valid_r),
	.act_vlan_ready				(act_vlan_ready),
	// vlan
	.vlan_out(vlan_out),
	.vlan_out_valid(vlan_valid_out),
	.vlan_out_ready(vlan_out_ready),
    //control path
    .c_s_axis_tdata(c_s_axis_tdata_1),
	.c_s_axis_tuser(c_s_axis_tuser_1),
	.c_s_axis_tkeep(c_s_axis_tkeep_1),
	.c_s_axis_tvalid(c_s_axis_tvalid_1),
	.c_s_axis_tlast(c_s_axis_tlast_1),

    .c_m_axis_tdata(c_m_axis_tdata),
	.c_m_axis_tuser(c_m_axis_tuser),
	.c_m_axis_tkeep(c_m_axis_tkeep),
	.c_m_axis_tvalid(c_m_axis_tvalid),
	.c_m_axis_tlast(c_m_axis_tlast)
);

endmodule
