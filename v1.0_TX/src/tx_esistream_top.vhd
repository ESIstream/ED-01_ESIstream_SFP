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

library UNISIM;
use UNISIM.VComponents.all;

entity tx_esistream_top is
port (
	rst										: in std_logic;									-- Active high asynchronous reset
	mgtrefclk_n, mgtrefclk_p				: in std_logic;                                 -- mgtrefclk from transceiver clock input
	sysclk_n, sysclk_p						: in std_logic;									-- sysclk from VC709
	sync_in									: in std_logic;                                 -- Pulse start synchronization sequence
	txn, txp								: out std_logic_vector(4-1 downto 0);           -- Serial output connected to SFP+
	dipswitch								: in std_logic_vector(3 downto 0);
	led										: out std_logic_vector(7 downto 0);
	-- SFP+ control
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
end entity tx_esistream_top;

architecture rtl of tx_esistream_top is

---------- Components ----------
component data_gen is
port (
	clk						: in std_logic;
	d_ctrl					: in std_logic_vector(1 downto 0) := "00";						-- Control the data output type ("00" 0x000; "01" ramp+; "10" ramp-; "11" 0xFFF)
	data_out				: out std_logic_vector(13 downto 0)           					-- Output data
);
end component data_gen;

component esistream_encoding is
port (
	clk					: in std_logic;
	sync				: in std_logic;												-- Resets LFSR, disparity and starts synchronization
	prbs_en				: in std_logic;												-- Enables scrambling processing
	disp_en				: in std_logic;												-- Enables disparity processing
	data_in				: in std_logic_vector(13 downto 0);							-- Input data to encode
	data_out			: out std_logic_vector(15 downto 0) := X"0000"				-- Output endoded data
);
end component esistream_encoding;

component pushbutton_request is
generic (
	NB_CLK_CYC		: std_logic_vector(31 downto 0) := X"0FFFFFFF"		-- Number of clock cycle between pusbutton_in and request
);
port (  
	pushbutton_in	: in std_logic;					-- Connected to pushbutton input		
	clk				: in std_logic;					
	request			: out std_logic := '0'			-- 1 clock period pulse  
);
end component pushbutton_request;

component gth_tx_sfp is
port
(
    SOFT_RESET_TX_IN                        : in   std_logic;
    DONT_RESET_ON_DATA_ERROR_IN             : in   std_logic;
    Q3_CLK1_GTREFCLK_PAD_N_IN               : in   std_logic;
    Q3_CLK1_GTREFCLK_PAD_P_IN               : in   std_logic;

    GT0_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT0_DATA_VALID_IN                       : in   std_logic;
    GT1_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT1_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT1_DATA_VALID_IN                       : in   std_logic;
    GT2_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT2_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT2_DATA_VALID_IN                       : in   std_logic;
    GT3_TX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT3_RX_FSM_RESET_DONE_OUT               : out  std_logic;
    GT3_DATA_VALID_IN                       : in   std_logic;
 
    GT0_TXUSRCLK_OUT                        : out  std_logic;
    GT0_TXUSRCLK2_OUT                       : out  std_logic;
 
    GT1_TXUSRCLK_OUT                        : out  std_logic;
    GT1_TXUSRCLK2_OUT                       : out  std_logic;
 
    GT2_TXUSRCLK_OUT                        : out  std_logic;
    GT2_TXUSRCLK2_OUT                       : out  std_logic;
 
    GT3_TXUSRCLK_OUT                        : out  std_logic;
    GT3_TXUSRCLK2_OUT                       : out  std_logic;

    --_________________________________________________________________________
    --GT0  (X1Y12)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt0_cpllfbclklost_out                   : out  std_logic;
    gt0_cplllock_out                        : out  std_logic;
    gt0_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                : out  std_logic;
    gt0_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt0_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        : in   std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        : in   std_logic;
    gt0_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt0_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt0_gthtxn_out                          : out  std_logic;
    gt0_gthtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclkfabric_out                  : out  std_logic;
    gt0_txoutclkpcs_out                     : out  std_logic;
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out                     : out  std_logic;

    --GT1  (X1Y13)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt1_cpllfbclklost_out                   : out  std_logic;
    gt1_cplllock_out                        : out  std_logic;
    gt1_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt1_eyescanreset_in                     : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt1_eyescandataerror_out                : out  std_logic;
    gt1_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt1_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt1_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt1_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt1_gtrxreset_in                        : in   std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt1_gttxreset_in                        : in   std_logic;
    gt1_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt1_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt1_gthtxn_out                          : out  std_logic;
    gt1_gthtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt1_txoutclkfabric_out                  : out  std_logic;
    gt1_txoutclkpcs_out                     : out  std_logic;
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt1_txresetdone_out                     : out  std_logic;

    --GT2  (X1Y14)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt2_cpllfbclklost_out                   : out  std_logic;
    gt2_cplllock_out                        : out  std_logic;
    gt2_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt2_eyescanreset_in                     : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt2_eyescandataerror_out                : out  std_logic;
    gt2_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt2_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt2_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt2_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt2_gtrxreset_in                        : in   std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt2_gttxreset_in                        : in   std_logic;
    gt2_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt2_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt2_gthtxn_out                          : out  std_logic;
    gt2_gthtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt2_txoutclkfabric_out                  : out  std_logic;
    gt2_txoutclkpcs_out                     : out  std_logic;
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt2_txresetdone_out                     : out  std_logic;

    --GT3  (X1Y15)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt3_cpllfbclklost_out                   : out  std_logic;
    gt3_cplllock_out                        : out  std_logic;
    gt3_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt3_eyescanreset_in                     : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt3_eyescandataerror_out                : out  std_logic;
    gt3_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt3_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt3_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt3_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt3_gtrxreset_in                        : in   std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt3_gttxreset_in                        : in   std_logic;
    gt3_txuserrdy_in                        : in   std_logic;
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt3_txdata_in                           : in   std_logic_vector(15 downto 0);
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt3_gthtxn_out                          : out  std_logic;
    gt3_gthtxp_out                          : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt3_txoutclkfabric_out                  : out  std_logic;
    gt3_txoutclkpcs_out                     : out  std_logic;
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt3_txresetdone_out                     : out  std_logic;

    --____________________________COMMON PORTS________________________________
    GT0_QPLLOUTCLK_OUT  : out std_logic;
    GT0_QPLLOUTREFCLK_OUT : out std_logic;

    sysclk_in                               : in   std_logic

);
end component gth_tx_sfp;

---------- Signals ----------
signal tx_usrclk		: std_logic;
signal sysclk			: std_logic;

signal rst_pulse		: std_logic;
signal tx_rst			: std_logic_vector(3 downto 0);
signal cpll_lock		: std_logic_vector(3 downto 0);
signal tx_usrrdy0		: std_logic_vector(31 downto 0);
signal tx_usrrdy1		: std_logic_vector(31 downto 0);
signal tx_usrrdy2		: std_logic_vector(31 downto 0);
signal tx_usrrdy3		: std_logic_vector(31 downto 0);
signal tx_rstdone		: std_logic_vector(3 downto 0);
signal sync_pulse		: std_logic;
signal d_ctrl			: std_logic_vector(1 downto 0);
signal prbs_en			: std_logic;
signal disp_en			: std_logic;

signal data_to_encode	: std_logic_vector(13 downto 0);
signal data_encoded		: std_logic_vector(15 downto 0);

begin

-- Input configuration
d_ctrl			<= dipswitch(1 downto 0);
prbs_en			<= dipswitch(2);
disp_en			<= dipswitch(3);

-- Output configuration
-- SFP+
SFP0_out		<= "100";
SFP1_out		<= "100";
SFP2_out		<= "100";
SFP3_out		<= "100";

led(0)			<= '1' when rst = '0' else '0';
led(1)			<= '1' when sync_in = '0' else '0';
led(2)			<= '1' when cpll_lock = "1111" else '0';
led(3)			<= '1' when tx_rstdone = "1111" else '0';
led(4) 			<= '1' when (SFP0_in(2) = '1' and SFP1_in(2) = '1' and SFP2_in(2) = '1' and SFP3_in(2) = '1') else '0';
led(5)			<= '0';
led(7 downto 6)	<= dipswitch(1 downto 0);

sync_pushbutton_request_inst: pushbutton_request
generic map (
	NB_CLK_CYC				=> X"0FFFFFFF"		-- Change to X"0000003F" to speed up simulation time
)
port map (  
	pushbutton_in			=> sync_in,
	clk						=> tx_usrclk,
	request					=> sync_pulse
);

rst_pushbutton_request_inst: pushbutton_request
generic map (
	NB_CLK_CYC				=> X"0FFFFFFF"		-- Change to X"0000003F" to speed up simulation time
)
port map (  
	pushbutton_in			=> rst,
	clk						=> sysclk,
	request					=> rst_pulse
);

data_gen_inst: data_gen
port map (
	clk						=> tx_usrclk,
	d_ctrl					=> d_ctrl,
	data_out				=> data_to_encode
);

esistream_encoding_inst: esistream_encoding
port map (
	clk						=> tx_usrclk,
	sync					=> sync_pulse,
	prbs_en					=> prbs_en,
	disp_en					=> disp_en,
	data_in					=> data_to_encode,
	data_out				=> data_encoded
);

ibuf_inst: IBUFGDS
port map (
	I		=> sysclk_p,
	IB		=> sysclk_n,
	O		=> sysclk
); 

-- GTH initialization management
process(tx_usrclk, cpll_lock)
begin

tx_rst		<= not cpll_lock;

if cpll_lock(0) = '0' then
	tx_usrrdy0		<= (others => '0');
	
elsif rising_edge(tx_usrclk) then
	tx_usrrdy0(0)	<= cpll_lock(0);
	tx_usrrdy0(31 downto 1)		<= tx_usrrdy0(30 downto 0);
	
end if;
	
if cpll_lock(1) = '0' then
	tx_usrrdy1		<= (others => '0');
	
elsif rising_edge(tx_usrclk) then
	tx_usrrdy1(0)	<= cpll_lock(1);
	tx_usrrdy1(31 downto 1)		<= tx_usrrdy1(30 downto 0);
	
end if;	

if cpll_lock(2) = '0' then
	tx_usrrdy2		<= (others => '0');
	
elsif rising_edge(tx_usrclk) then
	tx_usrrdy2(0)	<= cpll_lock(2);
	tx_usrrdy2(31 downto 1)		<= tx_usrrdy2(30 downto 0);
	
end if;	
	
if cpll_lock(3) = '0' then
	tx_usrrdy3		<= (others => '0');
	
elsif rising_edge(tx_usrclk) then
	tx_usrrdy3(0)	<= cpll_lock(3);
	tx_usrrdy3(31 downto 1)		<= tx_usrrdy3(30 downto 0);
	
end if;	
	
end process;

gth_inst: gth_tx_sfp 
port map
(
    SOFT_RESET_TX_IN                        => rst_pulse,
    DONT_RESET_ON_DATA_ERROR_IN             => '1',
    Q3_CLK1_GTREFCLK_PAD_N_IN               => mgtrefclk_n,
    Q3_CLK1_GTREFCLK_PAD_P_IN               => mgtrefclk_p,

    GT0_TX_FSM_RESET_DONE_OUT               => open,
    GT0_RX_FSM_RESET_DONE_OUT               => open,
    GT0_DATA_VALID_IN                       => '1',
    GT1_TX_FSM_RESET_DONE_OUT               => open,
    GT1_RX_FSM_RESET_DONE_OUT               => open,
    GT1_DATA_VALID_IN                       => '1',
    GT2_TX_FSM_RESET_DONE_OUT               => open,
    GT2_RX_FSM_RESET_DONE_OUT               => open,
    GT2_DATA_VALID_IN                       => '1',
    GT3_TX_FSM_RESET_DONE_OUT               => open,
    GT3_RX_FSM_RESET_DONE_OUT               => open,
    GT3_DATA_VALID_IN                       => '1',
 
    GT0_TXUSRCLK_OUT                        => tx_usrclk,
    GT0_TXUSRCLK2_OUT                       => open,

    GT1_TXUSRCLK_OUT                        => open,
    GT1_TXUSRCLK2_OUT                       => open,

    GT2_TXUSRCLK_OUT                        => open,
    GT2_TXUSRCLK2_OUT                       => open,

    GT3_TXUSRCLK_OUT                        => open,
    GT3_TXUSRCLK2_OUT                       => open,

    --_________________________________________________________________________
    --GT0  (X1Y12)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt0_cpllfbclklost_out                   => open,
    gt0_cplllock_out                        => cpll_lock(0),
    gt0_cpllreset_in                        => rst_pulse,
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     => '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                => open,
    gt0_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt0_dmonitorout_out                     => open,
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxmonitorout_out                    => open,
    gt0_rxmonitorsel_in                     => "01",
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        => '1', 
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        => tx_rst(0),
    gt0_txuserrdy_in                        => tx_usrrdy0(31),
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt0_txdata_in                           => data_encoded,
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt0_gthtxn_out                          => txn(0),
    gt0_gthtxp_out                          => txp(0),
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt0_txoutclkfabric_out                  => open,	
    gt0_txoutclkpcs_out                     => open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt0_txresetdone_out                     => tx_rstdone(0),

    --GT1  (X1Y13)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt1_cpllfbclklost_out                   => open,
    gt1_cplllock_out                        => cpll_lock(1),
    gt1_cpllreset_in                        => rst_pulse,
    --------------------- RX Initialization and Reset Ports --------------------
    gt1_eyescanreset_in                     => '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt1_eyescandataerror_out                => open,
    gt1_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt1_dmonitorout_out                     => open,
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt1_rxmonitorout_out                    => open,
    gt1_rxmonitorsel_in                     => "01",
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt1_gtrxreset_in                        => '1', 
    --------------------- TX Initialization and Reset Ports --------------------
    gt1_gttxreset_in                        => tx_rst(1),
    gt1_txuserrdy_in                        => tx_usrrdy1(31),
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt1_txdata_in                           => data_encoded,
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt1_gthtxn_out                          => txn(1),
    gt1_gthtxp_out                          => txp(1),
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt1_txoutclkfabric_out                  => open,	
    gt1_txoutclkpcs_out                     => open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt1_txresetdone_out                     => tx_rstdone(1),

    --GT2  (X1Y14)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt2_cpllfbclklost_out                   => open,
    gt2_cplllock_out                        => cpll_lock(2),
    gt2_cpllreset_in                        => rst_pulse,
    --------------------- RX Initialization and Reset Ports --------------------
    gt2_eyescanreset_in                     => '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt2_eyescandataerror_out                => open,
    gt2_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt2_dmonitorout_out                     => open,
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt2_rxmonitorout_out                    => open,
    gt2_rxmonitorsel_in                     => "01",
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt2_gtrxreset_in                        => '1', 
    --------------------- TX Initialization and Reset Ports --------------------
    gt2_gttxreset_in                        => tx_rst(2),
    gt2_txuserrdy_in                        => tx_usrrdy2(31),
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt2_txdata_in                           => data_encoded,
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt2_gthtxn_out                          => txn(2),
    gt2_gthtxp_out                          => txp(2),
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt2_txoutclkfabric_out                  => open,	
    gt2_txoutclkpcs_out                     => open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt2_txresetdone_out                     => tx_rstdone(2),

    --GT3  (X1Y15)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt3_cpllfbclklost_out                   => open,
    gt3_cplllock_out                        => cpll_lock(3),
    gt3_cpllreset_in                        => rst_pulse,
    --------------------- RX Initialization and Reset Ports --------------------
    gt3_eyescanreset_in                     => '0',
    -------------------------- RX Margin Analysis Ports ------------------------
    gt3_eyescandataerror_out                => open,
    gt3_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt3_dmonitorout_out                     => open,
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt3_rxmonitorout_out                    => open,
    gt3_rxmonitorsel_in                     => "01",
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt3_gtrxreset_in                        => '1', 
    --------------------- TX Initialization and Reset Ports --------------------
    gt3_gttxreset_in                        => tx_rst(3),
    gt3_txuserrdy_in                        => tx_usrrdy3(31),
    ------------------ Transmit Ports - TX Data Path interface -----------------
    gt3_txdata_in                           => data_encoded,
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    gt3_gthtxn_out                          => txn(3),
    gt3_gthtxp_out                          => txp(3),
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    gt3_txoutclkfabric_out                  => open,	
    gt3_txoutclkpcs_out                     => open,
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    gt3_txresetdone_out                     => tx_rstdone(3),

    --____________________________COMMON PORTS________________________________
    GT0_QPLLOUTCLK_OUT  					=> open,
    GT0_QPLLOUTREFCLK_OUT 					=> open,

    sysclk_in                               => sysclk
);

end architecture rtl;