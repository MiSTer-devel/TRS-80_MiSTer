--
-- HT 1080Z (TRS-80 clone) top level
--
--
-- Copyright (c) 2016-2017 Jozsef Laszlo (rbendr@gmail.com)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trs80 is
Port (
	reset      : in  std_logic;

	clk42m     : in  STD_LOGIC;

	RGB        : out STD_LOGIC_VECTOR (17 downto 0);
	HSYNC      : out STD_LOGIC;
	VSYNC      : out STD_LOGIC;
	hblank     : out STD_LOGIC;
	vblank     : out STD_LOGIC;
	ce_pix     : out STD_LOGIC;

	LED        : out STD_LOGIC;

	audiomix   : out STD_LOGIC_VECTOR(8 downto 0);

	joy0		  : in  std_logic_vector(7 downto 0);
	joy1		  : in  std_logic_vector(7 downto 0);
	joytype	  : in  std_logic_vector(1 downto 0);

	ps2_key    : in  STD_LOGIC_VECTOR(10 downto 0);

	kybdlayout : in  STD_LOGIC;
	disp_color : in  std_logic_vector(1 downto 0);
	lcasetype  : in  STD_LOGIC;
	overscan   : in  STD_LOGIC_VECTOR(1 downto 0);
	overclock  : in  STD_LOGIC_VECTOR(1 downto 0);
	flicker	   : in  STD_LOGIC;
	debug	   : in  STD_LOGIC;

	dn_clk     : in  std_logic;
	dn_go      : in  std_logic;
	dn_wr      : in  std_logic;
	dn_addr    : in  std_logic_vector(24 downto 0);
	dn_data    : in  std_logic_vector(7 downto 0);

	loader_download : in std_logic;
	execute_addr	: in std_logic_vector(15 downto 0);
	execute_enable	: in std_logic;

	img_mounted   	: in std_logic_vector(1 downto 0);
	img_readonly   	: in std_logic_vector(1 downto 0);
	img_size  	: in std_logic_vector(31 downto 0); -- in bytes

	sd_lba	 	: out std_logic_vector(31 downto 0);
	sd_rd	   	: out std_logic_vector(1 downto 0);
	sd_wr	   	: out std_logic_vector(1 downto 0);
	sd_ack	    	: in std_logic;
	sd_buff_addr   	: in std_logic_vector(8 downto 0);
	sd_buff_dout   	: in std_logic_vector(7 downto 0);
	sd_buff_din  	: out std_logic_vector(7 downto 0);
	sd_dout_strobe 	: in std_logic

);
end trs80;

architecture Behavioral of trs80 is


--
-- This is a static line of test to display on the debug line
-- It is meant to be overidden at points with any changing data values
--
type debugbuf is array(0 to 63) of std_logic_vector(7 downto 0);

signal msgbuf : debugbuf:=(
x"44",x"65",x"62",x"75",x"67",x"20",x"4D",x"65",x"73",x"73",x"61",x"67",x"65",x"3a",x"20",x"20",
x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",
x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20",x"20"
);

--
-- hex digit lookup helper array, to simplify debug output
--
type hexdigit is array(0 to 15) of std_logic_vector(7 downto 0);

signal hex : hexdigit:=(
x"30",x"31",x"32",x"33",x"34",x"35",x"36",x"37",x"38",x"39",x"41",x"42",x"43",x"44",x"45",x"46"
);


component dpram is
generic (
	DATA : integer;
	ADDR : integer
);
port (
	-- Port A
	a_clk  : in std_logic;
	a_wr   : in std_logic;
	a_addr : in std_logic_vector(ADDR-1 downto 0);
	a_din  : in std_logic_vector(DATA-1 downto 0);
	a_dout : out std_logic_vector(DATA-1 downto 0);

	-- Port B
	b_clk  : in std_logic;
	b_wr   : in std_logic;
	b_addr : in std_logic_vector(ADDR-1 downto 0);
	b_din  : in std_logic_vector(DATA-1 downto 0);
	b_dout : out std_logic_vector(DATA-1 downto 0)
);
end component;

component keyboard is
port (
	reset		: in std_logic;
	clk_sys	: in std_logic;

	ps2_key	: in std_logic_vector(10 downto 0);
	addr		: in std_logic_vector(7 downto 0);
	key_data	: out std_logic_vector(7 downto 0);
	kblayout	: in std_logic;

	Fn			: out std_logic_vector(11 downto 1);
	modif		: out std_logic_vector(2 downto 0)
);
end component;

component ym2149 is
port (
	CLK       : in  std_logic;
	CE        : in  std_logic;
	RESET     : in  std_logic;
	BDIR      : in  std_logic;
	BC        : in  std_logic;
	DI        : in  std_logic_vector(7 downto 0);
	DO        : out std_logic_vector(7 downto 0);
	CHANNEL_A : out std_logic_vector(7 downto 0);
	CHANNEL_B : out std_logic_vector(7 downto 0);
	CHANNEL_C : out std_logic_vector(7 downto 0);

	SEL       : in  std_logic;
	MODE      : in  std_logic;

	IOA_in    : in  std_logic_vector(7 downto 0);
	IOA_out   : out std_logic_vector(7 downto 0);

	IOB_in    : in  std_logic_vector(7 downto 0);
	IOB_out   : out std_logic_vector(7 downto 0)
);
end component;

component z80_regset is
--	generic (
--		SP_ADDR : integer
--	);
	port (
		execute_addr    : in std_logic_vector(15 downto 0);
		execute_enable  : in std_logic;
--		dir_in			: in std_logic_vector(211 downto 0);
		
		dir_out			: out std_logic_vector(211 downto 0);
		dir_set			: out std_logic
	);
end component ;

component fdc1771 is
		generic (
			SYS_CLK : integer		-- Main system clock
		);
		port (
			clk_sys  		: in std_logic;
			clk_cpu  		: in std_logic;
			clk_div	    	: in integer;

			floppy_drive    : in std_logic_vector(3 downto 0);
			floppy_side		: in std_logic;
			floppy_reset	: in std_logic;
			motor_on		: in std_logic;

			irq				: out std_logic;
			drq				: out std_logic;

			cpu_addr    	: in std_logic_vector(1 downto 0);
			cpu_sel	    	: in std_logic;
			cpu_rd	    	: in std_logic;
			cpu_wr	    	: in std_logic;
			cpu_din	    	: in std_logic_vector(7 downto 0);
			cpu_dout    	: out std_logic_vector(7 downto 0);
			
			img_mounted   	: in std_logic_vector(1 downto 0);
			img_wp		   	: in std_logic_vector(1 downto 0);
			img_size	   	: in std_logic_vector(31 downto 0); -- in bytes

			sd_lba 	  		: out std_logic_vector(31 downto 0);
			sd_rd		   	: out std_logic_vector(1 downto 0);
			sd_wr		   	: out std_logic_vector(1 downto 0);
			sd_ack	    	: in std_logic;
			sd_buff_addr   	: in std_logic_vector(8 downto 0);
			sd_dout		   	: in std_logic_vector(7 downto 0);
			sd_din		   	: out std_logic_vector(7 downto 0);
			sd_dout_strobe 	: in std_logic;

			fdc_new_command : out std_logic;

			cmd_out		    : out  std_logic_vector(7 downto 0);	
			track_out		: out  std_logic_vector(7 downto 0);	
			sector_out		: out  std_logic_vector(7 downto 0);	
			data_in_out		: out  std_logic_vector(7 downto 0);	
			status_out		: out  std_logic_vector(7 downto 0)
		);
end component ;

signal ch_a  : std_logic_vector(7 downto 0);
signal ch_b  : std_logic_vector(7 downto 0);
signal ch_c  : std_logic_vector(7 downto 0);
signal audio : std_logic_vector(9 downto 0);

signal ram_a_addr : std_logic_vector(16 downto 0);
signal ram_b_addr : std_logic_vector(16 downto 0);
signal ram_a_dout : STD_LOGIC_VECTOR(7 downto 0);
signal ram_b_dout : STD_LOGIC_VECTOR(7 downto 0);

signal cpua     : std_logic_vector(15 downto 0);
signal cpudo    : std_logic_vector(7 downto 0);
signal cpudi    : std_logic_vector(7 downto 0);
signal cpuwr,cpurd,cpumreq,cpuiorq,cpum1 : std_logic;
signal cpuclk,cpuclk_r : std_logic;
signal clk_25ms : std_logic;

signal rgbi : std_logic_vector(3 downto 0);
signal vramdo,kbdout : std_logic_vector(7 downto 0);

signal Fn : std_logic_vector(11 downto 0);
signal modif : std_logic_vector(2 downto 0);

signal romrd,ramrd,ramwr,vramsel,kbdsel : std_logic;
signal ior,iow,memr,memw : std_logic;

-- Local copy of disk registers for debugging
--signal reg_37ec : std_logic_vector(31 downto 0) := x"00000000";
signal dbg_cmd : std_logic_vector(7 downto 0);
signal dbg_track : std_logic_vector(7 downto 0);
signal dbg_sector : std_logic_vector(7 downto 0);
signal dbg_data_in : std_logic_vector(7 downto 0);
signal dbg_status : std_logic_vector(7 downto 0);

-- 0  1  2 3   4
-- 28 14 7 3.5 1.75
signal clk1774_div : std_logic_vector(5 downto 0) := "010111";
signal clk_25ms_div : integer := 1064450;
signal tick_1s : std_logic := '0';
signal tick_counter : integer := 40;

signal sndBC1,sndBDIR,sndCLK : std_logic;

signal ht_rgb_white	: std_logic_vector(17 downto 0);
signal ht_rgb_green	: std_logic_vector(17 downto 0);
signal ht_rgb_amber	: std_logic_vector(17 downto 0);


signal dbugmsg_addr  : STD_LOGIC_VECTOR (5 downto 0);
signal dbugmsg_data  : STD_LOGIC_VECTOR (7 downto 0);


signal io_ram_addr	: std_logic_vector(23 downto 0);
signal iorrd,iorrd_r	: std_logic;

signal tapebits		: std_logic_vector(2 downto 0);		-- motor on/off, plus two bits for output signal level
alias  tapemotor		: std_logic is tapebits(2);

signal taperead		: std_logic := '0';						-- only when motor is on, 0 = write, 1 = read
signal tape_cyccnt	: std_logic_vector(11 downto 0);		-- CPU cycle counter for cassette carrier signal
--signal tape_leadin	: std_logic_vector(7 downto 0);		-- additional 128 bits for sync-up, just in case
signal tape_bitptr	: natural := 7;

signal tapebit_val	: std_logic := '0';						-- represents bit being sent from cassette file
signal tapelatch		: std_logic := '0';						-- represents input bit from cassette (after signal conditioning)
--signal tapelatch_resetcnt	: std_logic_vector(3 downto 0) := "0000";	-- when port is read, reset value - but only after a few cycles

signal speaker : std_logic_vector(7 downto 0);

signal inkpulse, paperpulse, borderpulse : std_logic;
signal widemode : std_logic := '0';

-- Z80 Register control
--signal REG std_logic_vector(211 downto 0); -- IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
signal DIRSet : std_logic := '0';
signal DIR : std_logic_vector(211 downto 0) := (others => '0'); -- IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
--signal REG : std_logic_vector(211 downto 0) := (others => '0'); -- IFF2, IFF1, IM, IY, HL', DE', BC', IX, HL, DE, BC, PC, SP, R, I, F', A', F, A
-- Gated CPU clock
signal GCLK : std_logic; -- Pause CPU when loading CMD files (prevent crash)

-- Disk controller signals
signal fdc_irq : std_logic := '1';
signal old_fdc_irq : std_logic := '1';
signal fdc_irq_latch : std_logic := '1';
signal fdc_drq : std_logic;
signal fdc_wp : std_logic_vector(1 downto 0); -- = "00";
signal fdc_addr : std_logic_vector(1 downto 0);
signal fdc_sel : std_logic;
signal fdc_sel2 : std_logic;
signal fdc_rd : std_logic;
signal fdc_wr : std_logic;
signal fdc_din : std_logic_vector(7 downto 0);
signal fdc_dout : std_logic_vector(7 downto 0);
signal fdc_drive : std_logic_vector(1 downto 0);
signal fdc_strobe : std_logic := '0';
signal fdc_rd_strobe : std_logic := '0';
signal fdc_wr_strobe : std_logic := '0';
signal fdc_new_command : std_logic;
signal floppy_select : std_logic_vector(3 downto 0);
signal floppy_select_write : std_logic;
signal irq_latch_read : std_logic;
signal old_latch_read : std_logic := '1';
signal fdc_clk_div : integer;
signal fdc_slow_latch : std_logic := '0';

signal clk_25ms_latch : std_logic := '1';
signal old_clk_25ms : std_logic := '0';
signal expansion_irq : std_logic := '1';

type motor_state is (stopped, spinup, running);
signal fdc_motor_state : motor_state;
signal fdc_motor_on : std_logic := '0';
signal fdc_motor_countdown : integer := 0;
-- debugging counter
signal counter : std_logic_vector(31 downto 0) := (others => '0');  -- Used for debugging via SignalTap
attribute noprune: boolean; 
attribute noprune of counter: signal is true; -- set to false for RTL

begin

GCLK <= '0' when loader_download='1' and execute_enable='0' else cpuClk;

regset : z80_regset
port map
(
	execute_addr => execute_addr,
	execute_enable => execute_enable,
--	dir_in => REG,

	dir_out	=> DIR,
	dir_set => DIRSet
);

led <= taperead;

-- Generate 25ms clock for RTC in expansion interface
process(clk42m)
begin
	if rising_edge(clk42m) then
		clk_25ms <= '0';

		-- CPU clock divider
		if clk_25ms_div = 0 then	-- count down rather than up, as overclock may change
			clk_25ms <= '1';
			clk_25ms_div <= 1064450;   -- speed = 25ms for RTC
		else
			clk_25ms_div <= clk_25ms_div - 1;
		end if;
	end if;
end process;


-- RTC and FDC irq latch circuit
process(clk42m, reset)
begin
	if reset='1' then
		clk_25ms_latch <= '1';
		fdc_irq_latch <= '1';
	else
		if rising_edge(clk42m) then
			if(clk_25ms='1') then -- latch on rising edge
				clk_25ms_latch <= '0';
			end if;

			old_fdc_irq <= fdc_irq;
			if (old_fdc_irq='1' and fdc_irq='0') then
				fdc_irq_latch <= '0';
			end if;	

			old_latch_read <= irq_latch_read;
			if (old_latch_read='1' and irq_latch_read='0') then
				clk_25ms_latch <= '1';
				fdc_irq_latch <= '1';
			end if;
		end if;
	end if;
end process;

-- 1 second tick counter
process(clk42m, reset)
begin
	if reset='1' then
		tick_1s <= '0';
		tick_counter <= 40;	-- 40 hz counter
	else
		if rising_edge(clk42m) then
			if clk_25ms='1' then
				if tick_counter = 0 then
					tick_1s <= not tick_1s;
					tick_counter <= 40;
				else 
					tick_counter <= tick_counter - 1;
				end if;
			end if;
		end if;
	end if;
end process;

-- Motor controller state machine for auto spinup and spin down
process(clk42m, reset)
begin
	if reset='1' then
		fdc_motor_state <= stopped;	-- start with motor stopped
		fdc_motor_countdown <= 0;
		fdc_motor_on <= '0';
	else
		if rising_edge(clk42m) then
			case fdc_motor_state is
				when stopped =>	-- Motor off
					fdc_motor_on <= '0';
					if(floppy_select_write='1') then
						fdc_motor_state <= spinup;
						-- Countdown in 25ms ticks - 0.5 seconds to start
						fdc_motor_countdown <= 20 / fdc_clk_div;
					end if;
				when spinup =>	-- Motor spinning up
					if(fdc_motor_countdown=0) then
						fdc_motor_state <= running;
						-- Countdown in 25ms ticks - 3 seconds to idle
						fdc_motor_countdown <=  (40 * 3) / fdc_clk_div;
						fdc_motor_on <= '1';
					else 
						if clk_25ms='1' then
							fdc_motor_countdown <= fdc_motor_countdown - 1;
						end if;
					end if;
				when running => 	-- Motor running
					if(fdc_motor_countdown=0) then
						fdc_motor_state <= stopped;	-- idle timeout
						fdc_motor_on <= '0';
					else
						-- Reset on floppy select or new command received by fdv
						if(floppy_select_write='1' or fdc_new_command='1') then
							fdc_motor_countdown <= (40 * 3) / fdc_clk_div; -- reset countdown on select
						else
							if clk_25ms='1' then
								fdc_motor_countdown <= fdc_motor_countdown - 1;
							end if;
						end if;
					end if;
			end case;			
		end if;
	end if;
end process;

fdc : fdc1771
generic map (
	SYS_CLK => 42578000		-- sys_clk speed
)
port map
(
	clk_sys	=> clk42m,
	clk_cpu => cpuClk,
	clk_div => fdc_clk_div,

	floppy_drive => floppy_select,			-- ** Link up to drive select code
	floppy_side => '1',				-- Only single sided for now
	floppy_reset => not reset,
	motor_on => fdc_motor_on,

	irq => fdc_irq,					
	drq => fdc_drq,

	cpu_addr => cpua(1 downto 0),
	cpu_sel => fdc_sel2,	-- Calculated on falling edge of fdc_rd or fdc_wr signal
	cpu_rd => fdc_rd,
	cpu_wr => fdc_wr,
	cpu_din => fdc_din,
	cpu_dout => fdc_dout,

	-- The following signals are all passed in from the Top module
	img_mounted => img_mounted,
	img_wp => img_readonly,
	img_size => img_size,

	sd_lba => sd_lba,
	sd_rd => sd_rd,
	sd_wr => sd_wr,
	sd_ack => sd_ack,
	sd_buff_addr => sd_buff_addr,
	sd_dout => sd_buff_dout,
	sd_din => sd_buff_din,
	sd_dout_strobe => sd_dout_strobe,

	fdc_new_command => fdc_new_command,

	-- Debugging for overscan
	cmd_out => dbg_cmd,
	track_out => dbg_track,
	sector_out => dbg_sector,
	data_in_out => dbg_data_in,
	status_out => dbg_status

);

-- Generate main CPU Clock
process(clk42m)
begin
	if rising_edge(clk42m) then
		cpuClk <= '0';
		counter <= counter + 1;  -- debugging counter

		-- CPU clock divider
		if clk1774_div = "000000" then	-- count down rather than up, as overclock may change
			cpuClk     <= '1';
			
			if taperead = '1' then
				clk1774_div <= "000001"; 	--  12x speed = 21.36 (42MHz /  2)  --> override during tape read
				fdc_clk_div <= 12;  		
			elsif fdc_slow_latch = '1' then
				clk1774_div <= "010111"; 	--  1x speed = 21.36 (42MHz /  2)  
				fdc_clk_div <= 1;  			-- override during read if override enabled (port 254)
			else
				case overclock(1 downto 0) is
					when "00" => clk1774_div <= "010111";  --   1x speed =  1.78 (42MHz / 24)
					when "01" => clk1774_div <= "001011";  -- 	2x speed =  3.58 (42MHz / 12)
					when "10" => clk1774_div <= "000111";  --   3x speed =  5.34 (42MHz /  8)
					when "11" => clk1774_div <= "000001";  --  12x speed = 21.29 (42MHz /  2)
				end case;
				case overclock(1 downto 0) is
					when "00" => fdc_clk_div <= 1;  --   1x speed =  1.78 (42MHz / 24)
					when "01" => fdc_clk_div <= 2;  --   2x speed =  3.58 (42MHz / 12)
					when "10" => fdc_clk_div <= 3;  --   3x speed =  5.34 (42MHz /  8)
					when "11" => fdc_clk_div <= 12;  --  12x speed = 21.29 (42MHz /  2)
				end case;
			end if;
		else
			clk1774_div <= clk1774_div - 1;
		end if;
	end if;
end process;

ior <= cpurd or cpuiorq or (not cpum1);
iow <= cpuwr or cpuiorq;
memr <= cpurd or cpumreq;
memw <= cpuwr or cpumreq;

--romrd <= '1' when memr='0' and cpua<x"3780" else '0';
--ramrd <= '1' when cpua(15 downto 14)="01" and memr='0' else '0';
--ramwr <= '1' when cpua(15 downto 14)="01" and memw='0' else '0';
vramsel <= '1' when cpua(15 downto 10)="001111" and cpumreq='0' else '0';
kbdsel  <= '1' when cpua(15 downto 10)="001110" and memr='0' else '0';
iorrd <= '1' when ior='0' and (cpua(7 downto 0)=x"04" or cpua(7 downto 0)=x"ff") else '0'; -- in port $04 or $FF

fdc_din <= cpudo;
fdc_sel <= '1' when cpua(15 downto 2)="00110111111011" else '0';
fdc_rd <= not fdc_sel or memr;
fdc_wr <= not fdc_sel or memw;
fdc_sel2 <= (fdc_rd xor fdc_wr);
floppy_select_write <= '1' when cpua(15 downto 2)="00110111111000" and memw='0' else '0';
irq_latch_read <= '1' when cpua(15 downto 0)=x"37e0" and memr='0' else '0';
expansion_irq <= clk_25ms_latch and fdc_irq_latch;

-- Holmes Sprinter FDC override speed
process(clk42m, reset)
begin
	if reset='1' then
		fdc_slow_latch <= '0';
	else
		if rising_edge(clk42m) then
			if iow='0' and cpua(7 downto 0)=x"fe" then
				fdc_slow_latch <= not cpudo(0);
			end if;
		end if;
	end if;
end process;

process(clk42m, reset)
begin
	if reset='1' then
		floppy_select <= "1111";
	else
		if rising_edge(clk42m) then
			if(floppy_select_write='1') then
				floppy_select <= not cpudo(3 downto 0);
			end if;
		end if;
	end if;
end process;

cpu : entity work.T80pa
port map
(
	RESET_n => not reset,
	CLK     => clk42m, -- 1.75 MHz
	CEN_p   => GCLK,
	M1_n    => cpum1,
	INT_n	=> expansion_irq,
	MREQ_n  => cpumreq,
	IORQ_n  => cpuiorq,
	RD_n    => cpurd,
	WR_n    => cpuwr,
	A       => cpua,
	DI      => cpudi,
	DO      => cpudo,
--	REG		=> REG,
	DIR		=> DIR,
	DIRSet	=> DIRSet
);

cpudi <= vramdo when vramsel='1' else												-- RAM		($3C00-$3FFF)
		 kbdout when kbdsel='1' else	
		 fdc_dout when fdc_rd='0' else	
		 -- Floppy select and irq signals	
		 (not clk_25ms_latch) & fdc_irq & "000000" when irq_latch_read='1' else
  		 ram_b_dout when ior='0' and cpua(7 downto 0)=x"04" else			-- special case of system hack

         x"30"  when ior='0' and cpua(7 downto 0)=x"fd" else																-- printer io read

         "1111" & (not joy0(0)) & (not joy0(1)) & (not (joy0(2) or joy0(4))) & (not (joy0(3) or joy0(4)))	-- trisstick right, left, down, up
                when ior='0' and cpua(7 downto 0)=x"00" and joytype(1 downto 0) = "01" else						-- (BIG5 type; "fire" shows as "up+down")
         "111"  & (not joy0(4)) & (not joy0(0)) & (not joy0(1)) & (not joy0(2)) & (not joy0(3))					-- trisstick fire, right, left, down, up
                when ior='0' and cpua(7 downto 0)=x"00" and joytype(1 downto 0) = "10" else						-- (Alpha products type; separate fire bit)
         "11111111" when ior='0' and cpua(7 downto 0)=x"00" and joytype(1 downto 0) = "00" else					-- no joystick = empty port

         tapelatch & "111" & widemode & tapebits	when ior='0' and cpua(7 downto 0)=x"ff" else					-- cassette data
			
			x"ff"  when ior='0' else													-- all unassigned ports

         ram_b_dout;																		-- RAM

			
-- video ram at 0x3C00
video : entity work.videoctrl
port map
(
	reset => not reset,
	clk42 => clk42m,
	a => cpua(13 downto 0),
	din => cpudo,
	dout => vramdo,
	
	debug_enable => debug,			-- Enable to show disk debugging
	dbugmsg_addr => dbugmsg_addr,
	dbugmsg_data => dbugmsg_data,

	mreq => cpumreq,
	iorq => cpuiorq,
	wr => cpuwr,
	cs => not vramsel,
	rgbi => rgbi,
	ce_pix => ce_pix,
	inkp => '0', --inkpulse,
	paperp => '0', --paperpulse,
	borderp => '0', --borderpulse,
	widemode => widemode,
	lcasetype => lcasetype,
	overscan => overscan,
	flicker => flicker,
	hsync => hsync,
	vsync => vsync,
	hb => hblank,
	vb => vblank
);


--
-- setup debug output message
--
process(clk42m)
begin
	if rising_edge(clk42m) then

		-- override columns 14/15 to display hex for register reg_37ec:
		if (dbugmsg_addr = 15) then				-- drive select
			dbugmsg_data <= x"44";				-- D
		elsif (dbugmsg_addr = 16) then			
			if(floppy_select(0)='0') then		-- D0
				dbugmsg_data <= x"31";
			else
				dbugmsg_data <= x"30";
			end if;
		elsif (dbugmsg_addr = 17) then			-- D1
			if(floppy_select(1)='0') then
				dbugmsg_data <= x"31";
			else
				dbugmsg_data <= x"30";
			end if;
		elsif (dbugmsg_addr = 18) then			-- D2
			if(floppy_select(2)='0') then
				dbugmsg_data <= x"31";
			else
				dbugmsg_data <= x"30";
			end if;
		elsif (dbugmsg_addr = 19) then			-- D3
			if(floppy_select(3)='0') then
				dbugmsg_data <= x"31";
			else
				dbugmsg_data <= x"30";
			end if;
		elsif (dbugmsg_addr = 20) then							
			dbugmsg_data <= x"2c";				-- comma

		elsif (dbugmsg_addr = 21) then			-- command						
			dbugmsg_data <= x"43";				-- C
		elsif (dbugmsg_addr = 22) then			
			dbugmsg_data <= hex(conv_integer(dbg_cmd(7 downto 4)));
		elsif (dbugmsg_addr = 23) then							
			dbugmsg_data <= hex(conv_integer(dbg_cmd(3 downto 0)));
		elsif (dbugmsg_addr = 24) then							
			dbugmsg_data <= x"2c";				-- comma

		elsif (dbugmsg_addr = 25) then			-- track						
			dbugmsg_data <= x"54";				-- T
		elsif (dbugmsg_addr = 26) then			
			dbugmsg_data <= hex(conv_integer(dbg_track(7 downto 4)));
		elsif (dbugmsg_addr = 27) then							
			dbugmsg_data <= hex(conv_integer(dbg_track(3 downto 0)));
		elsif (dbugmsg_addr = 28) then							
			dbugmsg_data <= x"2c";				-- comma

		elsif (dbugmsg_addr = 29) then			-- sector
			dbugmsg_data <= x"53";				-- S
		elsif (dbugmsg_addr = 30) then			
			dbugmsg_data <= hex(conv_integer(dbg_sector(7 downto 4)));
		elsif (dbugmsg_addr = 31) then							
			dbugmsg_data <= hex(conv_integer(dbg_sector(3 downto 0)));
		elsif (dbugmsg_addr = 32) then							
			dbugmsg_data <= x"2c";				-- comma

		elsif (dbugmsg_addr = 33) then			-- data written
			dbugmsg_data <= x"64";				-- d
		elsif (dbugmsg_addr = 34) then			
			dbugmsg_data <= hex(conv_integer(dbg_data_in(7 downto 4)));
		elsif (dbugmsg_addr = 35) then							
			dbugmsg_data <= hex(conv_integer(dbg_data_in(3 downto 0)));
		elsif (dbugmsg_addr = 36) then							
			dbugmsg_data <= x"2c";				-- comma

		elsif (dbugmsg_addr = 37) then			-- status
			dbugmsg_data <= x"73";				-- s
		elsif (dbugmsg_addr = 38) then			-- status
			dbugmsg_data <= hex(conv_integer(dbg_status(7 downto 4)));
		elsif (dbugmsg_addr = 39) then							
			dbugmsg_data <= hex(conv_integer(dbg_status(3 downto 0)));

		elsif (dbugmsg_addr = 41) then			-- Tick Counter (after space)
			if(tick_1s='0') then
				dbugmsg_data <= x"20";
			else
				dbugmsg_data <= x"2a";
			end if;

		--
		-- otherwise split the remainder: first half just reads from the default text buffer,
		-- and second half is a calculated value based on position
		--
		elsif (dbugmsg_addr < 32) then							-- 1st half from string literal
			dbugmsg_data <= msgbuf(conv_integer( dbugmsg_addr ));
		else
			dbugmsg_data <=  x"20";			-- spaces
		end if;
		
	end if;
end process;

kbdpar : keyboard
port map
(
	reset	=> reset,
	clk_sys => clk42m,

	ps2_key => ps2_key,
	addr	=> cpua(7 downto 0),
	key_data => kbdout,
	kblayout => kybdlayout

	--Fn => Fn(11 downto 1),
	--modif => modif
);

-- PSG
-- (note: must be unique to the HT1080Z, as TRS-80 did not have this)
-- out 1e = data port
-- out 1f = register index

soundchip : ym2149
port map
(
	DI        => cpudo,

	BDIR      => sndBDIR,
	BC        => sndBC1,
	SEL       => '1',
	MODE      => '0',

	CHANNEL_A => ch_a,
	CHANNEL_B => ch_b,
	CHANNEL_C => ch_c,

	IOA_in    => (others => '1'),
	IOB_in    => (others => '1'),

	CE        => cpuClk,
	RESET     => reset,
	CLK       => clk42m
);

audio <= ("00" & ch_a) + ("00" & ch_b) + ("00" & ch_c) + ("00" & speaker);
audiomix <= audio(9 downto 1);

sndBDIR <= '1' when cpua(7 downto 1)="0001111" and iow='0' else '0';
sndBC1  <= cpua(0);

with tapebits(1 downto 0) select speaker <=
	"01000000" when "01",
	"00100000" when "00"|"11",
	"00000000" when others;

-- Note: format of colors below is 6 bits each of: BGR, not RGB

with rgbi select ht_rgb_white <=
	"000000000000000000" when "0000",
	"000000000000100000" when "0001",
	"000000100000000000" when "0010",
	"000000100000100000" when "0011",
	"100000000000000000" when "0100",
	"100000000000100000" when "0101",
	"110000011000000000" when "0110",
	"100000100000100000" when "0111",
	"110111111111111111" when "1000", -- P4 Phosphor 81ff00 + 7e00db = ffffdb
	"000000000000111100" when "1001",
	"000000111100000000" when "1010",
	"000000111100111100" when "1011",
	"111110000000000000" when "1100",
	"111100000000111100" when "1101",
	"111110111110000000" when "1110",
	"111110111110111110" when others;

with rgbi select ht_rgb_green <=
	"000000000000000000" when "0000",
	"000000000000000000" when "0001",
	"000000100000000000" when "0010",
	"000000100000000000" when "0011",
	"000000000000000000" when "0100",
	"000000000000000000" when "0101",
	"000000011000000000" when "0110",
	"000000100000000000" when "0111",
	"001101111111001101" when "1000", -- P1 Phosphor RGB #33FF33
	"000000000000000000" when "1001",
	"000000111100000000" when "1010",
	"000000000000100000" when "1011",
	"000000000000000000" when "1100",
	"000000000000000000" when "1101",
	"000000111110000000" when "1110",
	"000000111110000000" when others;

with rgbi select ht_rgb_amber <=
	"000000000000000000" when "0000",
	"000000000000100000" when "0001",
	"000000010000000000" when "0010",
	"000000010000100000" when "0011",
	"000000000000000000" when "0100",
	"000000000000100000" when "0101",
	"000000001100000000" when "0110",
	"000000010000100000" when "0111",
	"000000101100111111" when "1000",	-- P3 Phosphor RGB #FFBB00
	"000000000000111100" when "1001",
	"000000011110000000" when "1010",
	"000000011110111100" when "1011",
	"000000000000000000" when "1100",
	"000000000000111100" when "1101",
	"000000011111000000" when "1110",
	"000000011111111110" when others;


RGB <=
	ht_rgb_white when disp_color = "00" else
	ht_rgb_green when disp_color = "01" else
	ht_rgb_amber when disp_color = "10" else
	"111110111110111110";

main_mem : dpram
generic map (
	DATA => 8,
	ADDR => 17
)
port map
(
	-- Port A - used for system data load, cassette data load, and cassette readback - which won't normally happen simultaneously
	a_clk  => dn_clk,
	a_wr   => dn_wr,
	a_addr => ram_a_addr,
	a_din  => dn_data,
	a_dout => ram_a_dout,

	-- Port B - used for CPU access
	b_clk  => clk42m,
	b_wr   => ((not memw) and (cpua(15) or cpua(14))),
	b_addr => ram_b_addr,
	b_din  => cpudo,
	b_dout => ram_b_dout
);

ram_a_addr <= dn_addr(16 downto 0) when dn_wr = '1' else io_ram_addr(16 downto 0);
ram_b_addr <= io_ram_addr(16 downto 0) when iorrd='1' else ('0' & cpua);

process (clk42m,dn_go,loader_download,reset)
begin
	if (dn_go='1' and loader_download='0') or reset='1' then
		io_ram_addr <= x"010000"; -- above 64k
		iorrd_r<='0';

		tapebits<="000";
		tape_cyccnt <= x"000";
--		tape_leadin <= x"00";
		tape_bitptr <= 7;
		tapelatch <='0';
--		tapelatch_resetcnt <="0000";
		
	else
		if rising_edge(clk42m) then
			cpuClk_r <= cpuClk;

			if (cpuClk_r /= cpuClk) and cpuClk='1' then
			
				------  Extended memory 'hack' (covers ports 4/5/6) ------
				--
				-- Note:
				-- The original MiSTer port of HT1080Z placed cassette data at memory address 0x10000,
				-- beyond accessibility of the CPU.  It created port-based access to this data
				-- **WHICH NEVER EXISTED ON THE ORIGINAL MACHINE**
				-- ...in order to speed up data transfer from the cassette (normally 500 baud).
				--
				-- To use this, it required a hacked version of the boot ROM, accessing these ports
				-- ports instead of the original cassette data.

				if iow='0' and cpua(7 downto 2)="000001" then							-- write to port 4 5 6
					case cpua(1 downto 0) is
						when "00"=> io_ram_addr(7 downto 0) <= cpudo;					-- sets address of memory-read pointer
						when "01"=> io_ram_addr(15 downto 8) <= cpudo;
						when "10"=> io_ram_addr(23 downto 16) <= cpudo;
						when others => null;
					end case;
				end if;

				iorrd_r<=iorrd;
				if iorrd='0' and iorrd_r='1' and cpua(7 downto 2)="000001" then	-- read from port 4 reads memory directly
					io_ram_addr <= io_ram_addr + 1;
				end if;

				
				------  Cassette data I/O (covers port $FF) ------
				--
				-- Added in order to support regular/original BIOS ROMs.
				-- Synthesizes the cassette data from .CAS files; doesn't yet accept audio files as input.
				-- Since loading a 13KB fie takes several minutes at regular speed, this version automatically
				-- sets CPU to top speed on input.
				--
				if iow='0' and cpua(7 downto 0)=x"ff" then	-- write to tape port

					if ((tapemotor = '0') and (cpudo(2) = '1')) then		-- if start motor, then reset pointer
						io_ram_addr <= x"010000";
						tape_bitptr <= 7;
						taperead <= '0';
						
					elsif ((tapemotor = '1') and (cpudo(2) = '0')) then	-- if stop motor, then reset tape read status
						taperead <= '0';
					end if;

					tapebits <= cpudo(2 downto 0);
					widemode <= cpudo(3);
					tapelatch <= '0';									-- tapelatch is set by cassette data bit, and only reset by write to port $FF
				end if;

				if ior='0' and cpua(7 downto 0)=x"ff" then
					if tapemotor='1' and taperead='0' then		-- reading the port while motor is on implies tape playback
						taperead <= '1';
						tape_cyccnt <= x"000";
--						tape_leadin <= x"00";
					end if;
				end if;

				if (taperead = '1') then
					tape_cyccnt <= tape_cyccnt + 1;				-- count in *CPU* cycles, regardless of clock speed
					
					if tape_cyccnt < x"200" then					-- fixed-timing sync clock bit - hold the signal high for a bit
						tapelatch <= '1';								-- DO NOT reset the latch until port is read
						-- uncomment the following line when debugging cassette input:
						--tapebits(1 downto 0) <= "01";	-- ** remove when working
					end if;
					
					if tape_cyccnt = x"6ff" then					-- after 1791 cycles (~1ms @ normal clk), actual data bit is written only if it's a '1'
																			-- timing reverse-engineered from Level II ROM cassette write routine

						tapebit_val <= ram_a_dout(tape_bitptr);

						-- uncomment the following lines when debugging cassette input:
						--if ram_a_dout(tape_bitptr) = '1' then		-- ** make a noise
						--	tapebits(1 downto 0) <= "01";				-- ** remove when working
						--end if;												-- **
							
						if tape_bitptr = 0 then
							io_ram_addr <= io_ram_addr + 1;
							tape_bitptr <= 7;
						else
							tape_bitptr <= tape_bitptr - 1;
						end if;

					end if;
					
					if tape_cyccnt > x"6ff" and tape_cyccnt < x"8ff" then

						if tapebit_val = '1' then					-- if set, hold it for 200 cycles like a real tape
							tapelatch <= '1';							-- DO NOT reset the latch if '0'
							-- uncomment the following line when debugging cassette input:
							--tapebits(1 downto 0) <= "01";			-- ** make a noise  ** remove when working
						end if;
					end if;
					
					if tape_cyccnt >= x"e08" then					-- after 3582 cycles (~2ms), sync signal is written (and cycle reset)
						tape_cyccnt <= x"000";
					end if;
					
				end if;

			end if;
		end if;
	end if;
end process;

end Behavioral;
