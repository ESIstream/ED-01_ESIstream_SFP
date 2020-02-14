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

entity scrambling_lfsr is
port (
	clk					: in std_logic;
	init	 			: in std_logic;													-- Initialize LFSR with init_value
	init_value  		: in std_logic_vector(16 downto 0) := "11111111111111111";     	-- Initial value of LFSR
	lfsr_out			: out std_logic_vector(13 downto 0)                             -- PRBS word out
);
end entity scrambling_lfsr;

architecture rtl of scrambling_lfsr is

---------- Signals ----------
signal lfsr_out_t : std_logic_vector(16 downto 0) := "11111111111111111";

begin
	
lfsr_out 		<= lfsr_out_t(13 downto 0);	

process(clk)
begin

if rising_edge(clk) then

	if init = '1' then
		lfsr_out_t 			<= init_value;
	else
		lfsr_out_t(0) 		<= lfsr_out_t(14);
		lfsr_out_t(1) 		<= lfsr_out_t(15);
		lfsr_out_t(2) 		<= lfsr_out_t(16);
		lfsr_out_t(3) 		<= lfsr_out_t(0) xor lfsr_out_t(3);
		lfsr_out_t(4) 		<= lfsr_out_t(1) xor lfsr_out_t(4);
		lfsr_out_t(5) 		<= lfsr_out_t(2) xor lfsr_out_t(5);
		lfsr_out_t(6) 		<= lfsr_out_t(3) xor lfsr_out_t(6);
		lfsr_out_t(7) 		<= lfsr_out_t(4) xor lfsr_out_t(7);
		lfsr_out_t(8) 		<= lfsr_out_t(5) xor lfsr_out_t(8);
		lfsr_out_t(9) 		<= lfsr_out_t(6) xor lfsr_out_t(9);
		lfsr_out_t(10) 		<= lfsr_out_t(7) xor lfsr_out_t(10);
		lfsr_out_t(11) 		<= lfsr_out_t(8) xor lfsr_out_t(11);
		lfsr_out_t(12) 		<= lfsr_out_t(9) xor lfsr_out_t(12);
		lfsr_out_t(13) 		<= lfsr_out_t(10) xor lfsr_out_t(13);
		lfsr_out_t(14) 		<= lfsr_out_t(11) xor lfsr_out_t(14);
		lfsr_out_t(15) 		<= lfsr_out_t(12) xor lfsr_out_t(15);
		lfsr_out_t(16) 		<= lfsr_out_t(13) xor lfsr_out_t(16);
	end if;

end if;

end process;

end architecture rtl;
