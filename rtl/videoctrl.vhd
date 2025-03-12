--
-- HT 1080Z (TSR-80 clone) video controller PAL/VGA capable
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


entity videoctrl is
	Generic (
		H_START : integer := 165;		-- (630-384)/2 + 42   165
		V_START : integer := 37			-- (260-192)/2 + 3
	 );
    Port (   
		reset     : in  STD_LOGIC;
		clk42     : in  STD_LOGIC;		
		skin      : in  STD_LOGIC;
		a         : in  STD_LOGIC_VECTOR (13 downto 0);
		din       : in  STD_LOGIC_VECTOR (7 downto 0);
		dout      : out STD_LOGIC_VECTOR (7 downto 0);

		debug_enable : in STD_LOGIC;
		dbugmsg_addr : out STD_LOGIC_VECTOR (5 downto 0);
		dbugmsg_data : in STD_LOGIC_VECTOR (7 downto 0);
		v_debug      : out  STD_LOGIC;
		
		mreq      : in  STD_LOGIC;
		iorq      : in  STD_LOGIC;
		wr        : in  STD_LOGIC;
		cs        : in  STD_LOGIC;
		inkp      : in  STD_LOGIC;
		paperp    : in  STD_LOGIC;
		borderp   : in  STD_LOGIC;
		widemode  : in  STD_LOGIC;
		lcasetype : in  STD_LOGIC;
		rgbi      : out STD_LOGIC_VECTOR (3 downto 0);	
		ce_pix    : out STD_LOGIC;
		overscan  : in  STD_LOGIC_VECTOR (1 downto 0);
		flicker	 : in  STD_LOGIC;
		hsync     : out STD_LOGIC;
		vsync     : out STD_LOGIC;
		hb        : out STD_LOGIC;
		vb        : out STD_LOGIC;
		
		img_rgb	 : out STD_LOGIC_VECTOR (31 downto 0); -- R-G-B 8bits x 3
		img_valid : out STD_LOGIC ;
		
		UI_floppy_ready : in STD_LOGIC_VECTOR (3 downto 0) ;
		UI_floppy_write : in STD_LOGIC_VECTOR (3 downto 0) ;
		UI_floppy_read : in STD_LOGIC_VECTOR (3 downto 0);
		UART_RX   : in  STD_LOGIC;
		UART_TX   : in  STD_LOGIC;
		UART_RTS  : in  STD_LOGIC;
		UART_CTS  : in  STD_LOGIC;
		UART_DTR  : in  STD_LOGIC;
		UART_DSR  : in  STD_LOGIC
		);
end videoctrl;


architecture Behavioral of videoctrl is
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


type charmem is array(0 to 4095) of std_logic_vector(7 downto 0);



signal chrmem : charmem:=(
 --[PATCH_START]
x"00",x"1F",x"11",x"11",x"11",x"11",x"11",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 0x00  Symbols
x"00",x"1F",x"10",x"10",x"10",x"10",x"10",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"04",x"04",x"04",x"04",x"04",x"04",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"01",x"01",x"01",x"01",x"01",x"01",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"08",x"04",x"02",x"0F",x"04",x"02",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"11",x"1B",x"15",x"1B",x"11",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"01",x"02",x"14",x"18",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"11",x"1F",x"0A",x"0A",x"1B",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"04",x"08",x"1E",x"09",x"05",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"04",x"02",x"1F",x"02",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"00",x"00",x"1F",x"00",x"00",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"04",x"04",x"15",x"0E",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"04",x"15",x"0E",x"04",x"15",x"0E",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"04",x"08",x"1F",x"08",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"1B",x"15",x"1B",x"11",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"11",x"15",x"11",x"11",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"11",x"11",x"1F",x"11",x"11",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 0x10
x"00",x"0E",x"15",x"15",x"17",x"11",x"11",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"11",x"17",x"15",x"15",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"11",x"1D",x"15",x"15",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"15",x"15",x"1D",x"11",x"11",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"05",x"02",x"15",x"18",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"0A",x"0A",x"0A",x"0A",x"0A",x"1B",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"01",x"01",x"01",x"1F",x"01",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"11",x"0A",x"04",x"0A",x"11",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"04",x"04",x"0E",x"0E",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"10",x"08",x"04",x"00",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"0E",x"11",x"11",x"1F",x"11",x"11",x"0E",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"15",x"15",x"1D",x"11",x"11",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"11",x"11",x"1D",x"15",x"15",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"11",x"11",x"17",x"15",x"15",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"1F",x"15",x"15",x"17",x"11",x"11",x"1F",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- (space)  0x20
x"00",x"04",x"04",x"04",x"04",x"04",x"00",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- !
x"00",x"0a",x"0a",x"0a",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- "
x"00",x"0a",x"0a",x"1f",x"0a",x"1f",x"0a",x"0a",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- #
x"00",x"04",x"0f",x"14",x"0e",x"05",x"1e",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- $
x"00",x"18",x"19",x"02",x"04",x"08",x"13",x"03",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- %
x"00",x"08",x"14",x"14",x"08",x"15",x"12",x"0d",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- &
x"00",x"04",x"04",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- '
x"00",x"04",x"08",x"10",x"10",x"10",x"08",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- (
x"00",x"04",x"02",x"01",x"01",x"01",x"02",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- )
x"00",x"04",x"15",x"0e",x"04",x"0e",x"15",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- *
x"00",x"00",x"04",x"04",x"1f",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- +
x"00",x"00",x"00",x"00",x"00",x"00",x"04",x"04",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ,
x"00",x"00",x"00",x"00",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- -
x"00",x"00",x"00",x"00",x"00",x"00",x"0C",x"0C",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- .
x"00",x"00",x"01",x"02",x"04",x"08",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- /
x"00",x"0e",x"11",x"13",x"15",x"19",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 0	0x30
x"00",x"04",x"0c",x"04",x"04",x"04",x"04",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 1
x"00",x"0e",x"11",x"01",x"0e",x"10",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 2
x"00",x"1f",x"01",x"02",x"06",x"01",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 3
x"00",x"02",x"06",x"0a",x"12",x"1f",x"02",x"02",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 4
x"00",x"1f",x"10",x"1e",x"01",x"01",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 5
x"00",x"07",x"08",x"10",x"1e",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 6
x"00",x"1f",x"01",x"02",x"04",x"08",x"08",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 7
x"00",x"0e",x"11",x"11",x"0e",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 8
x"00",x"0e",x"11",x"11",x"0f",x"01",x"02",x"1c",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 9
x"00",x"00",x"00",x"04",x"00",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- :
x"00",x"00",x"00",x"04",x"00",x"04",x"04",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ;
x"00",x"02",x"04",x"08",x"10",x"08",x"04",x"02",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- <
x"00",x"00",x"00",x"1f",x"00",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- =
x"00",x"08",x"04",x"02",x"01",x"02",x"04",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- >
x"00",x"0e",x"11",x"01",x"06",x"04",x"00",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ?
x"00",x"0e",x"11",x"15",x"17",x"16",x"10",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- @	0x40
x"00",x"04",x"0a",x"11",x"11",x"1f",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- A
x"00",x"1e",x"09",x"09",x"0e",x"09",x"09",x"1e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- B
x"00",x"0e",x"11",x"10",x"10",x"10",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- C
x"00",x"1e",x"09",x"09",x"09",x"09",x"09",x"1e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- D
x"00",x"1f",x"10",x"10",x"1e",x"10",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- E
x"00",x"1f",x"10",x"10",x"1e",x"10",x"10",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- F
x"00",x"0e",x"11",x"10",x"10",x"13",x"11",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- G
x"00",x"11",x"11",x"11",x"1f",x"11",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- H
x"00",x"0e",x"04",x"04",x"04",x"04",x"04",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- I
x"00",x"01",x"01",x"01",x"01",x"01",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- J
x"00",x"11",x"12",x"14",x"18",x"14",x"12",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- K
x"00",x"10",x"10",x"10",x"10",x"10",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- L
x"00",x"11",x"1b",x"15",x"15",x"11",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- M
x"00",x"11",x"19",x"15",x"13",x"11",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- N
x"00",x"0e",x"11",x"11",x"11",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- O
x"00",x"1e",x"11",x"11",x"1e",x"10",x"10",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- P 0x50
x"00",x"0e",x"11",x"11",x"11",x"15",x"12",x"0d",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Q
x"00",x"1e",x"11",x"11",x"1e",x"14",x"12",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- R
x"00",x"0e",x"11",x"10",x"0e",x"01",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- S
x"00",x"1f",x"04",x"04",x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- T
x"00",x"11",x"11",x"11",x"11",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- U
x"00",x"11",x"11",x"11",x"0a",x"0a",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- V
x"00",x"11",x"11",x"11",x"11",x"15",x"15",x"0a",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- W
x"00",x"11",x"11",x"0a",x"04",x"0a",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- X
x"00",x"11",x"11",x"0a",x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Y
x"00",x"1f",x"01",x"02",x"04",x"08",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Z
--x"00",x"1c",x"10",x"10",x"10",x"10",x"10",x"1c",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- [ **
--x"00",x"00",x"10",x"08",x"04",x"02",x"01",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- \ **
--x"00",x"07",x"01",x"01",x"01",x"01",x"01",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ] **
--x"00",x"04",x"0a",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ^ **
x"00",x"04",x"0e",x"15",x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- up arrow
x"00",x"04",x"04",x"04",x"04",x"15",x"0e",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- down arrow
x"00",x"00",x"04",x"08",x"1f",x"08",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- left arrow
x"00",x"00",x"04",x"02",x"1f",x"02",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- right arrow
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- _ (underscore)
x"00",x"06",x"06",x"04",x"02",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ` 0x60
x"00",x"00",x"00",x"0e",x"01",x"0f",x"11",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- a
x"00",x"10",x"10",x"1e",x"11",x"11",x"11",x"1e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- b
x"00",x"00",x"00",x"0f",x"10",x"10",x"10",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- c
x"00",x"01",x"01",x"0f",x"11",x"11",x"11",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- d
x"00",x"00",x"00",x"0e",x"11",x"1f",x"10",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- e
x"00",x"03",x"04",x"04",x"0e",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- f
x"00",x"00",x"00",x"0f",x"11",x"11",x"11",x"0f",x"01",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",	-- g
x"00",x"10",x"10",x"1e",x"11",x"11",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- h
x"00",x"04",x"00",x"0c",x"04",x"04",x"04",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- i
x"00",x"02",x"00",x"06",x"02",x"02",x"02",x"02",x"12",x"0c",x"00",x"00",x"00",x"00",x"00",x"00",	-- j
x"00",x"08",x"08",x"09",x"0a",x"0c",x"0a",x"09",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- k
x"00",x"0c",x"04",x"04",x"04",x"04",x"04",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- l
x"00",x"00",x"00",x"1a",x"15",x"15",x"15",x"15",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- m
x"00",x"00",x"00",x"16",x"19",x"11",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- n
x"00",x"00",x"00",x"0e",x"11",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- o
x"00",x"00",x"00",x"1e",x"11",x"11",x"11",x"1e",x"10",x"10",x"00",x"00",x"00",x"00",x"00",x"00",	-- p 0x70
x"00",x"00",x"00",x"0f",x"11",x"11",x"11",x"0f",x"01",x"01",x"00",x"00",x"00",x"00",x"00",x"00",	-- q
x"00",x"00",x"00",x"0b",x"0c",x"08",x"08",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- r
x"00",x"00",x"00",x"0f",x"10",x"0e",x"01",x"1e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- s
x"00",x"00",x"04",x"0e",x"04",x"04",x"04",x"03",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- t
x"00",x"00",x"00",x"11",x"11",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- u
x"00",x"00",x"00",x"11",x"11",x"11",x"0a",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- v
x"00",x"00",x"00",x"11",x"11",x"15",x"15",x"0a",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- w
x"00",x"00",x"00",x"11",x"0a",x"04",x"0a",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- x
x"00",x"00",x"00",x"11",x"11",x"11",x"11",x"0f",x"01",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",	-- y
x"00",x"00",x"00",x"1f",x"02",x"04",x"08",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- z
x"00",x"02",x"04",x"04",x"08",x"04",x"04",x"02",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- {
x"00",x"04",x"04",x"04",x"00",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- |
x"00",x"08",x"04",x"04",x"02",x"04",x"04",x"08",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- }
x"00",x"08",x"15",x"02",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- ~
x"00",x"0a",x"15",x"0a",x"15",x"0a",x"15",x"0a",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 50% fill

x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 0x80  -- graphics start here
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",	-- 0x90
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",	-- 0xA0
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",	-- 0xB0
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- 0xC0
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",	-- 0xD0
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",	-- 0xE0
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",	-- 0xF0
x"38",x"38",x"38",x"38",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"00",x"00",x"00",x"00",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"38",x"38",x"38",x"38",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"07",x"07",x"07",x"07",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00",
x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"3f",x"00",x"00",x"00",x"00"
--[PATCH_END]
);

signal clkdiv  : std_logic_vector(1 downto 0);

signal hctr    : std_logic_vector(9 downto 0);
signal vctr    : std_logic_vector(8 downto 0);
signal vpos    : std_logic_vector(3 downto 0); -- line pos in a chr 0..11
signal hpos    : std_logic_vector(2 downto 0); -- pixel pos in a chr 0..5

signal img_hact, img_vact : std_logic;
signal img_hctr, img_hctr_led : std_logic_vector(8 downto 0);
signal img_vctr, img_adr_logo, img_adr_led_rs, img_adr_rs232 : std_logic_vector(7 downto 0);
signal img_adr_flp : std_logic_vector(7 downto 0);
signal img_address : std_logic_vector(15 downto 0);

signal img_logo, img_rs232 : std_logic;
signal img_dr1 : std_logic;
signal img_dr2 : std_logic;
signal img_dr3 : std_logic;
signal img_dr4 : std_logic;

signal img_led_col : std_logic ;
signal img_adr_led : std_logic_vector(7 downto 0);
signal img_led_state : std_logic_vector(8 downto 0);
signal img_rs232_state : std_logic_vector(8 downto 0);
signal img_adr_rdy : boolean ;
signal img_led_1 : std_logic;
signal img_led_2 : std_logic;
signal img_led_3 : std_logic;
signal img_led_4 : std_logic;

signal img_hctr_led_rs1, img_hctr_led_rs2, img_hctr_led_rs3, img_hctr_led_rs4, img_hctr_led_rs5, img_hctr_led_rs6 : std_logic_vector(8 downto 0);
signal img_led232_col1, img_led232_col2, img_led232_col3, img_led232_col4, img_led232_col5, img_led232_col6 : std_logic ;
signal img_led232_1, img_led232_2, img_led232_3, img_led232_4, img_led232_5, img_led232_6 : std_logic ;
signal img_led232_row : std_logic ;

signal ce      : std_logic;
signal vdebug  : std_logic;

signal hact,vact : std_logic;			-- '1' if inside active display area
signal hdisp,vdisp : std_logic;		-- '1' if inside CRT scanning area (includes borders)
signal pthdisp,ptvdisp : std_logic;	-- '1' if inside 'partial overscan' dislpay area (includes partial borders)

signal border : std_logic_vector(3 downto 0) := "0000";
signal  paper : std_logic_vector(3 downto 0) := "0000";
signal    ink : std_logic_vector(3 downto 0) := "1000";
CONSTANT dashbrd : std_logic_vector(3 downto 0) := "1011";  -- debug yellow color

signal  vid_addr : std_logic_vector(9 downto 0);

signal screen : std_logic;

signal vaVert : std_logic_vector(3 downto 0); -- vertical line
signal vaHoriz : std_logic_vector(5 downto 0); -- horizontal columnt pos

signal chraddr : std_logic_vector(11 downto 0); -- character bitmap data address in the charmem
signal chrCode : std_logic_vector(7 downto 0);
signal chrGrap : std_logic_vector(7 downto 0);
signal shiftReg : std_logic_vector(7 downto 0);

signal xpxsel : std_logic_vector(1 downto 0);
signal     v1 : std_logic;

signal rinkp,rpaperp,rborderp : std_logic; 

-- Notes about display area:
-- -------------------------
-- Screen's display area (actual foreground dots) is 384x192
-- Scanning area (cathode ray scanning) is 630x260 (plus 42 x 3 for sync signals)
-- Partial overscan is midway between these (showing half of the border)

signal hstart : std_logic_vector(9 downto 0);
signal vstart : std_logic_vector(8 downto 0);

CONSTANT hsynlen : std_logic_vector(9 downto 0) := conv_std_logic_vector(42,10);
CONSTANT vsynlen : std_logic_vector(8 downto 0) := conv_std_logic_vector(3,9);
CONSTANT   hsize : std_logic_vector(9 downto 0) := conv_std_logic_vector(384,10);
CONSTANT   vsize : std_logic_vector(8 downto 0) := conv_std_logic_vector(192,9);
CONSTANT    hend : std_logic_vector(9 downto 0) := conv_std_logic_vector(672,10);
CONSTANT    vend : std_logic_vector(8 downto 0) := conv_std_logic_vector(263,9);

CONSTANT ptlhstrt : std_logic_vector(9 downto 0) := conv_std_logic_vector(103,10);
CONSTANT ptlvstrt : std_logic_vector(8 downto 0) := conv_std_logic_vector(20,9);
CONSTANT  ptlhend : std_logic_vector(9 downto 0) := conv_std_logic_vector(611,10);
CONSTANT  ptlvend : std_logic_vector(8 downto 0) := conv_std_logic_vector(243,9);

begin

hstart <= conv_std_logic_vector(110,10) when skin='1' else conv_std_logic_vector(H_START,10) ;
vstart <= conv_std_logic_vector(V_START,9);

ce_pix <= ce;
v_debug <= vdebug ;

img_adr_logo <= img_vctr+72 ;
img_adr_rs232 <= img_vctr+61 ;
img_adr_led_rs <= img_vctr+48 ;  -- LEDs-5
img_adr_led <= img_vctr+50 ;  -- LEDs-3
img_hctr_led <= img_hctr-33 ;
img_hctr_led_rs1 <= img_hctr-16 ;
img_hctr_led_rs2 <= img_hctr-80 ;
img_hctr_led_rs3 <= img_hctr-144 ;
img_hctr_led_rs4 <= img_hctr-208 ;
img_hctr_led_rs5 <= img_hctr-272 ;
img_hctr_led_rs6 <= img_hctr-336 ;

img_adr_rdy <=  (UI_floppy_ready(0)='1' and img_dr1='1')  or 
											(UI_floppy_ready(1)='1' and img_dr2='1')  or
											(UI_floppy_ready(2)='1' and img_dr3='1')  or
											(UI_floppy_ready(3)='1' and img_dr4='1') ;
											
img_adr_flp <=  img_vctr when img_adr_rdy else img_vctr+28 ;
											
img_led_state <= conv_std_logic_vector(96,9)  when not img_adr_rdy else
					  conv_std_logic_vector(32,9) when (UI_floppy_write(0)='1' and img_dr1='1') or (UI_floppy_write(1)='1' and img_dr2='1') 
							 or (UI_floppy_write(2)='1' and img_dr3='1') or (UI_floppy_write(3)='1' and img_dr4='1') else
					  conv_std_logic_vector(0,9)  when (UI_floppy_read(0)='1' and img_dr1='1') or (UI_floppy_read(1)='1' and img_dr2='1') 
							 or (UI_floppy_read(2)='1' and img_dr3='1') or (UI_floppy_read(3)='1' and img_dr4='1') else											
						conv_std_logic_vector(64,9) ;	
						
img_rs232_state <= conv_std_logic_vector(96,9) when (img_led232_1='1' and UART_RX='1') or (img_led232_2='1' and UART_TX='1') or (img_led232_3='1' and UART_RTS='1') or
								(img_led232_4='1' and UART_CTS='1') or (img_led232_5='1' and UART_DTR='1') or (img_led232_6='1' and UART_DSR='1') else conv_std_logic_vector(0,9) ;
											
img_address <= (img_adr_logo & x"00")+(img_adr_logo & "0000000")+img_hctr when img_logo='1' else
					(img_adr_led_rs & x"00")+(img_adr_led_rs & "0000000")+img_hctr_led_rs1+img_rs232_state when img_led232_1='1' else
					(img_adr_led_rs & x"00")+(img_adr_led_rs & "0000000")+img_hctr_led_rs2+img_rs232_state when img_led232_2='1' else
					(img_adr_led_rs & x"00")+(img_adr_led_rs & "0000000")+img_hctr_led_rs3+img_rs232_state when img_led232_3='1' else
					(img_adr_led_rs & x"00")+(img_adr_led_rs & "0000000")+img_hctr_led_rs4+img_rs232_state when img_led232_4='1' else
					(img_adr_led_rs & x"00")+(img_adr_led_rs & "0000000")+img_hctr_led_rs5+img_rs232_state when img_led232_5='1' else
					(img_adr_led_rs & x"00")+(img_adr_led_rs & "0000000")+img_hctr_led_rs6+img_rs232_state when img_led232_6='1' else
					(img_adr_rs232 & x"00")+(img_adr_rs232 & "0000000")+img_hctr when img_rs232='1' else
						(img_adr_led & x"00")+(img_adr_led & "0000000")+img_hctr_led+img_led_state 
								when img_led_1='1' or img_led_2='1' or img_led_3='1' or img_led_4='1' else
						(img_adr_flp & x"00")+(img_adr_flp & "0000000")+img_hctr when img_dr1='1' else
						(img_adr_flp & x"00")+(img_adr_flp & "0000000")+img_hctr when img_dr2='1' else
						(img_adr_flp & x"00")+(img_adr_flp & "0000000")+img_hctr when img_dr3='1' else
						(img_adr_flp & x"00")+(img_adr_flp & "0000000")+img_hctr when img_dr4='1' else x"0000" ;
						
skin_rom_inst : entity work.sprom
generic map
(
		 init_file => "rtl/skin4.mif",
		 widthad_a => 16,
		 width_a => 32
)
port map
(
		 clock           => clk42,
		 address => img_address,
		 q    => img_rgb
);



process(clk42)
begin
  if rising_edge(clk42) then
		clkdiv <= clkdiv + 1;
		ce <= '0';
		if clkdiv = 0 then
			ce <= '1';
		end if;
  end if;
end process;

process(RESET,clk42)
begin
	if RESET='0' then
		ink <= "1000";
		paper <= "0000";
		border <= "0000";
	else
		if rising_edge(clk42) then
			if ce = '1' then
				rinkp <= INKP;
				rpaperp <= PAPERP;
				rborderp <= BORDERP;
				if rinkp='0' and INKP='1' then
					ink <= ink+1;
				end if;
				if rpaperp='0' and PAPERP='1' then
					paper <= paper+1;
				end if;
				if rborderp='0' and BORDERP='1' then
					border <= border+1;
				end if;					  
				if iorq='0' and wr='0' and a(7 downto 2)="000000" then
					case a(1 downto 0) is
						when "11"=> ink<=din(3 downto 0);
						when "01"=> paper<=din(3 downto 0);
						when "10"=> border<=din(3 downto 0);		  
						when others=>null;
					end case;
				end if;
			end if;
		end if;  
	end if;
end process;

-- Access to video ram will cause the char and graphic latches
-- to clear causing a black line (Model 1 only)

process(clk42)
begin
	if rising_edge(clk42) then
		if ce = '1' then
			if (vdebug='1') then
				chrGrap <= chrmem(conv_integer( dbugmsg_data & vpos ));
			else
				if (cs='0' and flicker='1') then
					chrGrap <= x"00";	-- Black line on video contention
				else 
					if (chrCode < x"20" and lcasetype = '0') then	-- if lowercase type is default, then display uppercase instead of symbols
						chrGrap <= chrmem(conv_integer( (chrCode + x"40") & vpos ));
					else
						chrGrap <= chrmem(conv_integer( chrCode & vpos ));
					end if;
				end if;
			end if;
		end if;
	end if;  
end process;

vid_addr <=  vaVert & vaHoriz(5 downto 1) & (vaHoriz(0) and not widemode);
dbugmsg_addr <= vaHoriz(5 downto 0);

vram : dpram
generic map (
	DATA => 8,
	ADDR => 10
)
port map (
	-- Port A - used for CPU access
	a_clk  => clk42,
	a_wr   => not cs and not wr,
	a_addr => a(9 downto 0),
	a_din  => din,
	a_dout => dout,

	-- Port B - used by raster scanner
	b_clk  => clk42,
	b_wr   => '0',
	b_addr => vid_addr,
	b_din  => (others => '0'),
	b_dout => chrCode
);


-- h and v counters
-- 10.5 MHz pixelclock => 672 pixels per scan line
-- 264 scanlines
-- 64*6 pixels active screen = 384 pixels
-- visible area: 52*10.5 = 546
-- Horizontal: |42T-hsync|84T-porch|81T-border|384T-screen|81T-border|
process(clk42)
begin
	if rising_edge(clk42) then
		if ce = '1' then
			hctr<=hctr+1;
			if hctr=hend then
				hctr<=(others=>'0');
				vctr<=vctr+1;
				if vctr=vend then
					vctr<=(others=>'0');
				end if;
			end if;
		end if;
	end if;
end process;

process(clk42)
begin
	if falling_edge(clk42) then
		if ce = '1' then
			if hctr<hsynlen then -- 4*10.5
				hsync <= '1';
				if vctr<vsynlen then
					vsync <= '1';
				else
					vsync <= '0';
				end if;
			else
				hsync <= '0';
			end if;
		end if;
	end if;	 	 
end process; 
  
hact <= '1' when hctr>=hstart and hctr<hstart+hsize else '0'; -- if widemode, allow for the last half-character
vact <= '1' when vctr>=vstart and vctr<vstart+vsize else '0';
vdebug <= '1' when vctr>=vstart-12 and vctr<vstart and debug_enable='1' else '0';

hdisp <= '1' when hctr>=hsynlen and hctr<hend else '0';
vdisp <= '1' when vctr>=vsynlen and vctr<vend else '0';

pthdisp <= '1' when hctr>=ptlhstrt and hctr<ptlhend else '0';
ptvdisp <= '1' when vctr>=ptlvstrt and vctr<ptlvend else '0';

img_hact <= '1' when hctr>=512 and hctr<608 else '0' ;
img_vact <= '1' when vctr>=40 and vctr<232 else '0' ; 

img_logo <= '1' when vctr>=40 and vctr<138 else '0' ;
img_rs232 <= '1' when vctr>=138 and vctr<150 else '0' ;
img_dr1 <= '1' when vctr>=150 and vctr<170 else '0' ; 
img_dr2 <= '1' when vctr>=170 and vctr<190 else '0' ; 
img_dr3 <= '1' when vctr>=190 and vctr<210 else '0' ; 
img_dr4 <= '1' when vctr>=210 and vctr<232 else '0' ; 

img_led232_col1 <=  '1' when img_hctr>=16 and img_hctr<48 else '0' ;
img_led232_col2 <=  '1' when img_hctr>=80 and img_hctr<112 else '0' ;
img_led232_col3 <=  '1' when img_hctr>=144 and img_hctr<176 else '0' ;
img_led232_col4 <=  '1' when img_hctr>=208 and img_hctr<240 else '0' ;
img_led232_col5 <=  '1' when img_hctr>=272 and img_hctr<304 else '0' ;
img_led232_col6 <=  '1' when img_hctr>=336 and img_hctr<368 else '0' ;
img_led232_row <='1' when vctr>=144 and vctr<146 else '0' ;
img_led232_1 <='1' when img_led232_row='1' and img_led232_col1='1' else '0' ;
img_led232_2 <='1' when img_led232_row='1' and img_led232_col2='1' else '0' ;
img_led232_3 <='1' when img_led232_row='1' and img_led232_col3='1' else '0' ;
img_led232_4 <='1' when img_led232_row='1' and img_led232_col4='1' else '0' ;
img_led232_5 <='1' when img_led232_row='1' and img_led232_col5='1' else '0' ;
img_led232_6 <='1' when img_led232_row='1' and img_led232_col6='1' else '0' ;

img_led_col <= '1' when img_hctr>=33 and img_hctr<64 else '0' ;
img_led_1 <= '1' when vctr>=153 and vctr<156 and img_led_col='1' else '0' ;
img_led_2 <= '1' when vctr>=173 and vctr<176 and img_led_col='1' else '0' ;
img_led_3 <= '1' when vctr>=193 and vctr<196 and img_led_col='1' else '0' ;
img_led_4 <= '1' when vctr>=213 and vctr<216 and img_led_col='1' else '0' ;

img_valid <= '1' when img_hact='1' and img_vact='1' and skin='1' else '0' ;

process(clk42)
begin
	if rising_edge(clk42) then
		if ce = '1' then

			if overscan = "10" then
				hb <= not hdisp;
				vb <= not vdisp;
			else
				if overscan = "01" then
					hb <= not pthdisp;
					vb <= not ptvdisp;
				else
					hb <= not hact;
					vb <= not vact;
				end if;
			end if;

			if hact='1' and (vact='1' or vdebug='1') then
				if hpos=5 then
					hpos <= "000";
					vaHoriz <= vaHoriz+1;
					if (widemode = '0' or vaHoriz(0) = '0' or vdebug='1') then	-- no wide mode in debug mode
						shiftReg <= chrGrap;
					else
						shiftReg <= shiftReg(6 downto 0) & '0';
					end if;
				else
					if (widemode = '0' or ( hpos(0) = '1') or vdebug='1') then	-- if widemode, only shift half the time
						shiftReg <= shiftReg(6 downto 0) & '0';
					end if;
					hpos <= hpos+1;
				end if;
				screen<= '1';
			else
				screen<= '0';
				hpos <= "101";
				vaHoriz <= "000000"; 
				shiftReg <= "00000000"; -- keep it clear
				if vctr=0 then
					-- new frame
					vaVert<= "0000";
					vpos <= "0000";
					img_vctr <= (others=>'0')  ;
					
				elsif (vact='1' or vdebug='1') and hctr=hstart+hsize+2 then  
					-- end of a scanline
					if vpos=11 then
						vpos <= "0000";
						if (vdebug='0') then
							vaVert <= vaVert+1;
						end if;
					else
						vpos <= vpos+1;
					end if;
				end if;
			end if;
			if (hctr=511) then 
				img_hctr<=(others=>'0')  ;
				if (vctr=40 or vctr=138 or vctr=150 or vctr=170 or vctr=190 or vctr=210) then -- origins of img parts in the page
					img_vctr<=(others=>'0')  ; 
				else 
					img_vctr<=img_vctr+1 ; 
				end if ;
			end if;
			
		end if;
		-- clock*4 here for Hires Skin pict
		if (hctr>511) then 
			img_hctr<=img_hctr+1 ;
		end if ;
	end if;
end process;

rgbi <= border when screen='0' else paper when shiftReg(5)='0' else dashbrd when vdebug='1' else ink ;

end Behavioral;
