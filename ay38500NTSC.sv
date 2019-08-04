// Copyright (c) 2012-2013 Ludvig Strigeus
// This program is GPL Licensed. See COPYING for the full license.
//
// MiSTer port: Copyright (C) 2017,2018 Sorgelig

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [44:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        VGA_CLK,

	//Multiple resolutions are supported using different VGA_CE rates.
	//Must be based on CLK_VIDEO
	output        VGA_CE,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)

	//Base video clock. Usually equals to CLK_SYS.
	output        HDMI_CLK,

	//Multiple resolutions are supported using different HDMI_CE rates.
	//Must be based on CLK_VIDEO
	output        HDMI_CE,

	output  [7:0] HDMI_R,
	output  [7:0] HDMI_G,
	output  [7:0] HDMI_B,
	output        HDMI_HS,
	output        HDMI_VS,
	output        HDMI_DE,   // = ~(VBlank | HBlank)
	output  [1:0] HDMI_SL,   // scanlines fx

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] HDMI_ARX,
	output  [7:0] HDMI_ARY,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S    // 1 - signed audio samples, 0 - unsigned
);

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign HDMI_ARX = status[1] ? 8'd16 : 8'd4;
assign HDMI_ARY = status[1] ? 8'd9  : 8'd3;


`include "build_id.v"
parameter CONF_STR = {
	"APF_TV_fun;;",
	"-;",
	"O23,Game		,Tennis,Soccer,Squash,Practice;",
//	"O13,Game		,Hidden,Tennis,Soccer,Squash,Practice,gameRifle1,gameRifle2;",
	"O4,Serve		,Auto,Manual;",
	"O5,Ball Angle	,20deg,40deg;", //check
	"O6,Bat Size	,Small,Big;",	//check
	"O7,Ball Speed	,Fast,Slow;",
	"-;",
	"T8,Start;",
	"-;",
	"O8,Aspect ratio,3:2,16:9;",
	"O9B,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"R0,Reset;",
	"J,Button,Select,Start;",
	"V,v",`BUILD_DATE
};


////////////////////   CLOCKS   ///////////////////

wire clk_16, clk_2;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_16),	
	.outclk_1(clk_2),	
	.locked(pll_locked)
);


///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [10:0] ps2_key;

wire [15:0] joy_0, joy_1;
wire [15:0] joy = joy_0 | joy_1;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_16),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.ps2_key(ps2_key)
);

wire       pressed = ps2_key[9];
wire [8:0] code    = ps2_key[8:0];
always @(posedge clk_16) begin
	reg old_state;
	old_state <= ps2_key[10];
	
	if(old_state != ps2_key[10]) begin
		casex(code)
			'h03a: btn_fire         <= pressed; // M
			'h005: btn_one_player   <= pressed; // F1
			'h006: btn_two_players  <= pressed; // F2
			'h01C: btn_left      	<= pressed; // A
			'h023: btn_right      	<= pressed; // D
			'h004: btn_coin  			<= pressed; // F3
			'h04b: btn_thrust  			<= pressed; // L
			'h042: btn_shield  			<= pressed; // K
//			'hX75: btn_up          <= pressed; // up
//			'hX72: btn_down        <= pressed; // down
			'hX6B: btn_left        <= pressed; // left
			'hX74: btn_right       <= pressed; // right
			'h014: btn_fire        <= pressed; // ctrl
			'h011: btn_thrust      <= pressed; // Lalt
			'h029: btn_shield      <= pressed; // space
			// JPAC/IPAC/MAME Style Codes
			'h016: btn_start_1     <= pressed; // 1
			'h01E: btn_two_players <= pressed; // 2
			'h02E: btn_coin        <= pressed; // 5
			'h036: btn_coin        <= pressed; // 6
			
		endcase
	end
end

reg btn_right = 0;
reg btn_left = 0;
reg btn_one_player = 0;
reg btn_two_players = 0;
reg btn_fire = 0;
reg btn_coin = 0;
reg btn_thrust = 0;
reg btn_shield = 0;
reg btn_start_1=0;

wire [7:0] BUTTONS = {~btn_right & ~joy[0],~btn_left & ~joy[1],~(btn_one_player|btn_start_1) & ~joy[7],~btn_two_players,~btn_fire & ~joy[4],~btn_coin & ~joy[7],~btn_thrust & ~joy[5],~btn_shield & ~joy[6]};
wire hblank, vblank;
/*
wire hs, vs;
wire [2:0] r,g;
wire [2:0] b;

reg ce_pix;
always @(posedge clk_24) begin
        reg old_clk;

        old_clk <= clk_6;
        ce_pix <= old_clk & ~clk_6;
end

arcade_fx #(640,9) arcade_video
(
        .*,

        .clk_video(clk_24),

        .RGB_in({r,g,b}),
        .HBlank(hblank),
        .VBlank(vblank),
        .HSync(~hs),
        .VSync(~vs),

        .fx(status[5:3])
);
*/
wire ce_vid = 1; 
wire hs, vs;
wire [2:0] r,g;
wire [2:0] b;

assign VGA_CLK  = clk_16; 
assign VGA_CE   = ce_vid;
assign VGA_R    = {vid,vid,vid,vid,vid,vid,vid,vid};
assign VGA_G    = {vid,vid,vid,vid,vid,vid,vid,vid};
assign VGA_B    = {vid,vid,vid,vid,vid,vid,vid,vid};
assign VGA_HS   = hs;
assign VGA_VS   = vs;
assign VGA_DE   = 1'b1;  // AJS - fix this

assign HDMI_CLK = VGA_CLK;
assign HDMI_CE  = VGA_CE;
assign HDMI_R   = VGA_R ;
assign HDMI_G   = VGA_G ;
assign HDMI_B   = VGA_B ;
assign HDMI_DE  = VGA_DE;
assign HDMI_HS  = VGA_HS;
assign HDMI_VS  = VGA_VS;
//assign HDMI_SL  = status[2] ? 2'd0   : status[4:3];
assign HDMI_SL  = 2'd0;



wire 			vid_play, vid_RP, vid_LP, vid_Ball;
wire 			vid = vid_play | vid_RP | vid_LP | vid_Ball;
wire			gameTennis;
wire			gameSoccer;
wire			gameSquash;
wire			gamePractice;
wire			gameRifle1;
wire			gameRifle2;
wire 			m_left, m_right;
wire 			LPin, RPin, Rifle1, Rifle2;

wire			audio;

assign AUDIO_L=AUDIO_R=audio;

always @(*) begin
 case (status[3:2])
// 3'b001  : begin gameTennis <= 0; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1; end
//	3'b010  : begin gameTennis <= 1; gameSoccer <= 0; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
// 3'b011  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 0; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
//	3'b100  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 0; gameRifle1 <= 1; gameRifle2 <= 1;  end	
//	3'b101  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 0; gameRifle2 <= 1;  end
//	3'b111  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 0;  end	
//	default : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
	
	2'b01  : begin gameTennis <= 1; gameSoccer <= 0; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
   2'b10  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 0; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
	2'b11  : begin gameTennis <= 1; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 0; gameRifle1 <= 1; gameRifle2 <= 1;  end
	default : begin gameTennis <= 0; gameSoccer <= 1; gameSquash <= 1; gamePractice <= 1; gameRifle1 <= 1; gameRifle2 <= 1;  end
 endcase
end

ay38500NTSC ay38500NTSC(
	.clk(clk_2),
	.reset(~(buttons[1] | status[0] | status[9])),
	.pinSound(audio),
	//Video
	.pinBallOut(vid_Ball),
	.pinRPout(vid_RP),
	.pinLPout(vid_LP),
	.pinSFout(vid_play),
	.vsync(vs),
   .hsync(hs),
	//Menu Items
	.pinManualServe(status[4] | joy_0[4] | joy_1[4]),
	.pinBallAngle(status[5]),
	.pinBatSize(status[6]),
	.pinBallSpeed(status[7]),
	//Game Select
	.pinRifle1(1'b1),//							?
	.pinRifle2(1'b1),//							?
	.pinTennis(gameTennis),
	.pinSoccer(gameSoccer),
	.pinSquash(gameSquash),
	.pinPractice(gamePractice),	
	
	.pinShotIn(1'b1),//							todo
	.pinHitIn(1'b0),//							todo
	.pinRifle1_DWN(Rifle1),//					?
	.pinTennis_DWN(Rifle2),//					?
	.pinRPin_DWN(RPin),
	.pinLPin_DWN(LPin),
	.pinRPin(m_right),//							todo
	.pinLPin(m_left)//							todo
	);


endmodule
