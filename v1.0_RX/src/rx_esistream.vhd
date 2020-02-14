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

entity rx_esistream is
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
end entity rx_esistream;

architecture rtl of rx_esistream is

---------------- Components ----------------
component control is
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
end component control ;

-- GTH Transceiver
component gth_rx_sfp is
port
(
     SOFT_RESET_RX_IN                        : in   std_logic;
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
 
    GT0_RXUSRCLK_OUT                        : out  std_logic;
    GT0_RXUSRCLK2_OUT                       : out  std_logic;
 
    GT1_RXUSRCLK_OUT                        : out  std_logic;
    GT1_RXUSRCLK2_OUT                       : out  std_logic;
 
    GT2_RXUSRCLK_OUT                        : out  std_logic;
    GT2_RXUSRCLK2_OUT                       : out  std_logic;
 
    GT3_RXUSRCLK_OUT                        : out  std_logic;
    GT3_RXUSRCLK2_OUT                       : out  std_logic;

    --_________________________________________________________________________
    --GT0  (X1Y12)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt0_cpllfbclklost_out                   : out  std_logic;
    gt0_cplllock_out                        : out  std_logic;
    gt0_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     : in   std_logic;
    gt0_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                : out  std_logic;
    gt0_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt0_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt0_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt0_gthrxn_in                           : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt0_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt0_rxoutclkfabric_out                  : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        : in   std_logic;
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt0_gthrxp_in                           : in   std_logic;
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt0_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        : in   std_logic;

    --GT1  (X1Y13)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt1_cpllfbclklost_out                   : out  std_logic;
    gt1_cplllock_out                        : out  std_logic;
    gt1_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt1_eyescanreset_in                     : in   std_logic;
    gt1_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt1_eyescandataerror_out                : out  std_logic;
    gt1_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt1_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt1_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt1_gthrxn_in                           : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt1_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt1_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt1_rxoutclkfabric_out                  : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt1_gtrxreset_in                        : in   std_logic;
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt1_gthrxp_in                           : in   std_logic;
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt1_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt1_gttxreset_in                        : in   std_logic;

    --GT2  (X1Y14)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt2_cpllfbclklost_out                   : out  std_logic;
    gt2_cplllock_out                        : out  std_logic;
    gt2_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt2_eyescanreset_in                     : in   std_logic;
    gt2_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt2_eyescandataerror_out                : out  std_logic;
    gt2_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt2_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt2_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt2_gthrxn_in                           : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt2_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt2_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt2_rxoutclkfabric_out                  : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt2_gtrxreset_in                        : in   std_logic;
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt2_gthrxp_in                           : in   std_logic;
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt2_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt2_gttxreset_in                        : in   std_logic;

    --GT3  (X1Y15)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt3_cpllfbclklost_out                   : out  std_logic;
    gt3_cplllock_out                        : out  std_logic;
    gt3_cpllreset_in                        : in   std_logic;
    --------------------- RX Initialization and Reset Ports --------------------
    gt3_eyescanreset_in                     : in   std_logic;
    gt3_rxuserrdy_in                        : in   std_logic;
    -------------------------- RX Margin Analysis Ports ------------------------
    gt3_eyescandataerror_out                : out  std_logic;
    gt3_eyescantrigger_in                   : in   std_logic;
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt3_dmonitorout_out                     : out  std_logic_vector(14 downto 0);
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt3_rxdata_out                          : out  std_logic_vector(15 downto 0);
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt3_gthrxn_in                           : in   std_logic;
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt3_rxmonitorout_out                    : out  std_logic_vector(6 downto 0);
    gt3_rxmonitorsel_in                     : in   std_logic_vector(1 downto 0);
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt3_rxoutclkfabric_out                  : out  std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt3_gtrxreset_in                        : in   std_logic;
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt3_gthrxp_in                           : in   std_logic;
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt3_rxresetdone_out                     : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gt3_gttxreset_in                        : in   std_logic;

    --____________________________COMMON PORTS________________________________
    GT0_QPLLOUTCLK_OUT  : out std_logic;
    GT0_QPLLOUTREFCLK_OUT : out std_logic;

    sysclk_in                               : in   std_logic

);
end component gth_rx_sfp;

component frame_alignment is
generic (
	DESER_FACTOR		: integer := 16;											-- Deserialization factor / For ESIstream 16
	COMMA				: std_logic_vector(31 downto 0) := X"00FFFF00"				-- COMMA to look for	
	);
port (
	clk 				: in std_logic;
	data_in		 		: in std_logic_vector(DESER_FACTOR-1 downto 0);				-- Input misaligned frames 
	start_align			: in std_logic;												-- Pulse when start synchronization
	data_out			: out std_logic_vector(DESER_FACTOR-1 downto 0);			-- Output aligned frames
	frame_align			: out std_logic												-- Indicates that frame alignment is done
	);
end component frame_alignment;

component lfsr_init is
generic (
	DESER_FACTOR 		: integer := 16;											-- Deserialization factor / For ESIstream 16
	LFSR_LENGTH			: integer := 17;											-- Length of LFSR / For ESIstream 17
	DATA_LENGTH			: integer := 14												-- Length of useful data / For ESIstream 14
	);
port (
	clk 				: in std_logic; 
	data_in 			: in std_logic_vector(DESER_FACTOR-1 downto 0);				-- Input aligned frames
	frame_align_done 	: in std_logic;												-- Indicates that frame alignment has been done, active high
	init_lfsr 			: out std_logic;											-- Start LFSR
	init_value 			: out std_logic_vector(LFSR_LENGTH-1 downto 0)				-- Initial value of LFSR
);
end component lfsr_init;

component scrambling_lfsr is	
port (
	clk					: in std_logic;
	init	 			: in std_logic;													-- Initialize LFSR with init_value
	init_value  		: in std_logic_vector(16 downto 0) := "11111111111111111";     	-- Initial value of LFSR
	lfsr_out			: out std_logic_vector(13 downto 0)                             -- PRBS word out
);
end component scrambling_lfsr;

component esistream_decoding is
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
end component esistream_decoding;

component fifo_data is
port (
    rst 			: in std_logic;	
    wr_clk 			: in std_logic;	
    rd_clk 			: in std_logic;	
    din 			: in std_logic_vector(DESER_FACTOR-1 downto 0);
    wr_en 			: in std_logic;	
    rd_en 			: in std_logic;	
    dout 			: out std_logic_vector(DESER_FACTOR-1 downto 0);
    full 			: out std_logic;
    empty 			: out std_logic
	);
end component fifo_data;

---------------- Signals ----------------

-- Clock
signal rx_usrclk				: std_logic_vector(NB_LANES-1 downto 0);
signal clk_out_t				: std_logic := '0';

-- Control
signal rst_gth                  : std_logic;
signal rst_logic_t				: std_logic;
signal rst_logic				: std_logic_vector(NB_LANES-1 downto 0);
signal sync_esistream			: std_logic;
signal start_cnt_sync			: std_logic;
signal cnt_sync					: std_logic_vector(7 downto 0);

signal rx_usrrdy				: std_logic_vector(NB_LANES-1 downto 0);
signal rx_rstdone				: std_logic_vector(NB_LANES-1 downto 0);
signal cpll_lock				: std_logic_vector(NB_LANES-1 downto 0);

signal frame_aligned			: std_logic_vector(NB_LANES-1 downto 0);

signal init_lfsr				: std_logic_vector(NB_LANES-1 downto 0);
signal lfsr_init_value			: std_logic_vector(LFSR_LENGTH*NB_LANES-1 downto 0);

signal write_fifo				: std_logic_vector(NB_LANES-1 downto 0);
signal write_fifo_t				: std_logic_vector(NB_LANES-1 downto 0);
signal release_fifo_t			: std_logic_vector(7 downto 0) := "00000000";
signal release_fifo				: std_logic_vector(NB_LANES-1 downto 0);

signal ip_ready_t				: std_logic := '0';

-- Data
signal data_gth					: std_logic_vector(DESER_FACTOR*NB_LANES-1 downto 0);
signal data_frame_aligned       : std_logic_vector(DESER_FACTOR*NB_LANES-1 downto 0);
signal data_prbs				: std_logic_vector(DATA_LENGTH*NB_LANES-1 downto 0);
signal data_decoded				: std_logic_vector(DATA_LENGTH*NB_LANES-1 downto 0);
signal data_out_t               : std_logic_vector(DESER_FACTOR*NB_LANES-1 downto 0);
signal clk_bit					: std_logic_vector(NB_LANES-1 downto 0);
signal disp_bit					: std_logic_vector(NB_LANES-1 downto 0);
signal data_fifo_in				: std_logic_vector(DESER_FACTOR*NB_LANES-1 downto 0);

begin

control_inst: control
generic map(
	NB_LANES 			=> NB_LANES
	)
port map(
	rst					=> rst,
	clk					=> clk_out_t,
	sync_in				=> sync_esistream,
	cpll_lock			=> cpll_lock,
	gth_rstdone			=> rx_rstdone,
	lanes_on			=> lanes_on,
	rst_gth				=> rst_gth,
	rst_logic			=> rst_logic_t,
	ip_ready			=> ip_ready_t
	);

-- Latch sync_in to clock_out for sync_out
process(clk_out_t)
begin
	if rising_edge(clk_out_t) then
	
		if sync_in = '1' then
			start_cnt_sync		<= '1';
			sync_out			<= '1';
		else
			sync_out			<= '0';
		end if;
		
		if start_cnt_sync = '1' then
			cnt_sync			<= cnt_sync + 1;
		else 
			cnt_sync			<= (others => '0');
		end if;
		
		if cnt_sync = DELAY_SYNC then
			start_cnt_sync		<= '0';
			sync_esistream		<= '1';
		else
			sync_esistream		<= '0';
		end if;
		
	end if;
end process;

-- Output affectation
data_out 		<= data_out_t;
clk_out_t		<= rx_usrclk(3);
clk_out			<= clk_out_t;
ip_ready		<= ip_ready_t;
lanes_sync		<= release_fifo_t(7) and ip_ready_t;

-- Internal affectation
rx_usrrdy		<= cpll_lock;

-- GTH Transceivers
gth_inst: gth_rx_sfp
port map
(
    SOFT_RESET_RX_IN                        => rst,
    DONT_RESET_ON_DATA_ERROR_IN             => '1', 				-- No automatic reset when data_valid = '0'
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
 
    GT0_RXUSRCLK_OUT                        => rx_usrclk(0),
    GT0_RXUSRCLK2_OUT                       => open,
                                            
    GT1_RXUSRCLK_OUT                        => rx_usrclk(1),
    GT1_RXUSRCLK2_OUT                       => open,
                                            
    GT2_RXUSRCLK_OUT                        => rx_usrclk(2),
    GT2_RXUSRCLK2_OUT                       => open,
                                            
    GT3_RXUSRCLK_OUT                        => rx_usrclk(3),
    GT3_RXUSRCLK2_OUT                       => open,

    --_________________________________________________________________________
    --GT0  (X1Y12)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt0_cpllfbclklost_out                   => open,
    gt0_cplllock_out                        => cpll_lock(0),
    gt0_cpllreset_in                        => rst,
    --------------------- RX Initialization and Reset Ports --------------------
    gt0_eyescanreset_in                     => '0',
    gt0_rxuserrdy_in                        => rx_usrrdy(0),
    -------------------------- RX Margin Analysis Ports ------------------------
    gt0_eyescandataerror_out                => open,
    gt0_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt0_dmonitorout_out                     => open,
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt0_rxdata_out                          => data_gth( (0+1)*DESER_FACTOR-1 downto 0*DESER_FACTOR ),
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt0_gthrxn_in                           => rxn(0),
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt0_rxmonitorout_out                    => open,
    gt0_rxmonitorsel_in                     => "01",	-- AGC loop
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt0_rxoutclkfabric_out                  => open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt0_gtrxreset_in                        => rst_gth,
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt0_gthrxp_in                           => rxp(0),
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt0_rxresetdone_out                     => rx_rstdone(0),
    --------------------- TX Initialization and Reset Ports --------------------
    gt0_gttxreset_in                        => rst_gth,

    --GT1  (X1Y13)
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt1_cpllfbclklost_out                   => open,
    gt1_cplllock_out                        => cpll_lock(1),
    gt1_cpllreset_in                        => rst,
    --------------------- RX Initialization and Reset Ports --------------------
    gt1_eyescanreset_in                     => '0',
    gt1_rxuserrdy_in                        => rx_usrrdy(1),
    -------------------------- RX Margin Analysis Ports ------------------------
    gt1_eyescandataerror_out                => open,
    gt1_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt1_dmonitorout_out                     => open,
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt1_rxdata_out                          => data_gth( (1+1)*DESER_FACTOR-1 downto 1*DESER_FACTOR ),
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt1_gthrxn_in                           => rxn(1),
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt1_rxmonitorout_out                    => open,
    gt1_rxmonitorsel_in                     => "01",	-- AGC loop
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt1_rxoutclkfabric_out                  => open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt1_gtrxreset_in                        => rst_gth,
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt1_gthrxp_in                           => rxp(1),
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt1_rxresetdone_out                     => rx_rstdone(1),
    --------------------- TX Initialization and Reset Ports --------------------
    gt1_gttxreset_in                        => rst_gth,
                                            
    --GT2  (X1Y14)                          
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt2_cpllfbclklost_out                   => open,
    gt2_cplllock_out                        => cpll_lock(2),
    gt2_cpllreset_in                        => rst,
    --------------------- RX Initialization and Reset Ports --------------------
    gt2_eyescanreset_in                     => '0',
    gt2_rxuserrdy_in                        => rx_usrrdy(2),
    -------------------------- RX Margin Analysis Ports ------------------------
    gt2_eyescandataerror_out                => open,
    gt2_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt2_dmonitorout_out                     => open,
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt2_rxdata_out                          => data_gth( (2+1)*DESER_FACTOR-1 downto 2*DESER_FACTOR ),
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt2_gthrxn_in                           => rxn(2),
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt2_rxmonitorout_out                    => open,
    gt2_rxmonitorsel_in                     => "01",	-- AGC loop
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt2_rxoutclkfabric_out                  => open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt2_gtrxreset_in                        => rst_gth,
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt2_gthrxp_in                           => rxp(2),
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt2_rxresetdone_out                     => rx_rstdone(2),
    --------------------- TX Initialization and Reset Ports --------------------
    gt2_gttxreset_in                        => rst_gth,
                                            
    --GT3  (X1Y15)                          
    --____________________________CHANNEL PORTS________________________________
    --------------------------------- CPLL Ports -------------------------------
    gt3_cpllfbclklost_out                   => open,
    gt3_cplllock_out                        => cpll_lock(3),
    gt3_cpllreset_in                        => rst,
    --------------------- RX Initialization and Reset Ports --------------------
    gt3_eyescanreset_in                     => '0',
    gt3_rxuserrdy_in                        => rx_usrrdy(3),
    -------------------------- RX Margin Analysis Ports ------------------------
    gt3_eyescandataerror_out                => open,
    gt3_eyescantrigger_in                   => '0',
    ------------------- Receive Ports - Digital Monitor Ports ------------------
    gt3_dmonitorout_out                     => open,
    ------------------ Receive Ports - FPGA RX interface Ports -----------------
    gt3_rxdata_out                          => data_gth( (3+1)*DESER_FACTOR-1 downto 3*DESER_FACTOR ),
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gt3_gthrxn_in                           => rxn(3),
    --------------------- Receive Ports - RX Equalizer Ports -------------------
    gt3_rxmonitorout_out                    => open,
    gt3_rxmonitorsel_in                     => "01",	-- AGC loop
    --------------- Receive Ports - RX Fabric Output Control Ports -------------
    gt3_rxoutclkfabric_out                  => open,
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gt3_gtrxreset_in                        => rst_gth,
    ------------------------ Receive Ports -RX AFE Ports -----------------------
    gt3_gthrxp_in                           => rxp(3),
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    gt3_rxresetdone_out                     => rx_rstdone(3),
    --------------------- TX Initialization and Reset Ports --------------------
    gt3_gttxreset_in                        => rst_gth,

    --____________________________COMMON PORTS________________________________
    GT0_QPLLOUTCLK_OUT  					=> open,
    GT0_QPLLOUTREFCLK_OUT 					=> open,
                                            
    sysclk_in                               => sysclk

);

-- Frame alignment
frame_align_generate: for i in NB_LANES-1 downto 0 generate
	frame_alignment_inst: frame_alignment 
	generic map(
		DESER_FACTOR		=> DESER_FACTOR,
		COMMA				=> COMMA
	) 
	port map(
		clk 				=> rx_usrclk(i),
		data_in		 		=> data_gth( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR ),
		start_align			=> sync_esistream,
		data_out			=> data_frame_aligned( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR ),
		frame_align			=> frame_aligned(i)
	);
end generate;

-- PRBS initialization
lfsr_init_generate: for i in NB_LANES-1 downto 0 generate
	lfsr_init_inst: lfsr_init
	generic map(
		DESER_FACTOR 		=> DESER_FACTOR,
		LFSR_LENGTH			=> LFSR_LENGTH,
		DATA_LENGTH			=> DATA_LENGTH
	)
	port map(
		clk 				=> rx_usrclk(i),
		data_in 			=> data_frame_aligned( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR ),
		frame_align_done 	=> frame_aligned(i),
		init_lfsr 			=> init_lfsr(i),
		init_value 			=> lfsr_init_value( (i+1)*LFSR_LENGTH-1 downto i*LFSR_LENGTH )
	);
end generate;

-- LFSR
scrambling_lfsr_generate: for i in NB_LANES-1 downto 0 generate
	scrambling_lfsr_inst: scrambling_lfsr
	port map(						
		clk					=> rx_usrclk(i),
		init	 			=> init_lfsr(i),
		init_value  		=> lfsr_init_value( (i+1)*LFSR_LENGTH-1 downto i*LFSR_LENGTH ),
		lfsr_out			=> data_prbs( (i+1)*DATA_LENGTH-1 downto i*DATA_LENGTH )
	);
end generate;

-- Process data
process_generate: for i in NB_LANES-1 downto 0 generate
	esistream_decoding_inst: esistream_decoding
	generic map(
		DESER_FACTOR		=> DESER_FACTOR,
		DATA_LENGTH			=> DATA_LENGTH											
	) 
	port map(
		clk 				=> rx_usrclk(i),
		data_in 			=> data_frame_aligned( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR ),
		prbs_value 			=> data_prbs( (i+1)*DATA_LENGTH-1 downto i*DATA_LENGTH ),
		prbs_ctrl			=> prbs_ctrl,
		data_out			=> data_decoded( (i+1)*DATA_LENGTH-1 downto i*DATA_LENGTH ),
		clk_bit				=> clk_bit(i),	
		disp_bit			=> disp_bit(i)
	);
end generate;

-- FIFO	    -- Comment for behavioral simulation
FIFO_generate: for i in NB_LANES-1 downto 0 generate
	data_fifo_in( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR )		<= disp_bit(i) & clk_bit(i) & data_decoded( (i+1)*DATA_LENGTH-1 downto i*DATA_LENGTH );

	fifo_data_inst: fifo_data
	port map(
		rst 				=> rst_logic(i),
		wr_clk 				=> rx_usrclk(i),
		rd_clk 				=> clk_out_t,	
		din 				=> data_fifo_in( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR ),
		wr_en 				=> write_fifo(i),	
		rd_en 				=> release_fifo(i),
		dout 				=> data_out_t( (i+1)*DESER_FACTOR-1 downto i*DESER_FACTOR ),
		full 				=> open,
		empty 				=> open
	);
end generate;

-- -- FIFO Uncomment for behavioral simulation
-- FIFO_generate: for i in NB_LANES-1 downto 0 generate
	-- data_out_t( (i+1)*DESER_FACTOR-1 ) 							<= disp_bit(i);
	-- data_out_t( (i+1)*DESER_FACTOR-2 ) 							<= clk_bit(i);
	-- data_out_t( (i+1)*DESER_FACTOR-3 downto i*DESER_FACTOR ) 	<= data_decoded( (i+1)*DATA_LENGTH-1 downto i*DATA_LENGTH );
-- end generate;

-- Reset timing management
process(rx_usrclk)
begin
	for i in NB_LANES-1 downto 0 loop
		if rising_edge(rx_usrclk(i)) then
			rst_logic(i)	<= rst_logic_t;
		end if;
	end loop;
end process;

-- Multiple lane alignment
write_fifo		<= write_fifo_t;

process(rx_usrclk, rst)
begin
	for i in NB_LANES-1 downto 0 loop
		if rst = '1' then
			write_fifo_t(i)    <= '0';		
		elsif rising_edge(rx_usrclk(i)) then			
			if rst_logic(i) = '1' then
				write_fifo_t(i)    <= '0';
			elsif init_lfsr(i) = '1' and lanes_on(i) = '1' then
				write_fifo_t(i)    <= '1';
			end if;
		end if;	
	end loop;
end process;

process(clk_out_t, rst)
begin
	if rst = '1' then
		release_fifo_t	      		<= (others => '0');
		release_fifo	      		<= (others => '0');
	elsif rising_edge(clk_out_t) then
		if rst_logic_t = '1' then 
			release_fifo_t	      		<= (others => '0');
			release_fifo	      		<= (others => '0');
		else
			if write_fifo = lanes_on then
					release_fifo_t(0)   <= '1';
			end if;
			release_fifo_t(7 downto 1)	<= release_fifo_t(6 downto 0);
			
			if release_fifo_t(3) = '1' then
				release_fifo				<= lanes_on;
			end if;
		end if;
	end if;	
end process;

end architecture rtl;