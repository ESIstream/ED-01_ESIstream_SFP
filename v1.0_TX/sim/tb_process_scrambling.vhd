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

entity tb_process_scrambling is
end entity tb_process_scrambling;

architecture simulate of tb_process_scrambling is

---------- Device under test ----------
component process_scrambling is
port (
	clk			: in std_logic;
	sync		: in std_logic;										-- Start synchronization sequence
	prbs_en		: in std_logic;										-- Enables scrambling processing
	data_in		: in std_logic_vector(13 downto 0);
	data_prbs	: in std_logic_vector(13 downto 0);
	data_out	: out std_logic_vector(15 downto 0)
);
end component process_scrambling;

---------- Constants ----------		
constant Tclk	: time := 10000 ps;

---------- Signals ----------
signal clk_t		: std_logic := '1';
signal sync_t		: std_logic := '0';
signal prbs_en_t	: std_logic := '0';
signal data_in_t	: std_logic_vector(13 downto 0) := "00000000000000";
signal data_prbs_t	: std_logic_vector(13 downto 0) := "00000000001111";
signal data_out_t	: std_logic_vector(15 downto 0);

begin

dut: process_scrambling 
port map (
	clk				=> clk_t,
	sync			=> sync_t,
	prbs_en			=> prbs_en_t,
	data_in			=> data_in_t,
	data_prbs		=> data_prbs_t,
	data_out		=> data_out_t
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
		sync_t		<= '0';
		prbs_en_t	<= '0';
		data_in_t	<= "00000000000000";
		data_prbs_t	<= "00000000001111";

	wait for Tclk/2;
-- ********************

-- ********** TEST 1 **********
		sync_t		<= '1';
	
	wait for Tclk;
		sync_t		<= '0';
		prbs_en_t	<= '0';
		data_in_t	<= "00000000000000";
		data_prbs_t	<= "00000000001111";
	
	wait for 100*Tclk;
-- ********************

-- ********** TEST 2 **********
		sync_t		<= '1';
	
	wait for Tclk;
		sync_t		<= '0';
		prbs_en_t	<= '1';
		data_in_t	<= "00000000000000";
		data_prbs_t	<= "00000000001111";
	
	wait for 100*Tclk;
-- ********************

	wait;
	
end process;

end architecture simulate;
