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
use ieee.std_logic_unsigned.all ;

library UNISIM;
use UNISIM.VComponents.all;

entity rx_top is
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
end entity rx_top;

architecture rtl of rx_top is

---------------- Components ----------------
component rx_esistream_top
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

end component rx_esistream_top;

component pushbutton_request is
generic (
	NB_CLK_CYC		: std_logic_vector(31 downto 0) := X"0FFFFFFF"		-- Number of clock cycle between pusbutton_in and request (needs to be larger than time pushbutton pressed)
	);
port (  
	pushbutton_in	: in std_logic;					-- Connected to pushbutton input		
	clk				: in std_logic;					
	request			: out std_logic := '0'			-- 1 clock period pulse  
	);
end component pushbutton_request;
-----------------------------------------

--------------------- Signals -------------------
signal sysclk			: std_logic;
signal clk_out			: std_logic;
signal rst_pulse		: std_logic;
signal sync_in_ip		: std_logic;
signal sync_out_ip		: std_logic;
signal ip_ready			: std_logic;
signal lanes_sync		: std_logic;

signal lanes_on_t		: std_logic_vector(3 downto 0) := X"F";
signal prbs_ctrl_t		: std_logic := '1';

signal data_out_t		: std_logic_vector(4*16-1 downto 0) := X"0000000000000000";

signal check_rampp		: std_logic_vector(4-1 downto 0) := X"0";
signal check_rampn		: std_logic_vector(4-1 downto 0) := X"0";
signal check_0			: std_logic := '0';
signal check_1			: std_logic := '0';
signal check_clkbit		: std_logic := '0';
signal check_align		: std_logic := '0';

signal clk_bit_buf		: std_logic_vector(4-1 downto 0) := X"0";
signal disp_buf			: std_logic_vector(4-1 downto 0) := X"0";

signal data_buf			: std_logic_vector(4*14-1 downto 0) := X"00000000000000";

-----------------------------------------

begin

-- Output affectation
process(clk_out)
begin
	if rising_edge(clk_out) then
		sync_out		<= sync_out_ip;
	end if;
end process;	
	
------------- SFP+
SFP0_out		<= "101";
SFP1_out		<= "101";
SFP2_out		<= "101";
SFP3_out		<= "101";
-----------------

-- Configuration
lanes_on_t(3 downto 0)			<= dipswitch(7 downto 4);
prbs_ctrl_t						<= dipswitch(0);

-- LED
led(0)          <= '1' when rst = '0' else '0';
led(1)			<= '1' when sync_in = '0' else '0';
led(2)			<= ip_ready;
led(3)			<= lanes_sync;
	
process(clk_out)
begin
if rising_edge(clk_out) then
	
	case dipswitch(3 downto 1) is
	
		when "000" => 
			led(4)				<= '0';
			led(5)				<= '0';
			led(6)				<= check_0;
			led(7)				<= check_1;
		
		when "001" =>
			led(7 downto 4)		<= check_rampp;
		
		when "010" =>
			led(7 downto 4)		<= check_rampn;
			
		when "011" =>
			led(4)				<= '0';
			led(5)				<= '0';
			led(6)				<= check_clkbit;
			led(7)				<= check_align;
		
		when "100" =>
			led(4)				<= SFP0_in(0);
			led(5)				<= SFP1_in(0);
			led(6)				<= SFP2_in(0);
			led(7)				<= SFP3_in(0);
			
		when "101" =>
			led(4)				<= SFP0_in(1);
			led(5)				<= SFP1_in(1);
			led(6)				<= SFP2_in(1);
			led(7)				<= SFP3_in(1);
			
		when "110" =>
			led(4)				<= SFP0_in(2);
			led(5)				<= SFP1_in(2);
			led(6)				<= SFP2_in(2);
			led(7)				<= SFP3_in(2);

		when "111" =>	
			led(7 downto 4)		<= disp_buf;
		
		when others => 
			led(7 downto 4)		<= (others => '0');
			
	end case;
	
end if;
end process;

ibuf_inst: IBUFGDS
port map (
	I		=> sysclk_p,
	IB		=> sysclk_n,
	O		=> sysclk
); 

central_pushbutton_inst: pushbutton_request
generic map(
	NB_CLK_CYC		=> X"0FFFFFFF"		-- Reduce to X"0000003F" to speed up simulation time
	)
port map (  
	pushbutton_in	=> rst,
	clk				=> sysclk,			
	request			=> rst_pulse
);

south_pushbutton_inst: pushbutton_request
generic map(
	NB_CLK_CYC		=> X"0FFFFFFF"		-- Reduce to X"0000003F" to speed up simulation time
	)
port map (  
	pushbutton_in	=> sync_in,
	clk				=> clk_out,			
	request			=> sync_in_ip
);

rx_esistream_top_inst: rx_esistream_top
port map (
	rst							=> rst_pulse,
	mgtrefclk_n					=> mgtrefclk_n,
	mgtrefclk_p					=> mgtrefclk_p,
	sysclk						=> sysclk,
	rxn							=> rxn,
	rxp							=> rxp,
	sync_in						=> sync_in_ip,
	prbs_ctrl					=> prbs_ctrl_t,
	lanes_on					=> lanes_on_t,
	clk_out						=> clk_out,
	sync_out					=> sync_out_ip,
	data_out					=> data_out_t,
	ip_ready					=> ip_ready,
	lanes_sync					=> lanes_sync
);

-- Data verification
process(rst_pulse, clk_out)
begin
if rst_pulse = '1' then
	check_rampp			<= (others => '0');
	check_rampn			<= (others => '0');
	check_0				<= '0';
	check_1				<= '0';
	check_clkbit		<= '0';
	check_align			<= '0';
	
elsif rising_edge(clk_out) then
	
	-- Check alignment
	check_align				<=  (not (data_out_t((0+1)*16-2) xor data_out_t((1+1)*16-2))) and (not (data_out_t((1+1)*16-2) xor data_out_t((2+1)*16-2))) and (not (data_out_t((2+1)*16-2) xor data_out_t((3+1)*16-2)));
	
	-- Check clkbit
	clk_bit_buf				<= data_out_t((3+1)*16-2) & data_out_t((2+1)*16-2) & data_out_t((1+1)*16-2) & data_out_t((0+1)*16-2);
	
	if clk_bit_buf = not ( data_out_t((3+1)*16-2) & data_out_t((2+1)*16-2) & data_out_t((1+1)*16-2) & data_out_t((0+1)*16-2) ) then
		check_clkbit		<= '1';
	else
		check_clkbit		<= '0';
	end if;
	
	-- Buffer disparity
		disp_buf			<= data_out_t((3+1)*16-1) & data_out_t((2+1)*16-1) & data_out_t((1+1)*16-1) & data_out_t((0+1)*16-1);
	
	-- Check ramp+ / ramp-
	for i in 4-1 downto 0 loop
		data_buf( (i+1)*14-1 downto i*14) 		<= data_out_t( (i+1)*16-3 downto i*16);
		
		if data_buf( (i+1)*14-1 downto i*14) + 1 = data_out_t( (i+1)*16-3 downto i*16) then
			check_rampp(i) 		<= '1';
		else
			check_rampp(i)		<= '0';
		end if;
		
		if data_buf( (i+1)*14-1 downto i*14) - 1 = data_out_t( (i+1)*16-3 downto i*16) then
			check_rampn(i) 		<= '1';
		else
			check_rampn(i)		<= '0';
		end if;
		
	end loop;
	
	-- Check 0 and 1*16
	if (data_out_t( (0+1)*16-3 downto 0*16) = "00000000000000") and (data_out_t( (1+1)*16-3 downto 1*16) = "00000000000000") and (data_out_t( (2+1)*16-3 downto 2*16) = "00000000000000") and (data_out_t( (3+1)*16-3 downto 3*16) = "00000000000000") then
		check_0			<= '1';
	else 
		check_0			<= '0';
	end if;
	
	if (data_out_t( (0+1)*16-3 downto 0*16) = "11111111111111") and (data_out_t( (1+1)*16-3 downto 1*16) = "11111111111111") and (data_out_t( (2+1)*16-3 downto 2*16) = "11111111111111") and (data_out_t( (3+1)*16-3 downto 3*16) = "11111111111111") then
		check_1			<= '1';
	else 
		check_1			<= '0';
	end if;
	
end if;

end process;

end architecture rtl;