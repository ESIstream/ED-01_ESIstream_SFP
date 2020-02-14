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

entity tb_rx_top is
end entity tb_rx_top;

architecture simulate of tb_rx_top is

-------------- Device under test ----------------
component rx_top
port (
	rst							: in std_logic;										-- Active high asynchronous reset
	mgtrefclk_n, mgtrefclk_p	: in std_logic;										-- mgtrefclk from transceiver clock input
	sysclk_n, sysclk_p			: in std_logic;
	rxn, rxp					: in std_logic_vector(4-1 downto 0);				-- Serial input for NB_LANES lanes
	sync_in						: in std_logic;										-- Pulse start synchronization demand
	dipswitch					: in std_logic_vector(8-1 downto 0);				
	sync_out					: out std_logic := '0';                             -- SYNC to FPGA - inverted value due to schematic issue
	led 						: out std_logic_vector(8-1 downto 0);						
	-- SFP control
	SFP0_in						: in std_logic_vector(2 downto 0);					-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP0_out					: out std_logic_vector(2 downto 0);					-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	SFP1_in						: in std_logic_vector(2 downto 0);					-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP1_out					: out std_logic_vector(2 downto 0);					-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	SFP2_in						: in std_logic_vector(2 downto 0);					-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP2_out					: out std_logic_vector(2 downto 0);					-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	SFP3_in						: in std_logic_vector(2 downto 0);					-- 2 - TX_FAULT; 1 - MOD_ABS; 0 - LOS
	SFP3_out					: out std_logic_vector(2 downto 0)					-- 2 - RS0; 1 - RS1; 0 - TX_DISABLE
	-----------
	);
end component rx_top;

---------------- Constant ----------------				-- DO NOT MODIFY => MODIFICATION HERE WILL CORRUPT INPUT DATA TIMINGS / Tserclk need to be multiple of 12.
constant Trefclk 		: time := 5376 ps;				-- mgtrefclk period - 187.5MHz
constant Tserclk 		: time := 168 ps;				-- UI of serial link - ~6Gbps
constant Tsysclk		: time := 10000 ps;				-- sysclk period - 100MHz

constant RST_ASYNC_R	: time := 200 ps;
constant RST_ASYNC_F	: time := 10.4 ns;

---------------- Signals ----------------
signal rst_t                    : std_logic := '0';
signal sync_in_t				: std_logic := '0';
signal sync_out_t				: std_logic := '0';
signal dipswitch_t				: std_logic_vector(7 downto 0) := X"00";

signal mgtrefclk_n_t			: std_logic := '0';
signal mgtrefclk_p_t			: std_logic := '1';

signal sysclk_n_t				: std_logic := '0';
signal sysclk_p_t				: std_logic := '1';

signal rxn_t					: std_logic_vector(3 downto 0) := X"F";
signal rxp_t					: std_logic_vector(3 downto 0) := X"0";
signal rxn_t2					: std_logic_vector(3 downto 0) := X"F";
signal rxp_t2					: std_logic_vector(3 downto 0) := X"0";
signal rxn_t3					: std_logic_vector(3 downto 0) := X"F";
signal rxp_t3					: std_logic_vector(3 downto 0) := X"0";

signal led_t					: std_logic_vector(7 downto 0);

signal clk_serial				: std_logic := '1';

signal ramp_data0				: std_logic_vector(15 downto 0) := X"0000";
signal ramp_data1				: std_logic_vector(15 downto 0) := X"0000";
signal ramp_data2				: std_logic_vector(15 downto 0) := X"0000";
signal ramp_data3				: std_logic_vector(15 downto 0) := X"0000";
signal ramp						: std_logic_vector(13 downto 0) := "00000000000000";
signal sync_sequence1			: std_logic_vector(15 downto 0) := X"FF00";
signal sync_sequence2			: std_logic_vector(15 downto 0) := X"FF00";
signal lfsr_out_t				: std_logic_vector(16 downto 0) := "11111111111111111";
signal rx_data0	                : std_logic_vector(15 downto 0) := X"0000";
signal rx_data1	                : std_logic_vector(15 downto 0) := X"0000";
signal rx_data2	                : std_logic_vector(15 downto 0) := X"0000";
signal rx_data3	                : std_logic_vector(15 downto 0) := X"0000";

signal clk_bit					: std_logic := '0';

signal mux_in					: std_logic_vector(1 downto 0) := "00";					-- Control whether sync sequence or data is sent to serial input

signal SFP0_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP0_out_t				: std_logic_vector(2 downto 0);
signal SFP1_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP1_out_t				: std_logic_vector(2 downto 0);
signal SFP2_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP2_out_t				: std_logic_vector(2 downto 0);
signal SFP3_in_t				: std_logic_vector(2 downto 0) := "000";
signal SFP3_out_t				: std_logic_vector(2 downto 0);

begin

dut: rx_top 
port map (
	rst										=> rst_t,
	mgtrefclk_n								=> mgtrefclk_n_t,
	mgtrefclk_p								=> mgtrefclk_p_t,
	sysclk_n								=> sysclk_n_t,
	sysclk_p								=> sysclk_p_t,
	rxn										=> rxn_t3,
	rxp										=> rxp_t3,
	sync_in									=> sync_in_t,
	dipswitch								=> dipswitch_t,
	sync_out								=> sync_out_t,
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

-- Input affectation
rx_data0				<= 	sync_sequence1 when mux_in = "00" else 
						'0'&clk_bit&lfsr_out_t(13 downto 0) when mux_in = "11" else
						ramp_data0;

rx_data1 				<= 	sync_sequence1 when mux_in = "00" else 
						'0'&clk_bit&lfsr_out_t(13 downto 0) when mux_in = "11" else
						ramp_data1;

rx_data2				<= 	sync_sequence1 when mux_in = "00" else 
						'0'&clk_bit&lfsr_out_t(13 downto 0) when mux_in = "11" else
						ramp_data2;

rx_data3 				<= 	sync_sequence1 when mux_in = "00" else 
						'0'&clk_bit&lfsr_out_t(13 downto 0) when mux_in = "11" else
						ramp_data3;						

rx_inst: for i in 3 downto 0 generate
	rxn_t3(i)		<= rxn_t2(i);
	rxp_t3(i)		<= rxp_t2(i);
end generate;	
						
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

serialclk_generation: process
begin
		clk_serial 	<= '1';
	wait for Tserclk / 2;
		clk_serial 	<= '0';
	wait for Tserclk / 2;
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

-- Ramp 12bits base
ramp_inst: process
begin
		ramp 		<= ramp + 1;
	wait for Trefclk / 2;
end process;

-- Ramp for XSL0
ramp_generation0: process
begin
		ramp_data0(13 downto 0) 	<= ramp;
		ramp_data0(14)				<= not ramp_data0(14);
		ramp_data0(15)				<= '0';
	wait for Trefclk / 2;
end process;

-- Ramp for XSL1
ramp_generation1: process
begin
		ramp_data1(13 downto 0) 	<= ramp;
		ramp_data1(14)				<= not ramp_data1(14);
		ramp_data1(15)				<= '0';
	wait for Trefclk / 2;
end process;

-- Ramp for XSL2
ramp_generation2: process
begin
		ramp_data2(13 downto 0) 	<= ramp;
		ramp_data2(14)				<= not ramp_data2(14);
		ramp_data2(15)				<= '0';
	wait for Trefclk / 2;
end process;

-- Ramp for XSL3
ramp_generation3: process
begin
		ramp_data3(13 downto 0) 	<= ramp;
		ramp_data3(14)				<= not ramp_data3(14);
		ramp_data3(15)				<= '0';
	wait for Trefclk / 2;
end process;

-- Synchronization sequence 0xFF00 & 0x00FF
sync_align_frame1: process
begin
		sync_sequence1(15 downto 0) <= X"FF00";
	wait for Trefclk / 2;
		sync_sequence1(15 downto 0) <= X"00FF";
	wait for Trefclk / 2;
end process;

-- PRBS value
lfsr_frame: process
begin
		lfsr_out_t(0) 	<= lfsr_out_t(14);
		lfsr_out_t(1) 	<= lfsr_out_t(15);
		lfsr_out_t(2) 	<= lfsr_out_t(16);
		lfsr_out_t(3) 	<= lfsr_out_t(0) xor lfsr_out_t(3);
		lfsr_out_t(4) 	<= lfsr_out_t(1) xor lfsr_out_t(4);
		lfsr_out_t(5) 	<= lfsr_out_t(2) xor lfsr_out_t(5);
		lfsr_out_t(6) 	<= lfsr_out_t(3) xor lfsr_out_t(6);
		lfsr_out_t(7) 	<= lfsr_out_t(4) xor lfsr_out_t(7);
		lfsr_out_t(8) 	<= lfsr_out_t(5) xor lfsr_out_t(8);
		lfsr_out_t(9) 	<= lfsr_out_t(6) xor lfsr_out_t(9);
		lfsr_out_t(10) 	<= lfsr_out_t(7) xor lfsr_out_t(10);
		lfsr_out_t(11) 	<= lfsr_out_t(8) xor lfsr_out_t(11);
		lfsr_out_t(12) 	<= lfsr_out_t(9) xor lfsr_out_t(12);
		lfsr_out_t(13) 	<= lfsr_out_t(10) xor lfsr_out_t(13);
		lfsr_out_t(14) 	<= lfsr_out_t(11) xor lfsr_out_t(14);
		lfsr_out_t(15) 	<= lfsr_out_t(12) xor lfsr_out_t(15);
		lfsr_out_t(16) 	<= lfsr_out_t(13) xor lfsr_out_t(16);
	wait for Trefclk/2;
end process;

clk_bit_generation : process
begin	
		clk_bit 	<= not clk_bit;
	wait for Trefclk/2;
end process;

-- Serialization
serializationA: process
begin
	wait for Tserclk/2;	
		rxp_t(0) 		<= rx_data0(0);
		rxn_t(0) 		<= not rx_data0(0);
		rxp_t(1)		<= rx_data1(0);
		rxn_t(1)		<= not rx_data1(0);
		rxp_t(2)		<= rx_data2(0);
		rxn_t(2)		<= not rx_data2(0);
		rxp_t(3)		<= rx_data3(0);
		rxn_t(3)		<= not rx_data3(0);
			
	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(1);
		rxn_t(0) 		<= not rx_data0(1);
		rxp_t(1)		<= rx_data1(1);
		rxn_t(1)		<= not rx_data1(1);
		rxp_t(2)		<= rx_data2(1);
		rxn_t(2)		<= not rx_data2(1);
		rxp_t(3)		<= rx_data3(1);
		rxn_t(3)		<= not rx_data3(1);
		
	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(2);
		rxn_t(0) 		<= not rx_data0(2);
		rxp_t(1)		<= rx_data1(2);
		rxn_t(1)		<= not rx_data1(2);
		rxp_t(2)		<= rx_data2(2);
		rxn_t(2)		<= not rx_data2(2);
		rxp_t(3)		<= rx_data3(2);
		rxn_t(3)		<= not rx_data3(2);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(3);
		rxn_t(0) 		<= not rx_data0(3);
		rxp_t(1)		<= rx_data1(3);
		rxn_t(1)		<= not rx_data1(3);
		rxp_t(2)		<= rx_data2(3);
		rxn_t(2)		<= not rx_data2(3);
		rxp_t(3)		<= rx_data3(3);
		rxn_t(3)		<= not rx_data3(3);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(4);
		rxn_t(0) 		<= not rx_data0(4);
		rxp_t(1)		<= rx_data1(4);
		rxn_t(1)		<= not rx_data1(4);
		rxp_t(2)		<= rx_data2(4);
		rxn_t(2)		<= not rx_data2(4);
		rxp_t(3)		<= rx_data3(4);
		rxn_t(3)		<= not rx_data3(4);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(5);
		rxn_t(0) 		<= not rx_data0(5);
		rxp_t(1)		<= rx_data1(5);
		rxn_t(1)		<= not rx_data1(5);
		rxp_t(2)		<= rx_data2(5);
		rxn_t(2)		<= not rx_data2(5);
		rxp_t(3)		<= rx_data3(5);
		rxn_t(3)		<= not rx_data3(5);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(6);
		rxn_t(0) 		<= not rx_data0(6);
		rxp_t(1)		<= rx_data1(6);
		rxn_t(1)		<= not rx_data1(6);
		rxp_t(2)		<= rx_data2(6);
		rxn_t(2)		<= not rx_data2(6);
		rxp_t(3)		<= rx_data3(6);
		rxn_t(3)		<= not rx_data3(6);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(7);
		rxn_t(0) 		<= not rx_data0(7);
		rxp_t(1)		<= rx_data1(7);
		rxn_t(1)		<= not rx_data1(7);
		rxp_t(2)		<= rx_data2(7);
		rxn_t(2)		<= not rx_data2(7);
		rxp_t(3)		<= rx_data3(7);
		rxn_t(3)		<= not rx_data3(7);
		
	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(8);
		rxn_t(0) 		<= not rx_data0(8);
		rxp_t(1)		<= rx_data1(8);
		rxn_t(1)		<= not rx_data1(8);
		rxp_t(2)		<= rx_data2(8);
		rxn_t(2)		<= not rx_data2(8);
		rxp_t(3)		<= rx_data3(8);
		rxn_t(3)		<= not rx_data3(8);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(9);
		rxn_t(0) 		<= not rx_data0(9);
		rxp_t(1)		<= rx_data1(9);
		rxn_t(1)		<= not rx_data1(9);
		rxp_t(2)		<= rx_data2(9);
		rxn_t(2)		<= not rx_data2(9);
		rxp_t(3)		<= rx_data3(9);
		rxn_t(3)		<= not rx_data3(9);
		
	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(10);
		rxn_t(0) 		<= not rx_data0(10);
		rxp_t(1)		<= rx_data1(10);
		rxn_t(1)		<= not rx_data1(10);
		rxp_t(2)		<= rx_data2(10);
		rxn_t(2)		<= not rx_data2(10);
		rxp_t(3)		<= rx_data3(10);
		rxn_t(3)		<= not rx_data3(10);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(11);
		rxn_t(0) 		<= not rx_data0(11);
		rxp_t(1)		<= rx_data1(11);
		rxn_t(1)		<= not rx_data1(11);
		rxp_t(2)		<= rx_data2(11);
		rxn_t(2)		<= not rx_data2(11);
		rxp_t(3)		<= rx_data3(11);
		rxn_t(3)		<= not rx_data3(11);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(12);
		rxn_t(0) 		<= not rx_data0(12);
		rxp_t(1)		<= rx_data1(12);
		rxn_t(1)		<= not rx_data1(12);
		rxp_t(2)		<= rx_data2(12);
		rxn_t(2)		<= not rx_data2(12);
		rxp_t(3)		<= rx_data3(12);
		rxn_t(3)		<= not rx_data3(12);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(13);
		rxn_t(0) 		<= not rx_data0(13);
		rxp_t(1)		<= rx_data1(13);
		rxn_t(1)		<= not rx_data1(13);
		rxp_t(2)		<= rx_data2(13);
		rxn_t(2)		<= not rx_data2(13);
		rxp_t(3)		<= rx_data3(13);
		rxn_t(3)		<= not rx_data3(13);
		
	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(14);
		rxn_t(0) 		<= not rx_data0(14);
		rxp_t(1)		<= rx_data1(14);
		rxn_t(1)		<= not rx_data1(14);
		rxp_t(2)		<= rx_data2(14);
		rxn_t(2)		<= not rx_data2(14);
		rxp_t(3)		<= rx_data3(14);
		rxn_t(3)		<= not rx_data3(14);

	wait for Tserclk;
		rxp_t(0) 		<= rx_data0(15);
		rxn_t(0) 		<= not rx_data0(15);
		rxp_t(1)		<= rx_data1(15);
		rxn_t(1)		<= not rx_data1(15);
		rxp_t(2)		<= rx_data2(15);
		rxn_t(2)		<= not rx_data2(15);
		rxp_t(3)		<= rx_data3(15);
		rxn_t(3)		<= not rx_data3(15);
		
	wait for Tserclk/2;			
end process;

phase3: process
begin
	wait for 8*Tserclk/12;
		rxn_t2(3)		<= rxn_t(3);
		rxp_t2(3)		<= rxp_t(3);
	wait for 4*Tserclk/12;
end process;

phase2: process
begin
	wait for 7*Tserclk/12;
		rxn_t2(2)		<= rxn_t(2);
		rxp_t2(2)		<= rxp_t(2);
	wait for 5*Tserclk/12;
end process;

phase1: process
begin
	wait for 2*Tserclk/12;
		rxn_t2(1)		<= rxn_t(1);
		rxp_t2(1)		<= rxp_t(1);
	wait for 10*Tserclk/12;
end process;

phase0: process
begin
	wait for 3*Tserclk/12;
		rxn_t2(0)		<= rxn_t(0);
		rxp_t2(0)		<= rxp_t(0);
	wait for 9*Tserclk/12;
end process;

-- Stimuli
process
begin
-- ******************************
-- INIT DEFAULT VALUE
	dipswitch_t(7 downto 4)		<= X"F";		-- All lanes on
	dipswitch_t(0)				<= '0';			-- Descrambling disabled
	mux_in						<= "00";		-- FLASH pattern in

	wait for Trefclk;			-- ~ 5 ns
		
-- ASYNC RST
	wait for RST_ASYNC_R;
		rst_t			<= '1';
	wait for RST_ASYNC_F;
		rst_t			<= '0';
	wait for 2*Trefclk - RST_ASYNC_R - RST_ASYNC_F;

	wait for 3125*Trefclk;		-- Wait for reset to complete
	
-- SYNC SYNC
	wait for Trefclk;
		sync_in_t		<= '1';
	wait for 10*Trefclk;
		sync_in_t		<= '0';
	
	wait for 5*Trefclk;			-- For the TX to process the sync request
		mux_in			<= "00";
	wait for 32*Trefclk/2;		-- Length of 1st step of synchronization sequence
		mux_in			<= "11";	
	wait for 32*Trefclk/2;		-- Length of 2st step of synchronization sequence

	mux_in				<= "00";	-- FLASH pattern in
	
	wait for 50*Trefclk;		
-- ******************************

-- *********** TEST 1 ***********
	dipswitch_t(7 downto 4)		<= X"F";		-- All lanes on
	dipswitch_t(3 downto 1)		<= "000";		-- Check constant 0/1
	dipswitch_t(0)				<= '1';			-- Descrambling enabled
	mux_in						<= "11";		-- PRBS only pattern in
	
	wait for 50*Trefclk;
-- ******************************

-- *********** TEST 1 ***********
	dipswitch_t(7 downto 4)		<= X"F";		-- All lanes on
	dipswitch_t(3 downto 1)		<= "001";		-- Check rampp
	dipswitch_t(0)				<= '0';			-- Descrambling disabled
	mux_in						<= "01";		-- RAMP pattern in
	
	wait for 50*Trefclk;
-- ******************************

wait;
	
end process;

end simulate;