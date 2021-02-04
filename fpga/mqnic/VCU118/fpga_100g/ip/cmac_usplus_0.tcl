
create_ip -name cmac_usplus -vendor xilinx.com -library ip -module_name cmac_usplus_0

set_property -dict [list \
    CONFIG.CMAC_CAUI4_MODE {1} \
    CONFIG.NUM_LANES {4x25} \
    CONFIG.GT_REF_CLK_FREQ {156.25} \
    CONFIG.USER_INTERFACE {AXIS} \
    CONFIG.GT_DRP_CLK {125} \
    CONFIG.TX_FLOW_CONTROL {0} \
    CONFIG.RX_FLOW_CONTROL {0} \
    CONFIG.INCLUDE_RS_FEC {1} \
    CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y7} \
    CONFIG.GT_GROUP_SELECT {X1Y48~X1Y51} \
    CONFIG.LANE1_GT_LOC {X1Y48} \
    CONFIG.LANE2_GT_LOC {X1Y49} \
    CONFIG.LANE3_GT_LOC {X1Y50} \
    CONFIG.LANE4_GT_LOC {X1Y51} \
    CONFIG.ENABLE_PIPELINE_REG {1}
] [get_ips cmac_usplus_0]
