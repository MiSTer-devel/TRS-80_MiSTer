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

    reset : in std_logic;

    -- osd status bits
    status:in  std_logic_vector(7 downto 0);

    -- clocks
    clk86M : in  STD_LOGIC;
    clk42m : in  STD_LOGIC;
    clk_download : in std_logic;
    plllocked: in STD_LOGIC;


    -- SPI interface to arm io controller
    SPI_DO	: out std_logic;
    SPI_DI	: in  std_logic;
    SPI_SCK	: in  std_logic;
    SPI_SS2	: in  std_logic;
    SPI_SS3	: in  std_logic;
    SPI_SS4	: in  std_logic;

    CONF_DATA0  : in  std_logic;

    RGB : out  STD_LOGIC_VECTOR (17 downto 0);
    HSYNC : out  STD_LOGIC;
    VSYNC : out  STD_LOGIC;
    hblank : out  STD_LOGIC;
    vblank : out  STD_LOGIC;

    LED : out  STD_LOGIC;

    audiomix: out STD_LOGIC_VECTOR(8 downto 0);


    joy0 : in std_logic_vector(7 downto 0);
    joy1 : in std_logic_vector(7 downto 0);

	 ps2_key_parallel : in STD_LOGIC_VECTOR(10 downto 0);
	 
    kybdlayout : in  STD_LOGIC;
    disp_color : in std_logic_vector(1 downto 0);
    lcasetype  : in STD_LOGIC;

    pixel_clock: out STD_LOGIC;

    dn_go : in std_logic;
    dn_wr : in std_logic;
    dn_addr : in std_logic_vector(24 downto 0);
    dn_data : in std_logic_vector(7 downto 0);
    dn_idx : in std_logic_vector(7 downto 0)


    );
end ht1080z;

architecture Behavioral of ht1080z is

  component data_io
    port ( sck, ss, sdi         :	in std_logic;

           -- download info
           downloading          :  out std_logic;
           --size				:  out std_logic_vector(24 downto 0);
           index				:  out std_logic_vector(4 downto 0);

           -- external ram interface
           clk				:	in std_logic;
           wr					:  out std_logic;
           addr                         :  out std_logic_vector(24 downto 0);
           data				:  out std_logic_vector(7 downto 0)
           );
  end component data_io;



  component dpram is
    generic (
      DATA : integer;
      ADDR : integer
      );
    port (
      -- Port A
      a_clk : in std_logic;
      a_wr : in std_logic;
      a_addr : in std_logic_vector(ADDR-1 downto 0);
      a_din : in std_logic_vector(DATA-1 downto 0);
      a_dout : out std_logic_vector(DATA-1 downto 0);

      -- Port B
      b_clk : in std_logic;
      b_wr : in std_logic;
      b_addr : in std_logic_vector(ADDR-1 downto 0);
      b_din : in std_logic_vector(DATA-1 downto 0);
      b_dout : out std_logic_vector(DATA-1 downto 0)
      );
  end component dpram;

  component keyboard is
    port  (
      reset		: in std_logic;
      clk_sys	: in std_logic;

      ps2_key	: in std_logic_vector(10 downto 0);
		addr		: in std_logic_vector(7 downto 0);
		key_data	: out std_logic_vector(7 downto 0);
      kblayout	: in std_logic;

		Fn			: out std_logic_vector(11 downto 1);
		modif		: out std_logic_vector(2 downto 0)
      );
	end component keyboard;

--component osd
--  generic ( OSD_COLOR : integer );
  -- port ( pclk                        : in std_logic;
--		sck, sdi, ss    : in std_logic;

  -- VGA signals coming from core
  --    red_in                  : in std_logic_vector(5 downto 0);
  --    green_in                : in std_logic_vector(5 downto 0);
  --    blue_in                         : in std_logic_vector(5 downto 0);
  --    hs_in                   : in std_logic;
  --    vs_in                   : in std_logic;

  -- VGA signals going to video connector
  --   red_out                  : out std_logic_vector(5 downto 0);
  --   green_out                : out std_logic_vector(5 downto 0);
  --   blue_out                 : out std_logic_vector(5 downto 0);
  --   hs_out                   : out std_logic;
  --   vs_out                   : out std_logic
  --);
--end component osd;

--component user_io
  --   generic ( STRLEN : integer := 0 );
  --    port (
  -- ps2 interface
  --		SPI_CLK, SPI_SS_IO, SPI_MOSI :in std_logic;
  --     SPI_MISO : out std_logic;
  --      conf_str : in std_logic_vector(8*STRLEN-1 downto 0);
  --       joystick_0 : out std_logic_vector(7 downto 0);
  --        joystick_1 : out std_logic_vector(7 downto 0);
--			status: out std_logic_vector(7 downto 0);
--			ps2_clk        : in std_LOGIC;
--			ps2_kbd_clk    : out std_logic;
--			ps2_kbd_data   : out std_logic;
--			ps2_mouse_clk  : out std_logic;
--			ps2_mouse_data : out std_logic;
--			scandoubler_disable : out std_logic
  --     );
--end component user_io;


  function to_slv(s: string) return std_logic_vector is
    constant ss: string(1 to s'length) := s;
    variable rval: std_logic_vector(1 to 8 * s'length);
    variable p: integer;
    variable c: integer;

  begin
    for i in ss'range loop
      p := 8 * i;
      c := character'pos(ss(i));
      rval(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
    end loop;
    return rval;

  end function;

  attribute keep: boolean;

  signal ram_addr : std_logic_vector(16 downto 0);
  signal ram_din : STD_LOGIC_VECTOR(7 downto 0);
  signal ram_dout : STD_LOGIC_VECTOR(7 downto 0);
  signal ram_we: std_logic;
  signal ram_oe: std_logic;


--signal   dn_go : std_logic;
--signal   dn_wr : std_logic;
--signal dn_addr : std_logic_vector(24 downto 0);
--signal dn_data : std_logic_vector(7 downto 0);
--signal  dn_idx : std_logic_vector(4 downto 0);

  signal   dn_wr_r : std_logic;
  signal dn_addr_r : std_logic_vector(24 downto 0);
  signal dn_data_r : std_logic_vector(7 downto 0);

  signal res_cnt : std_logic_vector(5 downto 0) := "111111";
  signal autores : std_logic;


  signal pvsel : std_logic;

  signal MPS2CLK : std_logic;
  signal MPS2DAT : std_logic;

--signal joy0 : std_logic_vector(7 downto 0);
--signal joy1 : std_logic_vector(7 downto 0);

--signal status: std_logic_vector(7 downto 0);

--signal clk56m : std_logic;
--signal clk42m,
  signal clk21m,clk7m : std_logic;
  attribute keep of clk21m: signal is true;
  attribute keep of clk7m: signal is true;

--signal pllLocked : std_logic;

  signal cpua     : std_logic_vector(15 downto 0);
  signal cpudo    : std_logic_vector(7 downto 0);
  signal cpudi    : std_logic_vector(7 downto 0);
  signal cpuwr,cpurd,cpumreq,cpuiorq,cpunmi,cpuint,cpum1,cpuclk,cpuClkEn : std_logic;

  signal rgbi : std_logic_vector(3 downto 0);
  signal hs,vs : std_logic;
  signal romdo,vramdo,ramdo,ramHdo,kbdout : std_logic_vector(7 downto 0);
  signal vramcs : std_logic;

  signal Fn : std_logic_vector(11 downto 0);
  signal modif : std_logic_vector(2 downto 0);

  signal page,vcut,swres : std_logic;

  signal romrd,ramrd,ramwr,vramsel,kbdsel : std_logic;
  signal ior,iow,memr,memw : std_logic;
  signal vdata : std_logic_vector(7 downto 0);


-- 0  1  2 3   4
-- 28 14 7 3.5 1.75
  signal clk1774_div : std_logic_vector(5 downto 0);
  signal clk7_div : std_logic_vector(3 downto 0);

  signal sndBC1,sndBDIR,sndCLK : std_logic;
  signal oaudio,snddo : std_logic_vector(7 downto 0);

  signal ht_rgb_white : std_logic_vector(17 downto 0);
  signal ht_rgb_green : std_logic_vector(17 downto 0);
  signal ht_rgb_amber : std_logic_vector(17 downto 0);

  signal ht_rgb : std_logic_vector(17 downto 0);

  signal out_rgb : std_logic_vector(17 downto 0);
  signal p_hs,p_vs,vgahs,vgavs : std_logic;
  signal pclk : std_logic;

  signal io_ram_addr : std_logic_vector(23 downto 0);
  signal iorrd,iorrd_r : std_logic;

--signal audiomix : std_logic_vector(8 downto 0);
  signal tapebits : std_logic_vector(2 downto 0);
  alias tapemotor : std_logic is tapebits(2);

  signal  speaker : std_logic_vector(7 downto 0);
  signal vga : std_logic := '1';
  signal scanlines : std_logic;
  signal oddline : std_logic;

  signal inkpulse, paperpulse, borderpulse : std_logic;
  signal widemode : std_logic := '0';

begin

  led <= tapemotor; -- not scanlines; --not dn_go;--swres;

  -- generate system clocks
  --clkmgr : entity work.pll
  -- port map (
--        inclk0 => CLK27M,
--        c0 => clk56M,
--        c1 => SDRAM_CLK,
--        c2 => clk42m,
--        locked => pllLocked
--	);


  process(clk42m)
  begin
    if rising_edge(clk42m) then
      clk7m <= '0';
      cpuClk <= '0';
      --if clk1774_div = 48 then
      --if clk1774_div = "110000" then
      if clk1774_div = "010111" then
        cpuClk     <= '1';
        clk1774_div <= "000000";
      else
        clk1774_div <= clk1774_div + 1;
      end if;
		
      --if clk7_div = 12 then
      --if clk7_div = "0110" then
      if clk7_div = "0101" then
        clk7m    <= '1';
        clk7_div <= "0000";
      else
        clk7_div <= clk7_div + 1;
      end if;
    end if;
  end process;
  --clk7m <= clk56div(2);
  --ps2clkout  <= clk56div(11);

  ior <= cpurd or cpuiorq or (not cpum1);
  iow <= cpuwr or cpuiorq;
  memr <= cpurd or cpumreq;
  memw <= cpuwr or cpumreq;

  romrd <= '1' when memr='0' and cpua<x"3780" else '0';
  ramrd <= '1' when cpua(15 downto 14)="01" and memr='0' else '0';
  ramwr <= '1' when cpua(15 downto 14)="01" and memw='0' else '0';
  vramsel <= '1' when cpua(15 downto 10)="001111" and cpumreq='0' else '0';
  kbdsel  <= '1' when cpua(15 downto 10)="001110" and memr='0' else '0';
  iorrd <= '1' when ior='0' and cpua(7 downto 0)=x"04" else '0'; -- in 04

  --cpuClk <= clk56div(4);
  --clk_download <= clk56div(3);

  cpu : entity work.T80se
    port map (
      RESET_n => autores, --swres,
      CLK_n   => clk42m, -- 1.75 MHz
      CLKEN   => cpuClkEn,
      WAIT_n  => '1',
      INT_n   => '1',
      NMI_n   => '1',
      BUSRQ_n => '1',
      M1_n    => cpum1,
      MREQ_n  => cpumreq,
      IORQ_n  => cpuiorq,
      RD_n    => cpurd,
      WR_n    => cpuwr,
      RFSH_n  => open,
      HALT_n  => open,
      BUSAK_n => open,
      A       => cpua,
      DI      => cpudi,
      DO      => cpudo
      );

  cpudi <= --romdo when romrd='1' else
           --ramdo when ramrd='1' else
           --ram_dout when romrd='1' else
           --ram_dout when ramrd='1' else
           vramdo when vramsel='1' else
           kbdout when kbdsel='1' else
           x"30" when ior='0' and cpua(7 downto 0)=x"fd" else -- printer io read
           --ram_dout when iorrd='1' else
           --x"ff";
           ram_dout;

  pvsel <='0' ;
  vga <= not pvsel;
--  vdata <= cpudo when cpudo>x"1f" else cpudo or x"40";	-- This forces video memory to uppercase values when written to by values < 0x20
  vdata <= cpudo;

  -- video ram at 0x3C00
  video : entity work.videoctrl
    port map (
      reset => autores, --swres and pllLocked,
      clk42 => clk42m,
      -- clk7 => clk7m,
      a => cpua(13 downto 0),
      din => vdata,--cpudo,
      dout => vramdo,
      mreq => cpumreq,
      iorq => cpuiorq,
      wr => cpuwr,
      cs => not vramsel,
      vcut => vcut,
      --vvga => vga,
      page => page,
      rgbi => rgbi,
      pclk => pclk,
      inkp => inkpulse,
      paperp => paperpulse,
      borderp => borderpulse,
      widemode => widemode,
      lcasetype => lcasetype,
      oddline => oddline,
      hsync => hs,
      vsync => vs,
      hb => hblank,
      vb => vblank
      );

  pixel_clock<=pclk;

  hsync <= hs when vga='1' else hs xor (not vs);
  vsync <= vs when vga='1' else '1';
--  hsync <= hs xor (not vs);
--  vsync <= '1';


  kbdpar : keyboard
    port  map (
      reset	=> not autores,
      clk_sys => clk_download,

      ps2_key => ps2_key_parallel,
		addr	=> cpua(7 downto 0),
		key_data => kbdout,
      kblayout => kybdlayout,

		Fn => Fn(11 downto 1),
		modif => modif
      );

  -- PSG
  -- out 1e = data port
  -- out 1f = register index

  soundchip : entity work.YM2149
    port map (
      -- data bus
      I_DA      => cpudo,
      O_DA      => open,
      O_DA_OE_L => open,
      -- control
      I_A9_L    => '0',
      I_A8      => '1',
      I_BDIR    => sndBDIR,
      I_BC2     => '1',
      I_BC1     => sndBC1,
      I_SEL_L   => '1',

      O_AUDIO   => oaudio,
      -- port a
      I_IOA      => "ZZZZZZZZ",
      O_IOA      => open,
      O_IOA_OE_L => open,
      -- port b
      I_IOB      => "ZZZZZZZZ",
      O_IOB      => open,
      O_IOB_OE_L => open,
      --
      ENA        => cpuClk,
      RESET_L    => autores,--swres and pllLocked,
      CLK        => clk42m
      );
  sndBDIR <= '1' when cpua(7 downto 1)="0001111" and iow='0' else '0';
  sndBC1  <= cpua(0);

  with tapebits select speaker <=
    "01000000" when "001",
    "00100000" when "000"|"011",
    "00000000" when others;

  audiomix <= ('0' & oaudio) + ('0' & speaker);


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

  with rgbi select ht_rgb_green <=
    "000000000000000000" when "0000",
    "000000000000000000" when "0001",
    "000000100000000000" when "0010",
    "000000100000000000" when "0011",
    "000000000000000000" when "0100",
    "000000000000000000" when "0101",
    "000000011000000000" when "0110",
    "000000100000000000" when "0111",
    "000000110000000000" when "1000",
    "000000000000000000" when "1001",
    "000000111100000000" when "1010",
    "000000111100000000" when "1011",
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
    "000000011000110000" when "1000",
    "000000000000111100" when "1001",
    "000000011110000000" when "1010",
    "000000011110111100" when "1011",
    "000000000000000000" when "1100",
    "000000000000111100" when "1101",
    "000000011111000000" when "1110",
    "000000011111111110" when others;


  ht_rgb <=
    ht_rgb_white when disp_color = "00" else
    ht_rgb_green when disp_color = "01" else
    ht_rgb_amber when disp_color = "10" else
    "111110111110111110";


  scanlines <= status(1) and vga and oddline;

--  userio: user_io
--   generic map (STRLEN => CONF_STR'length)
-- -  port map (

--         conf_str => to_slv(CONF_STR),
--
--		SPI_CLK   => SPI_SCK    ,
  --     SPI_SS_IO => CONF_DATA0 ,
  --    SPI_MISO  => SPI_DO     ,
  --    SPI_MOSI  => SPI_DI     ,

--		status     => status     ,

  -- ps2 interface
--		ps2_clk        => ps2clkout,
--		ps2_kbd_clk    => ps2CLK,
--		ps2_kbd_data   => ps2DAT,
--		ps2_mouse_clk  => mps2CLK,
--		ps2_mouse_data => mps2DAT,

--		joystick_0 => joy0,
  --     joystick_1 => joy1,

--		scandoubler_disable => pvsel
--	);

--osd_d : osd
--	generic map (OSD_COLOR => 6)
--	port map (
--		pclk => pclk,
  --     sck => SPI_SCK,
  --     ss => SPI_SS3,
  --    sdi => SPI_DI,

  --   red_in => ht_rgb(5 downto 0),
  --  green_in => ht_rgb(11 downto 6),
  --     blue_in => ht_rgb(17 downto 12),
  ---     hs_in => hs,
  --     vs_in => vs,

  --     red_out => out_RGB(17 downto 12),
  --     green_out => out_RGB(11 downto 6),
  --     blue_out => out_RGB(5 downto 0),
--		hs_out => open, --HSYNC,
--		vs_out => open --VSYNC
--);
  out_RGB<=ht_rgb;


  RGB(17 downto 12) <= out_RGB(17 downto 12) when scanlines='0' else "0" & out_RGB(17 downto 13);
  RGB(11 downto  6) <= out_RGB(11 downto  6) when scanlines='0' else "0" & out_RGB(11 downto  7);
  RGB( 5 downto  0) <= out_RGB( 5 downto  0) when scanlines='0' else "0" & out_RGB( 5 downto  1);


  main_mem : dpram
    generic map (
      DATA => 8,
      ADDR => 17
      )
    port map (
      -- Port A
      a_clk  => clk42m,
      a_wr   => dn_wr_r and dn_go,
      a_addr => dn_addr_r(16 downto 0),
      a_din  => dn_data_r,
      a_dout => open,

      -- Port B
      b_clk  => clk42m,
      b_wr   => ram_we,
      b_addr => ram_addr,
      b_din  => cpudo,
      b_dout => ram_dout
      );

    --ram_addr <= "000000000" & cpua when dn_go='0' else dn_addr_r;

  ram_din <= cpudo when dn_go='0' else dn_data_r;
  --ram_we <= ((not memw) and (cpua(15) or cpua(14))) when dn_go='0' else dn_wr_r;
  ram_we <= ((not memw) and (cpua(15) or cpua(14))) and not dn_go and cpuClkEn;
  --ram_addr <= io_ram_addr(16 downto 0) when iorrd='1' else ('0' & cpua) when dn_go='0' else dn_addr_r(16 downto 0);
  ram_addr <= io_ram_addr(16 downto 0) when iorrd='1' else ('0' & cpua) when dn_go='0' else dn_addr_r(16 downto 0);
  ram_oe <= '1' when iorrd='1' else not memr when dn_go='0' else '0';


  -- dataio : data_io
  --   port map (
--         sck  =>      SPI_SCK,
--		ss    =>        SPI_SS2,
--		sdi	=>		SPI_DI,

--		downloading => dn_go,
  --size        => ioctl_size,
--		index       => dn_idx,

  -- ram interface
--		clk     =>      clk_download, -- ???
--		wr    =>    dn_wr,
--		addr  =>		dn_addr,
--		data  =>		dn_data
--       );



  process(clk_download)
  begin
    if rising_edge(clk_download) then
      if dn_wr='1' then
        dn_wr_r <= '1';
        dn_data_r <= dn_data;
        dn_addr_r <= dn_addr;
      else
        dn_wr_r <= '0';
      end if;
    end if;
  end process;


  process (clk42m)
  begin
    if rising_edge(clk42m) then
      if cpuClk='1' then
        --if pllLocked='0' or status(0)='1' or status(2)='1' then
        if pllLocked='0' or reset='1' then
          res_cnt <= "000000";
        else
          if (res_cnt/="111111") then
            res_cnt <= res_cnt+1;
          end if;
        end if;
      end if;
    end if;
  end process;

  cpuClkEn <= cpuClk and not dn_go;
  autores <= '1' when res_cnt="111111" else '0';


  process (clk42m,dn_go,autores)
  begin
    if dn_go='1' or autores='0' then
      io_ram_addr <= x"010000"; -- above 64k
      iorrd_r<='0';
    else
      if rising_edge(clk42m) then
        if cpuClk='1' then
          if iow='0' and cpua(7 downto 0)=x"ff" then
            tapebits <= cpudo(2 downto 0);
            widemode <= cpudo(3);
          end if;
          if iow='0' and cpua(7 downto 2)="000001" then -- out 4 5 6
            case cpua(1 downto 0) is
              when "00"=> io_ram_addr(7 downto 0) <= cpudo;
              when "01"=> io_ram_addr(15 downto 8) <= cpudo;
              when "10"=> io_ram_addr(23 downto 16) <= cpudo;
              when others => null;
            end case;
          end if;
          iorrd_r<=iorrd;
          if iorrd='0' and iorrd_r='1' then
            io_ram_addr <= io_ram_addr + 1;
          end if;
        end if;
      end if;
    end if;
  end process;


end Behavioral;
