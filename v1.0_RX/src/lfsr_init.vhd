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

entity lfsr_init is
generic (
	DESER_FACTOR 				: integer := 16;											-- Deserialization factor / For ESIstream 16
	LFSR_LENGTH					: integer := 17;											-- Length of LFSR / For ESIstream 17
	DATA_LENGTH					: integer := 14												-- Length of useful data / For ESIstream 14
	);
port (
	clk 						: in std_logic; 
	data_in 					: in std_logic_vector(DESER_FACTOR-1 downto 0);				-- Input aligned frames
	frame_align_done 			: in std_logic;												-- Indicates that frame alignment has been done, active high
	init_lfsr 					: out std_logic;											-- Start LFSR
	init_value 					: out std_logic_vector(LFSR_LENGTH-1 downto 0)				-- Initial value of LFSR
);
end entity lfsr_init;

architecture rtl of lfsr_init is

signal data_in_t						: std_logic_vector(DESER_FACTOR-1 downto 0);							-- Input data temp
signal frame_align_done_buf 			: std_logic_vector(1 downto 0) := "00";									-- To recover rising edge of frame_align

signal step 							: std_logic_vector(2 downto 0) := "000";								-- To move through stages of process	
signal start 							: std_logic := '0';														-- Start process of PRBS alignment

signal init_lfsr_t						: std_logic := '0';														
signal init_value_t						: std_logic_vector(LFSR_LENGTH-1 downto 0) := "11111111111111111";		-- Output buffer
signal value_temp 						: std_logic_vector(LFSR_LENGTH-1 downto 0) := "11111111111111111";		

begin

-- Output affectation
init_lfsr 						<= init_lfsr_t;
init_value						<= init_value_t;

-- Input affectation
data_in_t						<= data_in;
frame_align_done_buf(0) 		<= frame_align_done;

process(clk)
begin

if rising_edge(clk) then	

	frame_align_done_buf(1) 	<= frame_align_done_buf(0);
	
	step(2 downto 1) 			<= step(1 downto 0);
	
	if frame_align_done_buf = "01" then   	-- rising edge of frame_align_done, start PRBS alignment process
		start 					<= '1';		
		value_temp 				<= (others => '0');
	end if;
	
	if start = '1' and data_in_t /= X"FF00" and data_in_t /= X"00FF" then			-- PRBS sequence of synchronization sequence
		step(0) 			<= '1';			
		start 				<= '0';		
	else
		step(0) 			<= '0';
	end if;
	
	if step(0) = '1' then		-- Recovering LFSR initial value (14bits)
		if data_in_t(15) = '1' then	-- Take disparity into account
			value_temp(DATA_LENGTH-1 downto 0) 		<= not data_in_t(DATA_LENGTH-1 downto 0);
		else
			value_temp(DATA_LENGTH-1 downto 0) 		<= data_in_t(DATA_LENGTH-1 downto 0);
		end if;

	elsif step(1) = '1' then	-- Recovering LFSR initial value (3bits) => total LFSR init value of 17bits acquired
		if data_in_t(15) = '1' then	-- Take disparity into account
			value_temp(LFSR_LENGTH-1 downto DATA_LENGTH) 		<= not data_in_t(LFSR_LENGTH-DATA_LENGTH-1 downto 0);
		else
			value_temp(LFSR_LENGTH-1 downto DATA_LENGTH) 		<= data_in_t(LFSR_LENGTH-DATA_LENGTH-1 downto 0);
		end if;
		
	elsif step(2) = '1' then	-- Take care of delay between recovering of value_temp and start of LFSR
		init_lfsr_t 			<= '1';
	
		-- -- 3 clk delay
		-- init_value_t(0) 			<= value_temp(8) xor value_temp(14);
		-- init_value_t(1) 			<= value_temp(9) xor value_temp(15);
		-- init_value_t(2) 			<= value_temp(10) xor value_temp(16);
		-- init_value_t(3) 			<= value_temp(11) xor value_temp(0) xor value_temp(3);
		-- init_value_t(4) 			<= value_temp(12) xor value_temp(1) xor value_temp(4);
		-- init_value_t(5) 			<= value_temp(13) xor value_temp(2) xor value_temp(5);
		-- init_value_t(6) 			<= value_temp(14) xor value_temp(3) xor value_temp(6);
		-- init_value_t(7) 			<= value_temp(15) xor value_temp(4) xor value_temp(7);
		-- init_value_t(8) 			<= value_temp(16) xor value_temp(5) xor value_temp(8);
		-- init_value_t(9) 			<= value_temp(0) xor value_temp(3) xor value_temp(6) xor value_temp(9);
		-- init_value_t(10)			<= value_temp(1) xor value_temp(4) xor value_temp(7) xor value_temp(10);
		-- init_value_t(11)			<= value_temp(2) xor value_temp(5) xor value_temp(8) xor value_temp(11);
		-- init_value_t(12)			<= value_temp(3) xor value_temp(6) xor value_temp(9) xor value_temp(12);
		-- init_value_t(13)			<= value_temp(4) xor value_temp(7) xor value_temp(10) xor value_temp(13);
		-- init_value_t(14)			<= value_temp(5) xor value_temp(8) xor value_temp(11) xor value_temp(14);
		-- init_value_t(15)			<= value_temp(6) xor value_temp(9) xor value_temp(12) xor value_temp(15);
		-- init_value_t(16)			<= value_temp(7) xor value_temp(10) xor value_temp(13) xor value_temp(16);
		
		-- 4 clk delay  
		init_value_t(0) 			<= value_temp(5) xor value_temp(8) xor value_temp(11) xor value_temp(14);
		init_value_t(1) 			<= value_temp(6) xor value_temp(9) xor value_temp(12) xor value_temp(15);
		init_value_t(2) 			<= value_temp(7) xor value_temp(10) xor value_temp(13) xor value_temp(16);
		init_value_t(3) 			<= value_temp(0) xor value_temp(3) xor value_temp(8) xor value_temp(11) xor value_temp(14);
		init_value_t(4) 			<= value_temp(1) xor value_temp(4) xor value_temp(9) xor value_temp(12) xor value_temp(15);
		init_value_t(5) 			<= value_temp(2) xor value_temp(5) xor value_temp(10) xor value_temp(13) xor value_temp(16);
		init_value_t(6) 			<= value_temp(0) xor value_temp(6) xor value_temp(11) xor value_temp(14);
		init_value_t(7) 			<= value_temp(1) xor value_temp(7) xor value_temp(12) xor value_temp(15);
		init_value_t(8) 			<= value_temp(2) xor value_temp(8) xor value_temp(13) xor value_temp(16);
		init_value_t(9) 			<= value_temp(0) xor value_temp(9) xor value_temp(14);
		init_value_t(10)			<= value_temp(1) xor value_temp(10) xor value_temp(15);
		init_value_t(11)			<= value_temp(2) xor value_temp(11) xor value_temp(16);
		init_value_t(12)			<= value_temp(0) xor value_temp(12);
		init_value_t(13)			<= value_temp(1) xor value_temp(13);
		init_value_t(14)			<= value_temp(2) xor value_temp(14);
		init_value_t(15)			<= value_temp(3) xor value_temp(15);
		init_value_t(16)			<= value_temp(4) xor value_temp(16);
		
		-- -- 5 clk delay   
		-- init_value_t(0) 			<= value_temp(2) xor value_temp(14) ;
		-- init_value_t(1) 			<= value_temp(3) xor value_temp(15) ;
		-- init_value_t(2) 			<= value_temp(4) xor value_temp(16) ;
		-- init_value_t(3) 			<= value_temp(0) xor value_temp(3) xor value_temp(5);
		-- init_value_t(4) 			<= value_temp(1) xor value_temp(4) xor value_temp(6);
		-- init_value_t(5) 			<= value_temp(2) xor value_temp(5) xor value_temp(7);
		-- init_value_t(6) 			<= value_temp(3) xor value_temp(6) xor value_temp(8);
		-- init_value_t(7) 			<= value_temp(4) xor value_temp(7) xor value_temp(9);
		-- init_value_t(8) 			<= value_temp(5) xor value_temp(8) xor value_temp(10);
		-- init_value_t(9) 			<= value_temp(6) xor value_temp(9) xor value_temp(11);
		-- init_value_t(10) 		<= value_temp(7) xor value_temp(10) xor value_temp(12);
		-- init_value_t(11) 		<= value_temp(8) xor value_temp(11) xor value_temp(13);
		-- init_value_t(12) 		<= value_temp(9) xor value_temp(12) xor value_temp(14);
		-- init_value_t(13) 		<= value_temp(10) xor value_temp(13) xor value_temp(15);
		-- init_value_t(14) 		<= value_temp(11) xor value_temp(14) xor value_temp(16);
		-- init_value_t(15) 		<= value_temp(0) xor value_temp(3) xor value_temp(12) xor value_temp(15);
		-- init_value_t(16) 		<= value_temp(1) xor value_temp(4) xor value_temp(13) xor value_temp(16);	

		-- -- 6 clk delay  
		-- init_value_t(0) 			<= value_temp(11) xor value_temp(14) xor value_temp(16);
		-- init_value_t(1) 			<= value_temp(0) xor value_temp(3) xor value_temp(12) xor value_temp(15);
		-- init_value_t(2) 			<= value_temp(1) xor value_temp(4) xor value_temp(13) xor value_temp(16);
		-- init_value_t(3) 			<= value_temp(0) xor value_temp(2) xor  value_temp(3) xor value_temp(5) xor value_temp(14);
		-- init_value_t(4) 			<= value_temp(1) xor value_temp(3) xor  value_temp(4) xor value_temp(6) xor value_temp(15);
		-- init_value_t(5) 			<= value_temp(2) xor value_temp(4) xor  value_temp(5) xor value_temp(7) xor value_temp(16);
		-- init_value_t(6) 			<= value_temp(0) xor value_temp(5) xor value_temp(6) xor value_temp(8);
		-- init_value_t(7) 			<= value_temp(1) xor value_temp(6) xor value_temp(7) xor value_temp(9);
		-- init_value_t(8) 			<= value_temp(2) xor value_temp(7) xor value_temp(8) xor value_temp(10);
		-- init_value_t(9) 			<= value_temp(3) xor value_temp(8) xor value_temp(9) xor value_temp(11);
		-- init_value_t(10) 		<= value_temp(4) xor value_temp(9) xor value_temp(10) xor value_temp(12);
		-- init_value_t(11) 		<= value_temp(5) xor value_temp(10) xor value_temp(11) xor value_temp(13);
		-- init_value_t(12) 		<= value_temp(6) xor value_temp(11) xor value_temp(12) xor value_temp(14);
		-- init_value_t(13) 		<= value_temp(7) xor value_temp(12) xor value_temp(13) xor value_temp(15);
		-- init_value_t(14) 		<= value_temp(8) xor value_temp(13) xor value_temp(14) xor value_temp(16);
		-- init_value_t(15) 		<= value_temp(0) xor value_temp(3) xor value_temp(9) xor value_temp(14) xor value_temp(15);
		-- init_value_t(16) 		<= value_temp(1) xor value_temp(4) xor value_temp(10) xor value_temp(15) xor value_temp(16);	

		-- -- 7 clk delay  
		-- init_value_t(0) 			<= value_temp(8) xor value_temp(13) xor value_temp(14) xor value_temp(16);	
		-- init_value_t(1) 			<= value_temp(0) xor value_temp(3) xor value_temp(9) xor value_temp(14) xor value_temp(15);
		-- init_value_t(2) 			<= value_temp(1) xor value_temp(4) xor value_temp(10) xor value_temp(15) xor value_temp(16);
		-- init_value_t(3) 			<= value_temp(0) xor value_temp(2) xor value_temp(3) xor value_temp(5) xor value_temp(11) xor value_temp(16);
		-- init_value_t(4) 			<= value_temp(0) xor value_temp(1) xor value_temp(4) xor value_temp(6) xor value_temp(12);
		-- init_value_t(5) 			<= value_temp(1) xor value_temp(2) xor value_temp(5) xor value_temp(7) xor value_temp(13);
		-- init_value_t(6) 			<= value_temp(2) xor value_temp(3) xor value_temp(6) xor value_temp(8) xor value_temp(14);
		-- init_value_t(7) 			<= value_temp(3) xor value_temp(4) xor value_temp(7) xor value_temp(9) xor value_temp(15);
		-- init_value_t(8) 			<= value_temp(4) xor value_temp(5) xor value_temp(8) xor value_temp(10) xor value_temp(16);
		-- init_value_t(9) 			<= value_temp(0) xor value_temp(3) xor value_temp(5) xor value_temp(6) xor value_temp(9) xor value_temp(11);
		-- init_value_t(10) 		<= value_temp(1) xor value_temp(4) xor value_temp(6) xor value_temp(7) xor value_temp(10) xor value_temp(12);
		-- init_value_t(11) 		<= value_temp(2) xor value_temp(5) xor value_temp(7) xor value_temp(8) xor value_temp(11) xor value_temp(13);
		-- init_value_t(12) 		<= value_temp(3) xor value_temp(6) xor value_temp(8) xor value_temp(9) xor value_temp(12) xor value_temp(14);
		-- init_value_t(13) 		<= value_temp(4) xor value_temp(7) xor value_temp(9) xor value_temp(10) xor value_temp(13) xor value_temp(15);
		-- init_value_t(14) 		<= value_temp(5) xor value_temp(8) xor value_temp(10) xor value_temp(11) xor value_temp(14) xor value_temp(16);
		-- init_value_t(15) 		<= value_temp(0) xor value_temp(3) xor value_temp(6) xor value_temp(9) xor value_temp(11) xor value_temp(12) xor value_temp(15);
		-- init_value_t(16) 		<= value_temp(1) xor value_temp(4) xor value_temp(7) xor value_temp(10) xor value_temp(12) xor value_temp(13) xor value_temp(16);
	
		-- -- 8 clk delay
		-- init_value_t(0) 			<= value_temp(5) xor value_temp(8) xor value_temp(10) xor value_temp(11) xor value_temp(14) xor value_temp(16);	
		-- init_value_t(1) 			<= value_temp(0) xor value_temp(3) xor value_temp(6) xor value_temp(9) xor value_temp(11) xor value_temp(12) xor value_temp(15);
		-- init_value_t(2) 			<= value_temp(1) xor value_temp(4) xor value_temp(7) xor value_temp(10) xor value_temp(12) xor value_temp(13) xor value_temp(16);
		-- init_value_t(3) 			<= value_temp(0) xor value_temp(2) xor value_temp(3) xor value_temp(5) xor value_temp(8) xor value_temp(11) xor value_temp(13) xor value_temp(16);
		-- init_value_t(4) 			<= value_temp(1) xor value_temp(3) xor value_temp(4) xor value_temp(6) xor value_temp(9) xor value_temp(12) xor value_temp(14) xor value_temp(15);
		-- init_value_t(5) 			<= value_temp(2) xor value_temp(4) xor value_temp(5) xor value_temp(7) xor value_temp(10) xor value_temp(13) xor value_temp(15) xor value_temp(16);
		-- init_value_t(6) 			<= value_temp(0) xor value_temp(5) xor value_temp(6) xor value_temp(8) xor value_temp(11) xor value_temp(14) xor value_temp(16);
		-- init_value_t(7) 			<= value_temp(0) xor value_temp(1) xor value_temp(3) xor value_temp(6) xor value_temp(7) xor value_temp(9) xor value_temp(12) xor value_temp(15);
		-- init_value_t(8) 			<= value_temp(1) xor value_temp(2) xor value_temp(4) xor value_temp(7) xor value_temp(8) xor value_temp(10) xor value_temp(13) xor value_temp(16);
		-- init_value_t(9) 			<= value_temp(0) xor value_temp(2) xor value_temp(5) xor value_temp(8) xor value_temp(9) xor value_temp(11) xor value_temp(14);
		-- init_value_t(10) 		<= value_temp(1) xor value_temp(3) xor value_temp(6) xor value_temp(9) xor value_temp(10) xor value_temp(12) xor value_temp(15);
		-- init_value_t(11) 		<= value_temp(2) xor value_temp(4) xor value_temp(7) xor value_temp(10) xor value_temp(11) xor value_temp(13) xor value_temp(16);
		-- init_value_t(12) 		<= value_temp(0) xor value_temp(5) xor value_temp(8) xor value_temp(11) xor value_temp(12) xor value_temp(14);
		-- init_value_t(13) 		<= value_temp(1) xor value_temp(6) xor value_temp(9) xor value_temp(12) xor value_temp(13) xor value_temp(15);
		-- init_value_t(14) 		<= value_temp(2) xor value_temp(7) xor value_temp(10) xor value_temp(13) xor value_temp(14) xor value_temp(16);
		-- init_value_t(15) 		<= value_temp(0) xor value_temp(8) xor value_temp(11) xor value_temp(14) xor value_temp(15);
		-- init_value_t(16) 		<= value_temp(1) xor value_temp(9) xor value_temp(12) xor value_temp(15) xor value_temp(16);
	
		-- -- 9 clk delay  
		-- init_value_t(0) 			<= value_temp(2) xor value_temp(7) xor value_temp(10) xor value_temp(13) xor value_temp(14) xor value_temp(16);	
		-- init_value_t(1) 			<= value_temp(0) xor value_temp(8) xor value_temp(11) xor value_temp(14) xor value_temp(15);	
		-- init_value_t(2) 			<= value_temp(1) xor value_temp(9) xor value_temp(12) xor value_temp(15) xor value_temp(16);	
		-- init_value_t(3) 			<= value_temp(0) xor value_temp(2) xor value_temp(3) xor value_temp(10) xor value_temp(13) xor value_temp(14);	
		-- init_value_t(4) 			<= value_temp(0) xor value_temp(1) xor value_temp(4) xor value_temp(11) xor value_temp(14);	
		-- init_value_t(5) 			<= value_temp(1) xor value_temp(2) xor value_temp(5) xor value_temp(12) xor value_temp(15) ;	
		-- init_value_t(6) 			<= value_temp(2) xor value_temp(3) xor value_temp(6) xor value_temp(13) xor value_temp(16);	
		-- init_value_t(7) 			<= value_temp(0) xor value_temp(4) xor value_temp(7) xor value_temp(14);	
		-- init_value_t(8) 			<= value_temp(1) xor value_temp(5) xor value_temp(8) xor value_temp(15);	
		-- init_value_t(9) 			<= value_temp(2) xor value_temp(6) xor value_temp(9) xor value_temp(16);	
		-- init_value_t(10) 		<= value_temp(0) xor value_temp(7) xor value_temp(10);	
		-- init_value_t(11) 		<= value_temp(1) xor value_temp(8) xor value_temp(11);	
		-- init_value_t(12) 		<= value_temp(2) xor value_temp(9) xor value_temp(12);	
		-- init_value_t(13) 		<= value_temp(3) xor value_temp(10) xor value_temp(13);	
		-- init_value_t(14) 		<= value_temp(4) xor value_temp(11) xor value_temp(14);	
		-- init_value_t(15) 		<= value_temp(5) xor value_temp(12) xor value_temp(15);	
		-- init_value_t(16) 		<= value_temp(6) xor value_temp(13) xor value_temp(16);	
	
	else 
		init_lfsr_t 			<= '0';	
	end if;	
	
end if;

end process;

end architecture rtl;