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

entity tb_tx_esistream_top is
end entity tb_tx_esistream_top;

architecture simulate of tb_tx_esistream_top is

-------------- Device under test ----------------
component tx_esistream_top
port (
	rst										: in std_logic;									-- Active high asynchronous reset
	mgtrefclk_n, mgtrefclk_p				: in std_logic;                                 -- mgtrefclk from transceiver clock input
	sysclk_n, sysclk_p						: in std_logic;									-- sysclk from VC709
	sync_in									: in std_logic;                                 -- Pulse start synchronization sequence
	txn, txp								: out std_logic_vector(4-1 downto 0);           -- Serial output connected to SFP+
	dipswitch								: in std_logic_vector(3 downto 0);
	led										: out std_logic_vector(7 downto 0);
	-- SFP control
	SFP0_in									: in std_logic_vector(2 downto 0);			-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP0_out								: out std_logic_vector(2 downto 0);			-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	SFP1_in									: in std_logic_vector(2 downto 0);			-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP1_out								: out std_logic_vector(2 downto 0);			-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	SFP2_in									: in std_logic_vector(2 downto 0);			-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP2_out								: out std_logic_vector(2 downto 0);			-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	SFP3_in									: in std_logic_vector(2 downto 0);			-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP3_out								: out std_logic_vector(2 downto 0)			-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	-----------
	);
end component tx_esistream_top;

---------------- Constants ----------------		
constant Trefclk 		: time := 5333 ps;				-- mgtrefclk period - 187.5MHz
constant Tsysclk		: time := 10000 ps;				-- sysclk period - 100MHz

constant RST_ASYNC_R	: time := 200 ps;
constant RST_ASYNC_F	: time := 10.4 ns;

---------------- Signals ----------------
signal rst_t                    : std_logic := '0';

signal mgtrefclk_n_t			: std_logic := '0';
signal mgtrefclk_p_t			: std_logic := '1';

signal sysclk_n_t				: std_logic := '0';
signal sysclk_p_t				: std_logic := '1';

signal sync_in_t				: std_logic := '0';
signal dipswitch_t				: std_logic_vector(3 downto 0) := X"0";

signal txn_t					: std_logic_vector(3 downto 0) := X"F";
signal txp_t					: std_logic_vector(3 downto 0) := X"0";

signal led_t					: std_logic_vector(7 downto 0) := X"FF";

signal SFP0_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP1_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP2_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP3_in_t				: std_logic_vector(2 downto 0) := "000";

signal SFP0_out_t				: std_logic_vector(2 downto 0);
signal SFP1_out_t				: std_logic_vector(2 downto 0);
signal SFP2_out_t				: std_logic_vector(2 downto 0);
signal SFP3_out_t				: std_logic_vector(2 downto 0);

begin

dut: tx_esistream_top 
port map (
	rst										=> rst_t,
	mgtrefclk_n								=> mgtrefclk_n_t,
	mgtrefclk_p								=> mgtrefclk_p_t,
	sysclk_n								=> sysclk_n_t,
	sysclk_p								=> sysclk_p_t,
	sync_in									=> sync_in_t,
	txn										=> txn_t,
	txp										=> txp_t,
	dipswitch								=> dipswitch_t,
	led										=> led_t,
	-- SFP control
	SFP0_in									=> SFP0_in_t,
	SFP0_out								=> SFP0_out_t,
	SFP1_in									=> SFP1_in_t,
	SFP1_out								=> SFP1_out_t,
	SFP2_in									=> SFP2_in_t,
	SFP2_out								=> SFP2_out_t,
	SFP3_in									=> SFP3_in_t,
	SFP3_out								=> SFP3_out_t
);
	
-- Clocks generation
mgtrefclk_generation: process
begin
		mgtrefclk_p_t 	<= '1';
		mgtrefclk_n_t 	<= '0';
	wait for Trefclk / 2;
		mgtrefclk_p_t 	<= '0';
		mgtrefclk_n_t 	<= '1';
	wait for Trefclk / 2;
end process;

sysclk_generation: process
begin
		sysclk_p_t 	<= '1';
		sysclk_n_t 	<= '0';
	wait for Tsysclk / 2;
		sysclk_p_t 	<= '0';
		sysclk_n_t 	<= '1';
	wait for Tsysclk / 2;
end process;

-- Stimuli
process
begin
-- ******************************
-- INIT DEFAULT VALUE
	dipswitch_t(1 downto 0)		<= "00";		-- TX data "00000000000000"
	dipswitch_t(2)				<= '1';			-- Scrambling enabled
	dipswitch_t(3)				<= '1';			-- Disparity enabled

	wait for Trefclk;			-- ~ 5 ns
		
-- ASYNC RST
	wait for RST_ASYNC_R;
		rst_t			<= '1';
	wait for RST_ASYNC_F;
		rst_t			<= '0';
	wait for 2*Tsysclk - RST_ASYNC_R - RST_ASYNC_F;

	wait for 1300*Trefclk;		-- Wait for reset to complete
	
-- SYNC SYNC
	wait for Trefclk;
		sync_in_t		<= '1';
	wait for 10*Trefclk;
		sync_in_t		<= '0';
	
	wait for 10*Trefclk;		
-- ******************************

-- *********** TEST 1 ***********
	dipswitch_t(1 downto 0)		<= "00";		-- TX data "00000000000000"
	dipswitch_t(2)				<= '1';			-- Scrambling enabled
	dipswitch_t(3)				<= '1';			-- Disparity enabled
	
	wait for 50*Trefclk;
-- ******************************

-- *********** TEST 2 ***********
	dipswitch_t(1 downto 0)		<= "00";		-- TX data "00000000000000"
	dipswitch_t(2)				<= '0';			-- Scrambling enabled
	dipswitch_t(3)				<= '1';			-- Disparity enabled
	
	wait for 50*Trefclk;
-- ******************************

-- *********** TEST 3 ***********
	dipswitch_t(1 downto 0)		<= "00";		-- TX data "00000000000000"
	dipswitch_t(2)				<= '0';			-- Scrambling enabled
	dipswitch_t(3)				<= '0';			-- Disparity enabled
	
	wait for 50*Trefclk;
-- ******************************

-- *********** TEST 4 ***********
	dipswitch_t(1 downto 0)		<= "01";		-- TX data ramp
	dipswitch_t(2)				<= '0';			-- Scrambling enabled
	dipswitch_t(3)				<= '0';			-- Disparity enabled
	
	wait for 50*Trefclk;
-- ******************************

-- *********** TEST 5 ***********
	dipswitch_t(1 downto 0)		<= "10";		-- TX data ramp
	dipswitch_t(2)				<= '0';			-- Scrambling enabled
	dipswitch_t(3)				<= '0';			-- Disparity enabled
	
	wait for 50*Trefclk;
-- ******************************

-- *********** TEST 6 ***********
	dipswitch_t(1 downto 0)		<= "11";		-- TX data "11111111111111"
	dipswitch_t(2)				<= '0';			-- Scrambling enabled
	dipswitch_t(3)				<= '0';			-- Disparity enabled
	
	wait for 50*Trefclk;
-- ******************************

wait;
	
end process;

end simulate;