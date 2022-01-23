`timescale 1ns / 1ps


module sub_deparser #(
	parameter C_PKT_VEC_WIDTH = 32*64+256,
	parameter C_PARSE_ACT_LEN = 9						// only 6 bits are used here
)
(
	input										clk,
	input										aresetn,

	input										parse_act_valid,
	input [C_PARSE_ACT_LEN-1:0]					parse_act,
	input [C_PKT_VEC_WIDTH-1:0]					phv_in,

	output reg									val_out_valid,
	output reg [47:0]							val_out,
	output reg [1:0]							val_out_type
);

// FIXME: 2B and 6B are not used here
localparam PHV_2B_START_POS = 0+256;
localparam PHV_4B_START_POS = 0+256;
localparam PHV_6B_START_POS = 0+256;


reg			val_out_valid_nxt;
reg [47:0]	val_out_nxt;
reg [1:0]	val_out_type_nxt;

integer i;

always @(*) begin
	val_out_valid_nxt = 0;
	val_out_nxt = val_out;
	val_out_type_nxt = val_out_type;

	if (parse_act_valid) begin
		val_out_valid_nxt = 1;

		case({parse_act[8:7], parse_act[0]})
			// 2B
			3'b011: begin
				val_out_type_nxt = 2'b01;
				case(parse_act[6:1])
					6'd0: val_out_nxt[15:0] = 0;
					6'd1: val_out_nxt[15:0] = 0;
					6'd2: val_out_nxt[15:0] = 0;
					6'd3: val_out_nxt[15:0] = 0;
					6'd4: val_out_nxt[15:0] = 0;
					6'd5: val_out_nxt[15:0] = 0;
					6'd6: val_out_nxt[15:0] = 0;
					6'd7: val_out_nxt[15:0] = 0;
					6'd8: val_out_nxt[15:0] = 0;
					6'd9: val_out_nxt[15:0] = 0;
					6'd10: val_out_nxt[15:0] = 0;
					6'd11: val_out_nxt[15:0] = 0;
					6'd12: val_out_nxt[15:0] = 0;
					6'd13: val_out_nxt[15:0] = 0;
					6'd14: val_out_nxt[15:0] = 0;
					6'd15: val_out_nxt[15:0] = 0;
					6'd16: val_out_nxt[15:0] = 0;
					6'd17: val_out_nxt[15:0] = 0;
					6'd18: val_out_nxt[15:0] = 0;
					6'd19: val_out_nxt[15:0] = 0;
					6'd20: val_out_nxt[15:0] = 0;
					6'd21: val_out_nxt[15:0] = 0;
					6'd22: val_out_nxt[15:0] = 0;
					6'd23: val_out_nxt[15:0] = 0;
					6'd24: val_out_nxt[15:0] = 0;
					6'd25: val_out_nxt[15:0] = 0;
					6'd26: val_out_nxt[15:0] = 0;
					6'd27: val_out_nxt[15:0] = 0;
					6'd28: val_out_nxt[15:0] = 0;
					6'd29: val_out_nxt[15:0] = 0;
					6'd30: val_out_nxt[15:0] = 0;
					6'd31: val_out_nxt[15:0] = 0;
					6'd32: val_out_nxt[15:0] = 0;
					6'd33: val_out_nxt[15:0] = 0;
					6'd34: val_out_nxt[15:0] = 0;
					6'd35: val_out_nxt[15:0] = 0;
					6'd36: val_out_nxt[15:0] = 0;
					6'd37: val_out_nxt[15:0] = 0;
					6'd38: val_out_nxt[15:0] = 0;
					6'd39: val_out_nxt[15:0] = 0;
					6'd40: val_out_nxt[15:0] = 0;
					6'd41: val_out_nxt[15:0] = 0;
					6'd42: val_out_nxt[15:0] = 0;
					6'd43: val_out_nxt[15:0] = 0;
					6'd44: val_out_nxt[15:0] = 0;
					6'd45: val_out_nxt[15:0] = 0;
					6'd46: val_out_nxt[15:0] = 0;
					6'd47: val_out_nxt[15:0] = 0;
					6'd48: val_out_nxt[15:0] = 0;
					6'd49: val_out_nxt[15:0] = 0;
					6'd50: val_out_nxt[15:0] = 0;
					6'd51: val_out_nxt[15:0] = 0;
					6'd52: val_out_nxt[15:0] = 0;
					6'd53: val_out_nxt[15:0] = 0;
					6'd54: val_out_nxt[15:0] = 0;
					6'd55: val_out_nxt[15:0] = 0;
					6'd56: val_out_nxt[15:0] = 0;
					6'd57: val_out_nxt[15:0] = 0;
					6'd58: val_out_nxt[15:0] = 0;
					6'd59: val_out_nxt[15:0] = 0;
					6'd60: val_out_nxt[15:0] = 0;
					6'd61: val_out_nxt[15:0] = 0;
					6'd62: val_out_nxt[15:0] = 0;
					6'd63: val_out_nxt[15:0] = 0;
				endcase
			end
			// 4B
			3'b101: begin
				val_out_type_nxt = 2'b10;
				case(parse_act[6:1])
					6'd0: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*0 +: 32];
					6'd1: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*1 +: 32];
					6'd2: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*2 +: 32];
					6'd3: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*3 +: 32];
					6'd4: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*4 +: 32];
					6'd5: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*5 +: 32];
					6'd6: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*6 +: 32];
					6'd7: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*7 +: 32];
					6'd8: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*8 +: 32];
					6'd9: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*9 +: 32];
					6'd10: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*10 +: 32];
					6'd11: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*11 +: 32];
					6'd12: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*12 +: 32];
					6'd13: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*13 +: 32];
					6'd14: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*14 +: 32];
					6'd15: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*15 +: 32];
					6'd16: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*16 +: 32];
					6'd17: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*17 +: 32];
					6'd18: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*18 +: 32];
					6'd19: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*19 +: 32];
					6'd20: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*20 +: 32];
					6'd21: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*21 +: 32];
					6'd22: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*22 +: 32];
					6'd23: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*23 +: 32];
					6'd24: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*24 +: 32];
					6'd25: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*25 +: 32];
					6'd26: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*26 +: 32];
					6'd27: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*27 +: 32];
					6'd28: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*28 +: 32];
					6'd29: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*29 +: 32];
					6'd30: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*30 +: 32];
					6'd31: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*31 +: 32];
					6'd32: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*32 +: 32];
					6'd33: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*33 +: 32];
					6'd34: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*34 +: 32];
					6'd35: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*35 +: 32];
					6'd36: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*36 +: 32];
					6'd37: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*37 +: 32];
					6'd38: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*38 +: 32];
					6'd39: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*39 +: 32];
					6'd40: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*40 +: 32];
					6'd41: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*41 +: 32];
					6'd42: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*42 +: 32];
					6'd43: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*43 +: 32];
					6'd44: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*44 +: 32];
					6'd45: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*45 +: 32];
					6'd46: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*46 +: 32];
					6'd47: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*47 +: 32];
					6'd48: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*48 +: 32];
					6'd49: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*49 +: 32];
					6'd50: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*50 +: 32];
					6'd51: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*51 +: 32];
					6'd52: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*52 +: 32];
					6'd53: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*53 +: 32];
					6'd54: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*54 +: 32];
					6'd55: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*55 +: 32];
					6'd56: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*56 +: 32];
					6'd57: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*57 +: 32];
					6'd58: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*58 +: 32];
					6'd59: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*59 +: 32];
					6'd60: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*60 +: 32];
					6'd61: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*61 +: 32];
					6'd62: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*62 +: 32];
					6'd63: val_out_nxt[31:0] = phv_in[PHV_4B_START_POS+32*63 +: 32];
				endcase
			end
			// 6B
			3'b111: begin
				val_out_type_nxt = 2'b11;
				case(parse_act[6:1])
					6'd0: val_out_nxt[47:0] = 0;
					6'd1: val_out_nxt[47:0] = 0;
					6'd2: val_out_nxt[47:0] = 0;
					6'd3: val_out_nxt[47:0] = 0;
					6'd4: val_out_nxt[47:0] = 0;
					6'd5: val_out_nxt[47:0] = 0;
					6'd6: val_out_nxt[47:0] = 0;
					6'd7: val_out_nxt[47:0] = 0;
					6'd8: val_out_nxt[47:0] = 0;
					6'd9: val_out_nxt[47:0] = 0;
					6'd10: val_out_nxt[47:0] = 0;
					6'd11: val_out_nxt[47:0] = 0;
					6'd12: val_out_nxt[47:0] = 0;
					6'd13: val_out_nxt[47:0] = 0;
					6'd14: val_out_nxt[47:0] = 0;
					6'd15: val_out_nxt[47:0] = 0;
					6'd16: val_out_nxt[47:0] = 0;
					6'd17: val_out_nxt[47:0] = 0;
					6'd18: val_out_nxt[47:0] = 0;
					6'd19: val_out_nxt[47:0] = 0;
					6'd20: val_out_nxt[47:0] = 0;
					6'd21: val_out_nxt[47:0] = 0;
					6'd22: val_out_nxt[47:0] = 0;
					6'd23: val_out_nxt[47:0] = 0;
					6'd24: val_out_nxt[47:0] = 0;
					6'd25: val_out_nxt[47:0] = 0;
					6'd26: val_out_nxt[47:0] = 0;
					6'd27: val_out_nxt[47:0] = 0;
					6'd28: val_out_nxt[47:0] = 0;
					6'd29: val_out_nxt[47:0] = 0;
					6'd30: val_out_nxt[47:0] = 0;
					6'd31: val_out_nxt[47:0] = 0;
					6'd32: val_out_nxt[47:0] = 0;
					6'd33: val_out_nxt[47:0] = 0;
					6'd34: val_out_nxt[47:0] = 0;
					6'd35: val_out_nxt[47:0] = 0;
					6'd36: val_out_nxt[47:0] = 0;
					6'd37: val_out_nxt[47:0] = 0;
					6'd38: val_out_nxt[47:0] = 0;
					6'd39: val_out_nxt[47:0] = 0;
					6'd40: val_out_nxt[47:0] = 0;
					6'd41: val_out_nxt[47:0] = 0;
					6'd42: val_out_nxt[47:0] = 0;
					6'd43: val_out_nxt[47:0] = 0;
					6'd44: val_out_nxt[47:0] = 0;
					6'd45: val_out_nxt[47:0] = 0;
					6'd46: val_out_nxt[47:0] = 0;
					6'd47: val_out_nxt[47:0] = 0;
					6'd48: val_out_nxt[47:0] = 0;
					6'd49: val_out_nxt[47:0] = 0;
					6'd50: val_out_nxt[47:0] = 0;
					6'd51: val_out_nxt[47:0] = 0;
					6'd52: val_out_nxt[47:0] = 0;
					6'd53: val_out_nxt[47:0] = 0;
					6'd54: val_out_nxt[47:0] = 0;
					6'd55: val_out_nxt[47:0] = 0;
					6'd56: val_out_nxt[47:0] = 0;
					6'd57: val_out_nxt[47:0] = 0;
					6'd58: val_out_nxt[47:0] = 0;
					6'd59: val_out_nxt[47:0] = 0;
					6'd60: val_out_nxt[47:0] = 0;
					6'd61: val_out_nxt[47:0] = 0;
					6'd62: val_out_nxt[47:0] = 0;
					6'd63: val_out_nxt[47:0] = 0;
				endcase
			end
			default: begin
				val_out_type_nxt = 0;
				val_out_nxt = 0;
			end
		endcase
	end
end


always @(posedge clk) begin
	if (~aresetn) begin
		val_out_valid <= 0;
		val_out <= 0;
		val_out_type <= 0;
	end
	else begin
		val_out_valid <= val_out_valid_nxt;
		val_out <= val_out_nxt;
		val_out_type <= val_out_type_nxt;
	end
end

endmodule
