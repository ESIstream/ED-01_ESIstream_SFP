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

entity esistream_encoding is
port (
	clk					: in std_logic;
	sync				: in std_logic;												-- Resets LFSR, disparity and starts synchronization
	prbs_en				: in std_logic;												-- Enables scrambling processing
	disp_en				: in std_logic;												-- Enables disparity processing
	data_in				: in std_logic_vector(13 downto 0);							-- Input data to encode
	data_out			: out std_logic_vector(15 downto 0) := X"0000"				-- Output endoded data
);
end entity esistream_encoding;

architecture rtl of esistream_encoding is

---------- Components ----------
component scrambling_lfsr is
port (
	clk			: in std_logic;
	init	 	: in std_logic;													-- Initialize LFSR with init_value
	init_value  : in std_logic_vector(16 downto 0) := "11111111111111111";     	-- Initial value of LFSR
	lfsr_out	: out std_logic_vector(13 downto 0)                             -- PRBS word out
);
end component scrambling_lfsr;

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

component process_disparity is
port (
	clk			: in std_logic;
	rst			: in std_logic;										-- Resets disparity counter
	disp_en		: in std_logic;										-- Enables disparity processing
	data_in		: in std_logic_vector(15 downto 0);
	data_out	: out std_logic_vector(15 downto 0)
);
end component process_disparity;

---------- Signals ----------
signal data_lfsr		: std_logic_vector(13 downto 0) := "00000000000000";
signal data_scrambled	: std_logic_vector(15 downto 0) := "0000000000000000";

begin

scrambling_lfsr_inst: scrambling_lfsr
port map(
	clk			=> clk,
	init	 	=> sync,
	init_value  => "11111111111111111",
	lfsr_out	=> data_lfsr
);

process_scrambling_inst: process_scrambling
port map(
	clk			=> clk,
	sync		=> sync,
	prbs_en		=> prbs_en,
	data_in		=> data_in,
	data_prbs	=> data_lfsr,
	data_out	=> data_scrambled
);

process_disparity_inst: process_disparity
port map(
	clk			=> clk,
	rst			=> sync,
	disp_en		=> disp_en,
	data_in		=> data_scrambled,
	data_out	=> data_out
);

end architecture rtl;
