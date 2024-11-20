--
-- Micro_RS232 for the MiSTer TRS-80 core
-- written-at-a-tube theflynn49 11/2024
-- 
-- Quick and dirty RS232 Mod.26-1145 RS232-C interface
-- based on the UART TR1602B chip
--
-- ============================================================================
--  (c)2017-2020 Alexey Melnikov
--
--  This program is free software; you can redistribute it and/or modify it
--  under the terms of the GNU General Public License as published by the Free
--  Software Foundation; either version 2 of the License, or (at your option)
--  any later version.
--
--  This program is distributed in the hope that it will be useful, but WITHOUT
--  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
--  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
--  more details.
--
--  You should have received a copy of the GNU General Public License along
--  with this program; if not, write to the Free Software Foundation, Inc.,
--  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
--
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity m_rs232_uart is
Port (
	reset      : in  std_logic;
	clk42m     : in  std_logic;  -- 42.578Mhz
	clk_rs16   : in  STD_LOGIC;
   addr		  : in std_logic_vector(1 downto 0) ; -- address from CPU
	cs_n		  : in  std_logic; -- chip select 0xE8
	iow_n		  : in std_logic;  -- io write
	ior_n		  : in std_logic;  -- io read
	DO			  : out std_logic_vector(7 downto 0) ;
	DI			  : in std_logic_vector(7 downto 0) ;
	
   baud_sel   : in std_logic_vector(3 downto 0);
	uart_mode  : in std_logic_vector(7 downto 0);

 	UART_TXD   : out  std_logic;
	UART_RXD   : in  std_logic;
	UART_RTS   : out  std_logic;
	UART_CTS   : in  std_logic;
	UART_DTR   : out  std_logic;
	UART_DSR   : in  std_logic ;
	
	uart_debug : out std_logic_vector(11 downto 0)
);
end m_rs232_uart;

architecture Behavioral of m_rs232_uart is
   
signal l_RESET : std_logic ;
signal UART_CD : std_logic ;
signal UART_BRK : std_logic ;
signal baud_sw : std_logic_vector(2 downto 0);

signal UART_OVERRUN : std_logic ;
signal UART_FRAME : std_logic ;

signal TX_BUFFER : std_logic_vector(7 downto 0);
signal TX_BUFFER_READY : std_logic ;
signal TX_BUFFER_READY_SET : std_logic ;

signal TX_SHIFT : std_logic_vector(7 downto 0);
signal TX_SHIFT_READY : std_logic ;
signal TX_STATE : std_logic_vector(3 downto 0);
signal TX_STATE_CTR : std_logic_vector(3 downto 0); -- divider by 16

signal RX_RESET : std_logic ;
signal RX_RESET_CLR : std_logic ;
signal RX_SHIFT : std_logic_vector(7 downto 0);
signal RX_BUFFER : std_logic_vector(7 downto 0);
signal RX_BUFFER_READY : std_logic ;
signal RX_BUFFER_READY_CLR : std_logic ;
signal RX_STATE_CTR : std_logic_vector(3 downto 0); -- divider by 16
signal RX_STATE : std_logic_vector(3 downto 0);
signal UART_RXD_PREV : std_logic ;

begin
	
process(reset, clk42m)
begin
 --  if (reset='1') or ( (addr = "01") and iow_n='0' and cs_n='0') then
   if (reset='1') then
      UART_CD <= '0' ;
		UART_DTR <= '0' ;
		UART_RTS <= '0' ;
		UART_BRK <= '1' ;
		RX_BUFFER_READY_CLR <= '0' ;
		TX_BUFFER_READY_SET <= '0' ;
		RX_RESET <= '0' ;
	else
	   if rising_edge(clk42m) then
			uart_debug <= RX_BUFFER_READY & not TX_BUFFER_READY & UART_OVERRUN & UART_FRAME & UART_CTS & UART_DSR & UART_CD & UART_RXD & '0' & baud_sw;
			if RX_RESET_CLR='1' then RX_RESET<='0' ; end if ;
			if RX_BUFFER_READY='0' then RX_BUFFER_READY_CLR<='0' ; end if;
			if TX_BUFFER_READY='1' then TX_BUFFER_READY_SET<='0'; end if;
			if uart_mode=0 then UART_CD<='0'; else UART_CD<='1' ; end if;
			case baud_sel is 
				when x"2" => baud_sw <= "000" ; -- 110
				when x"3" => baud_sw <= "100" ; -- 300
				when x"6" => baud_sw <= "101" ; -- 600
				when x"7" => baud_sw <= "010" ; -- 1200
				when x"a" => baud_sw <= "011" ; -- 2400
				when x"c" => baud_sw <= "110" ; -- 4800
				when x"e" => baud_sw <= "111" ; -- 9600
				when others => baud_sw <= "111" ;    -- 19200
			end case;
		
			if addr = "00" and cs_n='0' and iow_n='0' then RX_RESET <= '1' ; end if ;
			if addr = "00" and cs_n='0' and ior_n='0' then DO <= UART_CTS & UART_DSR & UART_CD & "000" & UART_RXD & UART_RXD  ; end if ;
			if addr = "01" and cs_n='0' and ior_n='0' then DO <= "01101" & baud_sw  ; end if ;
			if addr = "10" and cs_n='0' and ior_n='0' then DO <= RX_BUFFER_READY & not (TX_BUFFER_READY or TX_BUFFER_READY_SET)
																				& UART_OVERRUN & UART_FRAME &  "0000" ; end if;
			if (addr = "10") and (cs_n='0') and (iow_n='0') then
				UART_DTR <= DI(0); 
				UART_RTS <= DI(1); 
				UART_BRK <= DI(2); 
			end if ;
			if (addr = "11") and (cs_n='0') and (iow_n='0')  and (TX_BUFFER_READY='0') and (TX_BUFFER_READY_SET='0') then
				TX_BUFFER <= DI ;
				--TX_BUFFER_READY <= '1' ;
				TX_BUFFER_READY_SET <= '1' ;
			end if ;
			if (addr = "11") and (cs_n='0') and (ior_n='0')  then 
				DO <= RX_BUFFER ;
				-- RX_BUFFER_READY <= '0' ;
				RX_BUFFER_READY_CLR <= '1' ;
			end if ;
		end if ;
	end if;
end process;	

process(reset, clk_rs16)
begin
   if (reset='1') then
		TX_BUFFER_READY <= '0' ;
		TX_STATE <= "0000" ;
		TX_STATE_CTR <= "0000" ;
		UART_TXD <= '1' ;
	elsif rising_edge(clk_rs16) then
		if TX_BUFFER_READY_SET='1' then TX_BUFFER_READY<='1' ; end if ;
		TX_STATE_CTR <= TX_STATE_CTR + 1 ; -- divide clock by 16
		case TX_STATE is
		when "0000" => if TX_BUFFER_READY='1' then
					TX_SHIFT <= TX_BUFFER  ;  -- no parity, one stop
					TX_BUFFER_READY <= '0' ;
					TX_STATE <= "0001" ;  -- sync clock from this start bit
					UART_TXD <= not UART_BRK; -- start bit now
					TX_STATE_CTR <= "0000" ;
				end if;
		when "1010" => if TX_STATE_CTR=15 then
					TX_STATE <= "0000" ;
					UART_TXD <= '1'; 
				end if;
		when others => if TX_STATE_CTR=15 then
					UART_TXD <= not UART_BRK or TX_SHIFT(0) ;
					TX_SHIFT <= '1' & TX_SHIFT(7 downto 1) ;
				   TX_STATE <= TX_STATE+1 ;	
				end if;
		end case ;
	end if;
end process;


process(reset, clk_rs16)
begin
   if (reset='1') then
		RX_STATE <= "0000" ;
		RX_STATE_CTR <= "0000" ;
		RX_BUFFER_READY <= '0' ;
		UART_OVERRUN <= '0' ;
		UART_FRAME <= '0' ;
		RX_BUFFER <= "00000000" ;
		RX_RESET_CLR <= '0' ;
	elsif rising_edge(clk_rs16) then
	   if RX_RESET='1' then
			UART_OVERRUN <= '0' ;
			UART_FRAME <= '0' ;
			RX_BUFFER_READY <= '0' ;
			RX_BUFFER <= "00000000" ;
			RX_RESET_CLR <= '1' ;
		else 
			RX_RESET_CLR<='0' ;
		end if ;
	
		if RX_BUFFER_READY_CLR='1' then RX_BUFFER_READY<='0' ; end if ;
		RX_STATE_CTR <= RX_STATE_CTR + 1 ;
		UART_RXD_PREV <= UART_RXD ;
	   case RX_STATE is
	   when "0000" => if UART_RXD='0' and UART_RXD_PREV='1' then -- start bit 
				RX_STATE <= "0001" ;
				RX_STATE_CTR <= "0111" ; -- position to half-bit 
			end if;
		when "0001" => if RX_STATE_CTR=0 then
		
				-- RX_SHIFT <= UART_RXD & "0000000" ;
				RX_SHIFT <= "00000000" ;
				RX_STATE <= "0010" ;
			end if;
		when "1010" => if RX_STATE_CTR=0 then
				if UART_RXD='0' or UART_FRAME='1' then UART_FRAME<='1' ; end if; -- must be zero or its an error
				if RX_BUFFER_READY='1' or UART_OVERRUN='1' then UART_OVERRUN<='1' ; end if; 
				if (RX_BUFFER_READY='0') then
					RX_BUFFER <= RX_SHIFT ;
					RX_BUFFER_READY <= '1' ;
				end if;
				RX_STATE <= "0000" ;
			end if;
		when others => if RX_STATE_CTR=0 then
				RX_SHIFT <= UART_RXD & RX_SHIFT(7 downto 1) ;
				RX_STATE <= RX_STATE+1 ;
			end if;
	   end case;
	end if;
end process;	

end Behavioral;

-- Micro_RS232 for the MiSTer TRS-80 core
-- theflynn49 11/2024
-- 
-- Clock generator; Mister App will be the driver for the speed, so this always fits.
	
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
	
	
entity m_rs232_gclk is
Port (
	clk42m     : in  std_logic;  -- 42.578Mhz
	reset      : in  std_logic;  
	
	speed		  : in  std_logic_vector (31 downto 0) ;
	clk_rs16   : out std_logic ; -- RS232 clock *16
	baud_sel   : out std_logic_vector(3 downto 0) 
);

end m_rs232_gclk;

architecture Behavioral of m_rs232_gclk is

signal clk_counter : std_logic_vector(15 downto 0) ;
signal clk_out : std_logic ;
signal baud_div : std_logic_vector(15 downto 0) ;

begin

process(clk42m, reset)
begin	
	if reset='1' then
		clk_rs16 <= '0';
		clk_counter <= x"0001";
		baud_div <= x"08aa" ;
		baud_sel <= x"a" ;
		clk_out <= '0' ;
		clk_rs16 <= '0' ;
	else
		if rising_edge(clk42m) then	
			if (speed (31 downto  8)) = x"0000" then baud_div <= x"22a6"; baud_sel <= x"2" ; elsif  --  110 bauds
				(speed (31 downto  9)) = x"0000" then baud_div <= x"1153"; baud_sel <= x"3" ; elsif  --  300 bauds
				(speed (31 downto 10)) = x"0000" then baud_div <= x"08aa"; baud_sel <= x"6" ; elsif  --  600 bauds
				(speed (31 downto 11)) = x"0000" then baud_div <= x"0455"; baud_sel <= x"7" ; elsif  -- 1200 bauds
				(speed (31 downto 12)) = x"0000" then baud_div <= x"022a"; baud_sel <= x"a" ; elsif  -- 2400 bauds
				(speed (31 downto 13)) = x"0000" then baud_div <= x"0115"; baud_sel <= x"c" ; elsif  -- 4800 bauds
				(speed (31 downto 14)) = x"0000" then baud_div <= x"008b"; baud_sel <= x"e" ; else   -- 9600 bauds
								baud_div <= x"0045"; -- 19200 bauds
								baud_sel <= x"f"; 
			end if;	
		
			if clk_counter = 1 then
				clk_out <= not clk_out ;
				clk_rs16 <= not clk_out ;
				clk_counter <= baud_div;   
			else 
				clk_counter <= clk_counter - 1;
			end if;
		end if;
	end if;
end process;
	
end Behavioral;
