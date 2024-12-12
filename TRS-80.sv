//============================================================================
//  HT1080Z port to MiSTer
//  Renamed to TRS-80 after Cassette and CMD loading support
//  
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//
//============================================================================

localparam NBDRIV=4;

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign VGA_F1=0;
assign HDMI_FREEZE = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;

// assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign USER_OUT = '1;
// assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign DDRAM_CLK =  clk_sys ;
assign ADC_BUS  = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign BUTTONS = 0;

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_DISK  = LED;				/* later add disk motor on/off */
assign LED_POWER = 0;
assign LED_USER  = ioctl_download;

// Status Bit Map:
//             Upper                             Lower              
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// XXXXXXXXXXXXXXXXXXXXX

`include "build_id.v"
localparam CONF_STR = {
	"TRS-80;SS3E000000:10000,UART19200:9600:4800:2400:1200:300:110;",
	"S0,DSKJV1,Mount Disk 0:;",
 	"S1,DSKJV1,Mount Disk 1:;",
 	"S2,DSKJV1,Mount Disk 2:;",
 	"S3,DSKJV1,Mount Disk 3:;",
	"-;",
//	"F4,*,Upload File(s);",
	"F2,CMDBAS,Load Program;",
	"F1,CAS,Load Cassette;",
	"-;",
	"FS3,SAV,Snapshot;",
	"OJK,Savestate Slot,1,2,3,4;",
	"RH,Load State;",
	"RI,Save State;",
	"-;",
	"O56,Screen Color,White,Green,Amber;",
	"OE,Video Flicker,Off,On;",
	"O7,Lowercase Type,Normal,Symbol;",
	"OCD,Overscan,None,Partial,Full;",
	"OF,Overscan Status Line,Off,On;",
	"O13,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O4,Kbd Layout,TRS-80,PC;",
	"OAB,TRISSTICK,None,BIG5,ALPHA;",
	"O89,Clockspeed (MHz),1.78(1x),3.56(2x),5.34(3x),21.29(12x);",
	"-;",
	"RG,Erase memory and reset;",
	"R0,Reset;",
	"J,Fire;",
	"V,v",`BUILD_DATE
};

wire clk_sys;
pll pll
(
	.refclk   (CLK_50M),
	.rst      (0),
	.outclk_0 (clk_sys) // 42 MHz
);

wire [31:0] status;
wire  [1:0] buttons;
wire			cpum1;
wire        ioctl_download;
wire        ioctl_wr;
wire [15:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [15:0] ioctl_index;
wire	    ioctl_wait;
wire [31:0] sd_lba[NBDRIV];
wire [31:0] sd_lba_0;
wire  [3:0] sd_rd;
wire  [3:0] sd_wr;
wire  [3:0] sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din_0;
wire  [7:0] sd_buff_din[NBDRIV];
wire        sd_buff_wr;
wire  [3:0] img_mounted;
wire        img_readonly;
wire [63:0] img_size;

wire        forced_scandoubler;
wire [10:0] ps2_key;

wire [21:0] gamma_bus;

wire [15:0] joystick_0, joystick_1;
wire [31:0] uart_speed;
wire [7:0] uart_mode;

hps_io #(.CONF_STR(CONF_STR), .WIDE(0), .VDNUM(NBDRIV) ) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.ps2_key(ps2_key),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1),
	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.status(status),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_data),
	.ioctl_wait(ioctl_wait),
	.ioctl_index(ioctl_index),
	
	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),
	
	 .uart_mode(uart_mode),
	 .uart_speed(uart_speed)
);

wire rom_download = ioctl_download && ioctl_index==0;
wire reset = RESET | status[0] | buttons[1] | rom_download;

// signals from loader
wire loader_wr;		
wire loader_download;
wire [15:0] loader_addr;
wire [7:0] loader_data;
wire [15:0] execute_addr;
wire execute_enable;
wire loader_wait;
//(* preserve *) wire [31:0] iterations;

cmd_loader cmd_loader
(
	.clock(clk_sys),
	.reset(reset),
	.cpum1(cpum1),
	.erase_mem(status[16]),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_dout(ioctl_data),
	.ioctl_addr(ioctl_addr),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),
	
	.loader_wr(loader_wr),
	.loader_download(loader_download),
	.loader_addr(loader_addr),
	.loader_data(loader_data),
	.loader_din(trsram_din),
	.execute_addr(execute_addr),
	.execute_enable(execute_enable)
//	.iterations(iterations)		// Debugging only
);

wire trsram_wr;			// Writing loader data to ram 
wire trsram_rd;			// Reading loader data from ram 
wire trsram_download;	// Download in progress (active high)
wire [23:0] trsram_addr;
wire [7:0] trsram_data;
wire [7:0] trsram_din;

assign trsram_wr = loader_download ? loader_wr : |ioctl_index[5:1]==1'b0 ?  ioctl_wr : 1'b0 ; // we don't want a spurious write if loader_download is late
assign trsram_rd = loader_download ;
assign trsram_download = loader_download ? loader_download : ioctl_index == 1 ? ioctl_download : 1'b0;
assign trsram_addr = loader_download ? {8'b0, loader_addr} : {7'b0,|ioctl_index[5:0],ioctl_addr};
assign trsram_data = loader_download ? loader_data : ioctl_data;

wire LED;

// wire [1:0] fdc_wp = 2'b0;
wire       fdc_irq;
wire       fdc_drq;
wire [1:0] fdc_addr;
wire       fdc_sel;
wire       fdc_rw;
wire [7:0] fdc_din;
wire [7:0] fdc_dout;

// Map all such broken accesses to drive A only
//wire [1:0] floppy_sel = 2'b10;	// ** Need to change from code

//wire [1:0] floppy_sel_exclusive = (floppy_sel == 2'b00)?2'b10:floppy_sel;

trs80 trs80
(
	.reset(reset),
	.clk42m(clk_sys),
	.cpum1_out(cpum1),

	.joy0(joystick_0),
	.joy1(joystick_1),
	.joytype(status[11:10]),

	.RGB(RGB),
	.HSYNC(HSync),
	.VSYNC(VSync),
	.hblank(HBlank),
	.vblank(VBlank),
	.ce_pix(ce_pix),

	.LED(LED),
	.audiomix(audiomix),

	.ps2_key(ps2_key),
	.kybdlayout(status[4]),
	.disp_color(status[6:5]),
	.lcasetype(status[7]),
	.overscan(status[13:12]),
	.overclock(status[9:8]),
	.flicker(status[14]),
	.debug(status[15]),
	
	.dn_clk(clk_sys),
	.dn_go(trsram_download),
	.dn_wr(trsram_wr),
	.dn_rd(trsram_rd),
	.dn_addr(trsram_addr),			// CPU = 0000-FFFF; cassette = 10000-1FFFF
	.dn_data(trsram_data),	
	.dn_din(trsram_din),

	.loader_download(loader_download),
	.execute_addr(execute_addr),
	.execute_enable(execute_enable),

	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.sd_lba(sd_lba_0),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack[0]|sd_ack[1]|sd_ack[2]|sd_ack[3]),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din_0),
	.sd_dout_strobe(sd_buff_wr),

	.UART_TXD(UART_TXD),
	.UART_RXD(UART_RXD),
	.UART_RTS(UART_RTS),
	.UART_CTS(UART_CTS),
	.UART_DTR(UART_DTR),
	.UART_DSR(UART_DSR),
	
	.uart_mode(uart_mode),   // 0=None, 1=PPP or Modem, 2=Console, 3=MIDI 
	.uart_speed(uart_speed),
	
	// .DDRAM_CLK(clk_sys),
	.DDRAM_BUSY(DDRAM_BUSY),
	.DDRAM_BURSTCNT(DDRAM_BURSTCNT),
	.DDRAM_ADDR(DDRAM_ADDR),
	.DDRAM_DOUT(DDRAM_DOUT),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD(DDRAM_RD),
	.DDRAM_DIN(DDRAM_DIN),
	.DDRAM_BE(DDRAM_BE),
	.DDRAM_WE(DDRAM_WE),
	
	.load_state(status[17])	,
	.save_state(status[18]),
	.ss_slot(status[20:19])
	
);


assign sd_buff_din[0]=sd_buff_din_0;
assign sd_buff_din[1]=sd_buff_din_0;
assign sd_buff_din[2]=sd_buff_din_0;
assign sd_buff_din[3]=sd_buff_din_0;
assign sd_lba[0]=sd_lba_0;
assign sd_lba[1]=sd_lba_0;
assign sd_lba[2]=sd_lba_0;
assign sd_lba[3]=sd_lba_0;


///////////////////////////////////////////////////
wire        ce_pix;
wire [17:0] RGB;
wire        HSync,VSync,HBlank,VBlank;

wire  [2:0] scale = status[3:1];
wire  [2:0] sl = scale > 1'd1 ? scale - 1'd1 : 3'b000;
wire freeze_sync;
// aspect ratio including all border space is  4:3
// aspect ratio iwith partial border space is 20:17
// aspect ratio of only displayed area is     11:10
assign VIDEO_ARX = ~|status[13:12] ? 13'd4 : (status[12] ? 13'd40 : 13'd40);
assign VIDEO_ARY = ~|status[13:12] ? 13'd3 : (status[12] ? 13'd29 : 13'd28);

assign CLK_VIDEO = clk_sys;
assign VGA_SL = sl[1:0];

video_mixer #(.LINE_LENGTH(672), .GAMMA(1)) video_mixer
(
	.*,

	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==3'b001),


	.R({RGB[5:0],RGB[5:4]}),
	.G({RGB[11:6],RGB[11:10]}),
	.B({RGB[17:12],RGB[17:16]})
);

wire  [8:0] audiomix;

assign AUDIO_L={audiomix,7'b0000000};
assign AUDIO_R=AUDIO_L;

endmodule
