//============================================================================
//  HT1080Z port to MiSTer
//  Copyright (c) 2019 Alan Steremberg - alanswx
//
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

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


	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)
	input         TAPE_IN,
	//ADC
	inout   [3:0] ADC_BUS,

	// SD-SPI
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

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign USER_OUT = '1;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign ADC_BUS  = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign BUTTONS = 0;

// aspect ratio including all border space is  4:3
// aspect ratio iwith partial border space is 20:17
// aspect ratio of only displayed area is     11:10
assign VIDEO_ARX = status[13] ? 4 : (status[12] ? 20 : 11);
assign VIDEO_ARY = status[13] ? 3 : (status[12] ? 17 : 10);

assign AUDIO_S = 0;
assign AUDIO_MIX = 0;

assign LED_DISK  = LED;				/* later add disk motor on/off */
assign LED_POWER = 0;
assign LED_USER  = ioctl_download;

`include "build_id.v"
localparam CONF_STR = {
	"HT1080Z;;",
	"F2,CMD,Load Program;",
	"F1,CAS,Load Cassette;",
	"-;",
	"O56,Screen Color,White,Green,Amber;",
	"OE,Video Flicker,Off,On;",
	"O7,Lowercase Type,Normal,Symbol;",
	"OCD,Overscan,None,Partial,Full;",
	"O13,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"O4,Kbd Layout,TRS-80,PC;",
	"OAB,TRISSTICK,None,BIG5,ALPHA;",
	"O89,Clockspeed (MHz),1.78(1x),2.67(1.5x),3.56(2x),21.36(12x);",
	"-;",
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
wire        ioctl_download;
wire        ioctl_wr;
wire [15:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire  [7:0] ioctl_index;

wire        forced_scandoubler;
wire [10:0] ps2_key;

wire [21:0] gamma_bus;

wire [15:0] joystick_0, joystick_1;

hps_io #(.STRLEN(($size(CONF_STR)>>3) )) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

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
	.ioctl_index(ioctl_index)
);

reg loader_wr;			// Writing loader data to ram 
reg loader_download;	// Download in progress (active high)
reg execute_enable = 0;	// Jump to start address (execute_addr)
reg [15:0] loader_addr;
reg [15:0] execute_addr;
reg [7:0] loader_data;
reg loader_reset = 0;

typedef enum {IDLE, GET_TYPE, GET_LEN, GET_LSB, GET_LSB, SETUP, TRANSFER, IGNORE} loader_states;
loader_states state;

wire rom_download = ioctl_download && ioctl_index==0;
wire reset = RESET | status[0] | buttons[1] | rom_download;

always @(posedge clk_sys or negedge reset)
begin
	reg [8:0] block_len;
	reg [7:0] block_type;
	reg [15:0] block_addr;
	reg old_download;
	reg first_block;

	if (reset == 1'b0)
	begin
		loader_reset <= 0;
		execute_enable <= 0;
		loader_addr <= 16'd0;
		execute_addr <= 16'd0;
		loader_data <= 8'd0;
		old_download <= ioctl_download;
		state <= IDLE;
		loader_download <= 0;
		ioctl_wait <= 0;
		block_address <= 16'd0;
	end 
	else begin

		loader_wr <= 0;
		ioctl_wait <= 0;
		execute_enable <= 0;

		case(state)
			IDLE: begin 		// No transfer occurring
				if(~old_download && ioctl_download && ioctl_index > 1) begin
					loader_download <= 1;
					state <= GET_TYPE;
				end
			end
			GET_TYPE: begin		// Start of transfer, load block type
				ioctl_wait <= 0;
				if(ioctl_wr) begin
					block_type <= ioctl_dout;
					if(ioctl_dout ==8'd0) begin	// EOF
						loader_download <= 0;
						state <= IDLE;
					else
						state <= GET_LEN;
					end
				end
			end
			GET_LEN: begin		// Setup len or finish transfer
				if(ioctl_wr) begin
					if(block_type == 8'd1) begin
						case(ioctl_dout)
						8'd2: block_len = 9'd256;
						8'd1: block_len = 9'd0;
						default: block_len = {1b0,((ioctl_dout - 2 ) & 8'd255};
						endcase
						state = GET_LSB;
					end else if(block_type == 8'd2) begin
						block_len = 9'd0;
						state = GET_LSB;
					end else begin
						block_len = ioctl_dout;
						state = IGNORE;
					end
				end
			end
			GET_LSB: begin
				if(ioctl_wr) begin
					block_addr[7:0] <= ioctl_dout;
					state <= GET_MSB;
				end 
			end
			GET_MSB: begin
				if(ioctl_wr) begin
					block_addr[15:8] <= ioctl_dout;
					ioctl_wait <= 1;
					state <= SETUP;
				end 
			end
			SETUP: begin		
				if(block_type == 8'd1) begin	// Data block
					loader_addr <= block_addr;
					state <= TRANSFER;
				end if(block_type == 8'd2) begin	
					execute_addr <= block_addr;
					execute_enable <= 1;	// toggle execute flag
					if(block_len > 2)  begin
						state <= IGNORE; 
					end else begin
						loader_download <= 0;
						state <= IDLE; 
					end					
				end else begin	// Shoudl only ever be 1 or 2, so error state
					loader_download <= 0;
					state <= IDLE;
				end
			end
			TRANSFER: begin
				if(ioctl_wr) begin
					if(block_len > 0) begin
						loader_addr <= loader_addr + 1;
						block_len <= block_len - 1;
						loader_data <= ioctl_dout;
						loader_wr <= 1;
					end else begin	// Move to next block in chain
						state <= GET_TYPE;
						loader_wr <= 0;
					end
				end
			end
			IGNORE: begin
				if(ioctl_wr) begin
					if(block_len > 0) begin
						block_len <= block_len - 1;
					end else begin
						if(block_type == 8'd0 || block_type == 8'd2) begin
							state <= IDLE; 
							loader_download <= 0;
						end else state <= GET_TYPE;
					end
				end
			end
		endcase
	end
end

wire trsram_wr;			// Writing loader data to ram 
wire trsram_download;	// Download in progress (active high)
wire [15:0] trsram_addr;
wire [7:0] trsram_data;

assign trsram_wr = loader_download ? loader_wr : ioctl_wr;
assign trsram_download = loader_download ? loader_download : ioctl_download;
assign trsram_addr = loader_download ? {4'b0, loader_addr} : {|ioctl_index,ioctl_addr};
assign trsram_data = loader_download ? loader_data : ioctl_data;

wire LED;

ht1080z ht1080z
(
	.reset(reset),
	.clk42m(clk_sys),

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

	.dn_clk(clk_sys),
	.dn_go(trsram_download),
	.dn_wr(trsram_wr),
	.dn_addr(trsram_addr),			// CPU = 0000-FFFF; cassette = 10000-1FFFF
	.dn_data(trsram_data),

	.execute_addr(execute_addr),
	.execute_enable(execute_enable)
);

///////////////////////////////////////////////////
wire        ce_pix;
wire [17:0] RGB;
wire        HSync,VSync,HBlank,VBlank;

wire  [2:0] scale = status[3:1];
wire  [2:0] sl = scale ? scale - 1'd1 : 3'd0;

assign CLK_VIDEO = clk_sys;
assign VGA_SL = sl[1:0];

video_mixer #(.LINE_LENGTH(640), .GAMMA(1)) video_mixer
(
	.*,

	.clk_vid(clk_sys),
	.ce_pix_out(CE_PIXEL),

	.scanlines(0),
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale==1),

	.mono(0),

	.R({RGB[5:0],RGB[5:4]}),
	.G({RGB[11:6],RGB[11:10]}),
	.B({RGB[17:12],RGB[17:16]})
);

wire  [8:0] audiomix;

assign AUDIO_L={audiomix,7'b0000000};
assign AUDIO_R=AUDIO_L;

endmodule
