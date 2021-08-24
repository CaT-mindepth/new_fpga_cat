`timescale 1ns / 1ps

module lke_ram_part #(
    parameter C_S_AXIS_DATA_WIDTH = 512,
    parameter C_S_AXIS_TUSER_WIDTH = 128,
    parameter STAGE_ID = 0,
    parameter PHV_LEN = 48*8+32*8+16*8+256,
    parameter KEY_LEN = 48*2+32*2+16*2+5,
    parameter ACT_LEN = 625,
    parameter LOOKUP_ID = 2,
	parameter C_VLANID_WIDTH = 12
)
(
    input clk,
    input rst_n,

    //output from key extractor
    input [PHV_LEN-1:0]							phv_in,
	input										phv_valid,
	input [3:0]									match_addr,
	input										if_match,
	output										ready_out,


    //output to the action engine
    output [ACT_LEN-1:0]						action,
    output reg									action_valid,
    output reg [PHV_LEN-1:0]					phv_out, 
	input										ready_in,

	// output vlan to the action engine
	output reg [C_VLANID_WIDTH-1:0]				act_vlan_out,
	output reg									act_vlan_out_valid,
	input										act_vlan_ready,


    //control path
    input [C_S_AXIS_DATA_WIDTH-1:0]			    c_s_axis_tdata,
	input [C_S_AXIS_TUSER_WIDTH-1:0]		    c_s_axis_tuser,
	input [C_S_AXIS_DATA_WIDTH/8-1:0]		    c_s_axis_tkeep,
	input									    c_s_axis_tvalid,
	input									    c_s_axis_tlast,

    output reg [C_S_AXIS_DATA_WIDTH-1:0]		c_m_axis_tdata,
	output reg [C_S_AXIS_TUSER_WIDTH-1:0]		c_m_axis_tuser,
	output reg [C_S_AXIS_DATA_WIDTH/8-1:0]		c_m_axis_tkeep,
	output reg 								    c_m_axis_tvalid,
	output reg 							    	c_m_axis_tlast

);

/********intermediate variables declared here********/
wire [ACT_LEN-1:0] action_wire;
wire [11:0] vlan_id;

assign vlan_id = phv_in[140:129];


reg [PHV_LEN-1:0] phv_reg;
reg if_match_d1;
reg [2:0] lookup_state;

assign action = (if_match_d1==1)?action_wire:625'h3f;

//here, the output should be controlled.
localparam IDLE_S = 3'd0,
           WAIT1_S = 3'd1,
           WAIT2_S = 3'd2,
           TRANS_S = 3'd3,
		   HALT_S = 3'd4,
		   EMPTY1_S = 3'd5,
		   OUTPUT_S = 3'd6;

assign ready_out = lookup_state!=HALT_S;

always @(posedge clk or negedge rst_n) begin

    if (~rst_n) begin
        phv_reg <= 0;
        action_valid <= 1'b0;
        lookup_state <= IDLE_S;
        phv_out <= 0;
		// ready_out <= 1'b1;

		act_vlan_out <= 0;
		act_vlan_out_valid <= 0;

		if_match_d1 <= 0;
    end

    else begin
        case(lookup_state)
            IDLE_S: begin
                if (phv_valid == 1'b1) begin
					// ready_out <= 1'b0;
                    phv_reg <= phv_in;
					act_vlan_out <= vlan_id;
					if_match_d1 <= if_match;

					if (act_vlan_ready) begin
						act_vlan_out_valid <= 1;
					end

					lookup_state <= WAIT1_S;
                end
                else begin
					// ready_out <= 1'b1;
                    lookup_state <= IDLE_S;
					action_valid <= 1'b0;
					act_vlan_out_valid <= 0;
					if_match_d1 <= 0;
                end
            end

			WAIT1_S: begin
				if (ready_in) begin
					act_vlan_out_valid <= 0;
					action_valid <= 1'b1;
					// ready_out <= 1'b1;
					phv_out <= phv_reg;
					lookup_state <= IDLE_S;
				end
				else begin
					lookup_state <= HALT_S;
				end
			end
			HALT_S: begin
				if (ready_in) begin
					act_vlan_out_valid <= 0;
					action_valid <= 1'b1;
					// ready_out <= 1'b1;
					phv_out <= phv_reg;
					lookup_state <= IDLE_S;
				end
			end
        endcase
    end
end

//======================================================================



//======================================================================
/****control path*****/
wire [7:0]          mod_id; //module ID
//4'b0 for tcam entry;
//NOTE: we don't need tcam entry mask
//4'b2 for action table entry;
wire [3:0]          resv; //recog between tcam and action
wire [15:0]         control_flag; //dst udp port num


reg  [7:0]          c_index_cam; //table index(addr)

reg                 c_wr_en_cam; //enable table write(wena)

reg  [7:0]          c_index_act;
reg                 c_wr_en_act;
reg  [ACT_LEN-1:0]  act_entry_tmp;             
reg                 continous_flag;
reg [204:0]         cam_entry_reg;


reg [2:0]           c_state;

/****for 256b exclusively*****/
reg                                 c_m_axis_tvalid_r;
reg                                 c_m_axis_tlast_r;


localparam IDLE_C = 0,
           PARSE_C = 1,
           CAM_TMP_ENTRY = 2,
           SU_CAM_TMP_ENTRY = 3,
           ACT_TMP_ENTRY_WAIT = 4,
           ACT_TMP_ENTRY_WAIT_2 = 5,
           ACT_TMP_ENTRY = 6,
		   FLUSH_REST_C = 7;

generate 
    if(C_S_AXIS_DATA_WIDTH == 512) begin
        assign mod_id = c_s_axis_tdata[368+:8];
        assign resv   = c_s_axis_tdata[376+:4];
        assign control_flag = c_s_axis_tdata[335:320];
        //LE to BE switching
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
											c_s_axis_tdata[248+:8],
                                            c_s_axis_tdata[256+:8],
                                            c_s_axis_tdata[264+:8],
                                            c_s_axis_tdata[272+:8],
                                            c_s_axis_tdata[280+:8],
                                            c_s_axis_tdata[288+:8],
                                            c_s_axis_tdata[296+:8],
                                            c_s_axis_tdata[304+:8],
                                            c_s_axis_tdata[312+:8],
                                            c_s_axis_tdata[320+:8],
                                            c_s_axis_tdata[328+:8],
                                            c_s_axis_tdata[336+:8],
                                            c_s_axis_tdata[344+:8],
                                            c_s_axis_tdata[352+:8],
                                            c_s_axis_tdata[360+:8],
                                            c_s_axis_tdata[368+:8],
                                            c_s_axis_tdata[376+:8],
                                            c_s_axis_tdata[384+:8],
                                            c_s_axis_tdata[392+:8],
                                            c_s_axis_tdata[400+:8],
                                            c_s_axis_tdata[408+:8],
                                            c_s_axis_tdata[416+:8],
                                            c_s_axis_tdata[424+:8],
                                            c_s_axis_tdata[432+:8],
                                            c_s_axis_tdata[440+:8],
                                            c_s_axis_tdata[448+:8],
                                            c_s_axis_tdata[456+:8],
                                            c_s_axis_tdata[464+:8],
                                            c_s_axis_tdata[472+:8],
                                            c_s_axis_tdata[480+:8],
                                            c_s_axis_tdata[488+:8],
                                            c_s_axis_tdata[496+:8],
                                            c_s_axis_tdata[504+:8]
                                            };
        always @(posedge clk or negedge rst_n) begin
            if(~rst_n) begin
                c_index_cam <= 0;
                c_wr_en_cam <= 0;

                c_index_act <= 0;
                c_wr_en_act <= 0;

                act_entry_tmp <= 0;
                cam_entry_reg <= 0;
                continous_flag <= 0;

                c_m_axis_tdata <= 0;
                c_m_axis_tuser <= 0;
                c_m_axis_tkeep <= 0;
                c_m_axis_tvalid <= 0;
                c_m_axis_tlast <= 0;

                c_state <= IDLE_C;

            end

            else begin
                case(c_state)
                    IDLE_C: begin
                        if(c_s_axis_tvalid) begin
                            if(mod_id[7:3] == STAGE_ID && mod_id[2:0] == LOOKUP_ID 
									&& control_flag == 16'hf2f1
									&& resv != 4'b0) begin
                                //ACTION entry
                                continous_flag <= 1'b0;
                                c_index_act <= c_s_axis_tdata[384+:8];
                                c_state <= ACT_TMP_ENTRY_WAIT;
                            end
                            //not for lookup
                            else begin
                                c_index_cam <= 0;
                                c_wr_en_cam <= 0;

                                c_index_act <= 0;
                                c_wr_en_act <= 0;

                                act_entry_tmp <= 0;
                                continous_flag <= 0;

                                c_m_axis_tdata <= c_s_axis_tdata;
                                c_m_axis_tuser <= c_s_axis_tuser;
                                c_m_axis_tkeep <= c_s_axis_tkeep;
                                c_m_axis_tvalid <= c_s_axis_tvalid;
                                c_m_axis_tlast <= c_s_axis_tlast;

                                c_state <= IDLE_C;
                            end
                        end
                        //stay halt
                        else begin
                            c_index_cam <= 0;
                            c_wr_en_cam <= 0;

                            c_index_act <= 0;
                            c_wr_en_act <= 0;

                            act_entry_tmp <= 0;
                            continous_flag <= 0;

                            c_m_axis_tdata <= 0;
                            c_m_axis_tuser <= 0;
                            c_m_axis_tkeep <= 0;
                            c_m_axis_tvalid <= 0;
                            c_m_axis_tlast <= 0;

                            c_state <= IDLE_C;
                        end
                    end

                    ACT_TMP_ENTRY_WAIT: begin
                        c_m_axis_tvalid_r <= 1'b0;
                        c_m_axis_tlast_r <= 1'b0;
                        //flush the whole table
                        if(c_s_axis_tvalid && ~c_s_axis_tlast) begin
                            if (continous_flag)   c_index_act <= c_index_act + 8'b1;
                            else                  c_index_act <= c_index_act;
                            act_entry_tmp[624 -: 512] <= c_s_axis_tdata_swapped;
                            c_wr_en_act <= 1'b0;
                            c_state <= ACT_TMP_ENTRY;
                        end
                        else if(c_s_axis_tvalid && c_s_axis_tlast) begin
                            c_wr_en_act <= 1'b0;
                            c_state <= IDLE_C;
                        end
                        else begin
                            c_wr_en_act <= 1'b0;
                            c_state <= c_state;
                        end
                    end

                    ACT_TMP_ENTRY: begin
                        if(c_s_axis_tvalid) begin
                            act_entry_tmp[112:0] <= c_s_axis_tdata_swapped[511-:113];
                            c_wr_en_act <= 1'b1;
                            if(c_s_axis_tlast)   c_state <= IDLE_C;
                            else begin
                                continous_flag <= 1'b1;
                                c_state <= ACT_TMP_ENTRY_WAIT;
                            end
                        end
                        else begin
                            c_state <= c_state;
                            act_entry_tmp <= act_entry_tmp;
                            c_wr_en_act <= c_wr_en_act;
                        end
                    end

                endcase
            end
        end

        //ram for action
        // blk_mem_gen_1 #(
        // 	.C_INIT_FILE_NAME	("./llup.mif"),
        // 	.C_LOAD_INIT_FILE	(1)
        // )
        blk_mem_gen_1
        act_ram_625w_16d
        (
            .addra(c_index_act[3:0]),
            .clka(clk),
            .dina(act_entry_tmp),
            .ena(1'b1),
            .wea(c_wr_en_act),

            .addrb(match_addr[3:0]),
            .clkb(clk),
            .doutb(action_wire),
            .enb(1'b1)
        );

    end
    //NOTE: data width is 256b
    else begin
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
        assign resv = c_s_axis_tdata[120+:4];
        assign control_flag = c_s_axis_tdata[64+:16];
		// 
		reg [2:0] c_state_next;
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

		reg [7:0]							c_index_cam_next, c_index_act_next;
		reg									c_wr_en_cam_next, c_wr_en_act_next;
		reg [204:0]							c_wr_cam_data, c_wr_cam_data_next;
		reg [ACT_LEN-1:0]					c_wr_act_data, c_wr_act_data_next;

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

			c_index_cam_next = c_index_cam;
			c_index_act_next = c_index_act;
			c_wr_en_cam_next = 0;
			c_wr_en_act_next = 0;
			c_wr_cam_data_next = c_wr_cam_data;
			c_wr_act_data_next = c_wr_act_data;

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
					if (mod_id[7:3] == STAGE_ID && mod_id[2:0] == LOOKUP_ID && 
						control_flag == 16'hf2f1 && c_s_axis_tvalid && resv!=4'b0) begin
						// should not emit segment
						c_index_act_next = c_s_axis_tdata[128+:8];
						c_state_next = ACT_TMP_ENTRY_WAIT;
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
				ACT_TMP_ENTRY_WAIT: begin
					if (c_s_axis_tvalid) begin
						c_wr_act_data_next[369+:256] = c_s_axis_tdata_swapped;
						c_state_next = ACT_TMP_ENTRY_WAIT_2;
					end
				end
				ACT_TMP_ENTRY_WAIT_2: begin
					if (c_s_axis_tvalid) begin
						c_wr_act_data_next[113+:256] = c_s_axis_tdata_swapped;
						c_state_next = ACT_TMP_ENTRY;
					end
				end
				ACT_TMP_ENTRY: begin
					if (c_s_axis_tvalid) begin
						c_wr_en_act_next = 1; // next clk to write
						c_wr_act_data_next[0+:113] = c_s_axis_tdata_swapped[143+:113];
						c_state_next = IDLE_C;
					end
				end
				FLUSH_REST_C: begin
					c_wr_en_cam_next = 0;
					c_wr_en_act_next = 0;
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
				c_index_cam <= 0;
				c_index_act <= 0;
				c_wr_en_cam <= 0;
				c_wr_en_act <= 0;
				c_wr_cam_data <= 0;
				c_wr_act_data <= 0;
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
				c_index_cam <= c_index_cam_next;
				c_index_act <= c_index_act_next;
				c_wr_en_cam <= c_wr_en_cam_next;
				c_wr_en_act <= c_wr_en_act_next;
				c_wr_cam_data <= c_wr_cam_data_next;
				c_wr_act_data <= c_wr_act_data_next;
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

        //ram for action
        // blk_mem_gen_1 #(
        // 	.C_INIT_FILE_NAME	("./llup.mif"),
        // 	.C_LOAD_INIT_FILE	(1)
        // )
        blk_mem_gen_1
        act_ram_625w_16d
        (
            .addra(c_index_act[3:0]),
            .clka(clk),
            .dina(c_wr_act_data),
            .ena(1'b1), // always set to 1
            .wea(c_wr_en_act),

            .addrb(match_addr),
            .clkb(clk),
            .doutb(action_wire),
            .enb(1'b1) // always set to 1
        );
    end

endgenerate

endmodule
