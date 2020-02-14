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
use ieee.numeric_std.ALL;

use work.functions.all;

entity process_disparity is
port (
	clk			: in std_logic;
	rst			: in std_logic;										-- Resets disparity counter
	disp_en		: in std_logic;										-- Enables disparity processing
	data_in		: in std_logic_vector(15 downto 0);
	data_out	: out std_logic_vector(15 downto 0)
);
end entity process_disparity;

architecture rtl of process_disparity is

---------- Signals ----------
signal rst_buf		: std_logic_vector(2 downto 0);
signal data_in_buf	: std_logic_vector(15 downto 0);
signal disp_en_buf	: std_logic := '0';

signal cnt_disp		: integer range 0 to 32;
signal cnt_data_in	: integer range 0 to 15;

begin

process(clk)
begin

if rising_edge(clk) then

rst_buf(0)				<= rst;
rst_buf(2 downto 1)		<= rst_buf(1 downto 0);	

if rst_buf(2) = '1' then
	data_in_buf		<= "0101010101010101";
	data_out		<= X"5555";
	disp_en_buf		<= '0';
	
	cnt_disp		<= 16;
	cnt_data_in		<= 8;
	
else
	data_in_buf		<= data_in;
	disp_en_buf		<= disp_en;
	
	cnt_data_in		<= sl2int(data_in(0)) + sl2int(data_in(1)) + sl2int(data_in(2)) + sl2int(data_in(3)) + sl2int(data_in(4)) + sl2int(data_in(5)) + sl2int(data_in(6)) + sl2int(data_in(7)) + sl2int(data_in(8)) + sl2int(data_in(9)) + sl2int(data_in(10)) + sl2int(data_in(11)) + sl2int(data_in(12)) + sl2int(data_in(13)) + sl2int(data_in(14)) + sl2int(data_in(15)); 
	
	if disp_en_buf = '0' then
		data_out	<= data_in_buf;
		
	elsif ((cnt_disp + 2*cnt_data_in < 49) and (cnt_disp + 2*cnt_data_in > 15)) then
		data_out	<= data_in_buf;
		cnt_disp	<= cnt_disp + 2*cnt_data_in - 16;
		
	else
		data_out	<= '1' & (not data_in_buf(14 downto 0));
		cnt_disp	<= cnt_disp + 16 - 2*cnt_data_in;
	end if;
		
end if;

end if;

end process;

end architecture rtl;
	