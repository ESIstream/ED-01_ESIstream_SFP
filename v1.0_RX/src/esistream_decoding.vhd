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

entity esistream_decoding is
generic (
	DESER_FACTOR		: integer := 16;											-- Deserialization factor / For ESIstream 16
	DATA_LENGTH			: integer := 14												-- Length of useful data / For ESIstream 14
	);
port (
	clk 				: in std_logic;											
	data_in 			: in std_logic_vector(DESER_FACTOR-1 downto 0);				-- Input aligned frames
	prbs_value 			: in std_logic_vector(DATA_LENGTH-1 downto 0);				-- Input PRBS value to descramble data
	prbs_ctrl			: in std_logic;												-- Signal to configure if descrambling is enabled ('1') or not ('0')
	data_out			: out std_logic_vector(DATA_LENGTH-1 downto 0);				-- Output decoded data
	clk_bit				: out std_logic;											-- Output ESIstream clk bit
	disp_bit			: out std_logic												-- Output ESIstream disparity bit
	);
end entity esistream_decoding;

architecture rtl of esistream_decoding is

signal data_in_t			: std_logic_vector(DESER_FACTOR-1 downto 0) := X"0000";				-- Input aligned frames buffer

signal data_out_t 			: std_logic_vector(DATA_LENGTH-1 downto 0) := "00000000000000";		-- Temp data_out
signal clk_bit_t			: std_logic := '0';													-- Temp clk_bit
signal disp_bit_t			: std_logic := '0';													-- Temp disp_bit

begin

-- Output affectations
data_out 		<= data_out_t;

-- Buffer inputs
data_in_t 		<= data_in;
clk_bit			<= clk_bit_t;
disp_bit		<= disp_bit_t;

process(clk)
begin
if rising_edge(clk) then
	if data_in_t(15) = '1' then									-- disparity bit = '1', data inverted
		if prbs_ctrl = '0' then									-- prbs not applied
			data_out_t 		<= not( data_in_t(DATA_LENGTH-1 downto 0) );
			clk_bit_t		<= not data_in_t(DATA_LENGTH);
			disp_bit_t 		<= data_in_t(DATA_LENGTH+1);
		else 													-- prbs applied
			data_out_t 		<= not( data_in_t(DATA_LENGTH-1 downto 0) ) xor prbs_value;
			clk_bit_t		<= not data_in_t(DATA_LENGTH);
			disp_bit_t 		<= data_in_t(DATA_LENGTH+1);
		end if;
	else														-- disparity bit = '0', data not inverted
		if prbs_ctrl = '0' then									-- prbs not applied
			data_out_t 		<= data_in_t(DATA_LENGTH-1 downto 0);
			clk_bit_t		<= data_in_t(DATA_LENGTH);
			disp_bit_t 		<= data_in_t(DATA_LENGTH+1);
		else 													-- prbs applied
			data_out_t 		<= data_in_t(DATA_LENGTH-1 downto 0) xor prbs_value;
			clk_bit_t		<= data_in_t(DATA_LENGTH);
			disp_bit_t 		<= data_in_t(DATA_LENGTH+1);
		end if;
	end if;
end if;
end process;

end architecture rtl;