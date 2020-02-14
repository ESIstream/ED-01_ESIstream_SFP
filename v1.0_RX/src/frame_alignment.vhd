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
use ieee.std_logic_arith.all;

entity frame_alignment is
generic (
	DESER_FACTOR		: integer := 16;													-- Deserialization factor / For ESIstream 16
	COMMA				: std_logic_vector(31 downto 0) := X"00FFFF00"						-- COMMA to look for	
	);
port (
	clk 				: in std_logic;
	data_in		 		: in std_logic_vector(DESER_FACTOR-1 downto 0);						-- Input misaligned frames 
	start_align			: in std_logic;														-- Pulse when start synchronization
	data_out			: out std_logic_vector(DESER_FACTOR-1 downto 0);					-- Output aligned frames
	frame_align			: out std_logic														-- Indicates that frame alignment is done
	);
end entity frame_alignment;

architecture rtl of frame_alignment is

signal data_buf 			: std_logic_vector(DESER_FACTOR*2-1 downto 0) := X"00000000";			-- buffer used to get aligned data
signal data_buf_comma 		: std_logic_vector(DESER_FACTOR*3-1 downto 0) := X"000000000000";		-- buffer used to look for COMMA
signal bitslip 				: std_logic_vector(3 downto 0) := "0000";								-- number of bit slip to align frames
			
signal data_out_t 			: std_logic_vector(DESER_FACTOR-1 downto 0) := X"0000";					
signal frame_align_t 		: std_logic_vector(1 downto 0) := "00";									-- If '1' frame alignment done
signal start_align_t 		: std_logic := '0';														-- If '1', frame alignment in progress
signal bitslip_t 			: std_logic_vector(DESER_FACTOR-1 downto 0) := X"0000";					-- Temp bitslip

begin

-- Output affectations
data_out 						<= data_out_t;
frame_align						<= frame_align_t(1);

process(clk)
begin

if rising_edge(clk) then
	
	-- Normal operation
	data_out_t 		<= data_buf(conv_integer(bitslip)+DESER_FACTOR downto conv_integer(bitslip)+1); 

	-- Buffer inputs
	data_buf( 2*DESER_FACTOR-1 downto DESER_FACTOR ) 				<= data_in;
	data_buf_comma( 3*DESER_FACTOR-1 downto 2*DESER_FACTOR ) 		<= data_in;
	
	-- Update buffer
	data_buf( DESER_FACTOR-1 downto 0 ) 			<= data_buf( 2*DESER_FACTOR-1 downto DESER_FACTOR );
	
	data_buf_comma( 2*DESER_FACTOR-1 downto DESER_FACTOR ) 		<= data_buf_comma( 3*DESER_FACTOR-1 downto 2*DESER_FACTOR );
	data_buf_comma( DESER_FACTOR-1 downto 0 ) 					<= data_buf_comma( 2*DESER_FACTOR-1 downto DESER_FACTOR );
	
	frame_align_t(1) 											<= frame_align_t(0);

	-- Alignment is asked
	if start_align = '1' then
		
		frame_align_t(0) 		<= '0';
		start_align_t 			<= '1';
		
	-- COMMA is looked for	
	elsif start_align_t = '1' then

		for i in DESER_FACTOR-1 downto 0 loop
		
			if data_buf_comma(i+DESER_FACTOR*2 downto i+1) = COMMA then
				bitslip_t(i) <= '1';
			else 
				bitslip_t(i) <= '0';
			end if; 
			
			if bitslip_t(i) = '1' then
				bitslip 			<= conv_std_logic_vector(i, 4);
				frame_align_t(0) 		<= '1';
				start_align_t 		<= '0';
			end if;
		end loop;
	
	end if;
	
end if;

end process;

end architecture rtl;
