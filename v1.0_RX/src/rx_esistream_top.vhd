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

entity rx_esistream_top is
port (		
	rst							: in std_logic;												-- Active high asynchronous reset
	mgtrefclk_n, mgtrefclk_p	: in std_logic;												-- mgtrefclk from transceiver clock input
	sysclk						: in std_logic;												-- sysclock for transceiver input
	rxn, rxp					: in std_logic_vector(4-1 downto 0);						-- Serial input for NB_LANES lanes
	sync_in						: in std_logic;												-- Pulse start synchronization demand
	prbs_ctrl					: in std_logic;												-- Signal to configure if descrambling is enabled ('1') or not ('0')
	lanes_on					: in std_logic_vector(4-1 downto 0);						-- Signal that indicates if lane i is on ('1') or off ('0')
	clk_out						: out std_logic;											-- Output clock sync with data_out
	sync_out					: out std_logic;											-- SYNC pulse sent to TX
	data_out					: out std_logic_vector(16*4-1 downto 0);					-- Deserialized & decoded output data + clk bit + disparity bit
	ip_ready					: out std_logic;											-- Indicates GTH status
	lanes_sync					: out std_logic												-- Indicates lanes synchronization status
	);
end entity rx_esistream_top;

architecture rtl of rx_esistream_top is

---------------- Components ----------------

component rx_esistream			
generic (
	NB_LANES 					: integer := 8;												-- Number of serial lanes
	DESER_FACTOR 				: integer := 16;											-- Deserialization factor
	DATA_LENGTH					: integer := 14;											-- Length of a useful data
	COMMA						: std_logic_vector(31 downto 0) := X"00FFFF00";				-- COMMA for frame alignemnent / For ESIstream 32bits 0x00FFFF00 or 0xFF0000FF
	LFSR_LENGTH					: integer := 17;											-- Length of a lfsr / For ESIstream 17
	DELAY_SYNC					: std_logic_vector(7 downto 0) := "00100000"				-- Delay to add between sync output and sync process in fpga
	);		
port (		
	rst							: in std_logic;												-- Active high asynchronous reset
	mgtrefclk_n, mgtrefclk_p	: in std_logic;												-- mgtrefclk from transceiver clock input
	sysclk						: in std_logic;												-- sysclock for transceiver input
	rxn, rxp					: in std_logic_vector(NB_LANES-1 downto 0);					-- Serial input for NB_LANES lanes
	sync_in						: in std_logic;												-- Pulse start synchronization demand
	prbs_ctrl					: in std_logic;												-- Signal to configure if descrambling is enabled ('1') or not ('0')
	lanes_on					: in std_logic_vector(NB_LANES-1 downto 0);					-- Signal that indicates if lane i is on ('1') or off ('0')
	clk_out						: out std_logic;											-- Output clock sync with data_out
	sync_out					: out std_logic;											-- SYNC pulse sent to TX
	data_out					: out std_logic_vector(DESER_FACTOR*NB_LANES-1 downto 0);	-- Deserialized & decoded output data + clk bit + disparity bit
	ip_ready					: out std_logic;											-- Indicates GTH status
	lanes_sync					: out std_logic												-- Indicates lanes synchronization status 
	);
end component rx_esistream;

begin

rx_esistream_inst: rx_esistream 
generic map(
	NB_LANES 					=> 4,
	DESER_FACTOR 				=> 16,
	DATA_LENGTH					=> 14,
	COMMA						=> X"00FFFF00",
	LFSR_LENGTH					=> 17,
	DELAY_SYNC					=> "00100000"
	)	
port map(		
	rst							=> rst,
	mgtrefclk_n					=> mgtrefclk_n,
	mgtrefclk_p					=> mgtrefclk_p,
	sysclk						=> sysclk,
	rxn							=> rxn,
	rxp							=> rxp,
	sync_in						=> sync_in,
	prbs_ctrl					=> prbs_ctrl,
	lanes_on					=> lanes_on,
	clk_out						=> clk_out,
	sync_out					=> sync_out,
	data_out					=> data_out,
	ip_ready					=> ip_ready,
	lanes_sync					=> lanes_sync
	);

end architecture rtl;