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
        
entity pushbutton_request is
generic (
	NB_CLK_CYC		: std_logic_vector(31 downto 0) := X"0FFFFFFF"		-- Number of clock cycle between pusbutton_in and request
);
port (  
	pushbutton_in	: in std_logic;					-- Connected to pushbutton input		
	clk				: in std_logic;					
	request			: out std_logic := '0'			-- 1 clock period pulse  
);
end pushbutton_request;

architecture rtl of pushbutton_request is
 
 ---------- Signals ----------
signal start_cnt	: std_logic := '0';
signal cnt			: std_logic_vector(31 downto 0) := X"00000000";
 
begin

process(clk)
begin
if rising_edge(clk) then 

	if start_cnt = '0' and pushbutton_in = '1' then
		start_cnt 		<= '1';
		request			<= '0';
	elsif cnt = NB_CLK_CYC then
		start_cnt 		<= '0';
		request			<= '1';
		cnt 			<= (others => '0');	
	elsif start_cnt = '1' then
		cnt 			<= cnt + 1;
		request			<= '0';		
	else 
		request 		<= '0';
	end if;	
	
end if;
end process;
 
end architecture rtl;
