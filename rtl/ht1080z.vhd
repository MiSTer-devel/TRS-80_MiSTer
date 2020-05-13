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

entity ht1080z is
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

	dn_clk     : in  std_logic;
	dn_go      : in  std_logic;
	dn_wr      : in  std_logic;
	dn_addr    : in  std_logic_vector(24 downto 0);
	dn_data    : in  std_logic_vector(7 downto 0)
);
end ht1080z;

architecture Behavioral of ht1080z is

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

signal rgbi : std_logic_vector(3 downto 0);
signal vramdo,kbdout : std_logic_vector(7 downto 0);

signal Fn : std_logic_vector(11 downto 0);
signal modif : std_logic_vector(2 downto 0);

signal romrd,ramrd,ramwr,vramsel,kbdsel : std_logic;
signal ior,iow,memr,memw : std_logic;


-- 0  1  2 3   4
-- 28 14 7 3.5 1.75
signal clk1774_div : std_logic_vector(5 downto 0) := "010111";

signal sndBC1,sndBDIR,sndCLK : std_logic;

signal ht_rgb_white	: std_logic_vector(17 downto 0);
signal ht_rgb_green	: std_logic_vector(17 downto 0);
signal ht_rgb_amber	: std_logic_vector(17 downto 0);

signal io_ram_addr	: std_logic_vector(23 downto 0);
signal iorrd,iorrd_r	: std_logic;

signal tapebits		: std_logic_vector(2 downto 0);		-- motor on/off, plus two bits for output signal level
alias  tapemotor		: std_logic is tapebits(2);

signal taperead		: std_logic := '0';						-- only when motor is on, 0 = write, 1 = read
signal tape_cyccnt	: std_logic_vector(11 downto 0);		-- CPU cycle counter for cassette carrier signal
signal tape_leadin	: std_logic_vector(7 downto 0);		-- additional 128 bits for sync-up, just in case
signal tape_bitptr	: natural := 7;

signal tapebit_val	: std_logic := '0';						-- represents bit being sent from cassette file
signal tapelatch		: std_logic := '0';						-- represents input bit from cassette (after signal conditioning)
signal tapelatch_resetcnt	: std_logic_vector(3 downto 0) := "0000";	-- when port is read, reset value - but only after a few cycles

signal speaker : std_logic_vector(7 downto 0);

signal inkpulse, paperpulse, borderpulse : std_logic;
signal widemode : std_logic := '0';

begin

led <= taperead;

process(clk42m)
begin
	if rising_edge(clk42m) then
		cpuClk <= '0';

		-- CPU clock divider
		if clk1774_div = "000000" then	-- count down rather than up, as overclock may change
			cpuClk     <= '1';
			
			if taperead = '1' then
				clk1774_div <= "000001";  --  12x speed = 21.36 (42MHz /  2)  --> override during tape read
			else
				case overclock(1 downto 0) is
					when "00" => clk1774_div <= "010111";  --   1x speed =  1.78 (42MHz / 24)
					when "01" => clk1774_div <= "010001";  -- 1.5x speed =  2.67 (42MHz / 18)
					when "10" => clk1774_div <= "001011";  --   2x speed =  3.58 (42MHz / 12)
					when "11" => clk1774_div <= "000001";  --  12x speed = 21.36 (42MHz /  2)
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

cpu : entity work.T80s
port map
(
	RESET_n => not reset,
	CLK     => clk42m, -- 1.75 MHz
	CEN     => cpuClk,
	M1_n    => cpum1,
	MREQ_n  => cpumreq,
	IORQ_n  => cpuiorq,
	RD_n    => cpurd,
	WR_n    => cpuwr,
	A       => cpua,
	DI      => cpudi,
	DO      => cpudo
);

cpudi <= vramdo when vramsel='1' else												-- RAM		($3C00-$3FFF)
         kbdout when kbdsel='1' else												-- keyboard ($3800-$3BFF)
			
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
	hsync => hsync,
	vsync => vsync,
	hb => hblank,
	vb => vblank
);

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
	"110000110000110000" when "1000",
	"000000000000111100" when "1001",
	"000000111100000000" when "1010",
	"000000111100111100" when "1011",
	"111110000000000000" when "1100",
	"111100000000111100" when "1101",
	"111110111110000000" when "1110",
	"111110111110111110" when others;


RGB <=
	ht_rgb_white when disp_color = "00" else
	"000000"  & ht_rgb_white(11 downto 6) & "000000" when disp_color = "01" else						-- Green = zero out R and B channels
	"0000000" & ht_rgb_white(11 downto 7) & ht_rgb_white(5 downto 0) when disp_color = "10" else -- Amber = full red amount but only half green
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

process (clk42m,dn_go,reset)
begin
	if dn_go='1' or reset='1' then
		io_ram_addr <= x"010000"; -- above 64k
		iorrd_r<='0';

		tapebits<="000";
		tape_cyccnt <= x"000";
		tape_leadin <= x"00";
		tape_bitptr <= 7;
		tapelatch <='0';
		tapelatch_resetcnt <="0000";
		
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
						tape_leadin <= x"00";
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
