def to_bit_string(cons_1, cons_2, cons_3, sel_1, sel_2, sel_3, sel_4, sel_5, sel_6, rel_opcode):
    out_str = str('{0:06b}'.format(cons_1)) + str('{0:06b}'.format(cons_2)) + str('{0:06b}'.format(cons_3)) + two_mux_dic[sel_1] + three_mux_dic[sel_2] + two_mux_dic[sel_3] + three_mux_dic[sel_4] + two_mux_dic[sel_5] + three_mux_dic[sel_6] + rel_dic[rel_opcode] + '000000000'
    return out_str
    


two_mux_dic = {'state_1': '0', '0': '1'}
three_mux_dic = {'pkt_1': '00', 'pkt_2': '01', 'cons': '10'}
rel_dic = {'!=': '00', '<': '01', '>': '10', '==': '11'}

cons_1 = 0 
cons_2 = 0
cons_3 = 0
sel_1 = 'state_1'
sel_3 = 'state_1'
sel_5 = 'state_1'
sel_2 = 'pkt_1'
sel_4 = 'pkt_1'
sel_6 = 'pkt_1'
rel_opcode = '=='

assert to_bit_string(0, 1, 0, 'state_1', 'cons', '0', 'cons', 'state_1', 'cons', '==') == '00000000000100000001011001011000000000', "marple_new test failed"
print(to_bit_string(cons_1, cons_2, cons_3, sel_1, sel_2, sel_3, sel_4, sel_5, sel_6, rel_opcode))
