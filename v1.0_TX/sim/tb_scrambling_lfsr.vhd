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

entity tb_scrambling_lfsr is
end entity tb_scrambling_lfsr;

architecture simulate of tb_scrambling_lfsr is

---------- Device under test ----------
component scrambling_lfsr is
port (
	clk					: in std_logic;
	init	 			: in std_logic;												-- Initialize LFSR with init_value
	init_value  		: in std_logic_vector(16 downto 0) := "11111111111111111";     -- Initial value of LFSR
	lfsr_out			: out std_logic_vector(13 downto 0)                             -- PRBS word out
	) ;
end component scrambling_lfsr;

---------- Constants ----------		
constant Tclk	: time := 10000 ps;

---------- Signals ----------
signal clk_t		: std_logic := '1';
signal init_t		: std_logic := '0';
signal init_value_t	: std_logic_vector(16 downto 0) := "11111111111111111";
signal lfsr_out_t	: std_logic_vector(13 downto 0) := "00000000000000";

begin

dut: scrambling_lfsr 
port map (
	clk				=> clk_t,
	init			=> init_t,
	init_value		=> init_value_t,
	lfsr_out		=> lfsr_out_t
);

-- Clocks generation
clk_generation: process
begin
	wait for Tclk / 2;
		clk_t 	<= not clk_t;
		
end process;

-- Stimuli
process
begin
-- ********************
-- INIT DEFAULT VALUE
		init_t			<= '0';
		init_value_t	<= "11111111111111111";

	wait for Tclk/2;
-- ********************

-- ********** TEST 1 **********
		init_t			<= '1';
		init_value_t	<= "11111111111111111";
	
	wait for Tclk;
		init_t			<= '0';
	
	wait for 10*Tclk;
-- ********************

-- ********** TEST 2 **********
		init_t			<= '1';
		init_value_t	<= "01010101010101010";
	
	wait for Tclk;
		init_t			<= '0';
	
	wait for 10*Tclk;
-- ********************

	wait;
	
end process;

end architecture simulate;
