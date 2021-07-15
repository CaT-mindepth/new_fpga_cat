`timescale 1ns / 1ps

module rmt_wrapper #(
	// Slave AXI parameters
	// AXI Stream parameters
	// Slave
	parameter C_S_AXIS_DATA_WIDTH = 256,
	parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter C_NUM_QUEUES = 4,
	parameter C_VLANID_WIDTH = 12
	// Master
	// self-defined
)
(
	input									clk,		// axis clk
	input									aresetn,	

	// input Slave AXI Stream
	input [C_S_AXIS_DATA_WIDTH-1:0]				s_axis_tdata,
	input [((C_S_AXIS_DATA_WIDTH/8))-1:0]		s_axis_tkeep,
	input [C_S_AXIS_TUSER_WIDTH-1:0]			s_axis_tuser,
	input										s_axis_tvalid,
	output										s_axis_tready,
	input										s_axis_tlast,

	// output Master AXI Stream
	output     [C_S_AXIS_DATA_WIDTH-1:0]		m_axis_tdata,
	output     [((C_S_AXIS_DATA_WIDTH/8))-1:0]	m_axis_tkeep,
	output     [C_S_AXIS_TUSER_WIDTH-1:0]		m_axis_tuser,
	output    									m_axis_tvalid,
	input										m_axis_tready,
	output  									m_axis_tlast
	
);

/*=================================================*/
localparam PKT_VEC_WIDTH = (6+4+2)*8*8+256;
// 
wire								stg0_phv_in_valid;
wire								stg0_phv_in_valid_w;
reg									stg0_phv_in_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg0_phv_in;
// stage-related
wire [PKT_VEC_WIDTH-1:0]			stg0_phv_out;
wire								stg0_phv_out_valid;
wire								stg0_phv_out_valid_w;
reg									stg0_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg1_phv_out;
wire								stg1_phv_out_valid;
wire								stg1_phv_out_valid_w;
reg									stg1_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg2_phv_out;
wire								stg2_phv_out_valid;
wire								stg2_phv_out_valid_w;
reg									stg2_phv_out_valid_r;
wire [PKT_VEC_WIDTH-1:0]			stg3_phv_out;
wire								stg3_phv_out_valid;
wire								stg3_phv_out_valid_w;
reg									stg3_phv_out_valid_r;

wire [C_VLANID_WIDTH-1:0]			stg0_vlan_in;
wire								stg0_vlan_valid_in;
wire								stg0_vlan_fifo_ready;
wire [C_VLANID_WIDTH-1:0]			stg0_vlan_out;
wire								stg0_vlan_valid_out;
wire								stg1_vlan_fifo_ready;
wire [C_VLANID_WIDTH-1:0]			stg1_vlan_out;
wire								stg1_vlan_valid_out;
wire								stg2_vlan_fifo_ready;
wire [C_VLANID_WIDTH-1:0]			stg2_vlan_out;
wire								stg2_vlan_valid_out;
wire								stg3_vlan_fifo_ready;
wire [C_VLANID_WIDTH-1:0]			stg3_vlan_out;
wire								stg3_vlan_valid_out;
wire								last_stg_vlan_fifo_ready;

// back pressure signals
wire s_axis_tready_p;
wire stg0_ready;
wire stg1_ready;
wire stg2_ready;
wire stg3_ready;
wire last_stg_ready;

//NOTE: to filter out packets other than UDP/IP.
wire [C_S_AXIS_DATA_WIDTH-1:0]				s_axis_tdata_f;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		s_axis_tkeep_f;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				s_axis_tuser_f;
wire										s_axis_tvalid_f;
wire										s_axis_tready_f;
wire										s_axis_tlast_f;

reg [C_S_AXIS_DATA_WIDTH-1:0]				s_axis_tdata_f_r;
reg [((C_S_AXIS_DATA_WIDTH/8))-1:0]			s_axis_tkeep_f_r;
reg [C_S_AXIS_TUSER_WIDTH-1:0]				s_axis_tuser_f_r;
reg											s_axis_tvalid_f_r;
reg											s_axis_tready_f_r;
reg											s_axis_tlast_f_r;


//NOTE: filter control packets from data packets.
wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_1;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_1;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_1;
wire										ctrl_s_axis_tvalid_1;
wire										ctrl_s_axis_tlast_1;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_2;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_2;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_2;
wire 										ctrl_s_axis_tvalid_2;
wire 										ctrl_s_axis_tlast_2;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_3;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_3;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_3;
wire 										ctrl_s_axis_tvalid_3;
wire 										ctrl_s_axis_tlast_3;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_4;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_4;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_4;
wire 										ctrl_s_axis_tvalid_4;
wire 										ctrl_s_axis_tlast_4;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_5;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_5;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_5;
wire 										ctrl_s_axis_tvalid_5;
wire 										ctrl_s_axis_tlast_5;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_6;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_6;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_6;
wire 										ctrl_s_axis_tvalid_6;
wire 										ctrl_s_axis_tlast_6;

wire [C_S_AXIS_DATA_WIDTH-1:0]				ctrl_s_axis_tdata_7;
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]		ctrl_s_axis_tkeep_7;
wire [C_S_AXIS_TUSER_WIDTH-1:0]				ctrl_s_axis_tuser_7;
wire 										ctrl_s_axis_tvalid_7;
wire 										ctrl_s_axis_tlast_7;


pkt_filter #(
	.C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
	.C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH)
)pkt_filter
(
	.clk(clk),
	.aresetn(aresetn),

	// input Slave AXI Stream
	.s_axis_tdata(s_axis_tdata),
	.s_axis_tkeep(s_axis_tkeep),
	.s_axis_tuser(s_axis_tuser),
	.s_axis_tvalid(s_axis_tvalid),
	.s_axis_tready(s_axis_tready),
	.s_axis_tlast(s_axis_tlast),

	// output Master AXI Stream
	.m_axis_tdata(s_axis_tdata_f),
	.m_axis_tkeep(s_axis_tkeep_f),
	.m_axis_tuser(s_axis_tuser_f),
	.m_axis_tvalid(s_axis_tvalid_f),
	.m_axis_tready(s_axis_tready_f && s_axis_tready_p),
	.m_axis_tlast(s_axis_tlast_f),

	.ctrl_m_axis_tdata (ctrl_s_axis_tdata_1),
	.ctrl_m_axis_tuser (ctrl_s_axis_tuser_1),
	.ctrl_m_axis_tkeep (ctrl_s_axis_tkeep_1),
	.ctrl_m_axis_tlast (ctrl_s_axis_tlast_1),
	.ctrl_m_axis_tvalid (ctrl_s_axis_tvalid_1)
);

// we will have multiple pkt fifos and phv fifos

// pkt fifo wires
wire [C_S_AXIS_DATA_WIDTH-1:0]		pkt_fifo_tdata_out [C_NUM_QUEUES-1:0];
wire [C_S_AXIS_TUSER_WIDTH-1:0]		pkt_fifo_tuser_out [C_NUM_QUEUES-1:0];
wire [C_S_AXIS_DATA_WIDTH/8-1:0]	pkt_fifo_tkeep_out [C_NUM_QUEUES-1:0];
wire [C_NUM_QUEUES-1:0]				pkt_fifo_tlast_out;

// output from parser
wire [C_S_AXIS_DATA_WIDTH-1:0]		parser_m_axis_tdata [C_NUM_QUEUES-1:0];
wire [C_S_AXIS_TUSER_WIDTH-1:0]		parser_m_axis_tuser [C_NUM_QUEUES-1:0];
wire [C_S_AXIS_DATA_WIDTH/8-1:0]	parser_m_axis_tkeep [C_NUM_QUEUES-1:0];
wire [C_NUM_QUEUES-1:0]				parser_m_axis_tlast;
wire [C_NUM_QUEUES-1:0]				parser_m_axis_tvalid;

wire [C_NUM_QUEUES-1:0]				pkt_fifo_rd_en;
wire [C_NUM_QUEUES-1:0]				pkt_fifo_nearly_full;
wire [C_NUM_QUEUES-1:0]				pkt_fifo_empty;

assign s_axis_tready_f = !pkt_fifo_nearly_full[0] ||
							!pkt_fifo_nearly_full[1] ||
							!pkt_fifo_nearly_full[2] ||
							!pkt_fifo_nearly_full[3];

generate 
	genvar i;
	for (i=0; i<C_NUM_QUEUES; i=i+1) begin:
		sub_pkt_fifo
	// pkt fifos
		fallthrough_small_fifo #(
			.WIDTH(C_S_AXIS_DATA_WIDTH + C_S_AXIS_TUSER_WIDTH + C_S_AXIS_DATA_WIDTH/8 + 1),
			.MAX_DEPTH_BITS(8)
		)
		pkt_fifo
		(
			.wr_en									(parser_m_axis_tvalid[i]),
			.din									({parser_m_axis_tdata[i],
														parser_m_axis_tuser[i],
														parser_m_axis_tkeep[i],
														parser_m_axis_tlast[i]}),

			.rd_en									(pkt_fifo_rd_en[i]),
			.dout									({pkt_fifo_tdata_out[i], 
														pkt_fifo_tuser_out[i], 
														pkt_fifo_tkeep_out[i], 
														pkt_fifo_tlast_out[i]}),

			.full									(),
			.prog_full								(),
			.nearly_full							(pkt_fifo_nearly_full[i]),
			.empty									(pkt_fifo_empty[i]),
			.reset									(~aresetn),
			.clk									(clk)
		);
	end
endgenerate

wire [PKT_VEC_WIDTH-1:0]		last_stg_phv_out [C_NUM_QUEUES-1:0];
wire [PKT_VEC_WIDTH-1:0]		phv_fifo_out [C_NUM_QUEUES-1:0];
wire							last_stg_phv_out_valid [C_NUM_QUEUES-1:0];


wire							phv_fifo_rd_en [C_NUM_QUEUES-1:0];
wire							phv_fifo_nearly_full [C_NUM_QUEUES-1:0];
wire							phv_fifo_empty [C_NUM_QUEUES-1:0];

generate
	for (i=0; i<C_NUM_QUEUES; i=i+1) begin:
		sub_phv_fifo
		// multiple PHV fifos
		fallthrough_small_fifo #(
			.WIDTH(PKT_VEC_WIDTH),
			.MAX_DEPTH_BITS(8)
		)
		phv_fifo
		(
			.din			(last_stg_phv_out[i]),
			.wr_en			(last_stg_phv_out_valid[i]),
			// .din			(stg1_phv_out),
			// .wr_en			(stg1_phv_out_valid_w),
		
			.rd_en			(phv_fifo_rd_en[i]),
			.dout			(phv_fifo_out[i]),
		
			.full			(),
			.prog_full		(),
			.nearly_full	(phv_fifo_nearly_full[i]),
			.empty			(phv_fifo_empty[i]),
			.reset			(~aresetn),
			.clk			(clk)
		);
	end
endgenerate

parser_top #(
    .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH), //for 100g mac exclusively
	.C_S_AXIS_TUSER_WIDTH(),
	.PKT_HDR_LEN()
)
phv_parser
(
	.axis_clk		(clk),
	.aresetn		(aresetn),
	// input slvae axi stream
	.s_axis_tdata	(s_axis_tdata_f_r),
	.s_axis_tuser	(s_axis_tuser_f_r),
	.s_axis_tkeep	(s_axis_tkeep_f_r),
	.s_axis_tvalid	(s_axis_tvalid_f_r & s_axis_tready_f),
	.s_axis_tlast	(s_axis_tlast_f_r),
	.s_axis_tready	(s_axis_tready_p),

	// output
	.parser_valid		(stg0_phv_in_valid),
	.pkt_hdr_vec		(stg0_phv_in),
	.out_vlan			(stg0_vlan_in),
	.out_vlan_valid		(stg0_vlan_valid_in),
	.out_vlan_ready		(stg0_vlan_fifo_ready),
	// 
	.stg_ready_in	(stg0_ready),

	// output to different pkt fifos
	.m_axis_tdata_0					(parser_m_axis_tdata[0]),
	.m_axis_tuser_0					(parser_m_axis_tuser[0]),
	.m_axis_tkeep_0					(parser_m_axis_tkeep[0]),
	.m_axis_tlast_0					(parser_m_axis_tlast[0]),
	.m_axis_tvalid_0				(parser_m_axis_tvalid[0]),
	.m_axis_tready_0				(~pkt_fifo_nearly_full[0]),

	.m_axis_tdata_1					(parser_m_axis_tdata[1]),
	.m_axis_tuser_1					(parser_m_axis_tuser[1]),
	.m_axis_tkeep_1					(parser_m_axis_tkeep[1]),
	.m_axis_tlast_1					(parser_m_axis_tlast[1]),
	.m_axis_tvalid_1				(parser_m_axis_tvalid[1]),
	.m_axis_tready_1				(~pkt_fifo_nearly_full[1]),

	.m_axis_tdata_2					(parser_m_axis_tdata[2]),
	.m_axis_tuser_2					(parser_m_axis_tuser[2]),
	.m_axis_tkeep_2					(parser_m_axis_tkeep[2]),
	.m_axis_tlast_2					(parser_m_axis_tlast[2]),
	.m_axis_tvalid_2				(parser_m_axis_tvalid[2]),
	.m_axis_tready_2				(~pkt_fifo_nearly_full[2]),

	.m_axis_tdata_3					(parser_m_axis_tdata[3]),
	.m_axis_tuser_3					(parser_m_axis_tuser[3]),
	.m_axis_tkeep_3					(parser_m_axis_tkeep[3]),
	.m_axis_tlast_3					(parser_m_axis_tlast[3]),
	.m_axis_tvalid_3				(parser_m_axis_tvalid[3]),
	.m_axis_tready_3				(~pkt_fifo_nearly_full[3]),

	// control path
    .ctrl_s_axis_tdata(ctrl_s_axis_tdata_1),
	.ctrl_s_axis_tuser(ctrl_s_axis_tuser_1),
	.ctrl_s_axis_tkeep(ctrl_s_axis_tkeep_1),
	.ctrl_s_axis_tlast(ctrl_s_axis_tlast_1),
	.ctrl_s_axis_tvalid(ctrl_s_axis_tvalid_1),

    .ctrl_m_axis_tdata(ctrl_s_axis_tdata_2),
	.ctrl_m_axis_tuser(ctrl_s_axis_tuser_2),
	.ctrl_m_axis_tkeep(ctrl_s_axis_tkeep_2),
	.ctrl_m_axis_tlast(ctrl_s_axis_tlast_2),
	.ctrl_m_axis_tvalid(ctrl_s_axis_tvalid_2)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(0)
)
stage0
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg0_phv_in),
    .phv_in_valid			(stg0_phv_in_valid_w),
	.vlan_in				(stg0_vlan_in),
	.vlan_valid_in			(stg0_vlan_valid_in),
	.vlan_fifo_ready		(stg0_vlan_fifo_ready),
	// output
	.vlan_out				(stg0_vlan_out),
	.vlan_valid_out			(stg0_vlan_valid_out),
	.vlan_out_ready			(stg1_vlan_fifo_ready),
	// output
    .phv_out				(stg0_phv_out),
    .phv_out_valid			(stg0_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg0_ready),
	.stage_ready_in			(stg1_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_2),
	.c_s_axis_tuser(ctrl_s_axis_tuser_2),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_2),
	.c_s_axis_tlast(ctrl_s_axis_tlast_2),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_2),

    .c_m_axis_tdata(ctrl_s_axis_tdata_3),
	.c_m_axis_tuser(ctrl_s_axis_tuser_3),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_3),
	.c_m_axis_tlast(ctrl_s_axis_tlast_3),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_3)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(1)
)
stage1
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg0_phv_out),
    .phv_in_valid			(stg0_phv_out_valid_w),
	.vlan_in				(stg0_vlan_out),
	.vlan_valid_in			(stg0_vlan_valid_out),
	.vlan_fifo_ready		(stg1_vlan_fifo_ready),
	// output
	.vlan_out				(stg1_vlan_out),
	.vlan_valid_out			(stg1_vlan_valid_out),
	.vlan_out_ready			(stg2_vlan_fifo_ready),
	// output
    .phv_out				(stg1_phv_out),
    .phv_out_valid			(stg1_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg1_ready),
	.stage_ready_in			(stg2_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_3),
	.c_s_axis_tuser(ctrl_s_axis_tuser_3),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_3),
	.c_s_axis_tlast(ctrl_s_axis_tlast_3),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_3),

    .c_m_axis_tdata(ctrl_s_axis_tdata_4),
	.c_m_axis_tuser(ctrl_s_axis_tuser_4),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_4),
	.c_m_axis_tlast(ctrl_s_axis_tlast_4),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_4)
);


stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(2)
)
stage2
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg1_phv_out),
    .phv_in_valid			(stg1_phv_out_valid_w),
	.vlan_in				(stg1_vlan_out),
	.vlan_valid_in			(stg1_vlan_valid_out),
	.vlan_fifo_ready		(stg2_vlan_fifo_ready),
	// output
	.vlan_out				(stg2_vlan_out),
	.vlan_valid_out			(stg2_vlan_valid_out),
	.vlan_out_ready			(stg3_vlan_fifo_ready),
	// output
    .phv_out				(stg2_phv_out),
    .phv_out_valid			(stg2_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg2_ready),
	.stage_ready_in			(stg3_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_4),
	.c_s_axis_tuser(ctrl_s_axis_tuser_4),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_4),
	.c_s_axis_tlast(ctrl_s_axis_tlast_4),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_4),

    .c_m_axis_tdata(ctrl_s_axis_tdata_5),
	.c_m_axis_tuser(ctrl_s_axis_tuser_5),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_5),
	.c_m_axis_tlast(ctrl_s_axis_tlast_5),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_5)
);

stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(3)
)
stage3
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg2_phv_out),
    .phv_in_valid			(stg2_phv_out_valid_w),
	.vlan_in				(stg2_vlan_out),
	.vlan_valid_in			(stg2_vlan_valid_out),
	.vlan_fifo_ready		(stg3_vlan_fifo_ready),
	// output
	.vlan_out				(stg3_vlan_out),
	.vlan_valid_out			(stg3_vlan_valid_out),
	.vlan_out_ready			(last_stg_vlan_fifo_ready),
	// output
    .phv_out				(stg3_phv_out),
    .phv_out_valid			(stg3_phv_out_valid),
	// back-pressure signals
	.stage_ready_out		(stg3_ready),
	.stage_ready_in			(last_stg_ready),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_5),
	.c_s_axis_tuser(ctrl_s_axis_tuser_5),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_5),
	.c_s_axis_tlast(ctrl_s_axis_tlast_5),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_5),

    .c_m_axis_tdata(ctrl_s_axis_tdata_6),
	.c_m_axis_tuser(ctrl_s_axis_tuser_6),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_6),
	.c_m_axis_tlast(ctrl_s_axis_tlast_6),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_6)
);

// [NOTICE] change to last stage
last_stage #(
	.C_S_AXIS_DATA_WIDTH(256),
	.STAGE_ID(4)
)
stage4
(
	.axis_clk				(clk),
    .aresetn				(aresetn),

	// input
    .phv_in					(stg3_phv_out),
    .phv_in_valid			(stg3_phv_out_valid_w),
	.vlan_in				(stg3_vlan_out),
	.vlan_valid_in			(stg3_vlan_valid_out),
	.vlan_fifo_ready		(last_stg_vlan_fifo_ready),
	// back-pressure signals
	.stage_ready_out		(last_stg_ready),
	// output
    .phv_out_0				(last_stg_phv_out[0]),
    .phv_out_valid_0		(last_stg_phv_out_valid[0]),
	.phv_fifo_ready_0		(~phv_fifo_nearly_full[0]),

    .phv_out_1				(last_stg_phv_out[1]),
    .phv_out_valid_1		(last_stg_phv_out_valid[1]),
	.phv_fifo_ready_1		(~phv_fifo_nearly_full[1]),

    .phv_out_2				(last_stg_phv_out[2]),
    .phv_out_valid_2		(last_stg_phv_out_valid[2]),
	.phv_fifo_ready_2		(~phv_fifo_nearly_full[2]),

    .phv_out_3				(last_stg_phv_out[3]),
    .phv_out_valid_3		(last_stg_phv_out_valid[3]),
	.phv_fifo_ready_3		(~phv_fifo_nearly_full[3]),

	// control path
    .c_s_axis_tdata(ctrl_s_axis_tdata_6),
	.c_s_axis_tuser(ctrl_s_axis_tuser_6),
	.c_s_axis_tkeep(ctrl_s_axis_tkeep_6),
	.c_s_axis_tlast(ctrl_s_axis_tlast_6),
	.c_s_axis_tvalid(ctrl_s_axis_tvalid_6),

    .c_m_axis_tdata(ctrl_s_axis_tdata_7),
	.c_m_axis_tuser(ctrl_s_axis_tuser_7),
	.c_m_axis_tkeep(ctrl_s_axis_tkeep_7),
	.c_m_axis_tlast(ctrl_s_axis_tlast_7),
	.c_m_axis_tvalid(ctrl_s_axis_tvalid_7)
);

//

wire [C_S_AXIS_DATA_WIDTH-1:0]			depar_out_tdata [C_NUM_QUEUES-1:0];
wire [((C_S_AXIS_DATA_WIDTH/8))-1:0]	depar_out_tkeep [C_NUM_QUEUES-1:0];
wire [C_S_AXIS_TUSER_WIDTH-1:0]			depar_out_tuser [C_NUM_QUEUES-1:0];
wire									depar_out_tvalid [C_NUM_QUEUES-1:0];
wire 									depar_out_tready [C_NUM_QUEUES-1:0];
wire 									depar_out_tlast [C_NUM_QUEUES-1:0];

generate
	for (i=0; i<C_NUM_QUEUES; i=i+1) begin:
		sub_deparser_top
		deparser_top #(
			.C_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
			.C_AXIS_TUSER_WIDTH(),
			.C_PKT_VEC_WIDTH()
		)
		phv_deparser (
			.axis_clk				(clk),
			.aresetn				(aresetn),
		
			.pkt_fifo_tdata			(pkt_fifo_tdata_out[i]),
			.pkt_fifo_tkeep			(pkt_fifo_tkeep_out[i]),
			.pkt_fifo_tuser			(pkt_fifo_tuser_out[i]),
			.pkt_fifo_tlast			(pkt_fifo_tlast_out[i]),
			.pkt_fifo_empty			(pkt_fifo_empty[i]),
			// output from STAGE
			.pkt_fifo_rd_en			(pkt_fifo_rd_en[i]),
		
			.phv_fifo_out			(last_stg_phv_out[i]),
			.phv_fifo_empty			(phv_fifo_empty[i]),
			.phv_fifo_rd_en			(phv_fifo_rd_en[i]),
			// output
			.depar_out_tdata		(depar_out_tdata[i]),
			.depar_out_tkeep		(depar_out_tkeep[i]),
			.depar_out_tuser		(depar_out_tuser[i]),
			.depar_out_tvalid		(depar_out_tvalid[i]),
			.depar_out_tlast		(depar_out_tlast[i]),
			.depar_out_tready		(depar_out_tready[i]), // input
		
			// control path
			.ctrl_s_axis_tdata(ctrl_s_axis_tdata_7),
			.ctrl_s_axis_tuser(ctrl_s_axis_tuser_7),
			.ctrl_s_axis_tkeep(ctrl_s_axis_tkeep_7),
			.ctrl_s_axis_tlast(ctrl_s_axis_tlast_7),
			.ctrl_s_axis_tvalid(ctrl_s_axis_tvalid_7)
		);
	end
endgenerate

// output arbiter
output_arbiter #(
	.C_AXIS_DATA_WIDTH(256),
	.C_AXIS_TUSER_WIDTH(128)
)
out_arb (
	.axis_clk						(clk),
	.aresetn						(aresetn),
	// output
	.m_axis_tdata					(m_axis_tdata),
	.m_axis_tkeep					(m_axis_tkeep),
	.m_axis_tuser					(m_axis_tuser),
	.m_axis_tlast					(m_axis_tlast),
	.m_axis_tvalid					(m_axis_tvalid),
	.m_axis_tready					(m_axis_tready),
	// input from deparser
	.s_axis_tdata_0					(depar_out_tdata[0]),
	.s_axis_tkeep_0					(depar_out_tkeep[0]),
	.s_axis_tuser_0					(depar_out_tuser[0]),
	.s_axis_tlast_0					(depar_out_tlast[0]),
	.s_axis_tvalid_0				(depar_out_tvalid[0]),
	.s_axis_tready_0				(depar_out_tready[0]),

	.s_axis_tdata_1					(depar_out_tdata[1]),
	.s_axis_tkeep_1					(depar_out_tkeep[1]),
	.s_axis_tuser_1					(depar_out_tuser[1]),
	.s_axis_tlast_1					(depar_out_tlast[1]),
	.s_axis_tvalid_1				(depar_out_tvalid[1]),
	.s_axis_tready_1				(depar_out_tready[1]),

	.s_axis_tdata_2					(depar_out_tdata[2]),
	.s_axis_tkeep_2					(depar_out_tkeep[2]),
	.s_axis_tuser_2					(depar_out_tuser[2]),
	.s_axis_tlast_2					(depar_out_tlast[2]),
	.s_axis_tvalid_2				(depar_out_tvalid[2]),
	.s_axis_tready_2				(depar_out_tready[2]),

	.s_axis_tdata_3					(depar_out_tdata[3]),
	.s_axis_tkeep_3					(depar_out_tkeep[3]),
	.s_axis_tuser_3					(depar_out_tuser[3]),
	.s_axis_tlast_3					(depar_out_tlast[3]),
	.s_axis_tvalid_3				(depar_out_tvalid[3]),
	.s_axis_tready_3				(depar_out_tready[3])
);

always @(posedge clk) begin
	if (~aresetn) begin
		s_axis_tdata_f_r <= 0;
		s_axis_tuser_f_r <= 0;
		s_axis_tkeep_f_r <= 0;
		s_axis_tlast_f_r <= 0;
		s_axis_tvalid_f_r <= 0;
	end
	else begin
		s_axis_tdata_f_r <= s_axis_tdata_f;
		s_axis_tuser_f_r <= s_axis_tuser_f;
		s_axis_tkeep_f_r <= s_axis_tkeep_f;
		s_axis_tlast_f_r <= s_axis_tlast_f;
		s_axis_tvalid_f_r <= s_axis_tvalid_f;
	end
end


always @(posedge clk) begin
	if (~aresetn) begin
		stg0_phv_in_valid_r <= 0;
		stg0_phv_out_valid_r <= 0;
		stg1_phv_out_valid_r <= 0;
		stg2_phv_out_valid_r <= 0;
		stg3_phv_out_valid_r <= 0;
	end
	else begin
		stg0_phv_in_valid_r <= stg0_phv_in_valid;
		stg0_phv_out_valid_r <= stg0_phv_out_valid;
		stg1_phv_out_valid_r <= stg1_phv_out_valid;
		stg2_phv_out_valid_r <= stg2_phv_out_valid;
		stg3_phv_out_valid_r <= stg3_phv_out_valid;
	end
end

assign stg0_phv_in_valid_w = stg0_phv_in_valid ;//& ~stg0_phv_in_valid_r;
assign stg0_phv_out_valid_w = stg0_phv_out_valid ;//& ~stg0_phv_out_valid_r;
assign stg1_phv_out_valid_w = stg1_phv_out_valid ;//& ~stg1_phv_out_valid_r;
assign stg2_phv_out_valid_w = stg2_phv_out_valid ;//& ~stg2_phv_out_valid_r;
assign stg3_phv_out_valid_w = stg3_phv_out_valid ;//& ~stg3_phv_out_valid_r;

endmodule

