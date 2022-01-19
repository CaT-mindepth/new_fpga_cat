#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#



#set_property port_width 104 [get_debug_ports u_ila_1_0/probe2]
#connect_debug_port u_ila_1_0/probe2 [get_nets [list {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[0]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[1]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[2]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[3]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[4]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[5]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[6]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[7]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[8]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[9]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[10]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[11]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[12]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[13]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[14]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[15]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[16]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[17]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[18]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[19]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[20]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[21]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[22]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[23]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[24]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[25]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[26]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[27]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[28]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[29]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[30]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[31]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[32]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[33]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[34]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[35]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[36]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[37]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[38]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[39]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[40]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[41]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[42]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[43]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[44]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[45]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[46]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[47]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[48]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[49]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[50]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[51]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[52]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[53]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[54]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[55]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[56]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[57]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[58]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[59]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[60]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[61]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[62]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[63]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[64]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[65]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[66]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[67]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[68]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[69]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[70]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[71]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[72]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[73]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[74]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[75]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[76]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[77]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[78]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[79]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[80]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[81]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[82]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[83]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[84]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[85]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[86]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[87]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[88]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[89]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[90]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[91]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[92]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[93]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[94]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[95]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[96]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[97]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[98]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[99]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[100]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[101]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[102]} {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[103]}]]
#create_debug_port u_ila_1_0 probe
#connect_debug_port u_ila_1_0/probe2 [get_nets [list {nf_datapath_0/openstate156_i/openstate_core_i/HT1/value[*]}]]






#create_debug_core u_ila_0 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
#set_property C_DATA_DEPTH 4096 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list axi_clocking_i/clk_wiz_i/inst/clk_out2]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#set_property port_width 32 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list {nf_datapath_0/FB156_i/FB_core_i/count_frames[0]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[1]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[2]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[3]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[4]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[5]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[6]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[7]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[8]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[9]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[10]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[11]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[12]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[13]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[14]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[15]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[16]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[17]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[18]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[19]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[20]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[21]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[22]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[23]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[24]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[25]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[26]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[27]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[28]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[29]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[30]} {nf_datapath_0/FB156_i/FB_core_i/count_frames[31]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
#set_property port_width 32 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list {nf_datapath_0/FB156_i/FB_core_i/action[0]} {nf_datapath_0/FB156_i/FB_core_i/action[1]} {nf_datapath_0/FB156_i/FB_core_i/action[2]} {nf_datapath_0/FB156_i/FB_core_i/action[3]} {nf_datapath_0/FB156_i/FB_core_i/action[4]} {nf_datapath_0/FB156_i/FB_core_i/action[5]} {nf_datapath_0/FB156_i/FB_core_i/action[6]} {nf_datapath_0/FB156_i/FB_core_i/action[7]} {nf_datapath_0/FB156_i/FB_core_i/action[8]} {nf_datapath_0/FB156_i/FB_core_i/action[9]} {nf_datapath_0/FB156_i/FB_core_i/action[10]} {nf_datapath_0/FB156_i/FB_core_i/action[11]} {nf_datapath_0/FB156_i/FB_core_i/action[12]} {nf_datapath_0/FB156_i/FB_core_i/action[13]} {nf_datapath_0/FB156_i/FB_core_i/action[14]} {nf_datapath_0/FB156_i/FB_core_i/action[15]} {nf_datapath_0/FB156_i/FB_core_i/action[16]} {nf_datapath_0/FB156_i/FB_core_i/action[17]} {nf_datapath_0/FB156_i/FB_core_i/action[18]} {nf_datapath_0/FB156_i/FB_core_i/action[19]} {nf_datapath_0/FB156_i/FB_core_i/action[20]} {nf_datapath_0/FB156_i/FB_core_i/action[21]} {nf_datapath_0/FB156_i/FB_core_i/action[22]} {nf_datapath_0/FB156_i/FB_core_i/action[23]} {nf_datapath_0/FB156_i/FB_core_i/action[24]} {nf_datapath_0/FB156_i/FB_core_i/action[25]} {nf_datapath_0/FB156_i/FB_core_i/action[26]} {nf_datapath_0/FB156_i/FB_core_i/action[27]} {nf_datapath_0/FB156_i/FB_core_i/action[28]} {nf_datapath_0/FB156_i/FB_core_i/action[29]} {nf_datapath_0/FB156_i/FB_core_i/action[30]} {nf_datapath_0/FB156_i/FB_core_i/action[31]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
#set_property port_width 128 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list {nf_datapath_0/FB156_i/FB_core_i/full_input_1[0]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[1]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[2]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[3]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[4]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[5]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[6]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[7]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[8]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[9]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[10]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[11]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[12]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[13]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[14]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[15]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[16]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[17]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[18]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[19]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[20]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[21]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[22]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[23]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[24]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[25]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[26]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[27]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[28]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[29]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[30]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[31]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[32]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[33]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[34]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[35]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[36]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[37]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[38]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[39]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[40]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[41]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[42]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[43]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[44]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[45]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[46]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[47]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[48]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[49]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[50]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[51]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[52]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[53]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[54]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[55]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[56]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[57]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[58]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[59]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[60]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[61]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[62]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[63]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[64]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[65]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[66]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[67]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[68]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[69]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[70]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[71]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[72]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[73]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[74]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[75]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[76]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[77]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[78]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[79]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[80]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[81]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[82]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[83]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[84]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[85]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[86]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[87]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[88]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[89]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[90]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[91]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[92]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[93]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[94]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[95]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[96]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[97]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[98]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[99]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[100]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[101]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[102]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[103]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[104]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[105]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[106]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[107]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[108]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[109]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[110]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[111]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[112]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[113]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[114]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[115]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[116]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[117]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[118]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[119]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[120]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[121]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[122]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[123]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[124]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[125]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[126]} {nf_datapath_0/FB156_i/FB_core_i/full_input_1[127]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
#set_property port_width 24 [get_debug_ports u_ila_0/probe3]
#connect_debug_port u_ila_0/probe3 [get_nets [list {nf_datapath_0/FB156_i/FB_core_i/full_input_2[0]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[1]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[2]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[3]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[4]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[5]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[6]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[7]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[8]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[9]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[10]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[11]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[12]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[13]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[14]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[15]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[16]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[17]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[18]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[19]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[20]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[21]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[22]} {nf_datapath_0/FB156_i/FB_core_i/full_input_2[23]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
#set_property port_width 2 [get_debug_ports u_ila_0/probe4]
#connect_debug_port u_ila_0/probe4 [get_nets [list {nf_datapath_0/FB156_i/FB_core_i/curr_state[0]} {nf_datapath_0/FB156_i/FB_core_i/curr_state[1]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
#set_property port_width 12 [get_debug_ports u_ila_0/probe5]
#connect_debug_port u_ila_0/probe5 [get_nets [list {nf_datapath_0/FB156_i/FB_core_i/startd[0]} {nf_datapath_0/FB156_i/FB_core_i/startd[1]} {nf_datapath_0/FB156_i/FB_core_i/startd[2]} {nf_datapath_0/FB156_i/FB_core_i/startd[3]} {nf_datapath_0/FB156_i/FB_core_i/startd[4]} {nf_datapath_0/FB156_i/FB_core_i/startd[5]} {nf_datapath_0/FB156_i/FB_core_i/startd[6]} {nf_datapath_0/FB156_i/FB_core_i/startd[7]} {nf_datapath_0/FB156_i/FB_core_i/startd[8]} {nf_datapath_0/FB156_i/FB_core_i/startd[9]} {nf_datapath_0/FB156_i/FB_core_i/startd[10]} {nf_datapath_0/FB156_i/FB_core_i/startd[11]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
#set_property port_width 1 [get_debug_ports u_ila_0/probe6]
#connect_debug_port u_ila_0/probe6 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/insert_action]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
#set_property port_width 1 [get_debug_ports u_ila_0/probe7]
#connect_debug_port u_ila_0/probe7 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/int_S0_AXIS_TREADY]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
#set_property port_width 1 [get_debug_ports u_ila_0/probe8]
#connect_debug_port u_ila_0/probe8 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/match_ht]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
#set_property port_width 1 [get_debug_ports u_ila_0/probe9]
#connect_debug_port u_ila_0/probe9 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/S0_AXIS_TVALID]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
#set_property port_width 1 [get_debug_ports u_ila_0/probe10]
#connect_debug_port u_ila_0/probe10 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/start]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
#set_property port_width 1 [get_debug_ports u_ila_0/probe11]
#connect_debug_port u_ila_0/probe11 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/step]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
#set_property port_width 1 [get_debug_ports u_ila_0/probe12]
#connect_debug_port u_ila_0/probe12 [get_nets [list nf_datapath_0/FB156_i/FB_core_i/update_action]]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets clk_1XX]












