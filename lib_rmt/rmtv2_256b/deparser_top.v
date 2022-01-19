`timescale 1ns / 1ps

module deparser_top #(
	parameter	C_AXIS_DATA_WIDTH = 256,
	parameter	C_AXIS_TUSER_WIDTH = 128,
	parameter	C_PKT_VEC_WIDTH = 4*64*8+256,
	parameter	DEPARSER_MOD_ID = 3'b101,
	parameter	C_VLANID_WIDTH = 12,
	parameter	C_FIFO_BITS_WIDTH = 8
)
(
	input									axis_clk,
	input									aresetn,
	//
	input [C_AXIS_DATA_WIDTH-1:0]			pkt_fifo_tdata,
	input [C_AXIS_DATA_WIDTH/8-1:0]			pkt_fifo_tkeep,
	input [C_AXIS_TUSER_WIDTH-1:0]			pkt_fifo_tuser,
	input									pkt_fifo_tlast,
	input									pkt_fifo_empty,
	output									pkt_fifo_rd_en,

	input [C_PKT_VEC_WIDTH-1:0]				phv_fifo_out,
	input									phv_fifo_empty,
	output									phv_fifo_rd_en,

	output [C_AXIS_DATA_WIDTH-1:0]			depar_out_tdata,
	output [C_AXIS_DATA_WIDTH/8-1:0]		depar_out_tkeep,
	output [C_AXIS_TUSER_WIDTH-1:0]			depar_out_tuser,
	output									depar_out_tvalid,
	output 									depar_out_tlast,
	input									depar_out_tready,

	// control path
	input [C_AXIS_DATA_WIDTH-1:0]			ctrl_s_axis_tdata,
	input [C_AXIS_TUSER_WIDTH-1:0]			ctrl_s_axis_tuser,
	input [C_AXIS_DATA_WIDTH/8-1:0]			ctrl_s_axis_tkeep,
	input									ctrl_s_axis_tvalid,
	input									ctrl_s_axis_tlast
);

//
depar_do_deparsing #(
	.C_PKT_VEC_WIDTH(C_PKT_VEC_WIDTH),
	.DEPARSER_MOD_ID(DEPARSER_MOD_ID)
)
do_deparsing
(
	.clk										(axis_clk),
	.aresetn									(aresetn),
	// phv
	.phv_fifo_out								(phv_fifo_out),
	.phv_fifo_empty								(phv_fifo_empty),
	.phv_fifo_rd_en								(phv_fifo_rd_en),
	//
	.pkt_fifo_tdata								(pkt_fifo_tdata),
	.pkt_fifo_tuser								(pkt_fifo_tuser),
	.pkt_fifo_tkeep								(pkt_fifo_tkeep),
	.pkt_fifo_tlast								(pkt_fifo_tlast),
	.pkt_fifo_empty								(pkt_fifo_empty),
	.pkt_fifo_rd_en								(pkt_fifo_rd_en),
	
	// output
	.depar_out_tdata							(depar_out_tdata),
	.depar_out_tuser							(depar_out_tuser),
	.depar_out_tkeep							(depar_out_tkeep),
	.depar_out_tlast							(depar_out_tlast),
	.depar_out_tvalid							(depar_out_tvalid),
	.depar_out_tready							(depar_out_tready),
	// control path
	.ctrl_s_axis_tdata							(ctrl_s_axis_tdata),
	.ctrl_s_axis_tuser							(ctrl_s_axis_tuser),
	.ctrl_s_axis_tkeep							(ctrl_s_axis_tkeep),
	.ctrl_s_axis_tvalid							(ctrl_s_axis_tvalid),
	.ctrl_s_axis_tlast							(ctrl_s_axis_tlast)
);

endmodule

