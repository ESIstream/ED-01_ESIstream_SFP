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

entity tb_process_disparity is
end entity tb_process_disparity;

architecture simulate of tb_process_disparity is

---------- Device under test ----------
component process_disparity is
port (
	clk			: in std_logic;
	rst			: in std_logic;										-- Resets disparity counter
	disp_en		: in std_logic;										-- Enables disparity processing
	data_in		: in std_logic_vector(15 downto 0);
	data_out	: out std_logic_vector(15 downto 0)
);
end component process_disparity;

---------- Constants ----------		
constant Tclk	: time := 10000 ps;

---------- Signals ----------
signal clk_t		: std_logic := '1';
signal rst_t		: std_logic := '1';
signal disp_en_t	: std_logic := '0';
signal data_in_t	: std_logic_vector(15 downto 0) := X"00FF";
signal data_out_t	: std_logic_vector(15 downto 0);

begin

dut: process_disparity 
port map (
	clk				=> clk_t,
	rst				=> rst_t,
	disp_en			=> disp_en_t,
	data_in			=> data_in_t,
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
		rst_t		<= '1';
		disp_en_t	<= '0';
		data_in_t	<= X"0000";

	wait for Tclk/2;
-- ********************

-- ********** TEST 1 **********
		rst_t		<= '1';
	
	wait for Tclk;
		rst_t		<= '0';
		disp_en_t	<= '0';
		data_in_t	<= X"FFFF";
	
	wait for 5*Tclk;
-- ********************

-- ********** TEST 2 **********
		rst_t		<= '1';
	
	wait for Tclk;
		rst_t		<= '0';
		disp_en_t	<= '0';
		data_in_t	<= X"0000";
	
	wait for 5*Tclk;
-- ********************

-- ********** TEST 3 **********
		rst_t		<= '1';
	
	wait for Tclk;
		rst_t		<= '0';
		disp_en_t	<= '1';
		data_in_t	<= X"00FF";
	
	wait for 5*Tclk;
-- ********************

-- ********** TEST 4 **********
		rst_t		<= '1';
	
	wait for Tclk;
		rst_t		<= '0';
		disp_en_t	<= '1';
		data_in_t	<= X"01FF";
	
	wait for 20*Tclk;
-- ********************

-- ********** TEST 5 **********
		rst_t		<= '1';
	
	wait for Tclk;
		rst_t		<= '0';
		disp_en_t	<= '1';
		data_in_t	<= X"007F";
	
	wait for 20*Tclk;
-- ********************

	wait;
	
end process;

end architecture simulate;
