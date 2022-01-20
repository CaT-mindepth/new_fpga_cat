#include <core.p4>
#include <v1model.p4>

header packets_t {
    bit<32> pkt_0;
    bit<32> pkt_1;
}

struct headers {
    packets_t  pkts; 
}

struct metadata {
}

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {
    state start {
        packet.extract(hdr.pkts);
        transition accept;
    }
    
}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

control ingress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action action_1_0 () {
        hdr.pkts.pkt_1 = 1;
    }
    table table_1 {
        key = {
            hdr.pkts.pkt_0 : exact;
        }
        actions = {
            action_1_0;
        }
        const entries = {
            (5) : action_1_0();
        }
    }

    apply {
        table_1.apply();
    }
}

control egress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {  }
}

control MyDeparser(packet_out packet, in headers hdr) {
    apply { }
}

V1Switch(
MyParser(),
MyVerifyChecksum(),
ingress(),
egress(),
MyComputeChecksum(),
MyDeparser()
) main;
