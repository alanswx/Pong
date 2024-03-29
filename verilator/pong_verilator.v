//
//
//

`timescale 1ns/1ns

`define SDL_DISPLAY

module pong_verilator;

   reg clk/*verilator public_flat*/;
   reg reset/*verilator public_flat*/;
   reg vsync/*verilator public_flat*/;


  wire rpOut;
  wire lpOut;
  wire ballOut;
  wire manServe;
  wire rpDWN;
  wire lpDWN;
  wire PIN_18;
  wire PIN_19;
  wire ballAngle;
  wire ballSpeed;
  wire batSize;
  //wire hsync;
  wire audio;
  wire rifle1DWN;
  wire rifle1;
  wire rifle2;
  wire tennisDWN;
  wire tennis;
  wire sfOut;
  wire soccer;
  wire squash;
  wire practice;
   wire vid;
   wire sync;
   wire [8:0] rgb;

        assign vid= ballOut | sfOut | lpOut | rpOut;
	assign rgb= {vid,vid,vid,vid,vid,vid,vid,vid,vid};
   //wire       csync, hsync, vsync, hblank, vblank;
   wire       csync, hsync,  hblank, vblank;
//   wire [7:0] audio;
//   wire [3:0] led/*verilator public_flat*/;

//   reg [7:0]  trakball/*verilator public_flat*/;
   reg [7:0]  joystick/*verilator public_flat*/;
   reg [7:0]  sw1/*verilator public_flat*/;
   reg [7:0]  sw2/*verilator public_flat*/;
   reg [9:0]  playerinput/*verilator public_flat*/;
 
  //ay38500NTSC chip(rpOut,lpOut,ballOut,manServe,rpDWN,PIN_19,ballAngle,lpDWN,PIN_18,batSize,ballSpeed,vsync,audio,clk,0,rifle1DWN,rifle1,rifle2,1,tennisDWN,tennis,sfOut,soccer,squash,practice,~reset);
  // working? //ay38500NTSC chip(rpOut,lpOut,ballOut,0,rpDWN,PIN_19,1,lpDWN,PIN_18,1,1,sync,audio,clk,0,rifle1DWN,1,1,1,tennisDWN,0,sfOut,1,0,0,~reset,vsync,hsync);
  ay38500NTSC chip(rpOut,lpOut,ballOut,0,rpDWN,PIN_19,1,lpDWN,PIN_18,1,1,sync,audio,clk,0,rifle1DWN,1,1,1,tennisDWN,1,sfOut,1,0,1,~reset,vsync,hsync);
 
`ifdef SDL_DISPLAY
   import "DPI-C" function void dpi_vga_init(input integer h,
					     input integer v);

   import "DPI-C" function void dpi_vga_display(input integer vsync_,
						input integer hsync_,
    						input integer pixel_);

   initial
     begin
	dpi_vga_init(640, 480);
     end

   wire [31:0] pxd;
   wire [31:0] hs;
   wire [31:0] vs;

   wire [2:0]  vgaBlue;
   wire [2:0]  vgaGreen;
   wire [2:0]  vgaRed;

   assign vgaBlue  = rgb[8:6];
   assign vgaGreen = rgb[5:3];
   assign vgaRed   = rgb[2:0];

   //assign pxd = (hblank | vblank) ? 32'b0 : { 24'b0, vgaBlue, vgaGreen[2:1], vgaRed };
   //assign pxd = (hblank | vblank) ? 32'b0 : { vgaRed,5'b0,vgaGreen,5'b0,vgaBlue,5'b0,8'b11111111 };
   //assign pxd = (hblank | vblank) ? 32'b0 : { 8'b11111111,vgaRed,5'b0,vgaGreen,5'b0,vgaBlue,5'b0 };
   assign pxd =  { 8'b11111111,vgaRed,5'b0,vgaGreen,5'b0,vgaBlue,5'b0 };
//ARGB8888


   //assign vs = {31'b0, vsync};
   //assign hs = {31'b0, hsync};
   //assign vs = {31'b0, sync2};
   //assign hs = {31'b0, sync1};
   assign vs = {31'b0, vsync};
   assign hs = {31'b0, hsync};

   
   always @(posedge clk)
     dpi_vga_display(vs, hs, pxd);
`endif
   
endmodule // ff_tb


