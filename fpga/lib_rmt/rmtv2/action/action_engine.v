`timescale 1ns / 1ps
module action_engine #(
    parameter STAGE_ID = 0,
    parameter PHV_LEN = 4*8*64+256,
    parameter ACT_LEN = 64,
    parameter ACTION_ID = 3,
    parameter C_S_AXIS_DATA_WIDTH = 256,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
	parameter C_VLANID_WIDTH = 12,
	parameter C_NUM_PHVS = 64+1,
	parameter C_WIDTH_METADATA = 256
)(
    input clk,
    input rst_n,

    //signals from lookup to ALUs
    input [PHV_LEN-1:0]           phv_in,
    input                         phv_valid_in,
    input [ACT_LEN*C_NUM_PHVS-1:0]        action_in,
    input                         action_valid_in,
    output                        ready_out,

    //signals output from ALUs
    output reg [PHV_LEN-1:0]      phv_out,
    output reg                    phv_valid_out,
    input                         ready_in,
	// vlan input from lookup module
	input [C_VLANID_WIDTH-1:0]			act_vlan_in,
	input								act_vlan_valid_in,
	output reg							act_vlan_ready,
	// vlan
	// output reg [C_VLANID_WIDTH-1:0]		vlan_out_d1,
	// output reg							vlan_out_valid_d1,
	output reg [C_VLANID_WIDTH-1:0]		vlan_out,
	output reg							vlan_out_valid,
	input								vlan_out_ready,

    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]				c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]			c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]			c_s_axis_tkeep,
	input										c_s_axis_tvalid,
	input										c_s_axis_tlast,

    output reg [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output reg [C_S_AXIS_DATA_WIDTH/8-1:0]		c_m_axis_tkeep,
	output reg 								    c_m_axis_tvalid,
	output reg 								    c_m_axis_tlast
);

                        
/********intermediate variables declared here********/
localparam width_4B = 32;

wire                        alu_in_valid;
wire [width_4B*64-1:0]       alu_in_4B_1;
wire [width_4B*64-1:0]       alu_in_4B_2;
wire [width_4B*64-1:0]       alu_in_4B_3;
wire [C_WIDTH_METADATA-1:0]                alu_in_phv_remain_data;
wire [ACT_LEN*C_NUM_PHVS-1:0]       alu_in_action;
wire                        alu_in_action_valid;

// output phv
wire		                phv_valid_bit;

//
wire                        alu_ready_out;
reg							act_vlan_ready_next;

reg							page_tbl_out_valid, page_tbl_out_valid_next;
// reg							page_tbl_out_valid_d1;
// output from ram
wire [15:0]					page_tbl_out;
// reg [15:0]					page_tbl_out_d1;

/********intermediate variables declared here********/
/********IPs instancilized here*********/

wire [width_4B-1:0]			output_4B[0:63];
wire [C_WIDTH_METADATA-1:0]				output_md;


reg [PHV_LEN-1:0]	phv_out_r;
reg					phv_valid_out_r;

always @(*) begin

	phv_out_r = phv_out;
	phv_valid_out_r = 0;

	if (phv_valid_bit) begin
		phv_valid_out_r = 1;
		phv_out_r = {
				output_4B[63], output_4B[62], output_4B[61], output_4B[60], output_4B[59], output_4B[58], output_4B[57], output_4B[56],
				output_4B[55], output_4B[54], output_4B[53], output_4B[52], output_4B[51], output_4B[50], output_4B[49], output_4B[48],
				output_4B[47], output_4B[46], output_4B[45], output_4B[44], output_4B[43], output_4B[42], output_4B[41], output_4B[40],
				output_4B[39], output_4B[38], output_4B[37], output_4B[36], output_4B[35], output_4B[34], output_4B[33], output_4B[32],
				output_4B[31], output_4B[30], output_4B[29], output_4B[28], output_4B[27], output_4B[26], output_4B[25], output_4B[24],
				output_4B[23], output_4B[22], output_4B[21], output_4B[20], output_4B[19], output_4B[18], output_4B[17], output_4B[16],
				output_4B[15], output_4B[14], output_4B[13], output_4B[12], output_4B[11], output_4B[10], output_4B[9], output_4B[8],
				output_4B[7], output_4B[6], output_4B[5], output_4B[4], output_4B[3], output_4B[2], output_4B[1], output_4B[0],
				output_md};
	end
end

always @(posedge clk) begin
	if (~rst_n) begin
		phv_out <= 0;
		phv_valid_out <= 0;
	end
	else begin
		phv_out <= phv_out_r;
		phv_valid_out <= phv_valid_out_r;
	end
end

//================================================================
// vlan out logic
localparam		IDLE=0,
				EMPTY_1=1,
				FLUSH_VLAN=2;

reg [C_VLANID_WIDTH-1:0]	vlan_out_next;
reg							vlan_out_valid_next;
reg	[1:0]					state, state_next;


always @(*) begin

	state_next = state;
	vlan_out_next = vlan_out;
	vlan_out_valid_next = 0;

	case (state)
		IDLE: begin
			if (phv_valid_in) begin
				vlan_out_next = phv_in[140:129];

				state_next = FLUSH_VLAN;
			end
		end
		FLUSH_VLAN: begin
			if (vlan_out_ready) begin
				vlan_out_valid_next = 1;
				state_next = IDLE;
			end
		end
	endcase
end

always @(posedge clk) begin
	if (~rst_n) begin
		state <= IDLE;
		vlan_out <= 0;
		vlan_out_valid <= 0;

		//vlan_out_d1 <= 0;
		//vlan_out_valid_d1 <= 0;
	end
	else begin
		state <= state_next;
		vlan_out <= vlan_out_next;
		vlan_out_valid <= vlan_out_valid_next;

		// vlan_out_d1 <= vlan_out;
		// vlan_out_valid_d1 <= vlan_out_valid;
	end
end

localparam	VLAN_FIFO_IDLE=0,
			VLAN_FIFO_1CYCLE=1;

reg [2:0] vlan_fifo_state, vlan_fifo_state_next;

always @(*) begin
	vlan_fifo_state_next = vlan_fifo_state;
	act_vlan_ready_next = act_vlan_ready;
	page_tbl_out_valid_next = 0;

	case (vlan_fifo_state) 
		VLAN_FIFO_IDLE: begin
			if (act_vlan_valid_in) begin
				vlan_fifo_state_next = VLAN_FIFO_1CYCLE;
				act_vlan_ready_next = 0;
			end
		end
		VLAN_FIFO_1CYCLE: begin
			vlan_fifo_state_next = VLAN_FIFO_IDLE;
			act_vlan_ready_next = 1;
			page_tbl_out_valid_next = 1;
		end
	endcase
end

always @(posedge clk) begin
	if (~rst_n) begin
		vlan_fifo_state <= VLAN_FIFO_IDLE;
		act_vlan_ready <= 1;
		page_tbl_out_valid <= 0;
	end
	else begin
		vlan_fifo_state <= vlan_fifo_state_next;
		act_vlan_ready <= act_vlan_ready_next;
		page_tbl_out_valid <= page_tbl_out_valid_next;
	end
end



//crossbar
crossbar #(
    .STAGE_ID(STAGE_ID),
    .PHV_LEN(),
    .ACT_LEN(),
)cross_bar(
    .clk(clk),
    .rst_n(rst_n),
    //input from PHV
    .phv_in(phv_in),
    .phv_in_valid(phv_valid_in),
    //input from action
    .action_in(action_in),
    .action_in_valid(action_valid_in),
    .ready_out(ready_out),
    //output to the ALU
    .alu_in_valid(alu_in_valid),
    // .alu_in_6B_1(alu_in_6B_1),
    // .alu_in_6B_2(alu_in_6B_2),
    .alu_in_4B_1(alu_in_4B_1),
    .alu_in_4B_2(alu_in_4B_2),
    .alu_in_4B_3(alu_in_4B_3),
    // .alu_in_2B_1(alu_in_2B_1),
    // .alu_in_2B_2(alu_in_2B_2),
    .phv_remain_data(alu_in_phv_remain_data),
    .action_out(alu_in_action),
    .action_valid_out(alu_in_action_valid),
    .ready_in(alu_ready_out)
);



//ALU_2 with stateful memory
genvar gen_i;
alu_2 #(
    .STAGE_ID(STAGE_ID),
    .ACTION_LEN(),
    .DATA_WIDTH(width_4B),  //data width of the ALU
    .C_S_AXIS_DATA_WIDTH(C_S_AXIS_DATA_WIDTH),
    .C_S_AXIS_TUSER_WIDTH(C_S_AXIS_TUSER_WIDTH)
)alu_2_0(
    .clk(clk),
    .rst_n(rst_n),
    //input from sub_action
    .action_in(alu_in_action[(63+1+1)*ACT_LEN-1 -: ACT_LEN]),
    .action_valid(alu_in_action_valid),
    .operand_1_in(alu_in_4B_1[(63+1) * width_4B -1 -: width_4B]),
    .operand_2_in(alu_in_4B_2[(63+1) * width_4B -1 -: width_4B]),
    .operand_3_in(alu_in_4B_3[(63+1) * width_4B -1 -: width_4B]),
    .ready_out(alu_ready_out),
	//
	.page_tbl_out			(page_tbl_out),
	.page_tbl_out_valid		(page_tbl_out_valid),
    //output to form PHV
    .container_out_w(output_4B[63]),
    .container_out_valid(),
    .ready_in(ready_in)
);

generate
    for(gen_i = 62; gen_i >= 0; gen_i = gen_i - 1) begin
		alu_1 #(
		    .STAGE_ID(STAGE_ID),
		    .ACTION_LEN(),
		    .DATA_WIDTH(width_4B)
		)alu_1_4B(
		    .clk(clk),
		    .rst_n(rst_n),
		    .action_in(alu_in_action[(gen_i+1+1)*ACT_LEN-1 -: ACT_LEN]),
		    .action_valid(alu_in_action_valid),
		    .operand_1_in(alu_in_4B_1[(gen_i+1) * width_4B -1 -: width_4B]),
		    .operand_2_in(alu_in_4B_2[(gen_i+1) * width_4B -1 -: width_4B]),
		    // .container_out(phv_out[width_2B*8+356+width_4B*(gen_i+1) -1 -: width_4B]),
		    .container_out(output_4B[gen_i]),
		    .container_out_valid()
		);
    end
endgenerate


//initialize ALU_3 for matedata

alu_3 #(
    .STAGE_ID(STAGE_ID),
    .ACTION_LEN(),
    .META_LEN()
)alu_3_0(
    .clk(clk),
    .rst_n(rst_n),
    //input data shall be metadata & com_ins
    .comp_meta_data_in(alu_in_phv_remain_data),
    .comp_meta_data_valid_in(alu_in_valid),
    .action_in(alu_in_action[63:0]),
    .action_valid_in(alu_in_action_valid),

    //output is the modified metadata plus comp_ins
    // .comp_meta_data_out(phv_out[355:0]),
    .comp_meta_data_out(output_md),
    .comp_meta_data_valid_out(phv_valid_bit)
);




/*
    CONTROL PATH
*/

// control path remains the same for now
generate 
	if (C_S_AXIS_DATA_WIDTH == 256) begin
		wire [7:0]          mod_id; //module ID
		wire [15:0]         control_flag; //dst udp port num
		wire[C_S_AXIS_DATA_WIDTH-1:0] c_s_axis_tdata_swapped;
		assign c_s_axis_tdata_swapped = {	c_s_axis_tdata[0+:8],
											c_s_axis_tdata[8+:8],
											c_s_axis_tdata[16+:8],
											c_s_axis_tdata[24+:8],
											c_s_axis_tdata[32+:8],
											c_s_axis_tdata[40+:8],
											c_s_axis_tdata[48+:8],
											c_s_axis_tdata[56+:8],
											c_s_axis_tdata[64+:8],
											c_s_axis_tdata[72+:8],
											c_s_axis_tdata[80+:8],
											c_s_axis_tdata[88+:8],
											c_s_axis_tdata[96+:8],
											c_s_axis_tdata[104+:8],
											c_s_axis_tdata[112+:8],
											c_s_axis_tdata[120+:8],
											c_s_axis_tdata[128+:8],
											c_s_axis_tdata[136+:8],
											c_s_axis_tdata[144+:8],
											c_s_axis_tdata[152+:8],
											c_s_axis_tdata[160+:8],
											c_s_axis_tdata[168+:8],
											c_s_axis_tdata[176+:8],
											c_s_axis_tdata[184+:8],
											c_s_axis_tdata[192+:8],
											c_s_axis_tdata[200+:8],
											c_s_axis_tdata[208+:8],
											c_s_axis_tdata[216+:8],
											c_s_axis_tdata[224+:8],
											c_s_axis_tdata[232+:8],
											c_s_axis_tdata[240+:8],
											c_s_axis_tdata[248+:8]};

        assign mod_id = c_s_axis_tdata[112+:8];
        assign control_flag = c_s_axis_tdata[64+:16];
		localparam	IDLE_C = 0,
					PARSE_C = 1,
					RAM_ENTRY = 2,
					FLUSH_REST_C = 3;
		// 
		reg [2:0] c_state, c_state_next;
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

		reg [15:0]							c_wr_data_next, c_wr_data;
		reg [7:0]							c_index_next, c_index;
		reg									c_wr_en_next, c_wr_en;

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

			c_index_next = c_index;
			c_wr_en_next = 0;
			c_wr_data_next = c_wr_data;

			case (c_state) 
				IDLE_C: begin // 1st segment
					r_tvalid = 0;
					if (c_s_axis_tvalid) begin
						// store 1st segment
						r_1st_tdata_next = c_s_axis_tdata;
						r_1st_tuser_next = c_s_axis_tuser;
						r_1st_tkeep_next = c_s_axis_tkeep;
						r_1st_tlast_next = c_s_axis_tlast;
						r_1st_tvalid_next = c_s_axis_tvalid;

						c_state_next = PARSE_C;
					end
				end
				PARSE_C: begin // 2nd segment
					if (mod_id[7:3] == STAGE_ID && mod_id[2:0] == ACTION_ID && 
						control_flag == 16'hf2f1 && c_s_axis_tvalid) begin
						// should not emit segment
						c_index_next = c_s_axis_tdata[128+:8];
						c_state_next = RAM_ENTRY;
					end
					else if (!c_s_axis_tvalid) begin
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
				RAM_ENTRY: begin // 3rd segment
					if (c_s_axis_tvalid) begin
						c_wr_en_next = 1; // next clk to write
						c_wr_data_next = c_s_axis_tdata_swapped[255-:16];
						
						c_state_next = FLUSH_REST_C;
					end
				end
				FLUSH_REST_C: begin
					c_wr_en_next = 0;
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
				c_index <= 0;
				c_wr_en <= 0;
				c_wr_data <= 0;
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
				c_index <= c_index_next;
				c_wr_en <= c_wr_en_next;
				c_wr_data <= c_wr_data_next;
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
				c_s_axis_tdata_d1 <= c_s_axis_tdata;
				c_s_axis_tuser_d1 <= c_s_axis_tuser;
				c_s_axis_tkeep_d1 <= c_s_axis_tkeep;
				c_s_axis_tlast_d1 <= c_s_axis_tlast;
				c_s_axis_tvalid_d1 <= c_s_axis_tvalid;
				// 
				r_1st_tdata <= r_1st_tdata_next;
				r_1st_tkeep <= r_1st_tkeep_next;
				r_1st_tuser <= r_1st_tuser_next;
				r_1st_tlast <= r_1st_tlast_next;
				r_1st_tvalid <= r_1st_tvalid_next;
			end
		end
		//page table
		page_tbl_16w_32d
		page_tbl_16w_32d
		(
		    //write
		    .addra(c_index[4:0]),
		    .clka(clk),
		    .dina(c_wr_data),
		    .ena(1'b1),
		    .wea(c_wr_en),
		
		    //match
		    .addrb(act_vlan_in[8:4]),
		    .clkb(clk),
		    .doutb(page_tbl_out),
		    .enb(1'b1)
		);
	end
endgenerate

endmodule
