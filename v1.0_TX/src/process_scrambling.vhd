-------------------------------------------------------------------------------
-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or distribute
-- this software, either in source code form or as a compiled bitstream, for 
-- any purpose, commercial or non-commercial, and by any means.
--
-- In jurisdictions that recognize copyright laws, the author or authors of 
-- this software dedicate any and all copyright interest in the software to 
-- the public domain. We make this dedication for the benefit of the public at
-- large and to the detriment of our heirs and successors. We intend this 
-- dedication to be an overt act of relinquishment in perpetuity of all present
-- and future rights to this software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN 
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--
-- THIS DISCLAIMER MUST BE RETAINED AS PART OF THIS FILE AT ALL TIMES. 
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity process_scrambling is
port (
	clk			: in std_logic;
	sync		: in std_logic;										-- Start synchronization sequence
	prbs_en		: in std_logic;										-- Enables scrambling processing
	data_in		: in std_logic_vector(13 downto 0);
	data_prbs	: in std_logic_vector(13 downto 0);
	data_out	: out std_logic_vector(15 downto 0)
);
end entity process_scrambling;

architecture rtl of process_scrambling is

---------- Signals ----------
signal state		: std_logic := '0';				-- '0': NORMAL_OPERATION; '1':SYNC_SEQUENCE

signal sync_buf		: std_logic_vector(1 downto 0) := "00";
signal flash_seq	: std_logic_vector(15 downto 0) := X"00FF";
signal clk_bit		: std_logic := '0';
signal cnt_sync		: std_logic_vector(5 downto 0) := "000000";

begin

process(clk)
begin

if rising_edge(clk) then

	sync_buf(0)		<= sync;
	sync_buf(1)		<= sync_buf(0);

case state is
	when '0' 	=>
		if sync_buf = "10" then
			state		<= '1';
			cnt_sync	<= (others => '0');
			clk_bit		<= '0';
			flash_seq	<= X"00FF";
		else
			clk_bit		<= not clk_bit;
		end if;
	
		if prbs_en = '1' then
			data_out		<= '0' & clk_bit & (data_in xor data_prbs);
		else
			data_out		<= '0' & clk_bit & data_in;
		end if;
	
	when '1'	 =>
		cnt_sync		<= cnt_sync + 1;
		flash_seq		<= not flash_seq;
		clk_bit			<= not clk_bit;
		
		if cnt_sync = "111111" then
			state			<=	'0';
			data_out		<= '0' & clk_bit & data_prbs;
		elsif cnt_sync(5) = '0' then
			data_out		<= flash_seq;
		else
			data_out		<= '0' & clk_bit & data_prbs;
		end if;
	
end case;

end if;

end process;

end architecture rtl;
	