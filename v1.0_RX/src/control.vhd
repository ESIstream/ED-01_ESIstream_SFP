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

library IEEE ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity control is
generic (
	NB_LANES 					: integer := 8											-- Number of serial lanes
	);
port (
	rst					: in std_logic;													-- Reset asked by user, asynchronous active on falling edge
	clk					: in std_logic;		
	sync_in				: in std_logic;													-- Pulse start synchronization demand
	cpll_lock			: in std_logic_vector(NB_LANES-1 downto 0);						-- Indicates whether GTH CPLL is locked
	gth_rstdone			: in std_logic_vector(NB_LANES-1 downto 0);						-- Indicates that GTH is ready
	lanes_on			: in std_logic_vector(NB_LANES-1 downto 0);						-- Indicates which lanes are on
	rst_gth				: out std_logic;												-- Reset GTH, active high
	rst_logic			: out std_logic;												-- Reset logic FPGA, active high
	ip_ready			: out std_logic													-- Indicates that IP is ready if driven high
	) ;
end entity control ;

architecture rtl of control is

signal start_rst		: std_logic:= '0';

signal cpll_lock_buf		: std_logic_vector(1 downto 0) := "00";
signal cnt_rst_logic	: std_logic_vector(2 downto 0) := "000";
signal start_rst_logic 	: std_logic := '0';

signal rst_gth_t		: std_logic := '0';
signal rst_logic_t		: std_logic := '0';
signal ip_ready_t		: std_logic := '0';

begin

-- Output affectation
rst_gth 		<= rst_gth_t;
rst_logic		<= rst_logic_t;
ip_ready		<= ip_ready_t;

-- Asynchronous reset / No available clock before CPLL locked
rst_gth_t		<= '1' when rst = '1' or cpll_lock /= "1111" else '0';
ip_ready_t		<= '1' when gth_rstdone = "1111" else '0';

process(clk)		-- Synchronous reset for FPGA logic
begin
	if rising_edge(clk) then
		if cpll_lock = "1111" then
			cpll_lock_buf(0)		<= '1';
		else
			cpll_lock_buf(0)		<= '0';
		end if;
		
		cpll_lock_buf(1) 		<= cpll_lock_buf(0);
			
		if cpll_lock_buf = "01" or sync_in = '1' then			-- rising edge
			cnt_rst_logic		<= "000";
			start_rst_logic		<= '1';
		end if;
		
		if cnt_rst_logic = "111" then
			start_rst_logic		<= '0';
		end if;
		
		if start_rst_logic = '1' then
			cnt_rst_logic		<= cnt_rst_logic + 1;
			rst_logic_t			<= '1';
		else
			rst_logic_t			<= '0';
		end if;		
	end if;
end process;

end architecture rtl ;