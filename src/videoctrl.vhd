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
		H_START : integer := 42+84+81-16;
		V_START : integer := 2+28+((266-192)/2)+4
	 );
    Port (   
	        reset : in  STD_LOGIC;
		     clk42 : in  STD_LOGIC;
			   --clk7 : in  STD_LOGIC;
               a : in  STD_LOGIC_VECTOR (13 downto 0);
             din : in  STD_LOGIC_VECTOR (7 downto 0);
            dout : out STD_LOGIC_VECTOR (7 downto 0);
            mreq : in  STD_LOGIC;
            iorq : in  STD_LOGIC;
              wr : in  STD_LOGIC;
				  cs : in  STD_LOGIC;
				vcut : in  STD_LOGIC;
				--vvga : in  STD_LOGIC;
				page : in  STD_LOGIC;
				inkp : in  STD_LOGIC;
			 paperp : in  STD_LOGIC;
			borderp : in  STD_LOGIC;
		  widemode : in  STD_LOGIC;
		 lcasetype : in  STD_LOGIC;
			oddline : out STD_LOGIC;
            rgbi : out STD_LOGIC_VECTOR (3 downto 0);	
				pclk : out STD_LOGIC;
           hsync : out STD_LOGIC;
           vsync : out STD_LOGIC;
           hb : out STD_LOGIC;
           vb : out STD_LOGIC
			  );
end videoctrl;

architecture Behavioral of videoctrl is

type videomem is array(0 to 1023) of std_logic_vector(7 downto 0);

type charmem is array(0 to 4095) of std_logic_vector(7 downto 0);

signal vidmem : videomem:=(
others => x"00"
);

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

--x"0e",x"11",x"15",x"17",x"16",x"10",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate @  0x00
--x"04",x"0a",x"11",x"11",x"1f",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate A this character ROM repeats uppercase from 0x01-0x1f
--x"1e",x"09",x"09",x"0e",x"09",x"09",x"1e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate B
--x"0e",x"11",x"10",x"10",x"10",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate C
--x"1e",x"09",x"09",x"09",x"09",x"09",x"1e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate D
--x"1f",x"10",x"10",x"1e",x"10",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate E
--x"1f",x"10",x"10",x"1e",x"10",x"10",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate F
--x"0f",x"11",x"10",x"10",x"13",x"11",x"0f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate G
--x"11",x"11",x"11",x"1f",x"11",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate H
--x"0e",x"04",x"04",x"04",x"04",x"04",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate I
--x"01",x"01",x"01",x"01",x"01",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate J
--x"11",x"12",x"14",x"18",x"14",x"12",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate K
--x"10",x"10",x"10",x"10",x"10",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate L
--x"11",x"1b",x"15",x"15",x"15",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate M
--x"11",x"11",x"19",x"15",x"13",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate N
--x"0e",x"11",x"11",x"11",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate O
--x"1e",x"11",x"11",x"1e",x"10",x"10",x"10",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate P  0x10
--x"0e",x"11",x"11",x"11",x"15",x"12",x"0d",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate Q
--x"1e",x"11",x"11",x"1e",x"14",x"12",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate R
--x"0e",x"11",x"10",x"0e",x"01",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate S
--x"1f",x"15",x"04",x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate T
--x"11",x"11",x"11",x"11",x"11",x"11",x"0e",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate U
--x"11",x"11",x"11",x"0a",x"0a",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate V
--x"11",x"11",x"11",x"15",x"15",x"15",x"0a",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate W
--x"11",x"11",x"0a",x"04",x"0a",x"11",x"11",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate X
--x"11",x"11",x"0a",x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate Y
--x"1f",x"01",x"02",x"04",x"08",x"10",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- Alternate Z
--x"04",x"0e",x"15",x"04",x"04",x"04",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- up arrow
--x"04",x"04",x"04",x"04",x"15",x"0e",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- down arrow
--x"00",x"04",x"08",x"1f",x"08",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- left arrow
--x"00",x"04",x"02",x"1f",x"02",x"04",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",	-- right arrow
--x"00",x"00",x"00",x"00",x"00",x"00",x"1f",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

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
 --others => x"ff"
);

-- 0  1    2
-- 21 10.5 5.25
signal clkdiv : std_logic_vector(2 downto 0);
alias   clk21 : std_logic is clkdiv(0);
alias clk10_5 : std_logic is clkdiv(1);
alias clk5_25 : std_logic is clkdiv(2);


signal hctr : std_logic_vector(9 downto 0);
signal vctr : std_logic_vector(8 downto 0);
signal vpos : std_logic_vector(3 downto 0); -- line pos in a chr 0..11
signal hpos : std_logic_vector(2 downto 0); -- pixel pos in a chr 0..5
signal hstart : std_logic_vector(9 downto 0);
signal vstart : std_logic_vector(8 downto 0);
signal vend : std_logic_vector(8 downto 0);

signal pxclk : std_logic;
signal xpxclk : std_logic;

signal hact,vact : std_logic;


signal border : std_logic_vector(3 downto 0) := "0010";
signal  paper : std_logic_vector(3 downto 0) := "0000";
signal    ink : std_logic_vector(3 downto 0) := "1000";
signal  pixel : std_logic_vector(3 downto 0);

signal screen : std_logic;
signal hblank,vblank,blank : std_logic;

signal vaVert : std_logic_vector(3 downto 0); -- vertical line
signal vaHoriz : std_logic_vector(5 downto 0); -- horizontal columnt pos

signal chraddr : std_logic_vector(11 downto 0); -- character bitmap data address in the charmem
signal chrCode : std_logic_vector(7 downto 0);
signal chrGrap : std_logic_vector(7 downto 0);
signal shiftReg : std_logic_vector(7 downto 0);

signal xpxsel : std_logic_vector(1 downto 0);
signal     v1 : std_logic;

signal rinkp,rpaperp,rborderp : std_logic; 

signal vvga : std_logic;

begin

vvga <= '1';	
--pxclk <= clk10_5;
--xpxclk <= clk10_5 when vcut='0' else clk5_25;
--hstart <= conv_std_logic_vector(H_START,10);
--vstart <= conv_std_logic_vector(V_START,9); 
--vend <= conv_std_logic_vector(311,9); 

pxclk <= clk10_5 when vvga='0' else clk21;
xpxsel <= vvga & vcut;
with xpxsel select xpxclk <=
  clk10_5 when "00",
  clk5_25 when "01",
    clk21 when "10",
  clk10_5 when others;

hstart <= conv_std_logic_vector(H_START,10) when vvga='0' else conv_std_logic_vector(H_START,10);
vstart <= conv_std_logic_vector(V_START,9) when vvga='0' else conv_std_logic_vector(V_START-30,9);
vend <= conv_std_logic_vector(311,9) when vvga='0' else conv_std_logic_vector(262,9); 

process(clk42)
begin
  if rising_edge(clk42) then
    clkdiv <= clkdiv + 1;  
  end if;
end process;

process(RESET,clk10_5)
begin
 if RESET='0' then
   ink <= "1000";
	paper <= "0000";
	border <= "0000";
 else
  if rising_edge(clk10_5) then
  
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
		  when "00"=> ink<=din(3 downto 0);
		  when "01"=> paper<=din(3 downto 0);
		  when "10"=> border<=din(3 downto 0);		  
		  when others=>null;
		end case;
	 end if;
  end if;  
 end if;
end process;


process(clk10_5)
begin
  if rising_edge(clk10_5) then
  
    chrCode <= vidmem(conv_integer( vaVert & vaHoriz(5 downto 1) & (vaHoriz(0) and not widemode) ));
	 
	 if (chrCode < x"20" and lcasetype = '0') then	-- if lowercase type is default, then display uppercase instead of symbols
		chrGrap <= chrmem(conv_integer( (chrCode + x"40") & vpos ));
	 else
		chrGrap <= chrmem(conv_integer( chrCode & vpos ));
	 end if;
	 
	 dout <= vidmem(conv_integer( a(9 downto 0) ));
	 if cs='0' and wr='0' then
	   vidmem(conv_integer( a(9 downto 0) )) <= din;
	 end if;
  end if;  
end process;

-- h and v counters
-- 10.5 MHz pixelclock => 672 pixels per scan line
-- 312 scanlines
-- 64*6 pixels active screen = 384 pixels
-- visible area: 52*10.5 = 546
-- Horizontal: |42T-hsync|84T-porch|81T-border|384T-screen|81T-border|
process(pxclk)
begin
  if rising_edge(pxclk) then
     if hctr=671 then
	    hctr<="0000000000";
		 v1 <= not v1; 
		 if vctr>=vend then
		   vctr<="000000000";
			v1 <= '0';
		 else
			--vctr<=vctr+1;
			if v1='1' or vvga='0' then 
			  vctr<=vctr+1;
			end if; 
		 end if;
	  else
	    hctr<=hctr+1;
	  end if;
  end if;
end process;

--process(pxclk)
--begin
-- if falling_edge(pxclk) then
--	
--	-- 12*10.5
--	if hctr<126 or hctr>654 then
--	  hblank <= '0';
--	else
--	  hblank <= '1';
--	end if;
--	
--	if hctr<42 then -- 4*10.5
--	  hsync <= '0';
--	else
--	  hsync <= '1';
--	end if;
--	
--	if vctr<6 or vctr>309 then
--	  vblank <= '0';
--	else
--	  vblank <= '1';
--	end if;
--
--	if vctr<2 then
--	  vsync <= '0';
--	else
--	  vsync <= '1';
--	end if;
--		
-- end if;	 	 
--end process;

process(pxclk)
begin
 if falling_edge(pxclk) then
	
	if vvga='0' then
		-- 12*10.5
		if hctr<126 or hctr>654 then
		  hblank <= '0';
		else
		  hblank <= '1';
		end if;
	else
	   -- VGA 6us
		-- 
		--if hctr<64 or hctr>662 then
		if hctr<120 or hctr>654 then
		  hblank <= '0';
		else
		  hblank <= '1';
		end if;	
	end if;
	
	if vvga='0' then	
		if hctr<42 then -- 4*10.5
		  hsync <= '0';
		else
		  hsync <= '1';
		end if;
		
		if vctr<6 or vctr>309 then
		  vblank <= '0';
		else
		  vblank <= '1';
		end if;

   else
		if hctr<79 then -- 4*21
		  hsync <= '0';
		else
		  hsync <= '1';
		end if;	
		
		if vctr<16 or vctr>259 then
		  vblank <= '0';
		else
		  vblank <= '1';
		end if;
		
   end if;
	

	if vctr<3 then
	  vsync <= '0';
	else
	  vsync <= '1';
	end if;
		
 end if;	 	 
end process; 

hact <= '1' when hctr>=hstart and hctr<hstart+384 else '0';
vact <= '1' when vctr>=vstart and vctr<vstart+192 else '0';


process(xpxclk)
begin
  if rising_edge(xpxclk) then   
    if hact='1' and vact='1' then
	   if hpos=5 then
		  hpos <= "000";
		  vaHoriz <= vaHoriz+1;
		  if (widemode = '0' or vaHoriz(0) = '1') then
		    shiftReg <= chrGrap;
		  else
		  	 shiftReg <= shiftReg(6 downto 0) & '0';
		  end if;
		else
		  if (widemode = '0' or ( hpos(0) = '1') ) then	-- if widemode, only shift half the time
			 shiftReg <= shiftReg(6 downto 0) & '0';
		  end if;
		  hpos <= hpos+1;
		end if;
	   screen<= '1';
	 else
	   screen<= '0';
		hpos <= "101";
		vaHoriz <= (page and vcut) & "00000"; 
		shiftReg <= "00000000"; -- keep it clear
		if vctr=0 then
		  -- new frame
		  vaVert<= "0000";
		  vpos <= "0000";
		elsif vact='1' and hctr=hstart+384+2 and (v1='1' or vvga='0') then
		  -- end of a scanline
		  if vpos=11 then
		    vpos <= "0000";
			 vaVert <= vaVert+1;
		  else
		    vpos <= vpos+1;
		  end if;
		end if;
	 end if;
  end if;
end process; 

pixel <= border when screen='0' else paper when shiftReg(5)='0' else ink;
blank <= hblank and vblank;
hb <= hblank;
vb <= vblank;
rgbi <= pixel when blank='1' else "0000";
pclk <= clk10_5 when vvga='0' else clk21;
oddline <= v1;

end Behavioral;

