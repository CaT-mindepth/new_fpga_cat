#!/usr/bin/env python
"""

Copyright (c) 2015-2018 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

"""

from myhdl import *
import os

import eth_ep
import arp_ep
import udp_ep
import rgmii_ep

module = 'fpga_core'
testbench = 'test_%s' % module

srcs = []

srcs.append("../rtl/%s.v" % module)
srcs.append("../rtl/hex_display.v")
srcs.append("../lib/eth/rtl/iddr.v")
srcs.append("../lib/eth/rtl/oddr.v")
srcs.append("../lib/eth/rtl/ssio_ddr_in.v")
srcs.append("../lib/eth/rtl/ssio_ddr_out.v")
srcs.append("../lib/eth/rtl/rgmii_phy_if.v")
srcs.append("../lib/eth/rtl/eth_mac_1g_rgmii_fifo.v")
srcs.append("../lib/eth/rtl/eth_mac_1g_rgmii.v")
srcs.append("../lib/eth/rtl/eth_mac_1g.v")
srcs.append("../lib/eth/rtl/axis_gmii_rx.v")
srcs.append("../lib/eth/rtl/axis_gmii_tx.v")
srcs.append("../lib/eth/rtl/lfsr.v")
srcs.append("../lib/eth/rtl/eth_axis_rx.v")
srcs.append("../lib/eth/rtl/eth_axis_tx.v")
srcs.append("../lib/eth/rtl/udp_complete.v")
srcs.append("../lib/eth/rtl/udp_checksum_gen.v")
srcs.append("../lib/eth/rtl/udp.v")
srcs.append("../lib/eth/rtl/udp_ip_rx.v")
srcs.append("../lib/eth/rtl/udp_ip_tx.v")
srcs.append("../lib/eth/rtl/ip_complete.v")
srcs.append("../lib/eth/rtl/ip.v")
srcs.append("../lib/eth/rtl/ip_eth_rx.v")
srcs.append("../lib/eth/rtl/ip_eth_tx.v")
srcs.append("../lib/eth/rtl/ip_arb_mux.v")
srcs.append("../lib/eth/rtl/ip_mux.v")
srcs.append("../lib/eth/rtl/arp.v")
srcs.append("../lib/eth/rtl/arp_cache.v")
srcs.append("../lib/eth/rtl/arp_eth_rx.v")
srcs.append("../lib/eth/rtl/arp_eth_tx.v")
srcs.append("../lib/eth/rtl/eth_arb_mux.v")
srcs.append("../lib/eth/rtl/eth_mux.v")
srcs.append("../lib/eth/lib/axis/rtl/arbiter.v")
srcs.append("../lib/eth/lib/axis/rtl/priority_encoder.v")
srcs.append("../lib/eth/lib/axis/rtl/axis_fifo.v")
srcs.append("../lib/eth/lib/axis/rtl/axis_async_fifo.v")
srcs.append("../lib/eth/lib/axis/rtl/axis_async_fifo_adapter.v")
srcs.append("%s.v" % testbench)

src = ' '.join(srcs)

build_cmd = "iverilog -o %s.vvp %s" % (testbench, src)

def bench():

    # Parameters
    TARGET = "SIM"

    # Inputs
    clk = Signal(bool(0))
    clk90 = Signal(bool(0))
    rst = Signal(bool(0))
    current_test = Signal(intbv(0)[8:])

    btn = Signal(intbv(0)[4:])
    sw = Signal(intbv(0)[17:])
    phy0_rx_clk = Signal(bool(0))
    phy0_rxd = Signal(intbv(0)[4:])
    phy0_rx_ctl = Signal(bool(0))
    phy0_int_n = Signal(bool(1))
    phy1_rx_clk = Signal(bool(0))
    phy1_rxd = Signal(intbv(0)[4:])
    phy1_rx_ctl = Signal(bool(0))
    phy1_int_n = Signal(bool(1))

    # Outputs
    ledg = Signal(intbv(0)[8:])
    ledr = Signal(intbv(0)[18:])
    hex0 = Signal(intbv(0)[7:])
    hex1 = Signal(intbv(0)[7:])
    hex2 = Signal(intbv(0)[7:])
    hex3 = Signal(intbv(0)[7:])
    hex4 = Signal(intbv(0)[7:])
    hex5 = Signal(intbv(0)[7:])
    hex6 = Signal(intbv(0)[7:])
    hex7 = Signal(intbv(0)[7:])
    gpio = Signal(intbv(0)[36:])
    phy0_tx_clk = Signal(bool(0))
    phy0_txd = Signal(intbv(0)[4:])
    phy0_tx_ctl = Signal(bool(0))
    phy0_reset_n = Signal(bool(0))
    phy1_tx_clk = Signal(bool(0))
    phy1_txd = Signal(intbv(0)[4:])
    phy1_tx_ctl = Signal(bool(0))
    phy1_reset_n = Signal(bool(0))

    # sources and sinks
    mii_select_0 = Signal(bool(0))

    rgmii_source_0 = rgmii_ep.RGMIISource()

    rgmii_source_0_logic = rgmii_source_0.create_logic(
        phy0_rx_clk,
        rst,
        txd=phy0_rxd,
        tx_ctl=phy0_rx_ctl,
        mii_select=mii_select_0,
        name='rgmii_source_0'
    )

    rgmii_sink_0 = rgmii_ep.RGMIISink()

    rgmii_sink_0_logic = rgmii_sink_0.create_logic(
        phy0_tx_clk,
        rst,
        rxd=phy0_txd,
        rx_ctl=phy0_tx_ctl,
        mii_select=mii_select_0,
        name='rgmii_sink_0'
    )

    mii_select_1 = Signal(bool(0))

    rgmii_source_1 = rgmii_ep.RGMIISource()

    rgmii_source_1_logic = rgmii_source_1.create_logic(
        phy1_rx_clk,
        rst,
        txd=phy1_rxd,
        tx_ctl=phy1_rx_ctl,
        mii_select=mii_select_1,
        name='rgmii_source_1'
    )

    rgmii_sink_1 = rgmii_ep.RGMIISink()

    rgmii_sink_1_logic = rgmii_sink_1.create_logic(
        phy1_tx_clk,
        rst,
        rxd=phy1_txd,
        rx_ctl=phy1_tx_ctl,
        mii_select=mii_select_1,
        name='rgmii_sink_1'
    )

    # DUT
    if os.system(build_cmd):
        raise Exception("Error running build command")

    dut = Cosimulation(
        "vvp -m myhdl %s.vvp -lxt2" % testbench,
        clk=clk,
        clk90=clk90,
        rst=rst,
        current_test=current_test,

        btn=btn,
        sw=sw,
        ledg=ledg,
        ledr=ledr,
        hex0=hex0,
        hex1=hex1,
        hex2=hex2,
        hex3=hex3,
        hex4=hex4,
        hex5=hex5,
        hex6=hex6,
        hex7=hex7,
        gpio=gpio,

        phy0_rx_clk=phy0_rx_clk,
        phy0_rxd=phy0_rxd,
        phy0_rx_ctl=phy0_rx_ctl,
        phy0_tx_clk=phy0_tx_clk,
        phy0_txd=phy0_txd,
        phy0_tx_ctl=phy0_tx_ctl,
        phy0_reset_n=phy0_reset_n,
        phy0_int_n=phy0_int_n,

        phy1_rx_clk=phy1_rx_clk,
        phy1_rxd=phy1_rxd,
        phy1_rx_ctl=phy1_rx_ctl,
        phy1_tx_clk=phy1_tx_clk,
        phy1_txd=phy1_txd,
        phy1_tx_ctl=phy1_tx_ctl,
        phy1_reset_n=phy1_reset_n,
        phy1_int_n=phy1_int_n
    )

    @always(delay(4))
    def clkgen():
        clk.next = not clk

    @instance
    def clkgen2():
        yield delay(4+2)
        while True:
            clk90.next = not clk90
            yield delay(4)

    rx_clk_hp = Signal(int(4))

    @instance
    def rx_clk_gen():
        while True:
            yield delay(int(rx_clk_hp))
            phy0_rx_clk.next = not phy0_rx_clk

    @instance
    def check():
        yield delay(100)
        yield clk.posedge
        rst.next = 1
        yield clk.posedge
        rst.next = 0
        yield clk.posedge
        yield delay(100)
        yield clk.posedge

        # testbench stimulus

        yield clk.posedge
        print("test 1: test UDP RX packet")
        current_test.next = 1

        test_frame = udp_ep.UDPFrame()
        test_frame.eth_dest_mac = 0x020000000000
        test_frame.eth_src_mac = 0xDAD1D2D3D4D5
        test_frame.eth_type = 0x0800
        test_frame.ip_version = 4
        test_frame.ip_ihl = 5
        test_frame.ip_dscp = 0
        test_frame.ip_ecn = 0
        test_frame.ip_length = None
        test_frame.ip_identification = 0
        test_frame.ip_flags = 2
        test_frame.ip_fragment_offset = 0
        test_frame.ip_ttl = 64
        test_frame.ip_protocol = 0x11
        test_frame.ip_header_checksum = None
        test_frame.ip_source_ip = 0xc0a80181
        test_frame.ip_dest_ip = 0xc0a80180
        test_frame.udp_source_port = 5678
        test_frame.udp_dest_port = 1234
        test_frame.payload = bytearray(range(32))
        test_frame.build()

        rgmii_source_0.send(b'\x55\x55\x55\x55\x55\x55\x55\xD5'+test_frame.build_eth().build_axis_fcs().data)

        # wait for ARP request packet
        while rgmii_sink_0.empty():
            yield clk.posedge

        rx_frame = rgmii_sink_0.recv()
        check_eth_frame = eth_ep.EthFrame()
        check_eth_frame.parse_axis_fcs(rx_frame.data[8:])
        check_frame = arp_ep.ARPFrame()
        check_frame.parse_eth(check_eth_frame)

        print(check_frame)

        assert check_frame.eth_dest_mac == 0xFFFFFFFFFFFF
        assert check_frame.eth_src_mac == 0x020000000000
        assert check_frame.eth_type == 0x0806
        assert check_frame.arp_htype == 0x0001
        assert check_frame.arp_ptype == 0x0800
        assert check_frame.arp_hlen == 6
        assert check_frame.arp_plen == 4
        assert check_frame.arp_oper == 1
        assert check_frame.arp_sha == 0x020000000000
        assert check_frame.arp_spa == 0xc0a80180
        assert check_frame.arp_tha == 0x000000000000
        assert check_frame.arp_tpa == 0xc0a80181

        # generate response
        arp_frame = arp_ep.ARPFrame()
        arp_frame.eth_dest_mac = 0x020000000000
        arp_frame.eth_src_mac = 0xDAD1D2D3D4D5
        arp_frame.eth_type = 0x0806
        arp_frame.arp_htype = 0x0001
        arp_frame.arp_ptype = 0x0800
        arp_frame.arp_hlen = 6
        arp_frame.arp_plen = 4
        arp_frame.arp_oper = 2
        arp_frame.arp_sha = 0xDAD1D2D3D4D5
        arp_frame.arp_spa = 0xc0a80181
        arp_frame.arp_tha = 0x020000000000
        arp_frame.arp_tpa = 0xc0a80180

        rgmii_source_0.send(b'\x55\x55\x55\x55\x55\x55\x55\xD5'+arp_frame.build_eth().build_axis_fcs().data)

        while rgmii_sink_0.empty():
            yield clk.posedge

        rx_frame = rgmii_sink_0.recv()
        check_eth_frame = eth_ep.EthFrame()
        check_eth_frame.parse_axis_fcs(rx_frame.data[8:])
        check_frame = udp_ep.UDPFrame()
        check_frame.parse_eth(check_eth_frame)

        print(check_frame)

        assert check_frame.eth_dest_mac == 0xDAD1D2D3D4D5
        assert check_frame.eth_src_mac == 0x020000000000
        assert check_frame.eth_type == 0x0800
        assert check_frame.ip_version == 4
        assert check_frame.ip_ihl == 5
        assert check_frame.ip_dscp == 0
        assert check_frame.ip_ecn == 0
        assert check_frame.ip_identification == 0
        assert check_frame.ip_flags == 2
        assert check_frame.ip_fragment_offset == 0
        assert check_frame.ip_ttl == 64
        assert check_frame.ip_protocol == 0x11
        assert check_frame.ip_source_ip == 0xc0a80180
        assert check_frame.ip_dest_ip == 0xc0a80181
        assert check_frame.udp_source_port == 1234
        assert check_frame.udp_dest_port == 5678
        assert check_frame.payload.data == bytearray(range(32))

        assert rgmii_source_0.empty()
        assert rgmii_sink_0.empty()

        yield delay(100)

        raise StopSimulation

    return instances()

def test_bench():
    sim = Simulation(bench())
    sim.run()

if __name__ == '__main__':
    print("Running test...")
    test_bench()
