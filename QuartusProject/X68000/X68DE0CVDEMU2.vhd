LIBRARY	IEEE;
	USE	IEEE.STD_LOGIC_1164.ALL;
	USE IEEE.STD_LOGIC_ARITH.ALL;
	USE	IEEE.STD_LOGIC_UNSIGNED.ALL;
	use work.FDC_timing.all;
	use work.I2C_pkg.all;
	use work.I2C_TLC59116_pkg.all;


entity X68DE0CVDEMU2 is
generic(
	RCFREQ		:integer	:=80;			--SDRAM clock MHz
	SCFREQ		:integer	:=10000;		--kHz
	FCFREQ		:integer	:=30000;		--FDC clock
	ACFREQ		:integer	:=32000;		--Audio clock
	DACFREQ		:integer	:=16000;		--Audio DAC freq
	DEBUG			:std_logic_vector(7 downto 0)	:="00000010"	--nop,SPRBGONOFF,OPMCH_ONOFF,PAUSE_ONOFF,GRP_ONOFF,SCR_ONOFF,ADPCM_ONOFF,CYCLERESET
);
port(
	pClk50M		:in std_logic;
	
	pI2Cscl		: inout std_logic;
    pI2Csda		: inout std_logic;

    -- SD-RAM ports
    pMemClk     : out std_logic;                        -- SD-RAM Clock
    pMemCke     : out std_logic;                 		-- SD-RAM Clock enable
    pMemCs_n    : out std_logic;                        -- SD-RAM Chip select
    pMemRas_n   : out std_logic;                        -- SD-RAM Row/RAS
    pMemCas_n   : out std_logic;                        -- SD-RAM /CAS
    pMemWe_n    : out std_logic;                        -- SD-RAM /WE
    pMemUdq     : out std_logic;                        -- SD-RAM UDQM
    pMemLdq     : out std_logic;                        -- SD-RAM LDQM
    pMemBa1     : out std_logic;                        -- SD-RAM Bank select address 1
    pMemBa0     : out std_logic;                        -- SD-RAM Bank select address 0
    pMemAdr     : out std_logic_vector(12 downto 0);    -- SD-RAM Address
    pMemDat     : inout std_logic_vector(15 downto 0);  -- SD-RAM Data

    -- PS/2 keyboard ports
    pPs2Clk     : inout std_logic;
    pPs2Dat     : inout std_logic;
    pPmsClk		: inout std_logic;
    pPmsDat		: inout std_logic;

    -- Joystick ports (Port_A, Port_B)
    pJoyA       : inout std_logic_vector( 5 downto 0);
    pJoyB       : inout std_logic_vector( 5 downto 0);
    pStrA		: out std_logic;
	 pStrB		: out std_logic;
    -- SD/MMC slot ports
    pSd_Ck      : out std_logic;                        -- pin 5
    pSd_Cm      : out std_logic;                        -- pin 2
    pSd_Dt      : inout std_logic_vector(3 downto 0);

	-- FDD ports
	pFd_DENn		:out std_logic;
	pFd_INDEXn		:in std_logic;
	pFd_DIRn		:out std_logic;
	pFd_STEPn		:out std_logic;
	pFd_WDATAn		:out std_logic;
	pFd_WGATEn		:out std_logic;
	pFd_TRK00n		:in std_logic;
	pFd_WPTn		:in std_logic;
	pFd_RDATAn		:in std_logic;
	pFd_SIDE1n		:out std_logic;
	pFd_DSKCHG		:in std_logic;
	pFd_DS0			:out std_logic;
	pFd_DS1			:out std_logic;
	pFd_MOTORON		:out std_logic;
	pFd_PIN14		:out std_logic;

    -- DIP switch, Lamp ports
    pDip        : in std_logic_vector( 9 downto 0);     -- 0=ON,  1=OFF(default on shipment)
    pLed        : out std_logic_vector( 9 downto 0);    -- 0=OFF, 1=ON(green)
    pPsw			: in std_logic_vector(3 downto 0);
    pSeg0		: out std_logic_vector(7 downto 0);
    pSeg1		: out std_logic_vector(7 downto 0);
    pSeg2		: out std_logic_vector(7 downto 0);
    pSeg3		: out std_logic_vector(7 downto 0);
    pSeg4		: out std_logic_vector(7 downto 0);
    pSeg5		: out std_logic_vector(7 downto 0);

    -- Video, Audio/CMT ports
    pDac_VR     : inout std_logic_vector( 3 downto 0);  -- RGB_Red / Svideo_C
    pDac_VG     : inout std_logic_vector( 3 downto 0);  -- RGB_Grn / Svideo_Y
    pDac_VB     : inout std_logic_vector( 3 downto 0);  -- RGB_Blu / CompositeVideo
    pDac_SL     : out   std_logic;  -- Sound-L
    pDac_SR     : out std_logic;  	-- Sound-R

    pVideoHS_n  : out std_logic;                        -- Csync(RGB15K), HSync(VGA31K)
    pVideoVS_n  : out std_logic;                        -- Audio(RGB15K), VSync(VGA31K)

	pMidi_in		:in std_logic;
	pMidi_out	:out std_logic;
	-- COM(RS-232C) port
--	pCOM_TxD	:out std_logic;
--	pCOM_RxD	:in std_logic;
--	pCOM_CTS	:in std_logic;
--	pCOM_RTS	:out std_logic;

	pHDMI_DAT0	:out std_logic;
	pHDMI_DAT1	:out std_logic;
	pHDMI_DAT2	:out std_logic;
	pHDMI_CLK	:out std_logic;
--	pHDMI_SCL	:inout std_logic;
--	pHDMI_SDA	:inout std_logic;
--	pHDMI_PWR	:in std_logic;

	pDemuSw		:in std_logic;
	pHang	:out std_logic;
	
	rstn		:in std_logic;

	-- F68k I/O board's ports (kunichiko's experiments)
	pF68kIO_I2S_BICK   : out std_logic;
	pF68kIO_I2S_DATA   : out std_logic;
	pF68kIO_I2S_LRCK   : out std_logic;
	
	-- to real YM2151
	pOPM_DATA  : inout std_logic_vector( 7 downto 0);
	pOPM_A0    : out std_logic;
	pOPM_RD_n  : out std_logic;
	pOPM_WR_n  : out std_logic;
	pOPM_IRQ_n : in std_logic;
	pOPM_RST   : out std_logic;
	pOPM_CLK   : out std_logic;
	--
	pOPM_CLK_PHY1  : in std_logic;
	pOPM_SDATA     : in std_logic;
	pOPM_SAM_HOLD1 : in std_logic;
	pOPM_SAM_HOLD2 : in std_logic;

	pOPM_SEL_L : in std_logic;
	pOPM_SEL_R : in std_logic
);
end X68DE0CVDEMU2;

architecture rtl of X68DE0CVDEMU2 is

constant brsize		:integer	:=7;
constant RAMAWIDTH	:integer	:=26;	--per byte

constant DBIT_CYCLERESET	:integer	:=0;
constant DBIT_ADPCM_ONOFF	:integer	:=1;
constant DBIT_SCR_ONOFF		:integer	:=2;
constant DBIT_GRP_ONOFF		:integer	:=3;
constant DBIT_PAUSE_ONOFF	:integer	:=4;
constant DBIT_OPMCH_ONOFF	:integer	:=5;
constant DBIT_SPRBG_ONOFF	:integer	:=6;

signal	ramclk	:std_logic;
signal	sysclk	:std_logic;
signal	vidclk	:std_logic;
signal	sndclk	:std_logic;
signal	emuclk	:std_logic;
signal	i2sclk	:std_logic;
signal	srstn	:std_logic;
signal	srst	:std_logic;
signal	pllrst	:std_logic;
signal	plllock	:std_logic;
signal	ldr_rstn:std_logic;
signal	mem_rstn:std_logic;
signal	pwr_rstn:std_logic;
signal	pwrsw	:std_logic;
signal	vid_rstn	:std_logic;
signal	willrst:std_logic;

signal	dbus	:std_logic_vector(15 downto 0);
signal	abus	:std_logic_vector(23 downto 0);
signal	b_as	:std_logic;
signal	b_udsn	:std_logic;
signal	b_ldsn	:std_logic;
signal	b_uds	:std_logic;
signal	b_lds	:std_logic;
signal	b_rwn	:std_logic;
signal	b_ack	:std_logic;
signal	b_rd,b_rdn	:std_logic;
signal	b_wr,b_wrn	:std_logic_vector(1 downto 0);
-- for mpu
signal	mpu_addr	:std_logic_vector(31 downto 0);
signal	mpu_od		:std_logic_vector(15 downto 0);
signal	mpu_oe		:std_logic;
signal	mpu_ipl			:std_logic_vector(2 downto 0);
signal	mpu_dtack		:std_logic;
signal	mpu_as			:std_logic;
signal	mpu_udsn			:std_logic;
signal	mpu_ldsn			:std_logic;
signal	mpu_rwn			:std_logic;
signal	mpu_clke			:std_logic;

-- for memorymap
signal	m_addr	:std_logic_vector(31 downto 0);
signal	m_odat	:std_logic_vector(15 downto 0);
signal	m_doe	:std_logic;
signal	m_ack	:std_logic;
signal	ram_addr:std_logic_vector(22 downto 0);
signal	ram_addrw:std_logic_vector(RAMAWIDTH-2 downto 0);
signal	ram_rdat:std_logic_vector(15 downto 0);
signal	ram_wdat:std_logic_vector(15 downto 0);
signal	ram_rd	:std_logic;
signal	ram_wr	:std_logic_vector(1 downto 0);
signal	ram_rmw	:std_logic_vector(1 downto 0);
signal	ram_rmwmask	:std_logic_vector(15 downto 0);
signal	ram_ack	:std_logic;
constant trambase	:std_logic_vector(RAMAWIDTH-1 downto 0)	:="00"& x"e00000";
signal	ram_cpys:std_logic_vector(RAMAWIDTH-brsize-2 downto 0);
signal	ram_cpyd:std_logic_vector(RAMAWIDTH-brsize-2 downto 0);
signal	ram_cplane:std_logic_vector(3 downto 0);
signal	ram_cpy	:std_logic;
signal	ram_cpya:std_logic;
signal	ram_inidone:std_logic;
signal	buserr	:std_logic;
signal	iackbe	:std_logic;
signal	mmap_min	:std_logic;
signal	iowait	:std_logic;

-- Initial ROM loader
signal	ldr_addr	:std_logic_vector(19 downto 0);
signal	ldr_aen		:std_logic;
signal	ldr_wdat	:std_logic_vector(7 downto 0);
signal	ldr_wr		:std_logic;
signal	ldr_ack		:std_logic;
signal	ldr_done	:std_logic;

--Interrupt
signal	INT7	:std_logic;
signal	INT6	:std_logic;
signal	IACK6	:std_logic;
signal	IVECT6	:std_logic_vector(7 downto 0);
signal	INT5	:std_logic;
signal	IACK5	:std_logic;
signal	IVECT5	:std_logic_vector(7 downto 0);
signal	INT4	:std_logic;
signal	IACK4	:std_logic;
signal	IVECT4	:std_logic_vector(7 downto 0);
signal	INT3	:std_logic;
signal	IACK3	:std_logic;
signal	IVECT3	:std_logic_vector(7 downto 0);
signal	INT2	:std_logic;
signal	IACK2	:std_logic;
signal	IVECT2	:std_logic_vector(7 downto 0);
signal	INT1	:std_logic;
signal	IACK1	:std_logic;
signal	IVECT1	:std_logic_vector(7 downto 0);
signal	int_addr	:std_logic_vector(23 downto 0);

--for DMA
signal	dma_bconte	:std_logic;
signal	dma_addr	:std_logic_vector(23 downto 0);
signal	dma_as		:std_logic;
signal	dma_rwn		:std_logic;
signal	dma_udsn		:std_logic;
signal	dma_ldsn		:std_logic;
signal	dma_odat	:std_logic_vector(15 downto 0);
signal	dma_doe		:std_logic;
signal	dma_drd		:std_logic;
signal	dma_dwr		:std_logic;

-- for graphics line buffer
signal	LRAMSEL	:std_logic;
signal	LBUFADR	:std_logic_vector(9 downto 0);
signal	LBUFRD0	:std_logic_vector(15 downto 0);
signal	LBUFRD1	:std_logic_vector(15 downto 0);
signal	LBUFRD	:std_logic_vector(15 downto 0);
signal	LBUFWD	:std_logic_vector(15 downto 0);
signal	LBUFWR	:std_logic;
signal	LVIDADR	:std_logic_vector(9 downto 0);
signal	LVIDRD0	:std_logic_vector(15 downto 0);
signal	LVIDRD1	:std_logic_vector(15 downto 0);
signal	LVIDRD	:std_logic_vector(15 downto 0);
signal	LBUFWR0,LBUFWR1	:std_logic;

signal	HCOMP	:std_logic;
signal	VPSTART	:std_logic;
--Video
signal	VID_HRTC	:std_logic;
signal	VID_HRTCd	:std_logic;
signal	VID_HRTCi	:std_logic;
signal	VID_VRTC	:std_logic;
signal	VID_RINT	:std_logic;
signal	VID_VVIDEN	:std_logic;
--sprite
signal	spr_x		:std_logic_vector(9 downto 0);
signal	spr_y		:std_logic_vector(9 downto 0);
signal	spr_dot		:std_logic_vector(7 downto 0);
 --registaer
signal	spreg_rdat		:std_logic_vector(15 downto 0);
signal	spreg_doe		:std_logic;
signal	spreg_sprno		:std_logic_vector(6 downto 0);
signal	spreg_xpos		:std_logic_Vector(9 downto 0);
signal	spreg_ypos		:std_logic_vector(9 downto 0);
signal	spreg_VR		:std_logic;
signal	spreg_HR		:std_logic;
signal	spreg_COLOR		:std_logic_vector(3 downto 0);
signal	spreg_PATNO		:std_logic_vector(7 downto 0);
signal	spreg_PRI		:std_logic_vector(1 downto 0);
signal	spreg_BG0Xpos	:std_logic_vector(9 downto 0);
signal	spreg_BG0Ypos	:std_logic_vector(9 downto 0);
signal	spreg_BG1Xpos	:std_logic_vector(9 downto 0);
signal	spreg_BG1Ypos	:std_logic_vector(9 downto 0);
signal	spreg_DISPEN	:std_logic;
signal	spreg_BG1TXSEL	:std_logic_vector(1 downto 0);
signal	spreg_BG0TXSEL	:std_logic_vector(1 downto 0);
signal	spreg_BGON		:std_logic_vector(1 downto 0);
signal	spreg_VRES		:std_logic_vector(1 downto 0);
signal	spreg_HRES		:std_logic_vector(1 downto 0);
 --ram
signal	spram_rdat	:std_logic_vector(15 downto 0);
signal	spram_doe	:std_logic;
signal	sp_patno	:std_logic_vector(9 downto 0);
signal	sp_dotx		:std_logic_vector(2 downto 0);
signal	sp_doty		:std_logic_vector(2 downto 0);
signal	sp_dot		:std_logic_vector(3 downto 0);
	
signal	bg_addr		:std_logic_vector(12 downto 0);
signal	bg_VR		:std_logic;
signal	bg_HR		:std_logic;
signal	bg_COLOR	:std_logic_vector(3 downto 0);
signal	bg_PAT		:std_logic_vector(7 downto 0);

--Disk emu
signal	dem_rstn	:std_logic;
signal	dem_initdone	:std_logic;
signal	dem_tramaddr	:std_logic_vector(12 downto 0);
signal	dem_tramdat		:std_logic_vector(7 downto 0);
signal	dem_tramamod	:std_logic_vector(12 downto 0);
signal	dem_fontaddr	:std_logic_vector(11 downto 0);
signal	dem_fontdat		:std_logic_vector(7 downto 0);
signal	dem_kbdat		:std_logic_vector(7 downto 0);
signal	dem_kbrx		:std_logic;
signal	dem_curl		:std_logic_vector(5 downto 0);
signal	dem_curc		:std_logic_vector(6 downto 0);
signal	dem_curen		:std_logic;
signal	dem_fderamaddr	:std_logic_vector(23 downto 0);
signal	dem_fderamrdat	:std_logic_vector(15 downto 0);
signal	dem_fderamwdat	:std_logic_vector(15 downto 0);
signal	dem_fderamwr	:std_logic;
signal	dem_fecramaddrh	:std_logic_vector(15 downto 0);
signal	dem_fecramaddrl	:std_logic_vector(7 downto 0);
signal	dem_fecramwe	:std_logic;
signal	dem_fecramrdat	:std_logic_vector(15 downto 0);
signal	dem_fecramwdat	:std_logic_vector(15 downto 0);
signal	dem_fecramrd	:std_logic;
signal	dem_fecramwr	:std_logic;
signal	dem_fdetracklen	:std_logic_vector(13 downto 0);
signal	dem_fecrambusy	:std_logic;
signal	dem_conten		:std_logic;
-- for FDC
signal	fdcclk		:std_logic;
signal	FDC_cs		:std_logic;
signal	FDC_csn		:std_logic;
signal	FDC_WD		:std_logic_vector(7 downto 0);
signal	FDC_OE		:std_logic;
signal	FDC_DACK	:std_logic;
signal	FDC_DACKn	:std_logic;
signal	FDC_DRQ		:std_logic;
signal	FDC_TC		:std_logic;
signal	FDC_INTn	:std_logic;
signal	FDC_INT		:std_logic;
signal	FDC_WAIT	:std_logic;
signal	FD_hmssft	:std_logic;
signal	FD_int0		:integer range 0 to (BR_300_D*FCFREQ/1000000);
signal	FD_int1		:integer range 0 to (BR_300_D*FCFREQ/1000000);
signal	FDC_READYn	:std_logic;
signal	FDD_READYn	:std_logic;
signal	FDC_READYm	:std_logic;
signal	FDSREG		:std_logic_vector(15 downto 0);
signal	FD_DE		:std_logic_vector(1 downto 0);
signal	FDC_BUSY	:std_logic;
signal	FDCPY_BUSY	:std_logic;
signal	FDC_DSKCHG	:std_logic;
signal	FDC_indisk	:std_logic_vector(3 downto 0);
signal	FDC_wrenn	:std_logic;
signal	FDC_wrbitn	:std_logic;
signal	FDC_rdbitn	:std_logic;
signal	FDC_stepn	:std_logic;
signal	FDC_sdirn	:std_logic;
signal	FDC_track0n	:std_logic;
signal	FDC_indexn	:std_logic;
signal	FDC_siden	:std_logic;
signal	FDC_wprotn	:std_logic;
signal	FDC_USELn	:std_logic_vector(3 downto 0);
signal	FDC_MOTORn	:std_logic_vector(3 downto 0);
signal	FDC_MFM		:std_logic;
signal	FDC_eject	:std_logic_vector(3 downto 0);
signal	FDD_eject	:std_logic_vector(1 downto 0);
signal	FDD_indisk	:std_logic_vector(1 downto 0);
signal	FDD_USELn	:std_logic_vector(1 downto 0);
signal	FD_USELn	:std_logic_vector(1 downto 0);
signal	FD_MOTORn	:std_logic_vector(1 downto 0);

-- for SDcard
signal	SDC_CS		:std_logic;
signal	SDC_SCLK	:std_logic;
signal	SDC_DO		:std_logic;
signal	SDC_DI		:std_logic;

signal	SD_FAST_MISO	:std_logic;
signal	SD_FAST_MOSI	:std_logic;
signal	SD_FAST_CLK		:std_logic;
signal	SD_FAST_CS		:std_logic;
signal	SD_SLOW_MISO	:std_logic;
signal	SD_SLOW_MOSI	:std_logic;
signal	SD_SLOW_CLK		:std_logic;
signal	SD_SLOW_CS		:std_logic;
signal	SD_HS			:std_logic;

--for SCSI
signal	SCSI_CS		:std_logic;
signal	SCSI_RDAT	:std_logic_vector(7 downto 0);
signal	SCSI_DOE	:std_logic;
signal	SCSI_INT	:std_logic;
signal	SCSI_IACK	:std_logic;
signal	SCSI_DRQ	:std_logic;
signal	SCSI_DACK	:std_logic;
signal	SCSI_BUSY	:std_logic;
signal	iowait_scsi	:std_logic;

signal	SCSI_H2C	:std_logic_vector(7 downto 0);
signal	SCSI_C2H	:std_logic_vector(7 downto 0);
signal	SCSI_SEL	:std_logic;
signal	SCSI_BSY	:std_logic;
signal	SCSI_REQ	:std_logic;
signal	SCSI_ACK	:std_logic;
signal	SCSI_IO		:std_logic;
signal	SCSI_CD		:std_logic;
signal	SCSI_MSG	:std_logic;
signal	SCSI_RST	:std_logic;

signal	SCSI_SELf	:std_logic;
signal	SCSI_BSYf	:std_logic;
signal	SCSI_REQf	:std_logic;
signal	SCSI_ACKf	:std_logic;
signal	SCSI_IOf	:std_logic;
signal	SCSI_CDf	:std_logic;
signal	SCSI_MSGf	:std_logic;
signal	SCSI_RSTf	:std_logic;

-- IO unit
signal	IOU_rdat	:std_logic_vector(7 downto 0);
signal	IOU_doe		:std_logic;
signal	IOU_INT		:std_logic;
signal	IOU_IVECT	:std_logic_vector(7 downto 0);
signal	IOU_ivack	:std_logic_vector(7 downto 0);
signal	FD_HD,FD_HDn		:std_logic;
signal	FD_MOTOR	:std_logic;
signal	FD_USEL		:std_logic_vector(1 downto 0);
signal	FD_DIRn		:std_logic;
signal	FD_STEPn	:std_logic;
signal	FDD_MOTORn	:std_logic_vector(1 downto 0);

-- nvram(SRAM)
signal	nvwp		:std_logic_vector(7 downto 0);
signal	nv_rdat		:std_logic_vector(15 downto 0);
signal	nv_wr		:std_logic_vector(1 downto 0);
signal	nv_ce		:std_logic;
signal	nv_doe		:std_logic;
signal	nv_wren		:std_logic;
--signal	I2Csclin	:std_logic;
--signal	I2Csclout	:std_logic;
--signal	I2CSDAin	:std_logic;
--signal	I2CSDAout	:std_logic;

--video controller
signal	g00_addr	:std_logic_vector(24 downto 0);
signal	g00_rd		:std_logic;
signal	g00_rdat	:std_logic_vector(15 downto 0);
signal	g00_ack		:std_logic;
signal	g01_addr	:std_logic_vector(24 downto 0);
signal	g01_rd		:std_logic;
signal	g01_rdat	:std_logic_vector(15 downto 0);
signal	g01_ack		:std_logic;
signal	g02_addr	:std_logic_vector(24 downto 0);
signal	g02_rd		:std_logic;
signal	g02_rdat	:std_logic_vector(15 downto 0);
signal	g02_ack		:std_logic;
signal	g03_addr	:std_logic_vector(24 downto 0);
signal	g03_rd		:std_logic;
signal	g03_rdat	:std_logic_vector(15 downto 0);
signal	g03_ack		:std_logic;

signal	t0_addr		:std_logic_vector(22 downto 0);
signal	t0_rd		:std_logic;
signal	t0_rdat0	:std_logic_vector(15 downto 0);
signal	t0_rdat1	:std_logic_vector(15 downto 0);
signal	t0_rdat2	:std_logic_vector(15 downto 0);
signal	t0_rdat3	:std_logic_vector(15 downto 0);
signal	t0_ack		:std_logic;

signal	g10_addr	:std_logic_vector(24 downto 0);
signal	g10_rd		:std_logic;
signal	g10_rdat	:std_logic_vector(15 downto 0);
signal	g10_ack		:std_logic;
signal	g11_addr	:std_logic_vector(24 downto 0);
signal	g11_rd		:std_logic;
signal	g11_rdat	:std_logic_vector(15 downto 0);
signal	g11_ack		:std_logic;
signal	g12_addr	:std_logic_vector(24 downto 0);
signal	g12_rd		:std_logic;
signal	g12_rdat	:std_logic_vector(15 downto 0);
signal	g12_ack		:std_logic;
signal	g13_addr	:std_logic_vector(24 downto 0);
signal	g13_rd		:std_logic;
signal	g13_rdat	:std_logic_vector(15 downto 0);
signal	g13_ack		:std_logic;

signal	t1_addr		:std_logic_vector(22 downto 0);
signal	t1_rd		:std_logic;
signal	t1_rdat0	:std_logic_vector(15 downto 0);
signal	t1_rdat1	:std_logic_vector(15 downto 0);
signal	t1_rdat2	:std_logic_vector(15 downto 0);
signal	t1_rdat3	:std_logic_vector(15 downto 0);
signal	t1_ack		:std_logic;

signal	g0_caddr	:std_logic_vector(24 downto 7);
signal	g0_clear	:std_logic;
signal	g1_caddr	:std_logic_vector(24 downto 7);
signal	g1_clear	:std_logic;
signal	g2_caddr	:std_logic_vector(24 downto 7);
signal	g2_clear	:std_logic;
signal	g3_caddr	:std_logic_vector(24 downto 7);
signal	g3_clear	:std_logic;
signal	vlineno		:std_logic_vector(9 downto 0);

--video registers
signal	vr_hfreq	:std_logic;
signal	vr_htotal	:std_logic_vector(7 downto 0);
signal	vr_hsync	:std_logic_vector(7 downto 0);
signal	vr_hvbgn	:std_logic_vector(7 downto 0);
signal	vr_hvend	:std_logic_vector(7 downto 0);
signal	vr_vtotal	:std_logic_vector(9 downto 0);
signal	vr_vsync	:std_logic_vector(9 downto 0);
signal	vr_vvbgn	:std_logic_vector(9 downto 0);
signal	vr_vvend	:std_logic_vector(9 downto 0);
signal	vr_hadj		:std_logic_vector(7 downto 0);
signal	vr_rdat	:std_logic_vector(15 downto 0);
signal	vr_doe	:std_logic;
signal	txt_offsetx	:std_logic_vector(9 downto 0);
signal	txt_offsety	:std_logic_vector(9 downto 0);
signal	gr0_offsetx	:std_logic_vector(9 downto 0);
signal	gr0_offsety	:std_logic_vector(9 downto 0);
signal	gr1_offsetx	:std_logic_vector(8 downto 0);
signal	gr1_offsety	:std_logic_vector(8 downto 0);
signal	gr2_offsetx	:std_logic_vector(8 downto 0);
signal	gr2_offsety	:std_logic_vector(8 downto 0);
signal	gr3_offsetx	:std_logic_vector(8 downto 0);
signal	gr3_offsety	:std_logic_vector(8 downto 0);
signal	vr_rintline	:std_logic_vector(9 downto 0);
signal	vr_MEN		:std_logic;
signal	vr_SA		:std_logic;
signal	vr_AP		:std_logic_vector(3 downto 0);
signal	vr_txtmask	:std_logic_vector(15 downto 0);
signal	vr_rcpysrc	:std_logic_vector(7 downto 0);
signal	vr_rcpydst	:std_logic_vector(7 downto 0);
signal	vr_rcpyplane:std_logic_vector(3 downto 0);
signal	vr_rcpybgn	:std_logic;
signal	vr_rcpyend	:std_logic;
signal	vr_rcpybusy	:std_logic;
signal	vr_fcbgn	:std_logic;
signal	vr_fcend	:std_logic;
signal	vr_fcbusy	:std_logic;
signal	vr_size		:std_logic;
signal	vr_col		:std_logic_vector(1 downto 0);
signal	vr_VD		:std_logic_vector(1 downto 0);
signal	vr_HD		:std_logic_vector(1 downto 0);
signal	vr_GR_SIZE	:std_logic;
signal	vr_GR_CMODE	:std_logic_vector(1 downto 0);
signal	vr_PRI_SP	:std_logic_vector(1 downto 0);
signal	vr_PRI_TX	:std_logic_vector(1 downto 0);
signal	vr_PRI_GR	:std_logic_vector(1 downto 0);
signal	vr_GR_PRI	:std_logic_vector(7 downto 0);
signal	vr_GRPEN	:std_logic_vector(4 downto 0);
signal	vr_GREN		:std_logic;
signal	vr_TXTEN	:std_logic;
signal	vr_SPREN	:std_logic;
signal	vr_GT		:std_logic;
signal	vr_GG		:std_logic;
signal	vr_BP		:std_logic;
signal	vr_HP		:std_logic;
signal	vr_EXON		:std_logic;
signal	vr_VHT		:std_logic;
signal	vr_AH		:std_logic;
signal	vr_YS		:std_logic;
signal	iowait_rcpy	:std_logic;

--text & sprite palette
signal	tpal_cs		:std_logic;
signal	tpal_rdat	:std_logic_vector(15 downto 0);
signal	tpal_doe	:std_logic;
signal	tpal_pno	:std_logic_vector(7 downto 0);
signal	tpal_pdat	:std_logic_vector(15 downto 0);
signal	spal_pno	:std_logic_vector(7 downto 0);
signal	spal_pdat	:std_logic_vector(15 downto 0);
signal	tpal0_pdat	:std_logic_vector(15 downto 0);
--graphics palette
signal	gpal_cs		:std_logic;
signal	gpal_rdat	:std_logic_vector(15 downto 0);
signal	gpal_doe	:std_logic;
signal	gpal_skel	:std_logic;
signal	gpal_pnoh	:std_logic_vector(7 downto 0);
signal	gpal_pnol	:std_logic_vector(7 downto 0);
signal	gpal_pdat	:std_logic_vector(15 downto 0);

signal	dclk	:std_logic;
signal	vidR	:std_logic_vector(3 downto 0);
signal	vidG	:std_logic_vector(3 downto 0);
signal	vidB	:std_logic_vector(3 downto 0);
signal	vidRF	:std_logic_vector(5 downto 0);
signal	vidGF	:std_logic_vector(5 downto 0);
signal	vidBF	:std_logic_vector(5 downto 0);
signal	vidRC	:std_logic_vector(7 downto 0);
signal	vidGC	:std_logic_vector(7 downto 0);
signal	vidBC	:std_logic_vector(7 downto 0);
signal	vidHS	:std_logic;
signal	vidVS	:std_logic;
signal	vidEN	:std_logic;
signal	HDMI_DAT0	:std_logic;
signal	HDMI_DAT1	:std_logic;
signal	HDMI_DAT2	:std_logic;

--for OPM
signal	opm_cen		:std_logic;
signal	opm_wr_n_d	:std_logic;
signal	opm_odat	:std_logic_vector(7 downto 0);
signal	opm_doe		:std_logic;
signal	opm_intn	:std_logic;
signal	opm_ct2		:std_logic;
signal	opm_sft		:std_logic;
signal	opm_sndl		:std_logic_vector(15 downto 0);
signal	opm_sndr		:std_logic_vector(15 downto 0);
signal	iowait_opm		:std_logic;
signal	opm_wstate	:integer range 0 to 3;

--for real YM2151
signal  opm_clk_divider : std_logic_vector(2 downto 0); -- 32MHz → 4MHz
signal  opm_data_d  : std_logic_vector(7 downto 0);
signal  opm_irq_n_d : std_logic;

--for EM3012
signal  em3012_sndL : std_logic_vector(15 downto 0);
signal  em3012_sndR : std_logic_vector(15 downto 0);

--for adpcm
signal	pcm_ce	:std_logic;
signal	pcm_odat	:std_logic_vector(7 downto 0);
signal	pcm_wr	:std_logic;
signal	pcm_doe	:std_logic;
signal	pcm_drq	:std_logic;
signal	pcm_sft	:std_logic;
signal	pcm_snd	:std_logic_vector(11 downto 0);
signal	pcm_sndL	:std_logic_vector(15 downto 0);
signal	pcm_sndR	:std_logic_vector(15 downto 0);
signal	pcm_enL,pcm_enR	:std_logic;
signal	pcm_clkmode	:std_logic;
signal	pcm_clkdiv	:std_logic_vector(1 downto 0);

--Sound DAC
signal  opm_sndL_sel,opm_sndR_sel :std_logic_vector(15 downto 0);
signal	mix_sndL,mix_sndR	:std_logic_vector(15 downto 0);
signal	sndL,sndR	:std_logic_vector(15 downto 0);
signal	dacsft		:std_logic;

--I2S DAC
signal	i2s_sndL,i2s_sndR	:std_logic_vector(31 downto 0);

--for I2C I/F
signal	SDAIN,SDAOUT	:std_logic;
signal	SCLIN,SCLOUT	:std_logic;
signal	I2CCLKEN	:std_logic;

signal	I2C_TXDAT	:std_logic_vector(7 downto 0);		--tx data in
signal	I2C_RXDAT	:std_logic_vector(7 downto 0);	--rx data out
signal	I2C_WRn		:std_logic;						--write
signal	I2C_RDn		:std_logic;						--read
signal	I2C_TXEMP	:std_logic;							--tx buffer empty
signal	I2C_RXED	:std_logic;							--rx buffered
signal	I2C_NOACK	:std_logic;							--no ack
signal	I2C_COLL	:std_logic;							--collision detect
signal	I2C_NX_READ	:std_logic;							--next data is read
signal	I2C_RESTART	:std_logic;							--make re-start condition
signal	I2C_START	:std_logic;							--make start condition
signal	I2C_FINISH	:std_logic;							--next data is final(make stop condition)
signal	I2C_F_FINISH :std_logic;							--next data is final(make stop condition)
signal	I2C_INIT	:std_logic;

-- Define the number of I2C device drivers  
constant NUM_DRIVERS: integer := 2;

signal	I2C_TXDAT_PXY	:i2cdat_array(NUM_DRIVERS-1 downto 0);	    --tx data in
signal	I2C_RXDAT_PXY	:i2cdat_array(NUM_DRIVERS-1 downto 0);	    --rx data out
signal	I2C_WRn_PXY		:std_logic_vector(NUM_DRIVERS-1 downto 0);	--write
signal	I2C_RDn_PXY		:std_logic_vector(NUM_DRIVERS-1 downto 0);	--read
signal	I2C_TXEMP_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--tx buffer empty
signal	I2C_RXED_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--rx buffered
signal	I2C_NOACK_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--no ack
signal	I2C_COLL_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);  --collision detect
signal	I2C_NX_READ_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is read
signal	I2C_RESTART_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--make re-start condition
signal	I2C_START_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--make start condition
signal	I2C_FINISH_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is final(make stop condition)
signal	I2C_F_FINISH_PXY:std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is final(make stop condition)
signal	I2C_INIT_PXY	:std_logic_vector(NUM_DRIVERS-1 downto 0);

-- for frontpanel
signal  LED_POWER       :std_logic_vector(1 downto 0);
signal  LED_HD_BUSY     :std_logic;
signal  LED_TIMER       :std_logic;
signal  LED_FDD0_ACCESS :std_logic_vector(1 downto 0);
signal  LED_FDD1_ACCESS :std_logic_vector(1 downto 0);
signal  LED_FDD0_EJECT  :std_logic;
signal  LED_FDD1_EJECT  :std_logic;

signal  ledmodes			:led_mode_array(0 to 15);

--RTC
signal	rtc_odat	:std_logic_Vector(3 downto 0);
signal	rtc_doe		:std_logic;
signal	rtc_cs		:std_logic;
signal	rtc_wr		:std_logic;
signal	rtc_alarm	:std_logic;

--PPI(i8255)
signal	ppi_odat	:std_logic_vector(7 downto 0);
signal	ppi_doe		:std_logic;
signal	ppi_csn		:std_logic;
signal	ppi_pai		:std_logic_vector(7 downto 0);
signal	ppi_pao		:std_logic_vector(7 downto 0);
signal	ppi_paoe	:std_logic;
signal	ppi_pbi		:std_logic_vector(7 downto 0);
signal	ppi_pbo		:std_logic_vector(7 downto 0);
signal	ppi_pboe	:std_logic;
signal	ppi_pchi	:std_logic_vector(3 downto 0);
signal	ppi_pcho	:std_logic_vector(3 downto 0);
signal	ppi_pchoe	:std_logic;
signal	ppi_pcli	:std_logic_vector(3 downto 0);
signal	ppi_pclo	:std_logic_vector(3 downto 0);
signal	ppi_pcloe	:std_logic;

--MFP
signal	mfp_odat	:std_logic_vector(7 downto 0);
signal	mfp_doe		:std_logic;
signal	mfp_gpip7	:std_logic;
signal	mfp_gpip6	:std_logic;
signal	mfp_gpip5	:std_logic;
signal	mfp_gpip4	:std_logic;
signal	mfp_gpip3	:std_logic;
signal	mfp_gpip2	:std_logic;
signal	mfp_gpip1	:std_logic;
signal	mfp_gpip0	:std_logic;
signal	mfp_tai		:std_logic;
signal	mfp_ivack	:std_logic_vector(7 downto 0);
 --KB
signal	kb_clkin	:std_logic;
signal	kb_clkout	:std_logic;
signal	kb_datin	:std_logic;
signal	kb_datout	:std_logic;

--SCC
signal	scc_odat	:std_logic_vector(7 downto 0);
signal	scc_doe		:std_logic;
--mouse
signal	ms_clkin	:std_logic;
signal	ms_clkout	:std_logic;
signal	ms_datin	:std_logic;
signal	ms_datout	:std_logic;

--MIDI I/F
signal	midi_odat	:std_logic_vector(7 downto 0);
signal	midi_doe		:std_logic;
signal	midi_cs		:std_logic;
signal	midi_rd		:std_logic;
signal	midi_wr		:std_logic;
signal	midi_int		:std_logic;
signal	midi_ivect	:std_logic_vector(7 downto 0);

--Contrast controller
constant	context	:integer	:=2;
signal	contval	:std_logic_vector(3+context downto 0);
signal	contvalm	:std_logic_vector(3+context downto 0);
signal	contc_rdat	:std_logic_vector(7 downto 0);
signal	contc_doe	:std_logic;

--for debug
signal	monseg		:std_logic_vector(23 downto 0);
signal	Seg0		:std_logic_vector(7 downto 0);
signal	Seg1		:std_logic_vector(7 downto 0);
signal	Seg2		:std_logic_vector(7 downto 0);
signal	Seg3		:std_logic_vector(7 downto 0);
signal	Seg4		:std_logic_vector(7 downto 0);
signal	Seg5		:std_logic_vector(7 downto 0);
signal	dgrpen	:std_logic_vector(4 downto 0);
signal	dopmonoff:std_logic_vector(7 downto 0);
signal	dwait		:std_logic;
signal	dsprbgen	:std_logic_vector(1 downto 0);

component mainpllCVdemu
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		outclk_1 : out std_logic;        -- outclk1.clk
		outclk_2 : out std_logic;        -- outclk2.clk
		outclk_3 : out std_logic;        -- outclk3.clk
		outclk_4 : out std_logic;        -- outclk4.clk
		outclk_5 : out std_logic;        -- outclk5.clk
		outclk_6 : out std_logic;        -- outclk6.clk
		outclk_7 : out std_logic;        -- outclk7.clk
		locked   : out std_logic         --  locked.export
	);
end component;

component TG68
   port(        
		clk           : in std_logic;
		reset         : in std_logic;
        clkena_in     : in std_logic:='1';
        data_in       : in std_logic_vector(15 downto 0);
        IPL           : in std_logic_vector(2 downto 0):="111";
        dtack         : in std_logic;
        addr          : out std_logic_vector(31 downto 0);
        data_out      : out std_logic_vector(15 downto 0);
        as            : out std_logic;
        uds           : out std_logic;
        lds           : out std_logic;
        rw            : out std_logic;
        drive_data    : out std_logic				--enable for data_out driver
        );
end component;

component  memcont
generic(
	AWIDTH		:integer	:=25;
	CAWIDTH		:integer	:=10;
	BRSIZE		:integer	:=8;
	BRBLOCKS		:integer	:=4;
	CLKMHZ		:integer 	:=120;		--SDRAM clk MHz
	REFINT	:integer	:=3;
	REFCNT	:integer	:=64
);
port(
	-- SDRAM PORTS
	PMEMCKE		:OUT	STD_LOGIC;							-- SD-RAM CLOCK ENABLE
	PMEMCS_N	:OUT	STD_LOGIC;							-- SD-RAM CHIP SELECT
	PMEMRAS_N	:OUT	STD_LOGIC;							-- SD-RAM ROW/RAS
	PMEMCAS_N	:OUT	STD_LOGIC;							-- SD-RAM /CAS
	PMEMWE_N	:OUT	STD_LOGIC;							-- SD-RAM /WE
	PMEMUDQ		:OUT	STD_LOGIC;							-- SD-RAM UDQM
	PMEMLDQ		:OUT	STD_LOGIC;							-- SD-RAM LDQM
	PMEMBA1		:OUT	STD_LOGIC;							-- SD-RAM BANK SELECT ADDRESS 1
	PMEMBA0		:OUT	STD_LOGIC;							-- SD-RAM BANK SELECT ADDRESS 0
	PMEMADR		:OUT	STD_LOGIC_VECTOR( 12 DOWNTO 0 );	-- SD-RAM ADDRESS
	PMEMDAT		:INOUT	STD_LOGIC_VECTOR( 15 DOWNTO 0 );	-- SD-RAM DATA

	b_addr	:in std_logic_vector(awidth-1 downto 0);
	b_wdat	:in std_logic_vector(15 downto 0);
	b_rdat	:out std_logic_vector(15 downto 0);
	b_rd	:in std_logic;
	b_wr	:in std_logic_vector(1 downto 0);
	b_rmw	:in std_logic_vector(1 downto 0);
	b_rmwmsk:in std_logic_vector(15 downto 0);
	b_ack	:out std_logic;

	b_csaddr	:in std_logic_vector(awidth-brsize-1 downto 0)	:=(others=>'0');
	b_cdaddr	:in std_logic_vector(awidth-brsize-1 downto 0)	:=(others=>'0');
	b_cplane	:in std_logic_vector(3 downto 0)	:=(others=>'0');
	b_cpy		:in std_logic;
	b_cack	:out std_logic;
	
	g00_addr:in std_logic_vector(awidth-1 downto 0);
	g00_rd	:in std_logic;
	g00_rdat:out std_logic_vector(15 downto 0);
	g00_ack	:out std_logic;

	g01_addr:in std_logic_vector(awidth-1 downto 0);
	g01_rd	:in std_logic;
	g01_rdat:out std_logic_vector(15 downto 0);
	g01_ack	:out std_logic;

	g02_addr:in std_logic_vector(awidth-1 downto 0);
	g02_rd	:in std_logic;
	g02_rdat:out std_logic_vector(15 downto 0);
	g02_ack	:out std_logic;

	g03_addr:in std_logic_vector(awidth-1 downto 0);
	g03_rd	:in std_logic;
	g03_rdat:out std_logic_vector(15 downto 0);
	g03_ack	:out std_logic;

	g10_addr:in std_logic_vector(awidth-1 downto 0);
	g10_rd	:in std_logic;
	g10_rdat:out std_logic_vector(15 downto 0);
	g10_ack	:out std_logic;

	g11_addr:in std_logic_vector(awidth-1 downto 0);
	g11_rd	:in std_logic;
	g11_rdat:out std_logic_vector(15 downto 0);
	g11_ack	:out std_logic;

	g12_addr:in std_logic_vector(awidth-1 downto 0);
	g12_rd	:in std_logic;
	g12_rdat:out std_logic_vector(15 downto 0);
	g12_ack	:out std_logic;

	g13_addr:in std_logic_vector(awidth-1 downto 0);
	g13_rd	:in std_logic;
	g13_rdat:out std_logic_vector(15 downto 0);
	g13_ack	:out std_logic;

	t0_addr	:in std_logic_vector(awidth-3 downto 0);
	t0_rd	:in std_logic;
	t0_rdat0:out std_logic_vector(15 downto 0);
	t0_rdat1:out std_logic_vector(15 downto 0);
	t0_rdat2:out std_logic_vector(15 downto 0);
	t0_rdat3:out std_logic_vector(15 downto 0);
	t0_ack	:out std_logic;
	
	t1_addr	:in std_logic_vector(awidth-3 downto 0);
	t1_rd	:in std_logic;
	t1_rdat0:out std_logic_vector(15 downto 0);
	t1_rdat1:out std_logic_vector(15 downto 0);
	t1_rdat2:out std_logic_vector(15 downto 0);
	t1_rdat3:out std_logic_vector(15 downto 0);
	t1_ack	:out std_logic;
	
	g0_caddr	:in std_logic_vector(awidth-1 downto 7);
	g0_clear	:in std_logic;
	
	g1_caddr	:in std_logic_vector(awidth-1 downto 7);
	g1_clear	:in std_logic;

	g2_caddr	:in std_logic_vector(awidth-1 downto 7);
	g2_clear	:in std_logic;

	g3_caddr	:in std_logic_vector(awidth-1 downto 7);
	g3_clear	:in std_logic;

	fde_addr	:in std_logic_vector(awidth-1 downto 0)	:=(others=>'0');
	fde_rdat	:out std_logic_vector(15 downto 0);
	fde_wdat	:in std_logic_vector(15 downto 0)	:=(others=>'0');
	fde_wr		:in std_logic	:='0';
	fde_tlen	:in std_logic_vector(13 downto 0)	:=(others=>'1');
	
	fec_addr	:out std_logic_vector(7 downto 0);
	fec_rdat	:out std_logic_vector(15 downto 0);
	fec_wdat	:in std_logic_vector(15 downto 0)	:=(others=>'0');
	fec_we	:out std_logic;
	fec_addrh	:in std_logic_vector(awidth-9 downto 0)	:=(others=>'0');
	fec_rd		:in std_logic	:='0';
	fec_wr		:in std_logic	:='0';
	fec_busy	:out std_logic;
	
	initdone:out std_logic;
	sclk	:in std_logic;
	vclk	:in std_logic;
	fclk	:in std_logic;
	rclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component romcopy
generic(
	BGNADDR	:std_logic_vector(23 downto 0)	:=x"700000";
	ENDADDR	:std_logic_vector(23 downto 0)	:=x"7fffff";
	AWIDTH	:integer	:=20
);
port(
	addr	:out std_logic_vector(AWIDTH-1 downto 0);
	wdat	:out std_logic_vector(7 downto 0);
	aen		:out std_logic;
	wr		:out std_logic;
	ack		:in std_logic;
	done	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component INTcont
port(
	int7	:in std_logic	:='0';
	vect7	:in std_logic_vector(7 downto 0)	:=x"1f";
	iack7	:out std_logic;
	e_ln7	:in std_logic	:='1';
	ivack7	:out std_logic_vector(7 downto 0);
	
	int6	:in std_logic	:='0';
	vect6	:in std_logic_vector(7 downto 0)	:=x"1e";
	iack6	:out std_logic;
	e_ln6	:in std_logic	:='1';
	ivack6	:out std_logic_vector(7 downto 0);
	
	int5	:in std_logic	:='0';
	vect5	:in std_logic_vector(7 downto 0)	:=x"1d";
	iack5	:out std_logic;
	e_ln5	:in std_logic	:='1';
	ivack5	:out std_logic_vector(7 downto 0);
	
	int4	:in std_logic	:='0';
	vect4	:in std_logic_vector(7 downto 0)	:=x"1c";
	iack4	:out std_logic;
	e_ln4	:in std_logic	:='1';
	ivack4	:out std_logic_vector(7 downto 0);
	
	int3	:in std_logic	:='0';
	vect3	:in std_logic_vector(7 downto 0)	:=x"1b";
	iack3	:out std_logic;
	e_ln3	:in std_logic	:='1';
	ivack3	:out std_logic_vector(7 downto 0);
	
	int2	:in std_logic	:='0';
	vect2	:in std_logic_vector(7 downto 0)	:=x"1a";
	iack2	:out std_logic;
	e_ln2	:in std_logic	:='1';
	ivack2	:out std_logic_vector(7 downto 0);
	
	int1	:in std_logic	:='0';
	vect1	:in std_logic_vector(7 downto 0)	:=x"19";
	iack1	:out std_logic;
	e_ln1	:in std_logic	:='1';
	ivack1	:out std_logic_vector(7 downto 0);
	
	IPL		:out std_logic_vector(2 downto 0);
	addrin	:in std_logic_vector(23 downto 0);
	addrout	:out std_logic_vector(23 downto 0);
	rw		:in std_logic;
	dtack	:in std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component DMA63450
generic(
	BASEADDR	:std_logic_vector(23 downto 8)	:=x"e840"
);
port(
	addrin	:in std_logic_vector(23 downto 0);
	m_as	:in std_logic;
	b_rd	:in std_logic;
	b_wr	:in std_logic_vector(1 downto 0);
	b_addr	:out std_logic_vector(23 downto 0);
	b_as	:out std_logic;
	b_rwn	:out std_logic;
	b_uds	:out std_logic;
	b_lds	:out std_logic;
	b_dout	:out std_logic_vector(15 downto 0);
	b_doe	:out std_logic;
	b_din	:in std_logic_vector(15 downto 0);
	b_ack	:in std_logic;
	b_conte	:out std_logic;
	
	drq0		:in std_logic;
	dack0		:out std_logic;
	pcli0		:in std_logic;
	pclo0		:out std_logic;
	doneo0		:out std_logic;
	
	drq1		:in std_logic;
	dack1		:out std_logic;
	pcli1		:in std_logic;
	pclo1		:out std_logic;
	doneo1		:out std_logic;

	drq2		:in std_logic;
	dack2		:out std_logic;
	pcli2		:in std_logic;
	pclo2		:out std_logic;
	doneo2		:out std_logic;

	drq3		:in std_logic;
	dack3		:out std_logic;
	pcli3		:in std_logic;
	pclo3		:out std_logic;
	doneo3		:out std_logic;
	
	d_rd		:out std_logic;
	d_wr		:out std_logic;
	
	donei		:in std_logic;

	dtc			:out std_logic;
	
	int			:out std_logic;
	ivect		:out std_logic_vector(7 downto 0);
	iack		:in std_logic;
	
	clk			:in std_logic;
	rstn		:in std_logic
);

end component;

component X68mmapCV
generic(
	t_base	:std_logic_vector(22 downto 0)	:="11100000000000000000000";
	g_base	:std_logic_vector(22 downto 0)	:="11101000000000000000000";
	rom_base:std_logic_vector(22 downto 0)	:="11110000000000000000000"
	);
port(
	m_addr	:in std_logic_vector(23 downto 0);
	m_rdat	:out std_logic_vector(15 downto 0);
	m_wdat	:in std_logic_vector(15 downto 0);
	m_doe	:out std_logic;
	m_uds	:in std_logic;
	m_lds	:in std_logic;
	m_as	:in std_logic;
	m_rw	:in std_logic;
	m_ack	:out std_logic;
	
	b_rd	:out std_logic;
	b_wr	:out std_logic_vector(1 downto 0);
	
	buserr	:out std_logic;
	iackbe	:in std_logic	:='0';
	
	MEN		:in std_logic;
	SA		:in std_logic;
	AP		:in std_logic_vector(3 downto 0);
	txtmask	:in std_logic_vector(15 downto 0)	:=(others=>'0');
	gmode	:in std_logic_vector(1 downto 0);
	vmode	:in std_logic_vector(1 downto 0);
	gsize	:in std_logic;
	rcpybusy:in std_logic  :='0';
	
	ram_addr	:out std_logic_vector(22 downto 0);
	ram_rdat	:in std_logic_vector(15 downto 0);
	ram_wdat	:out std_logic_vector(15 downto 0);
	ram_rd		:out std_logic;
	ram_wr		:out std_logic_vector(1 downto 0);
	ram_rmw		:out std_logic_vector(1 downto 0);
	ram_rmwmask	:out std_logic_vector(15 downto 0);
	ram_ack		:in std_logic;
	
	ldr_addr	:in std_logic_vector(19 downto 0);
	ldr_wdat	:in std_logic_vector(7 downto 0);
	ldr_aen		:in std_logic;
	ldr_wr		:in std_logic;
	ldr_ack		:out std_logic;
	
	iowait		:in std_logic	:='0';
	
	gpcen		:in std_logic;

	min			:in std_logic;
	mon			:out std_logic;
	sclk		:in std_logic;
	rstn		:in std_logic
);
end component;

component CRTCX68TXT
generic(
	DACRES		:integer	:=4
);
port(
	LRAMSEL		:out std_logic;
	LRAMADR		:out std_logic_vector(9 downto 0);
	LRAMDAT		:in std_logic_vector(15 downto 0);
	
	TRAM_ADR	:out std_logic_vector(12 downto 0);
	TRAM_DAT	:in std_logic_vector(7 downto 0);
	
	FRAM_ADR	:out std_logic_vector(11 downto 0);
	FRAM_DAT	:in std_logic_vector(7 downto 0);
	
	CURL		:in std_logic_vector(5 downto 0);
	CURC		:in std_logic_vector(6 downto 0);
	CURE		:in std_logic;

	TXTMODE		:in std_logic;
	
	ROUT		:out std_logic_vector(DACRES-1 downto 0);
	GOUT		:out std_logic_vector(DACRES-1 downto 0);
	BOUT		:out std_logic_vector(DACRES-1 downto 0);
	
	RFOUT		:out std_logic_vector(5 downto 0);
	GFOUT		:out std_logic_vector(5 downto 0);
	BFOUT		:out std_logic_vector(5 downto 0);

	HSYNC		:out std_logic;
	VSYNC		:out std_logic;
	
	HMODE		:in std_logic_vector(1 downto 0);		-- "00":256 "01":512 "10":768 "11":768
	VMODE		:in std_logic;		-- 1:512 0:256

	VRTC		:out std_logic;
	HRTC		:out std_logic;
	VIDEN		:out std_logic;
	
	HCOMP		:out std_logic;
	VCOMP		:out std_logic;
	VPSTART		:out std_logic;
	
	dclk		:out std_logic;

	gclk		:in std_logic;
	rstn		:in std_logic
);
end component;

component rastercopy
generic(
	arange	:integer	:=14;
	brsize	:integer	:=8
);
port(
	src		:in std_logic_vector(7 downto 0);
	dst		:in std_logic_vector(7 downto 0);
	plane	:in std_logic_vector(3 downto 0);
	start	:in std_logic;
	stop	:in std_logic;
	busy	:out std_logic;

	t_base	:in std_logic_vector(arange-1 downto 0);
	srcaddr	:out std_logic_vector(arange-1 downto 0);
	dstaddr	:out std_logic_vector(arange-1 downto 0);
	cplane	:out std_logic_vector(3 downto 0);
	cpy		:out std_logic;
	ack		:in std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component VLINEBUF
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;

component  FDCs is
generic(
	maxtrack	:integer	:=85;
	maxbwidth	:integer	:=88;
	preseek		:std_logic	:='0';
	sysclk		:integer	:=20
);
port(
	RDn		:in std_logic;
	WRn		:in std_logic;
	CSn		:in std_logic;
	A0		:in std_logic;
	WDAT	:in std_logic_vector(7 downto 0);
	RDAT	:out std_logic_vector(7 downto 0);
	DATOE	:out std_logic;
	DACKn	:in std_logic;
	DRQ		:out std_logic;
	TC		:in std_logic;
	INTn	:out std_logic;
	WAITIN	:in std_logic	:='0';

	WREN	:out std_logic;		--pin24
	WRBIT	:out std_logic;		--pin22
	RDBIT	:in std_logic;		--pin30
	STEP	:out std_logic;		--pin20
	SDIR	:out std_logic;		--pin18
	WPRT	:in std_logic;		--pin28
	track0	:in std_logic;		--pin26
	index	:in std_logic;		--pin8
	side	:out std_logic;		--pin32
	usel	:out std_logic_vector(1 downto 0);
	READY	:in std_logic;		--pin34
	
	int0	:in integer range 0 to maxbwidth;
	int1	:in integer range 0 to maxbwidth;
	int2	:in integer range 0 to maxbwidth;
	int3	:in integer range 0 to maxbwidth;
	
	td0		:in std_logic;
	td1		:in std_logic;
	td2		:in std_logic;
	td3		:in std_logic;
	
	hmssft	:in std_logic;		--0.5msec
	
	busy	:out std_logic;
	mfm		:out std_logic;
	
	ismode	:in std_logic	:='1';
	
	sclk		:in std_logic;
	fclk		:in std_logic;
	rstn	:in std_logic
);
end component;

component FDtiming
generic(
	sysclk	:integer	:=21477		--in kHz
);
port(
	drv0sel		:in std_logic;		--0:300rpm 1:360rpm
	drv1sel		:in std_logic;
	drv0sele	:in std_logic;		--1:speed selectable
	drv1sele	:in std_logic;

	drv0hd		:in std_logic;
	drv0hdi		:in std_logic;		--IBM 1.44MB format
	drv1hd		:in std_logic;
	drv1hdi		:in std_logic;		--IBM 1.44MB format
	
	drv0hds		:out std_logic;
	drv1hds		:out std_logic;
	
	drv0int		:out integer range 0 to (BR_300_D*sysclk/1000000);
	drv1int		:out integer range 0 to (BR_300_D*sysclk/1000000);
	
	hmssft		:out std_logic;
	
	clk			:in std_logic;
	rstn		:in std_logic
);
end component;

component dc2ry
generic(
	delay	:integer	:=100
);
port(
	USEL	:in std_logic_vector(1 downto 0);
	BUSY	:in std_logic;
	DSKCHGn	:in std_logic;
	RDBITn	:in std_logic;
	INDEXn	:in std_logic;
	
	READYn	:out std_logic;
	READYV	:out std_logic_vector(3 downto 0);
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component dskchk2d
generic(
	sysclk	:integer	:=20000;	--system clock(kHz)	20000
	chkint	:integer	:=300;		--check interval(msec)
	signwait:integer	:=1;		--signal wait length(usec)
	datwait	:integer	:=10;		--data wait length(usec)
	motordly:integer	:=500		--motor rotate delay(msec)	
);
port(
	FDC_USELn	:in std_logic_vector(1 downto 0);
	FDC_BUSY	:in std_logic;
	FDC_MOTORn	:in std_logic_vector(1 downto 0);
	FDC_DIRn	:in std_logic;
	FDC_STEPn	:in std_logic;
	FDC_READYn	:out std_logic;
	FDC_WAIT	:out std_logic;
	
	FDD_USELn	:out std_logic_vector(1 downto 0);
	FDD_MOTORn	:out std_logic_vector(1 downto 0);
	FDD_DATAn	:in std_logic;
	FDD_INDEXn	:in std_logic;
	FDD_DSKCHGn	:in std_logic;
	FDD_DIRn	:out std_logic;
	FDD_STEPn	:out std_logic;
	
	driveen		:in std_logic_vector(1 downto 0)	:=(others=>'1');
	f_eject		:in std_logic_vector(1 downto 0)	:=(others=>'0');
	
	indisk		:out std_logic_vector(1 downto 0);
	
	hmssft		:in std_logic;
	
	clk			:in std_logic;
	rstn		:in std_logic
);	
end component;	

component scsiif
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(3 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	rdat	:out std_logic_vector(7 downto 0);
	doe		:out std_logic;
	int		:out std_logic;
	iack	:in std_logic;
	drq		:out std_logic;
	dack	:in std_logic;
	iowait	:out std_logic;
	
	IDAT	:in std_logic_vector(7 downto 0);
	IDATp	:in std_logic;
	ODAT	:out std_logic_vector(7 downto 0);
	ODATp	:out std_logic;
	ODEN	:out std_logic;
	SEL		:out std_logic;
	BSY		:in std_logic;
	REQ		:in std_logic;
	ACK		:out std_logic;
	IO		:in std_logic;
	CD		:in std_logic;
	MSG		:in std_logic;
	RST		:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component diskemuunit
generic(
	clkfreq		:integer	:=30000;
	VLwidth		:integer	:=6;
	VCwidth		:integer	:=7
);
port(
--video
	vaddr		:in std_logic_vector(12 downto 0);
	vdata		:out std_logic_vector(7 downto 0);
	vcursor_L	:out std_logic_vector(VLwidth-1 downto 0);
	vcursor_C	:out std_logic_vector(VCwidth-1 downto 0);
	vcursoren	:out std_logic;

--Keyboard
	kbdat		:in std_logic_vector(7 downto 0);
	kbrx		:in std_logic;

--SDcard
	sdc_miso	:in std_logic;
	sdc_mosi	:out std_logic;
	sdc_sclk	:out std_logic;
	sdc_cs		:out std_logic;
	
--SCSI
	sasi_din	:in std_logic_vector(7 downto 0);
	sasi_dout	:out std_logic_vector(7 downto 0);
	sasi_sel	:in std_logic;
	sasi_bsy	:out std_logic;
	sasi_req	:out std_logic;
	sasi_ack	:in std_logic;
	sasi_io		:out std_logic;
	sasi_cd		:out std_logic;
	sasi_msg	:out std_logic;
	sasi_rst	:in std_logic;

--FDD
	fdc_useln	:in std_logic_vector(3 downto 0);
	fdc_motorn	:in std_logic_vector(3 downto 0);
	fdc_readyn	:out std_logic;
	fdc_wrenn	:in std_logic;
	fdc_wrbitn	:in std_logic;
	fdc_rdbitn	:out std_logic;
	fdc_stepn	:in std_logic;
	fdc_sdirn	:in std_logic;
	fdc_track0n	:out std_logic;
	fdc_indexn	:out std_logic;
	fdc_siden	:in std_logic;
	fdc_wprotn	:out std_logic;
	fdc_eject	:in std_logic_vector(3 downto 0);
	fdc_indisk	:out std_logic_vector(3 downto 0);
	fdc_trackwid:in std_logic;	--1:2HD/2DD 0:2D
	fdc_dencity	:in std_logic;	--1:2HD 0:2DD/2D
	fdc_rpm		:in std_logic;	--1:360rpm 0:300rpm
	fdc_mfm		:in std_logic;
	
	fdd_useln	:out std_logic_vector(1 downto 0);
	fdd_motorn	:out std_logic_vector(1 downto 0);
	fdd_readyn	:in std_logic;
	fdd_wrenn	:out std_logic;
	fdd_wrbitn	:out std_logic;
	fdd_rdbitn	:in std_logic;
	fdd_stepn	:out std_logic;
	fdd_sdirn	:out std_logic;
	fdd_track0n	:in std_logic;
	fdd_indexn	:in std_logic;
	fdd_siden	:out std_logic;
	fdd_wprotn	:in std_logic;
	fdd_eject	:out std_logic_vector(1 downto 0);
	fdd_indisk	:in std_logic_vector(1 downto 0);
	fdd_cpyen	:out std_logic;

--FD emulation
	fde_tracklen:out std_logic_vector(13 downto 0);
	fde_ramaddr	:out std_logic_vector(23 downto 0);
	fde_ramrdat	:in std_logic_vector(15 downto 0);
	fde_ramwdat	:out std_logic_vector(15 downto 0);
	fde_ramwr	:out std_logic;
	fde_ramwait	:in std_logic;
	fec_ramaddrh :out std_logic_vector(15 downto 0);
	fec_ramaddrl :in std_logic_vector(7 downto 0);
	fec_ramwe	:in std_logic;
	fec_ramrdat	:out std_logic_vector(15 downto 0);
	fec_ramwdat	:in std_logic_vector(15 downto 0);
	fec_ramrd	:out std_logic;
	fec_ramwr	:out std_logic;
	fec_rambusy	:in std_logic;

--SRAM
	sram_cs		:in std_logic;
	sram_addr	:in std_logic_vector(12 downto 0);
	sram_rdat	:out std_logic_vector(15 downto 0);
	sram_wdat	:in std_logic_vector(15 downto 0);
	sram_rd		:in std_logic;
	sram_wr		:in std_logic_vector(1 downto 0);
	sram_wp		:in std_logic;
	
--common
	model		:in std_logic_vector(7 downto 0);
	initdone	:out std_logic;
	busy		:out std_logic;
	pclk		:in std_logic;
	vclk		:in std_logic;
	fclk		:in std_logic;
	sclk		:in std_logic;
	rclk		:in std_logic;
	rstn		:in std_logic
);
end component;

component bwlatch
generic(
	awidth	:integer	:=24;
	dwidth	:integer	:=16
);
port(
	addr	:in std_logic_vector(awidth-1 downto 0);
	ce		:in std_logic;
	wr		:in std_logic;
	din		:in std_logic_vector(dwidth-1 downto 0);
	
	myaddr	:in std_logic_vector(awidth-1 downto 0);
	pout	:out std_logic_vector(dwidth-1 downto 0);
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component nvram
port(
	addr	:in std_logic_vector(12 downto 0);
	ce		:in std_logic;
	rd		:in std_logic;
	wr		:in std_logic_vector(1 downto 0);
	wdat	:in std_logic_vector(15 downto 0);
	rdat	:out std_logic_vector(15 downto 0);
	doe		:out std_logic;
	wp		:in std_logic_vector(7 downto 0);
	
	SCLin	:in std_logic;
	SCLout	:out std_logic;
	SDAin	:in std_logic;
	SDAout	:out std_logic;
	
	I2Csft	:in std_logic;
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component vidcont
generic(
	arange	:integer	:=22
	);
port(
	t_base	:in std_logic_vector(arange-1 downto 0);
	g_base	:in std_logic_vector(arange-1 downto 0);

	g00_addr	:out std_logic_vector(arange-1 downto 0);
	g00_rd		:out std_logic;
	g00_rdat	:in std_logic_vector(15 downto 0);

	g01_addr	:out std_logic_vector(arange-1 downto 0);
	g01_rd		:out std_logic;
	g01_rdat	:in std_logic_vector(15 downto 0);

	g02_addr	:out std_logic_vector(arange-1 downto 0);
	g02_rd		:out std_logic;
	g02_rdat	:in std_logic_vector(15 downto 0);

	g03_addr	:out std_logic_vector(arange-1 downto 0);
	g03_rd		:out std_logic;
	g03_rdat	:in std_logic_vector(15 downto 0);

	g10_addr	:out std_logic_vector(arange-1 downto 0);
	g10_rd		:out std_logic;
	g10_rdat	:in std_logic_vector(15 downto 0);

	g11_addr	:out std_logic_vector(arange-1 downto 0);
	g11_rd		:out std_logic;
	g11_rdat	:in std_logic_vector(15 downto 0);

	g12_addr	:out std_logic_vector(arange-1 downto 0);
	g12_rd		:out std_logic;
	g12_rdat	:in std_logic_vector(15 downto 0);

	g13_addr	:out std_logic_vector(arange-1 downto 0);
	g13_rd		:out std_logic;
	g13_rdat	:in std_logic_vector(15 downto 0);

	t0_addr		:out std_logic_vector(arange-3 downto 0);
	t0_rd		:out std_logic;
	t0_rdat0	:in std_logic_vector(15 downto 0);
	t0_rdat1	:in std_logic_vector(15 downto 0);
	t0_rdat2	:in std_logic_vector(15 downto 0);
	t0_rdat3	:in std_logic_vector(15 downto 0);
	
	t1_addr		:out std_logic_vector(arange-3 downto 0);
	t1_rd		:out std_logic;
	t1_rdat0	:in std_logic_vector(15 downto 0);
	t1_rdat1	:in std_logic_vector(15 downto 0);
	t1_rdat2	:in std_logic_vector(15 downto 0);
	t1_rdat3	:in std_logic_vector(15 downto 0);
	
	g0_caddr	:out std_logic_vector(arange-1 downto 7);
	g0_clear	:out std_logic;
	
	g1_caddr	:out std_logic_vector(arange-1 downto 7);
	g1_clear	:out std_logic;

	g2_caddr	:out std_logic_vector(arange-1 downto 7);
	g2_clear	:out std_logic;

	g3_caddr	:out std_logic_vector(arange-1 downto 7);
	g3_clear	:out std_logic;

	t_hoffset	:in std_logic_vector(9 downto 0);
	t_voffset	:in std_logic_vector(9 downto 0);
	
	g0_hoffset	:in std_logic_vector(9 downto 0);
	g0_voffset	:in std_logic_vector(9 downto 0);
	g1_hoffset	:in std_logic_vector(8 downto 0);
	g1_voffset	:in std_logic_vector(8 downto 0);
	g2_hoffset	:in std_logic_vector(8 downto 0);
	g2_voffset	:in std_logic_vector(8 downto 0);
	g3_hoffset	:in std_logic_vector(8 downto 0);
	g3_voffset	:in std_logic_vector(8 downto 0);

	gmode	:in std_logic_vector(1 downto 0);		--00:4bit color 01:8bit color 11/10:16bit color
	memres	:in std_logic;							--0:512x512 1:1024x1024
	hres	:in std_logic_vector(1 downto 0);		--00:256 01:512 10/11:768
	vres	:in std_logic;							--0:256 1:512
	txten	:in std_logic;
	grpen	:in std_logic;
	spren	:in std_logic;
	graphen	:in std_logic_vector(4 downto 0);
	grpri	:in std_logic_vector(7 downto 0);
	pri_sp	:in std_logic_vector(1 downto 0);
	pri_tx	:in std_logic_vector(1 downto 0);
	pri_gr	:in std_logic_vector(1 downto 0);
	exon		:in std_logic;
	hp			:in std_logic;
	bp			:in std_logic;
	gg			:in std_logic;
	gt			:in std_logic;
	ah			:in std_logic;

	lbaddr	:out std_logic_vector(9 downto 0);
	lbwdat	:out std_logic_vector(15 downto 0);
	lbwr	:out std_logic;
	
	hcomp	:in std_logic;
	vpstart	:in std_logic;
	hfreq	:in std_logic;
	htotal	:in std_logic_vector(7 downto 0);
	hvbgn	:in std_logic_vector(7 downto 0);
	hvend	:in std_logic_vector(7 downto 0);
	vtotal	:in std_logic_vector(9 downto 0);
	vvbgn	:in std_logic_vector(9 downto 0);
	vvend	:in std_logic_vector(9 downto 0);
	
	addrx	:out std_logic_vector(9 downto 0);
	addry	:out std_logic_vector(9 downto 0);
	sprite_in:in std_logic_vector(7 downto 0);
	
	tpalno	:out std_logic_vector(7 downto 0);
	tpalin	:in std_logic_vector(15 downto 0);
	tpal0in	:in std_logic_vector(15 downto 0);
	
	spalno	:out std_logic_vector(7 downto 0);
	spalin	:in std_logic_vector(15 downto 0);
	
	gpal0no	:out std_logic_vector(7 downto 0);
	gpal1no	:out std_logic_vector(7 downto 0);
	gpalin	:in std_logic_vector(15 downto 0);
	
	vvideoen	:out std_logic;
	rintline:in std_logic_vector(9 downto 0);
	rint	:out std_logic;

	vlineno	:out std_logic_vector(9 downto 0);
	
	gclrbgn	:in std_logic;
	gclrend	:in std_logic;
	gclrpage:in std_logic_vector(3 downto 0);
	gclrbusy:out std_logic;
	
	vidclk	:in std_logic;
	sysclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component spritec
port(
	hres	:in std_logic;
	bgen	:in std_logic_vector(1 downto 0);
	bg0asel	:in std_logic;
	bg1asel	:in std_logic;
	spren	:in std_logic;

	hcomp	:in std_logic;
	linenum	:in std_logic_vector(8 downto 0);
	bg0hoff	:in std_logic_vector(9 downto 0);
	bg0voff	:in std_logic_vector(9 downto 0);
	bg1hoff	:in std_logic_vector(9 downto 0);
	bg1voff	:in std_logic_vector(9 downto 0);
	
	sprno	:out std_logic_vector(6 downto 0);
	sprxpos	:in std_logic_vector(9 downto 0);
	sprypos	:in std_logic_vector(9 downto 0);
	sprVR	:in std_logic;
	sprHR	:in std_logic;
	sprCOLOR:in std_logic_vector(3 downto 0);
	sprPAT	:in std_logic_vector(7 downto 0);
	sprPRI	:in std_logic_vector(1 downto 0);
	
	bgaddr	:out std_logic_vector(12 downto 0);
	bgVR	:in std_logic;
	bgHR	:in std_logic;
	bgCOLOR	:in std_logic_vector(3 downto 0);
	bgPAT	:in std_logic_vector(7 downto 0);
	
	patno	:out std_logic_vector(9 downto 0);
	dotx	:out std_logic_vector(2 downto 0);
	doty	:out std_logic_vector(2 downto 0);
	dotin	:in std_logic_vector(3 downto 0);
	
	rdaddr	:in std_logic_vector(8 downto 0);
	dotout	:out std_logic_vector(7 downto 0);
	
	debugsel	:in std_logic_vector(1 downto 0);
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component vcreg
port(
	addr	:in std_logic_vector(23 downto 0);
	rdat	:out std_logic_vector(15 downto 0);
	wdat	:in std_logic_vector(15 downto 0);
	rd		:in std_logic;
	wr		:in std_logic_vector(1 downto 0);
	doe		:out std_logic;
	
	htotal		:out std_logic_vector(7 downto 0);
	hsync		:out std_logic_vector(7 downto 0);
	hvbgn		:out std_logic_vector(7 downto 0);
	hvend		:out std_logic_vector(7 downto 0);
	vtotal		:out std_logic_vector(9 downto 0);
	vsync		:out std_logic_vector(9 downto 0);
	vvbgn		:out std_logic_vector(9 downto 0);
	vvend		:out std_logic_vector(9 downto 0);
	hadj		:out std_logic_vector(7 downto 0);
	intraster	:out std_logic_vector(9 downto 0);
	txtoffsetx	:out std_logic_vector(9 downto 0);
	txtoffsety	:out std_logic_vector(9 downto 0);
	g0offsetx	:out std_logic_vector(9 downto 0);
	g0offsety	:out std_logic_vector(9 downto 0);
	g1offsetx	:out std_logic_vector(8 downto 0);
	g1offsety	:out std_logic_vector(8 downto 0);
	g2offsetx	:out std_logic_vector(8 downto 0);
	g2offsety	:out std_logic_vector(8 downto 0);
	g3offsetx	:out std_logic_vector(8 downto 0);
	g3offsety	:out std_logic_vector(8 downto 0);
	siz			:out std_logic;
	col			:out std_logic_vector(1 downto 0);
	HF			:out std_logic;
	VD			:out std_logic_vector(1 downto 0);
	HD			:out std_logic_vector(1 downto 0);
	MEN			:out std_logic;
	SA			:out std_logic;
	AP			:out std_logic_vector(3 downto 0);
	CP			:out std_logic_vector(3 downto 0);
	csrc		:out std_logic_vector(7 downto 0);
	cdst		:out std_logic_vector(7 downto 0);
	tmask		:out std_logic_vector(15 downto 0);
	RCbgn		:out std_logic;
	RCend		:out std_logic;
	FCbgn		:out std_logic;
	FCend		:out std_logic;
	VIbgn		:out std_logic;
	VIend		:out std_logic;
	RCbusy		:in std_logic;
	FCbusy		:in std_logic;
	VIbusy		:in std_logic;
	GR_SIZE		:out std_logic;
	GR_CMODE	:out std_logic_vector(1 downto 0);
	PRI_SP		:out std_logic_vector(1 downto 0);
	PRI_TX		:out std_logic_vector(1 downto 0);
	PRI_GR		:out std_logic_vector(1 downto 0);
	GR_PRI		:out std_logic_vector(7 downto 0);
	GRPEN		:out std_logic_vector(4 downto 0);
	TXTEN		:out std_logic;
	SPREN		:out std_logic;
	GT			:out std_logic;
	GG			:out std_logic;
	BP			:out std_logic;
	HP			:out std_logic;
	EXON		:out std_logic;
	VHT			:out std_logic;
	AH			:out std_logic;
	YS			:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component sprram
port(
	addr	:in std_logic_vector(23 downto 0);
	b_rd	:in std_logic;
	b_wr	:in std_logic_vector(1 downto 0);
	wrdat	:in std_logic_Vector(15 downto 0);
	rddat	:out std_logic_vector(15 downto 0);
	datoe	:out std_logic;
	
	patno	:in std_logic_vector(9 downto 0);
	dotx	:in std_logic_vector(2 downto 0);
	doty	:in std_logic_vector(2 downto 0);
	dot		:out std_logic_vector(3 downto 0);
	
	bg_addr	:in std_logic_vector(12 downto 0);
	bg_VR	:out std_logic;
	bg_HR	:out std_logic;
	bg_COLOR:out std_logic_vector(3 downto 0);
	bg_PAT	:out std_logic_vector(7 downto 0);
	
	sclk	:in std_logic;
	vclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component sprregs
port(
	addr	:in std_logic_vector(23 downto 0);
	b_rd	:in std_logic;
	b_wr	:in std_logic_vector(1 downto 0);
	wrdat	:in std_logic_Vector(15 downto 0);
	rddat	:out std_logic_vector(15 downto 0);
	datoe	:out std_logic;

	sprno	:in std_logic_vector(6 downto 0);
	xpos	:out std_logic_Vector(9 downto 0);
	ypos	:out std_logic_vector(9 downto 0);
	VR		:out std_logic;
	HR		:out std_logic;
	COLOR	:out std_logic_vector(3 downto 0);
	PATNO	:out std_logic_vector(7 downto 0);
	PRI		:out std_logic_vector(1 downto 0);
	
	BG0Xpos	:out std_logic_vector(9 downto 0);
	BG0Ypos	:out std_logic_vector(9 downto 0);
	BG1Xpos	:out std_logic_vector(9 downto 0);
	BG1Ypos	:out std_logic_vector(9 downto 0);
	DISPEN	:out std_logic;
	BG1TXSEL	:out std_logic_vector(1 downto 0);
	BG0TXSEL	:out std_logic_vector(1 downto 0);
	BGON	:out std_logic_vector(1 downto 0);
	HTOTAL	:out std_logic_vector(7 downto 0);
	HDISP	:out std_logic_vector(5 downto 0);
	VDISP	:out std_logic_vector(7 downto 0);
	LH		:out std_logic;
	VRES	:out std_logic_vector(1 downto 0);
	HRES	:out std_logic_vector(1 downto 0);
	
	sclk	:in std_logic;
	vclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component  MFP
generic(
	SCFREQ		:integer	:=20000		--kHz
);
port(
	addr	:in std_logic_vector(23 downto 0);
	rdat	:out std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(7 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	datoe	:out std_logic;
	
	KBCLKIN	:in std_logic;
	KBCLKOUT:out std_logic;
	KBDATIN	:in std_logic;
	KBDATOUT:out std_logic;

	KBWAIT	:in std_logic;
	KBen	:out std_logic;
	KBLED	:out std_logic_vector(6 downto 0);

	kbsel	:in std_logic	:='0';
	kbout	:out std_logic_vector(7 downto 0);
	kbrx	:out std_logic;

	GPIPI7	:in std_logic;
	GPIPI6	:in std_logic;
	GPIPI5	:in std_logic;
	GPIPI4	:in std_logic;
	GPIPI3	:in std_logic;
	GPIPI2	:in std_logic;
	GPIPI1	:in std_logic;
	GPIPI0	:in std_logic;

	GPIPO7	:out std_logic;
	GPIPO6	:out std_logic;
	GPIPO5	:out std_logic;
	GPIPO4	:out std_logic;
	GPIPO3	:out std_logic;
	GPIPO2	:out std_logic;
	GPIPO1	:out std_logic;
	GPIPO0	:out std_logic;

	GPIPD7	:out std_logic;
	GPIPD6	:out std_logic;
	GPIPD5	:out std_logic;
	GPIPD4	:out std_logic;
	GPIPD3	:out std_logic;
	GPIPD2	:out std_logic;
	GPIPD1	:out std_logic;
	GPIPD0	:out std_logic;

	TAI		:in std_logic;
	TAO		:out std_logic;

	TBI		:in std_logic;
	TBO		:out std_logic;

	TCO		:out std_logic;

	TDO		:out std_logic;

	INT		:out std_logic;
	IVECT	:out std_logic_vector(7 downto 0);
	INTack	:in std_logic;
	IVack	:in std_logic_vector(7 downto 0);
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component scc
generic(
	CLKCYC	:integer	:=20000
);
port(
	addr	:in std_logic_vector(23 downto 0);
	rd		:in std_logic;
	wr		:in std_logic;
	wdat	:in std_logic_vector(7 downto 0);
	rdat	:out std_logic_vector(7 downto 0);
	doe		:out std_logic;
	int		:out std_logic;
	ivect	:out std_logic_vector(7 downto 0);
	iack	:in std_logic;
	
	mclkin	:in std_logic;
	mclkout	:out std_logic;
	mdatin	:in std_logic;
	mdatout	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component IOcont
port(
	addr		:in std_logic_vector(23 downto 0);
	rdat		:out std_logic_vector(7 downto 0);
	wdat		:in std_logic_vector(7 downto 0);
	rd			:in std_logic;
	wr			:in std_logic;
	datoe		:out std_logic;
	int			:out std_logic;
	ivect		:out std_logic_vector(7 downto 0);
	iack		:in std_logic;
	iackvect	:in std_logic_vector(7 downto 0);
	
	fd_dcontsel	:out std_logic_vector(3 downto 0);
	fd_drvled	:out std_logic_vector(3 downto 0);
	fd_drveject	:out std_logic_vector(3 downto 0);
	fd_drvejen	:out std_logic_vector(3 downto 0);
	fd_diskin	:in std_logic_vector(3 downto 0);
	fd_diskerr	:in std_logic_vector(3 downto 0);
	
	fd_drvsel	:out std_logic_vector(3 downto 0);
	fd_usel		:out std_logic_vector(1 downto 0);
	fd_drvhd	:out std_logic;
	fd_drvmt	:out std_logic;
	
	fd_feject	:out std_logic_vector(3 downto 0);
	fd_LED		:out std_logic_vector(3 downto 0);
	fd_lock		:out std_logic_vector(3 downto 0);
	
	fdc_cs		:out std_logic;
	fdc_int		:in std_logic;

	hdd_int		:in std_logic;
	prn_int		:in std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component wrreg
generic(
	address	:std_logic_vector(23 downto 0)	:=x"000000"
);
port(
	addr	:in std_logic_vector(23 downto 0);
	wrdat	:in std_logic_vector(15 downto 0);
	wr		:in std_logic_vector(1 downto 0);
	
	do		:out std_logic_vector(15 downto 0);
	wrote	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component rp5c15
generic(
	clkfreq	:integer	:=21477270
);
port(
	addr	:in std_logic_vector(3 downto 0);
	wdat	:in std_logic_vector(3 downto 0);
	rdat	:out std_logic_vector(3 downto 0);
	wr		:in std_logic;
	
	clkout	:out std_logic;
	alarm	:out std_logic;
	
--I2C I/F
	TXOUT		:out	std_logic_vector(7 downto 0);		--tx data in
	RXIN		:in		std_logic_vector(7 downto 0);		--rx data out
	WRn			:out	std_logic;							--write
	RDn			:out	std_logic;							--read

	TXEMP		:in		std_logic;							--tx buffer empty
	RXED		:in		std_logic;							--rx buffered
	NOACK		:in		std_logic;							--no ack
	COLL		:in		std_logic;							--collision detect
	NX_READ		:out	std_logic;							--next data is read
	RESTART		:out	std_logic;							--make re-start condition
	START		:out	std_logic;							--make start condition
	FINISH		:out	std_logic;							--next data is final(make stop condition)
	F_FINISH	:out	std_logic;							--next data is final(make stop condition)
	INIT		:out	std_logic;

	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component e8255
port(
	CSn		:in std_logic;
	RDn		:in std_logic;
	WRn		:in std_logic;
	ADR		:in std_logic_vector(1 downto 0);
	DATIN	:in std_logic_vector(7 downto 0);
	DATOUT	:out std_logic_vector(7 downto 0);
	DATOE	:out std_logic;
	
	PAi		:in std_logic_vector(7 downto 0);
	PAo		:out std_logic_vector(7 downto 0);
	PAoe	:out std_logic;
	PBi		:in std_logic_vector(7 downto 0);
	PBo		:out std_logic_vector(7 downto 0);
	PBoe	:out std_logic;
	PCHi	:in std_logic_vector(3 downto 0);
	PCHo	:out std_logic_vector(3 downto 0);
	PCHoe	:out std_logic;
	PCLi	:in std_logic_vector(3 downto 0);
	PCLo	:out std_logic_vector(3 downto 0);
	PCLoe	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component OPM_JT51  -- If you want to use OPM_JT51.vhd, replace OPM with OPM_JT51
--component OPM
generic(
	res		:integer	:=9
);
port(
	DIN		:in std_logic_vector(7 downto 0);
	DOUT	:out std_logic_vector(7 downto 0);
	DOE		:out std_logic;
	CSn		:in std_logic;
	ADR0	:in std_logic;
	RDn		:in std_logic;
	WRn		:in std_logic;
	INTn	:out std_logic;
	
	sndL	:out std_logic_vector(res-1 downto 0);
	sndR	:out std_logic_vector(res-1 downto 0);
	
	CT1		:out std_logic;
	CT2		:out std_logic;
--	monout	:out std_logic_vector(15 downto 0);

	chenable:in std_logic_vector(7 downto 0)	:=(others=>'1');

	fmclk	:in std_logic;
	pclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component EM3012
port(
    CLK_PHY1  : in std_logic; -- Phy0 clock 2MHz divided by YM2151
    SDATA     : in std_logic;
    SAM_HOLD1 : in std_logic;
    SAM_HOLD2 : in std_logic;

    -- sytem side
    sndL      : out std_logic_vector(15 downto 0);
    sndR      : out std_logic_vector(15 downto 0);

    fmclk     : in std_logic;  -- 32MHz
    rstn	  : in std_logic
);
end component;

component e6258
port(
	addr	:in std_logic;
	datin	:in std_logic_vector(7 downto 0);
	datout	:out std_logic_vector(7 downto 0);
	datwr	:in std_logic;
	drq		:out std_logic;
	
	clkdiv	:in std_logic_vector(1 downto 0);
	sft		:in std_logic;
	
	sndout	:out std_logic_vector(11 downto 0);
	
	sysclk	:in std_logic;
	sndclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component deltasigmadac
	generic(
		width	:integer	:=8
	);
	port(
		data	:in	std_logic_vector(width-1 downto 0);
		datum	:out std_logic;
		
		sft		:in std_logic;
		clk		:in std_logic;
		rstn	:in std_logic
	);
end component;

component addsat
generic(
	datwidth	:integer	:=16
);
port(
	INA		:in std_logic_vector(datwidth-1 downto 0);
	INB		:in std_logic_vector(datwidth-1 downto 0);
	
	OUTQ	:out std_logic_vector(datwidth-1 downto 0);
	OFLOW	:out std_logic;
	UFLOW	:out std_logic
);
end component;

component txtpal
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(15 downto 0);
	rdat	:out std_logic_vector(15 downto 0);
	datoe	:out std_logic;
	rd		:in std_logic;
	wr		:in std_logic_vector(1 downto 0);
	
	palno	:in std_logic_vector(7 downto 0);
	palout	:out std_logic_vector(15 downto 0);
	
	sclk	:in std_logic;
	vclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component grpal
port(
	cs		:in std_logic;
	addr	:in std_logic_vector(7 downto 0);
	wdat	:in std_logic_vector(15 downto 0);
	rdat	:out std_logic_vector(15 downto 0);
	datoe	:out std_logic;
	rd		:in std_logic;
	wr		:in std_logic_vector(1 downto 0);
	
	gmode	:in std_logic;
	skel	:in std_logic;
	palnoh	:in std_logic_vector(7 downto 0);
	palnol	:in std_logic_vector(7 downto 0);
	palout	:out std_logic_vector(15 downto 0);
	
	sclk	:in std_logic;
	vclk	:in std_logic;
	rstn	:in std_logic
);
end component;

component I2CIF
port(
	DATIN	:in	std_logic_vector(I2CDAT_WIDTH-1 downto 0);		--tx data in
	DATOUT	:out	std_logic_vector(I2CDAT_WIDTH-1 downto 0);	--rx data out
	WRn		:in		std_logic;						--write
	RDn		:in		std_logic;						--read

	TXEMP	:out std_logic;							--tx buffer empty
	RXED	:out std_logic;							--rx buffered
	NOACK	:out std_logic;							--no ack
	COLL	:out std_logic;							--collision detect
	NX_READ	:in std_logic;							--next data is read
	RESTART	:in std_logic;							--make re-start condition
	START	:in std_logic;							--make start condition
	FINISH	:in std_logic;							--next data is final(make stop condition)
	F_FINISH :in std_logic;							--next data is final(make stop condition)
	INIT	:in std_logic;
	
--	INTn :out	std_logic;

	SDAIN :in	std_logic;
	SDAOUT :out	std_logic;
	SCLIN :in	std_logic;
	SCLOUT :out	std_logic;

	SFT	:in		std_logic;
	clk	:in		std_logic;
	rstn :in	std_logic
);
end component;

component pwrcont
port(
	addrin	:in std_logic_vector(23 downto 0);
	wr		:in std_logic;
	wrdat	:in std_logic_vector(7 downto 0);
	
	psw		:in std_logic;
	
	power	:out std_logic;
	pint	:out std_logic;
	willrst	:out std_logic;

	sclk	:in std_logic;
	srstn	:in std_logic;
	pclk	:in std_logic;
	prstn	:in std_logic
);
end component;

component contcont
generic(
	extwid	:integer	:=3
);
port(
	addrin	:in std_logic_vector(23 downto 0);
	wr		:in std_logic;
	rd		:in std_logic;
	wrdat	:in std_logic_vector(7 downto 0);
	rddat	:out std_logic_vector(7 downto 0);
	doe	:out std_logic;
	
	vviden	:in std_logic;
	contrast:out std_logic_vector(3+extwid downto 0);
	
	sclk	:in std_logic;
	srstn	:in std_logic
);
end component;

component em3802
generic(
	sysclk	:integer	:=10000;
	oscm		:integer	:=1000;
	oscf		:integer	:=614
);
port(
	ADDR	:in std_logic_vector(2 downto 0);
	DATIN	:in std_logic_vector(7 downto 0);
	DATOUT:out std_logic_vector(7 downto 0);
	DATWR	:in std_logic;
	DATRD	:in std_logic;
	INT	:out std_logic;
	IVECT	:out std_logic_vector(7 downto 0);

	RxD	:in std_logic;
	TxD	:out std_logic;
	RxF	:in std_logic;
	TxF	:out std_logic;
	SYNC	:out std_logic;
	CLICK	:out std_logic;
	GPOUT	:out std_logic_vector(7 downto 0);
	GPIN	:in std_logic_vector(7 downto 0);
	GPOE	:out std_logic_vector(7 downto 0);
	
	clk	:in std_logic;
	rstn	:in std_logic
);
end component;

component SFTCLK
generic(
	SYS_CLK	:integer	:=20000;
	OUT_CLK	:integer	:=1600;
	selWIDTH :integer	:=2
);
port(
	sel		:in std_logic_vector(selWIDTH-1 downto 0);
	SFT		:out std_logic;

	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component pcmclk
port(
	clkmode	:in std_logic;
	pcmsft	:out std_logic;
	
	clk		:in std_logic;
	rstn	:in std_logic
);
end component;

component HEX2SEGn
	port(
		HEX	:in std_logic_vector(3 downto 0);
		DOT	:in std_logic;
		SEG	:out std_logic_vector(7 downto 0)
	);
end component;

component DIGIFILTER
	generic(
		TIME	:integer	:=2;
		DEF		:std_logic	:='0'
	);
	port(
		D	:in std_logic;
		Q	:out std_logic;

		clk	:in std_logic;
		rstn :in std_logic
	);
end component;

component fontrom
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END component;

component contrast
generic(
	datwidth		:integer	:=5;
	contwidth	:integer	:=4;
	outwidth		:integer	:=8
);
port(
	indat	:in std_logic_vector(datwidth-1 downto 0);
	contrast:in std_logic_vector(contwidth-1  downto 0);
	
	outdat	:out std_logic_vector(outwidth-1 downto 0)
);
end component;

component hdmiconv
port(
	datinR	:in std_logic_vector(7 downto 0);
	datinG	:in std_logic_vector(7 downto 0);
	datinB	:in std_logic_vector(7 downto 0);
	Hsync		:in std_logic;
	Vsync		:in std_logic;
	VIDen		:in std_logic;
	
	LVDS0		:out std_logic;
	LVDS1		:out std_logic;
	LVDS2		:out std_logic;
	LVDSclk	:out std_logic;
	
	vclk		:in std_logic;
	clk2		:in std_logic;
	rstn		:in std_logic
);
end component;

component datlatch
generic(
	datwidth	:integer	:=8
);
port(
	datin		:in std_logic_vector(datwidth-1 downto 0);
	wr			:in std_logic;
	datout	:out std_logic_vector(datwidth-1 downto 0);
	
	clk		:in std_logic;
	rstn		:in std_logic
);
end component;

--component hangmon
--generic(
--	num	:integer	:=3
--);
--port(
--	addr	:in std_logic_vector(23 downto 0);
--	data	:in std_logic_vector(15 downto 0);
--	rd		:in std_logic;
--	wr		:in std_logic_vector(1 downto 0);
--	ack	:in std_logic;
--	drq	:in std_logic_vector(3 downto 0);
--	irq	:in std_logic_vector(2 downto 0);
--	
--	evnum	:out std_logic_vector(7 downto 0);
--	eaddr	:out std_logic_vector(23 downto 0);
--	edata	:out std_logic_vector(15 downto 0);
--	erd	:out std_logic;
--	ewr	:out std_logic_vector(1 downto 0);
--	edrq	:out std_logic_vector(3 downto 0);
--	eirq	:out std_logic_vector(2 downto 0);
--	
--	hang	:out std_logic;
--	
--	sclk	:in std_logic;
--	mclk	:in std_logic;
--	rstn	:in std_logic
--);
--end component;

component i2s_encoder
port(
	snd_clk     :in std_logic;
	snd_L       :in std_logic_vector(31 downto 0);
	snd_R       :in std_logic_vector(31 downto 0);
	
	i2s_data    :out std_logic;
	i2s_lrck    :out std_logic;
		
	i2s_bclk    :in std_logic;  -- I2S BCK (Bit Clock) 3.072MHz (=48kHz * 64)
	rstn		:in std_logic
);
end component;

component I2C_MUX is
generic(
    NUM_DRIVERS	:integer	:=2
);
port(
    -- I2C
    TXOUT		:out	std_logic_vector(7 downto 0);	--tx data in
    RXIN		:in		std_logic_vector(7 downto 0);	--rx data out
    WRn			:out	std_logic;						--write
    RDn			:out	std_logic;						--read
    
    TXEMP		:in		std_logic;						--tx buffer empty
    RXED		:in		std_logic;						--rx buffered
    NOACK		:in		std_logic;						--no ack
    COLL		:in		std_logic;						--collision detect
    NX_READ		:out	std_logic;						--next data is read
    RESTART		:out	std_logic;						--make re-start condition
    START		:out	std_logic;						--make start condition
    FINISH		:out	std_logic;						--next data is final(make stop condition)
    F_FINISH	:out	std_logic;						--next data is final(make stop condition by force)
    INIT		:out	std_logic;
    
    -- for Driver
    DATIN_PXY   :in     i2cdat_array(NUM_DRIVERS-1 downto 0);		--tx data in
    DATOUT_PXY	:out    i2cdat_array(NUM_DRIVERS-1 downto 0);		--rx data out
    WRn_PXY		:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--write
    RDn_PXY		:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--read
    
    TXEMP_PXY   :out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--tx buffer empty
    RXED_PXY	:out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--rx buffered
    NOACK_PXY	:out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--no ack
    COLL_PXY	:out    std_logic_vector(NUM_DRIVERS-1 downto 0);	--collision detect
    NX_READ_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is read
    RESTART_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--make re-start condition
    START_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--make start condition
    FINISH_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is final(make stop condition)
    F_FINISH_PXY:in     std_logic_vector(NUM_DRIVERS-1 downto 0);	--next data is final(make stop condition)
    INIT_PXY	:in     std_logic_vector(NUM_DRIVERS-1 downto 0);
    
    clk			:in     std_logic;
    rstn		:in     std_logic
);
end component;

component I2C_TLC59116 is
port(
    -- I2C
    TXOUT		:out	std_logic_vector(7 downto 0);	--tx data in
    RXIN		:in		std_logic_vector(7 downto 0);	--rx data out
    WRn			:out	std_logic;						--write
    RDn			:out	std_logic;						--read
    
    TXEMP		:in		std_logic;						--tx buffer empty
    RXED		:in		std_logic;						--rx buffered
    NOACK		:in		std_logic;						--no ack
    COLL		:in		std_logic;						--collision detect
    NX_READ		:out	std_logic;						--next data is read
    RESTART		:out	std_logic;						--make re-start condition
    START		:out	std_logic;						--make start condition
    FINISH		:out	std_logic;						--next data is final(make stop condition)
    F_FINISH	:out	std_logic;						--next data is final(make stop condition by force)
    INIT		:out	std_logic;
    
    -- Ports
    LEDMODES    :in led_mode_array(0 to 15);

    clk			:in std_logic;
    rstn		:in std_logic
);
end component;

component X68_FRONTPANEL_CONTROLLER is
port(
    -- Control
    LED_POWER       :in     std_logic_vector(1 downto 0);
    LED_HD_BUSY     :in     std_logic;
    LED_TIMER       :in     std_logic;
    LED_FDD0_ACCESS :in     std_logic_vector(1 downto 0);
    LED_FDD1_ACCESS :in     std_logic_vector(1 downto 0);
    LED_FDD0_EJECT  :in     std_logic;
    LED_FDD1_EJECT  :in     std_logic;
    
    -- to TLC59116 module
    LEDMODES        :out	led_mode_array(0 to 15);
                
    clk			    :in     std_logic;
    rstn		    :in     std_logic
);
end component;

begin
	pllrst<=not pwr_rstn;
	clkgen	:mainpllCVdemu port map(
		refclk   =>pClk50M,
		rst      =>pllrst,
		outclk_0 =>ramclk,
		outclk_1 =>sysclk,
		outclk_2 =>vidclk,
		outclk_3 =>pMemClk,
		outclk_4 =>fdcclk,
		outclk_5 =>sndclk,
		outclk_6 =>emuclk,
		outclk_7 =>i2sclk,
		locked   =>plllock
	);
--	pMemClk<=not ramclk;

	sr	:sftclk    generic map(100000000,1,1) port map("1",srst,sysclk,rstn);

	mem_rstn<=	not srst when pDip(0)='1' else plllock when DEBUG(DBIT_CYCLERESET)='1' else
					plllock and rstn;

--	fdcclk<=pClk50M;
	ldr_rstn<=plllock and pwr_rstn and rstn and ram_inidone;
	dem_rstn<=plllock and pwr_rstn;
	srstn<=plllock and pwr_rstn and ldr_done and dem_initdone;
	vid_rstn<=plllock and pwr_rstn and ram_inidone;
	dem_conten<=(not pDip(1)) xor pDemuSw;

	pwr	:pwrcont  port map(
		addrin	=>abus,
		wr		=>b_wr(0),
		wrdat	=>dbus(7 downto 0),
		
		psw		=>not pPsw(0),
		
		power	=>pwr_rstn,
		pint	=>pwrsw,
		willrst	=>willrst,
		
		sclk	=>sysclk,
		srstn	=>srstn,
		pclk	=>pClk50M,
		prstn	=>rstn
	);
	
	pLed(1)<=dma_bconte;
	
	mpu_clke<=(not dma_bconte);
	MPU	:TG68 port map(
		clk           =>sysclk,
		reset         =>srstn,
        clkena_in     =>mpu_clke,
        data_in       =>dbus,
        IPL           =>mpu_ipl,
        dtack         =>mpu_dtack,
        addr          =>mpu_addr,
        data_out      =>mpu_od,
        as            =>mpu_as,
        uds           =>mpu_udsn,
        lds           =>mpu_ldsn,
        rw            =>mpu_rwn,
        drive_data    =>mpu_oe
	);

	INTC	:INTcont port map(
		int7	=>INT7,
		vect7	=>x"1f",
		iack7	=>open,
		e_ln7	=>'1',
				
		int6	=>INT6,
		vect6	=>IVECT6,
		iack6	=>IACK6,
		e_ln6	=>'0',
		ivack6	=>mfp_ivack,
		
		int5	=>INT5,
		vect5	=>IVECT5,
		iack5	=>IACK5,
		e_ln5	=>'0',
		
		int4	=>INT4,
		vect4	=>IVECT4,
		iack4	=>IACK4,
		e_ln4	=>'1',
		
		int3	=>INT3,
		vect3	=>IVECT3,
		iack3	=>IACK3,
		e_ln3	=>'0',
		
		int2	=>INT2,
		vect2	=>IVECT2,
		iack2	=>IACK2,
		e_ln2	=>'1',
		
		int1	=>INT1,
		vect1	=>IVECT1,
		iack1	=>IACK1,
		e_ln1	=>'1',
		ivack1	=>IOU_ivack,

		IPL		=>mpu_ipl,
		addrin	=>mpu_addr(23 downto 0),
		addrout	=>int_addr,
		rw		=>mpu_rwn,
        dtack	=>mpu_dtack,
		
		clk		=>sysclk,
		rstn	=>srstn
	);
	
	DMA	:DMA63450 port map(
		addrin	=>abus,
		m_as	=>mpu_as,
		b_rd	=>b_rd,
		b_wr	=>b_wr,
		b_addr	=>dma_addr,
		b_as	=>dma_as,
		b_rwn	=>dma_rwn,
		b_uds	=>dma_udsn,
		b_lds	=>dma_ldsn,
		b_dout	=>dma_odat,
		b_doe	=>dma_doe,
		b_din	=>dbus,
		b_ack	=>b_ack,
		b_conte	=>dma_bconte,
		
		drq0	=>FDC_DRQ,
		dack0	=>FDC_DACK,
		pcli0	=>'0',
		pclo0	=>open,
		doneo0	=>FDC_TC,
		
		drq1	=>SCSI_DRQ,
		dack1	=>SCSI_DACK,
		pcli1	=>'1',
		pclo1	=>open,
		doneo1	=>open,

		drq2	=>'0',
		dack2	=>open,
		pcli2	=>'0',
		pclo2	=>open,
		doneo2	=>open,

--		drq3	=>pcm_drq,
		drq3	=>pcm_drq and ((not pDip(8)) or (not DEBUG(DBIT_ADPCM_ONOFF))),
		dack3	=>open,
		pcli3	=>pcm_drq,
		pclo3	=>open,
		doneo3	=>open,
		
		d_rd	=>dma_drd,
		d_wr	=>dma_dwr,
		
		donei	=>'0',

		dtc		=>open,
		
		int		=>INT3,
		ivect	=>IVECT3,
		iack	=>IACK3,
		
		clk		=>sysclk,
		rstn	=>srstn
	);

--	INT3<='0';

	abus<=	dma_addr when dma_bconte='1' else int_addr;

	dbus<=	dma_odat			when dma_doe='1' else
			mpu_od				when mpu_oe='1' and dma_bconte='0' else
			m_odat				when m_doe='1' else
			nv_rdat				when nv_doe='1' else
			vr_rdat				when vr_doe='1' else
			mfp_odat & mfp_odat	when mfp_doe='1' else
			spreg_rdat			when spreg_doe='1' else
			spram_rdat			when spram_doe='1' else
			x"00" & scc_odat	when scc_doe='1' else
			x"00" & FDC_WD		when FDC_OE='1' else
			x"00" & SCSI_RDAT	when SCSI_DOE='1' else
			x"00" & IOU_rdat	when IOU_doe='1' else
			x"000" & rtc_odat	when rtc_doe='1' else
			x"00" & ppi_odat	when ppi_doe='1' else
			opm_odat & opm_odat when opm_doe='1' else
			x"00" & pcm_odat	when pcm_doe='1' else
			tpal_rdat			when tpal_doe='1' else
			gpal_rdat			when gpal_doe='1' else
			x"00" & contc_rdat when contc_doe='1' else
			x"00" & midi_odat	when midi_doe='1' else
			(others=>'0');

	b_ack<=	'0' when m_ack='1' else
			'1';
	
	b_as<=dma_as when dma_bconte='1' else mpu_as;
	b_udsn<=dma_udsn when dma_bconte='1' else mpu_udsn;
	b_ldsn<=dma_ldsn when dma_bconte='1' else mpu_ldsn;
	b_rwn<=dma_rwn when dma_bconte='1' else mpu_rwn;
	b_lds<=not b_ldsn;
	b_uds<=not b_udsn;
	
	iowait<=iowait_rcpy or iowait_scsi or iowait_opm;
	process(sysclk)begin
		if(sysclk' event and sysclk='1')then
			dwait<=pDip(9);
		end if;
	end process;
			
	mpu_dtack<='1' when (dwait='1' and DEBUG(DBIT_PAUSE_ONOFF)='1') else b_ack when dma_bconte='0' else '1';
--	mpu_dtack<=b_ack when dma_bconte='0' else '1';
	mmap_min<='0';
	MMP	:X68mmapCV port map(
		m_addr	=>abus(23 downto 0),
		m_rdat	=>m_odat,
		m_wdat	=>dbus,
		m_doe	=>m_doe,
		m_uds	=>b_udsn,
		m_lds	=>b_ldsn,
		m_as	=>b_as,
		m_rw	=>b_rwn,
		m_ack	=>m_ack,
		
		b_rd	=>b_rd,
		b_wr	=>b_wr,
		
		buserr	=>buserr,
		iackbe	=>iackbe,
		
		MEN		=>vr_MEN,
		SA		=>vr_SA,
		AP		=>vr_AP,
		txtmask	=>vr_txtmask,
		gmode	=>vr_col,
		vmode	=>vr_GR_CMODE,
		gsize	=>vr_size,
		rcpybusy=>vr_rcpybusy,
		
		ram_addr	=>ram_addr,
		ram_rdat	=>ram_rdat,
		ram_wdat	=>ram_wdat,
		ram_rd		=>ram_rd,
		ram_wr		=>ram_wr,
		ram_rmw		=>ram_rmw,
		ram_rmwmask	=>ram_rmwmask,
		ram_ack		=>ram_ack,
		
		ldr_addr	=>ldr_addr,
		ldr_wdat	=>ldr_wdat,
		ldr_aen		=>ldr_aen,
		ldr_wr		=>ldr_wr,
		ldr_ack		=>ldr_ack,
	
		iowait		=>iowait,

		gpcen			=>'1',		

		min			=>mmap_min,
		sclk		=>sysclk,
		rstn		=>srstn
);
	b_rdn<=not b_rd;
	b_wrn<=not b_wr;

	
	ram_addrw<="00" & ram_addr;
	
	RAM	:memcont generic map(
		AWIDTH		=>25,
		CAWIDTH		=>10,
		BRSIZE		=>brsize,
		BRBLOCKS		=>8,
		CLKMHZ		=>RCFREQ,
		REFINT		=>3,
		REFCNT		=>64
	) port map(
		PMEMCKE		=>pMemCke,
		PMEMCS_N	=>pMemCs_n,
		PMEMRAS_N	=>pMemRas_n,
		PMEMCAS_N	=>pMemCas_n,
		PMEMWE_N	=>pMemWe_n,
		PMEMUDQ		=>pMemUdq,
		PMEMLDQ		=>pMemLdq,
		PMEMBA1		=>pMemBa1,
		PMEMBA0		=>pMemBa0,
		PMEMADR		=>pMemAdr,
		PMEMDAT		=>pMemDat,

		b_addr		=>ram_addrw,
		b_wdat		=>ram_wdat,
		b_rdat		=>ram_rdat,
		b_rd		=>ram_rd,
		b_wr		=>ram_wr,
		b_rmw		=>ram_rmw,
		b_rmwmsk	=>ram_rmwmask,
		b_ack		=>ram_ack,
		
		b_csaddr	=>ram_cpys,
		b_cdaddr	=>ram_cpyd,
		b_cplane	=>ram_cplane,
		b_cpy		=>ram_cpy,
		b_cack		=>ram_cpya,
	
		g00_addr	=>g00_addr,
		g00_rd		=>g00_rd,
		g00_rdat	=>g00_rdat,
		g00_ack		=>g00_ack,

		g01_addr	=>g01_addr,
		g01_rd		=>g01_rd,
		g01_rdat	=>g01_rdat,
		g01_ack		=>g01_ack,

		g02_addr	=>g02_addr,
		g02_rd		=>g02_rd,
		g02_rdat	=>g02_rdat,
		g02_ack		=>g02_ack,

		g03_addr	=>g03_addr,
		g03_rd		=>g03_rd,
		g03_rdat	=>g03_rdat,
		g03_ack		=>g03_ack,

		g10_addr	=>g10_addr,
		g10_rd		=>g10_rd,
		g10_rdat	=>g10_rdat,
		g10_ack		=>g10_ack,

		g11_addr	=>g11_addr,
		g11_rd		=>g11_rd,
		g11_rdat	=>g11_rdat,
		g11_ack		=>g11_ack,

		g12_addr	=>g12_addr,
		g12_rd		=>g12_rd,
		g12_rdat	=>g12_rdat,
		g12_ack		=>g12_ack,

		g13_addr	=>g13_addr,
		g13_rd		=>g13_rd,
		g13_rdat	=>g13_rdat,
		g13_ack		=>g13_ack,

		t0_addr		=>t0_addr,
		t0_rd		=>t0_rd,
		t0_rdat0	=>t0_rdat0,
		t0_rdat1	=>t0_rdat1,
		t0_rdat2	=>t0_rdat2,
		t0_rdat3	=>t0_rdat3,
		t0_ack		=>t0_ack,
		
		t1_addr		=>t1_addr,
		t1_rd		=>t1_rd,
		t1_rdat0	=>t1_rdat0,
		t1_rdat1	=>t1_rdat1,
		t1_rdat2	=>t1_rdat2,
		t1_rdat3	=>t1_rdat3,
		t1_ack		=>t1_ack,
		
		g0_caddr	=>g0_caddr,
		g0_clear	=>g0_clear,
		
		g1_caddr	=>g1_caddr,
		g1_clear	=>g1_clear,

		g2_caddr	=>g2_caddr,
		g2_clear	=>g2_clear,

		g3_caddr	=>g3_caddr,
		g3_clear	=>g3_clear,

		fde_addr	=>'1' & dem_fderamaddr,
		fde_rdat	=>dem_fderamrdat,
		fde_wdat	=>dem_fderamwdat,
		fde_wr		=>dem_fderamwr,
		fde_tlen	=>dem_fdetracklen,
		
		fec_addr	=>dem_fecramaddrl,
		fec_rdat	=>dem_fecramrdat,
		fec_wdat	=>dem_fecramwdat,
		fec_we	=>dem_fecramwe,
		fec_addrh	=>'1' & dem_fecramaddrh,
		fec_rd		=>dem_fecramrd,
		fec_wr		=>dem_fecramwr,
		fec_busy	=>dem_fecrambusy,

		initdone	=>ram_inidone,
		sclk		=>sysclk,
		vclk		=>vidclk,
		fclk		=>fdcclk,
		rclk		=>ramclk,
		rstn		=>mem_rstn
	);
	
	ROM :romcopy port map(
	addr	=>ldr_addr,
	wdat	=>ldr_wdat,
	aen		=>ldr_aen,
	wr		=>ldr_wr,
	ack		=>ldr_ack,
	done	=>ldr_done,
	
	clk		=>sysclk,
	rstn	=>ldr_rstn
);
	
	nvwpl	:bwlatch generic map(24,8) port map(abus(23 downto 0),b_lds,b_wr(0),dbus(7 downto 0),x"e8e00d",nvwp,sysclk,srstn);
	nv_ce<='1' when abus(23 downto 14)="1110110100" else '0';

	CRTC	:CRTCX68TXT generic map(4) port map(
		LRAMSEL		=>LRAMSEL,
		LRAMADR		=>LVIDADR,
		LRAMDAT		=>LVIDRD,
		
		TRAM_ADR	=>dem_tramaddr,
		TRAM_DAT	=>dem_tramdat,
		
		FRAM_ADR	=>dem_fontaddr,
		FRAM_DAT	=>dem_fontdat,
		
		CURL		=>dem_curl,
		CURC		=>dem_curc,
		CURE		=>dem_curen,

		TXTMODE		=>dem_conten or (not dem_initdone),
	
		ROUT		=>vidR,
		GOUT		=>vidG,
		BOUT		=>vidB,

		RFOUT		=>vidRF,
		GFOUT		=>vidGF,
		BFOUT		=>vidBF,
		
		HSYNC		=>vidHS,
		VSYNC		=>vidVS,
		
		HMODE		=>"11",
		VMODE		=>'1',

		VRTC		=>VID_VRTC,
		HRTC		=>VID_HRTC,
		VIDEN		=>vidEN,

		HCOMP		=>HCOMP,
		VCOMP		=>open,
		VPSTART		=>VPSTART,
		
		dclk		=>dclk,
		
		gclk		=>vidclk,
		rstn		=>vid_rstn
	);

	pDac_VR<=vidR;
	pDac_VG<=vidG;
	pDac_VB<=vidB;
	
	pVideoHS_n<=vidHS;
	pVideoVS_n<=vidVS;
	
	cont	:contcont generic map(context) port map(
		addrin	=>abus,
		wr		=>b_wr(0),
		rd		=>b_rd,
		wrdat	=>dbus(7 downto 0),
		rddat	=>contc_rdat,
		doe	=>contc_doe,
		
		vviden	=>VID_VVIDEN,
		contrast=>contval,

		sclk	=>sysclk,
		srstn	=>vid_rstn
	);
	contvalm<=	(others=>'1') when dem_conten ='1' or dem_initdone='0' else
					contval;
	contR	:contrast  generic map(6,4+context,8) port map(vidRF,contvalm,vidRC);
	contG	:contrast  generic map(6,4+context,8) port map(vidGF,contvalm,vidGC);
	contB	:contrast  generic map(6,4+context,8) port map(vidBF,contvalm,vidBC);
			
	hdmi	:hdmiconv port map(
		datinR	=>vidRC,
		datinG	=>vidGC,
		datinB	=>vidBC,
		Hsync		=>vidHS,
		Vsync		=>vidVS,
		VIDen		=>vidEN,
		
		LVDS0		=>pHDMI_DAT0,
		LVDS1		=>pHDMI_DAT1,
		LVDS2		=>pHDMI_DAT2,
		LVDSclk	=>pHDMI_CLK,
		
		vclk		=>vidclk,
		clk2		=>not dclk,
		rstn		=>vid_rstn
	);

--	pHDMI_SCL<='Z';
--	pHDMI_SDA<='Z';

	font	:fontrom port map(dem_fontaddr,vidclk,dem_fontdat);
	dem_tramamod<= dem_tramaddr(0) & dem_tramaddr(12 downto 1);
	
	LBUFWR0<=LBUFWR and LRAMSEL;
	LBUFWR1<=LBUFWR and (not LRAMSEL);
	VLBUF0	:VLINEBUF port map(
		address_a	=>LBUFADR,
		address_b	=>LVIDADR,
		clock		=>vidclk,
		data_a		=>LBUFWD,
		data_b		=>(others=>'0'),
		wren_a		=>LBUFWR0,
		wren_b		=>'0',
		q_a			=>LBUFRD0,
		q_b			=>LVIDRD0
	);
	VLBUF1	:VLINEBUF port map(
		address_a	=>LBUFADR,
		address_b	=>LVIDADR,
		clock		=>vidclk,
		data_a		=>LBUFWD,
		data_b		=>(others=>'0'),
		wren_a		=>LBUFWR1,
		wren_b		=>'0',
		q_a			=>LBUFRD1,
		q_b			=>LVIDRD1
	);
	LBUFRD<=LBUFRD0 when LRAMSEL='0' else LBUFRD1;
	LVIDRD<=LVIDRD0 when LRAMSEL='1' else LVIDRD1;

	vreg	:vcreg port map(
		addr	=>abus(23 downto 0),
		rdat	=>vr_rdat,
		wdat	=>dbus,
		rd		=>b_rd,
		wr		=>b_wr,
		doe		=>vr_doe,
		
		htotal		=>vr_htotal,
		hsync		=>vr_hsync,
		hvbgn		=>vr_hvbgn,
		hvend		=>vr_hvend,
		vtotal		=>vr_vtotal,
		vsync		=>vr_vsync,
		vvbgn		=>vr_vvbgn,
		vvend		=>vr_vvend,
		hadj		=>vr_hadj,
		intraster	=>vr_rintline,
		txtoffsetx	=>txt_offsetx,
		txtoffsety	=>txt_offsety,
		g0offsetx	=>gr0_offsetx,
		g0offsety	=>gr0_offsety,
		g1offsetx	=>gr1_offsetx,
		g1offsety	=>gr1_offsety,
		g2offsetx	=>gr2_offsetx,
		g2offsety	=>gr2_offsety,
		g3offsetx	=>gr3_offsetx,
		g3offsety	=>gr3_offsety,
		siz			=>vr_size,
		col			=>vr_col,
		HF			=>vr_hfreq,
		VD			=>vr_VD,
		HD			=>vr_HD,
		MEN			=>vr_MEN,
		SA			=>vr_SA,
		AP			=>vr_AP,
		CP			=>vr_rcpyplane,
		csrc		=>vr_rcpysrc,
		cdst		=>vr_rcpydst,
		RCbgn		=>vr_rcpybgn,
		RCend		=>vr_rcpyend,
		FCbgn		=>vr_fcbgn,
		FCend		=>vr_fcend,
		VIbgn		=>open,
		VIend		=>open,
		tmask		=>vr_txtmask,
		RCbusy		=>vr_rcpybusy,
		FCbusy		=>vr_fcbusy,
		VIbusy		=>'0',
		GR_SIZE		=>vr_GR_SIZE,
		GR_CMODE	=>vr_GR_CMODE,
		PRI_SP		=>vr_PRI_SP,
		PRI_TX		=>vr_PRI_TX,
		PRI_GR		=>vr_PRI_GR,
		GR_PRI		=>vr_GR_PRI,
		GRPEN		=>vr_GRPEN,
		TXTEN		=>vr_TXTEN,
		SPREN		=>VR_SPREN,
		GT			=>vr_GT,
		GG			=>vr_GG,
		BP			=>vr_BP,
		HP			=>vr_HP,
		EXON		=>vr_EXON,
		VHT			=>vr_VHT,
		AH			=>vr_AH,
		YS			=>vr_YS,
		
		clk		=>sysclk,
		rstn	=>srstn
	);
	dgrpen<=	vr_GRPEN(4) & (vr_GRPEN(3) and pDip(6)) & (vr_GRPEN(2) and pDip(5)) & (vr_GRPEN(1) and pDip(4)) & (vr_GRPEN(0) and pDip(3)) when DEBUG(DBIT_GRP_ONOFF)='1' else
				vr_GRPEN;

	vr_GREN<=	vr_GRPEN(4) when vr_GR_SIZE='1' else
					'0' when vr_GRPEN(3 downto 0)="0000" else
					'1';
	vc	:vidcont generic map(25) port map(
		t_base	=>"0011100000000000000000000",
		g_base	=>"0011101000000000000000000",
		g00_addr	=>g00_addr,
		g00_rd		=>g00_rd,
		g00_rdat	=>g00_rdat,
		g01_addr	=>g01_addr,
		g01_rd		=>g01_rd,
		g01_rdat	=>g01_rdat,
		g02_addr	=>g02_addr,
		g02_rd		=>g02_rd,
		g02_rdat	=>g02_rdat,
		g03_addr	=>g03_addr,
		g03_rd		=>g03_rd,
		g03_rdat	=>g03_rdat,

		t0_addr		=>t0_addr,
		t0_rd		=>t0_rd,
		t0_rdat0	=>t0_rdat0,
		t0_rdat1	=>t0_rdat1,
		t0_rdat2	=>t0_rdat2,
		t0_rdat3	=>t0_rdat3,

		g10_addr	=>g10_addr,
		g10_rd		=>g10_rd,
		g10_rdat	=>g10_rdat,
		g11_addr	=>g11_addr,
		g11_rd		=>g11_rd,
		g11_rdat	=>g11_rdat,
		g12_addr	=>g12_addr,
		g12_rd		=>g12_rd,
		g12_rdat	=>g12_rdat,
		g13_addr	=>g13_addr,
		g13_rd		=>g13_rd,
		g13_rdat	=>g13_rdat,

		t1_addr		=>t1_addr,
		t1_rd		=>t1_rd,
		t1_rdat0	=>t1_rdat0,
		t1_rdat1	=>t1_rdat1,
		t1_rdat2	=>t1_rdat2,
		t1_rdat3	=>t1_rdat3,

		t_hoffset	=>txt_offsetx,
		t_voffset	=>txt_offsety,

		g0_caddr	=>g0_caddr,
		g0_clear	=>g0_clear,
		
		g1_caddr	=>g1_caddr,
		g1_clear	=>g1_clear,

		g2_caddr	=>g2_caddr,
		g2_clear	=>g2_clear,

		g3_caddr	=>g3_caddr,
		g3_clear	=>g3_clear,

		g0_hoffset	=>gr0_offsetx,
		g0_voffset	=>gr0_offsety,
		g1_hoffset	=>gr1_offsetx,
		g1_voffset	=>gr1_offsety,
		g2_hoffset	=>gr2_offsetx,
		g2_voffset	=>gr2_offsety,
		g3_hoffset	=>gr3_offsetx,
		g3_voffset	=>gr3_offsety,

		gmode		=>vr_GR_CMODE,		--00:4bit color 01:8bit color 11/10:16bit color
		memres		=>vr_GR_SIZE,		--0:512x512 1:1024x1024
		hres	=>vr_HD,
		vres	=>vr_VD(0),
		txten	=>vr_TXTEN and (pDip(3) or (not DEBUG(DBIT_SCR_ONOFF))),-- and pDip(3),
		grpen	=>vr_GREN and (pDip(4) or (not DEBUG(DBIT_SCR_ONOFF))),-- and pDip(4),
		spren	=>vr_SPREN and (pDip(5) or (not DEBUG(DBIT_SCR_ONOFF))),-- and pDip(5),
--		txten	=>'1',
--		grpen	=>'1',
--		spren	=>'1',
--		graphen	=>vr_GRPEN,
		graphen	=>dgrpen,
		pri_sp	=>vr_PRI_SP,
		pri_tx	=>vr_PRI_TX,
		pri_gr	=>vr_PRI_GR,
		grpri	=>vr_GR_PRI,
		exon		=>vr_exon,
		hp			=>vr_HP,
		bp			=>vr_BP,
		gg			=>vr_GG,
		gt			=>vr_GT,
		ah			=>vr_AH,
		
		lbaddr	=>LBUFADR,
		lbwdat	=>LBUFWD,
		lbwr	=>LBUFWR,
		
		hcomp	=>HCOMP,
		vpstart	=>VPSTART,
		hfreq	=>vr_hfreq,
		htotal	=>vr_htotal,
		hvbgn	=>vr_hvbgn,
		hvend	=>vr_hvend,
		vtotal	=>vr_vtotal,
		vvbgn	=>vr_vvbgn,
		vvend	=>vr_vvend,
		
		addrx	=>spr_x,
		addry	=>spr_y,
		sprite_in=>spr_dot,
		
		tpalno	=>tpal_pno,
		tpalin	=>tpal_pdat,
		tpal0in	=>tpal0_pdat,

		spalno	=>spal_pno,
		spalin	=>spal_pdat,

		gpal0no	=>gpal_pnol,
		gpal1no	=>gpal_pnoh,
		gpalin	=>gpal_pdat,
	
		vvideoen	=>VID_VVIDEN,
		rintline=>vr_rintline,
		rint	=>VID_RINT,
		
		vlineno	=>vlineno,
	
		gclrbgn	=>vr_fcbgn,
		gclrend	=>vr_fcend,
		gclrpage=>vr_rcpyplane,
		gclrbusy=>vr_fcbusy,

		vidclk	=>vidclk,
		sysclk	=>sysclk,
		rstn	=>vid_rstn
	);

	pLed(9 downto 7)<=vr_TXTEN & vr_GREN & vr_SPREN;
	
	rcpy	:rastercopy generic map(
		arange	=>RAMAWIDTH-brsize-1,
		brsize	=>BRSIZE
	) port map(
		src		=>vr_rcpysrc,
		dst		=>vr_rcpydst,
		plane	=>vr_rcpyplane,
		start	=>vr_rcpybgn,
--		stop	=>vr_rcpyend,
		stop	=>'0',
		busy	=>vr_rcpybusy,
		
		t_base	=>trambase(RAMAWIDTH-1 downto brsize+1),	
		srcaddr	=>ram_cpys,
		dstaddr	=>ram_cpyd,
		cplane	=>ram_cplane,
		cpy		=>ram_cpy,
		ack		=>ram_cpya,
		
		clk		=>sysclk,
		rstn	=>srstn
	);
	
	iowait_rcpy	<=vr_rcpybgn and vr_rcpybusy;
	dsprbgen<=	"11" when DEBUG(DBIT_SPRBG_ONOFF)='0' else pdip(8) & pDip(7);
	sprite	:spritec port map(
		hres	=>spreg_HRES(0),
		bgen	=>spreg_BGON,
		bg0asel	=>spreg_BG0TXSEL(0),
		bg1asel	=>spreg_BG1TXSEL(0),
		spren	=>spreg_DISPEN,

		
		hcomp	=>HCOMP,
		linenum	=>spr_y(8 downto 0),
		bg0hoff	=>spreg_BG0Xpos,
		bg0voff	=>spreg_BG0Ypos,
		bg1hoff	=>spreg_BG1Xpos,
		bg1voff	=>spreg_BG1Ypos,
		
		sprno	=>spreg_sprno,
		sprxpos	=>spreg_xpos,
		sprypos	=>spreg_ypos,
		sprVR	=>spreg_VR,
		sprHR	=>spreg_HR,
		sprCOLOR=>spreg_COLOR,
		sprPAT	=>spreg_PATNO,
		sprPRI	=>spreg_PRI,
		
		bgaddr	=>bg_addr,
		bgVR	=>bg_VR,
		bgHR	=>bg_HR,
		bgCOLOR	=>bg_COLOR,
		bgPAT	=>bg_PAT,
		
		patno	=>sp_patno,
		dotx	=>sp_dotx,
		doty	=>sp_doty,
		dotin	=>sp_dot,
		
		rdaddr	=>spr_x(8 downto 0),
		dotout	=>spr_dot,
	
		debugsel	=>dsprbgen,
		
		clk		=>vidclk,
		rstn	=>srstn
	);

	spreg	:sprregs port map(
		addr	=>abus(23 downto 0),
		b_rd	=>b_rd,
		b_wr	=>b_wr,
		wrdat	=>dbus,
		rddat	=>spreg_rdat,
		datoe	=>spreg_doe,

		sprno	=>spreg_sprno,
		xpos	=>spreg_xpos,
		ypos	=>spreg_ypos,
		VR		=>spreg_VR,
		HR		=>spreg_HR,
		COLOR	=>spreg_COLOR,
		PATNO	=>spreg_PATNO,
		PRI		=>spreg_PRI,
		
		BG0Xpos	=>spreg_BG0Xpos,
		BG0Ypos	=>spreg_BG0Ypos,
		BG1Xpos	=>spreg_BG1Xpos,
		BG1Ypos	=>spreg_BG1Ypos,
		DISPEN	=>spreg_DISPEN,
		BG1TXSEL=>spreg_BG1TXSEL,
		BG0TXSEL=>spreg_BG0TXSEL,
		BGON	=>spreg_BGON,
		HTOTAL	=>open,
		HDISP	=>open,
		VDISP	=>open,
		LH		=>open,
		VRES	=>spreg_VRES,
		HRES	=>spreg_HRES,
		
		sclk	=>sysclk,
		vclk	=>vidclk,
		rstn	=>srstn
	);
	
	spmem	:sprram port map(
		addr	=>abus(23 downto 0),
		b_rd	=>b_rd,
		b_wr	=>b_wr,
		wrdat	=>dbus,
		rddat	=>spram_rdat,
		datoe	=>spram_doe,
		
		patno	=>sp_patno,
		dotx	=>sp_dotx,
		doty	=>sp_doty,
		dot		=>sp_dot,
		
		bg_addr	=>bg_addr,
		bg_VR	=>bg_VR,
		bg_HR	=>bg_HR,
		bg_COLOR=>bg_COLOR,
		bg_PAT	=>bg_PAT,
		
		sclk	=>sysclk,
		vclk	=>vidclk,
		rstn	=>srstn
	);

	tpal_cs<='1' when abus(23 downto  9)="111010000010001" else '0';
	
	tpal	:txtpal port map(
		cs		=>tpal_cs,
		addr	=>abus(8 downto 1),
		wdat	=>dbus,
		rdat	=>tpal_rdat,
		datoe	=>tpal_doe,
		rd		=>b_rd,
		wr		=>b_wr,
		
		palno	=>tpal_pno,
		palout	=>tpal_pdat,
		
		sclk	=>sysclk,
		vclk	=>vidclk,
		rstn	=>srstn
	);
	
	process(sysclk,rstn)begin
		if(rstn='0')then
			tpal0_pdat<=(others=>'0');
		elsif(sysclk' event and sysclk='1')then
			if(tpal_cs='1' and abus(8 downto 1)="00000000")then
				if(b_wr(1)='1')then
					tpal0_pdat(15 downto 8)<=dbus(15 downto 8);
				end if;
				if(b_wr(0)='1')then
					tpal0_pdat( 7 downto 0)<=dbus( 7 downto 0);
				end if;
			end if;
		end if;
	end process;

	spal	:txtpal port map(
		cs		=>tpal_cs,
		addr	=>abus(8 downto 1),
		wdat	=>dbus,
		rdat	=>open,
		datoe	=>open,
		rd		=>'0',
		wr		=>b_wr,
		
		palno	=>spal_pno,
		palout	=>spal_pdat,
		
		sclk	=>sysclk,
		vclk	=>vidclk,
		rstn	=>srstn
	);
	
	gpal_cs<='1' when abus(23 downto  9)="111010000010000" else '0';
	
	gpal_skel<='1' when vr_EXON='1' and vr_HP='1' and vr_GG='1' else '0';
	
	gpal	:grpal port map(
		cs		=>gpal_cs,
		addr	=>abus(8 downto 1),
		wdat	=>dbus,
		rdat	=>gpal_rdat,
		datoe	=>gpal_doe,
		rd		=>b_rd,
		wr		=>b_wr,
		
		gmode	=>vr_GR_CMODE(1),
		skel	=>gpal_skel,
		palnoh	=>gpal_pnoh,
		palnol	=>gpal_pnol,
		palout	=>gpal_pdat,
		
		sclk	=>sysclk,
		vclk	=>vidclk,
		rstn	=>srstn
	);

	FD_HDn<=not FD_HD;
	FDT	:FDtiming generic map(FCFREQ) port map(
		drv0sel		=>'0',	--0:300rpm 1:360rpm
		drv1sel		=>'0',
		drv0sele	=>'0',
		drv1sele	=>'0',
	
		drv0hd		=>FD_HDn,
		drv0hdi		=>'1',		--IBM 1.44MB format
		drv1hd		=>FD_HDn,
		drv1hdi		=>'1',		--IBM 1.44MB format
		
		drv0hds		=>open,
		drv1hds		=>open,
		
		drv0int		=>FD_int0,
		drv1int		=>FD_int1,
		
		hmssft		=>FD_hmssft,
		
		clk			=>fdcclk,
		rstn		=>rstn
	);
	
	FDC_DACKn<=not FDC_DACK;
	FDC_CSn<=not FDC_CS;
	fd	:fdcs generic map(
		maxtrack	=>85,
		maxbwidth	=>(BR_300_D*FCFREQ/1000000),
		sysclk		=>FCFREQ/1000
	)
	port map(
		RDn		=>b_rdn,
		WRn		=>b_wrn(0),
		CSn		=>FDC_CSn,
		A0		=>abus(1),
		WDAT	=>dbus(7 downto 0),
		RDAT	=>FDC_WD,
		DATOE	=>FDC_OE,
		DACKn	=>FDC_DACKn,
		DRQ		=>FDC_DRQ,
		TC		=>FDC_TC,
		INTn	=>FDC_INTn,
		WAITIN	=>FDC_WAIT,

		WREN	=>FDC_wrenn,
		WRBIT	=>FDC_wrbitn,
		RDBIT	=>FDC_rdbitn,
		STEP	=>FDC_stepn,
		SDIR	=>FDC_sdirn,
		WPRT	=>FDC_wprotn,
		track0	=>FDC_track0n,
		index	=>FDC_indexn,
		side	=>FDC_siden,
		usel	=>open,
		READY	=>FDC_READYm,
		
		int0	=>FD_int0,
		int1	=>FD_int1,
		int2	=>FD_int0,
		int3	=>FD_int1,
	
		td0		=>'1',
		td1		=>'1',
		td2		=>'1',
		td3		=>'1',
		
		hmssft	=>FD_hmssft,
		
		busy	=>FDC_BUSY,
		mfm		=>FDC_MFM,
		
		ismode	=>'0',
		
		sclk		=>sysclk,
		fclk		=>fdcclk,
		rstn	=>srstn
	);

	FDC_DSKCHG<='0' when FD_USEL(1)='1' else pFD_DSKCHG;
	FDC_INT<=not FDC_INTn;
	
	FDC_USELn<=	--"1111" when FD_MOTOR='0' else
				"1110" when FD_USEL="00" else
				"1101" when FD_USEL="01" else
				"1011" when FD_USEL="10" else
				"0111" when FD_USEL="11" else
				"1111";
	FDC_MOTORn<=not FD_MOTOR & not FD_MOTOR & not FD_MOTOR & not FD_MOTOR;
	
	dchk	:dskchk2d generic map(FCFREQ,300,1,10,500) port map(
		FDC_USELn	=>FD_USELn,
		FDC_BUSY		=>FDC_BUSY or FDCPY_BUSY,
		FDC_MOTORn	=>FD_MOTORn,
		FDC_DIRn		=>FD_DIRn,
		FDC_STEPn	=>FD_STEPn,
		FDC_READYn	=>FDD_READYn,
		FDC_WAIT		=>FDC_WAIT,
		
		FDD_USELn	=>FD_DE,
		FDD_MOTORn	=>FDD_MOTORn,
		FDD_DATAn	=>pFD_RDATAn,
		FDD_INDEXn	=>pFD_INDEXn,
		FDD_DSKCHGn	=>pFD_DSKCHG,
		FDD_DIRn	=>pFD_DIRn,
		FDD_STEPn	=>pFD_STEPn,

		driveen		=>"11",
		f_eject		=>FDD_eject,
		
		indisk		=>FDD_indisk,
		
		hmssft		=>FD_hmssft,
		
		clk			=>fdcclk,
		rstn		=>srstn
	);
--	d2r	:dc2ry generic map(100) port map(
--		USEL	=> FD_USEL,
--		BUSY	=> FDC_BUSY,
--		DSKCHGn	=> FDC_DSKCHG,
--		RDBITn	=> pFD_RDATAn,
--		INDEXn	=> pFD_INDEXn,
--		
--		READYn	=> FD_READY,
--		READYV	=> FDC_RDYv,
--		
--		clk		=> fdcclk,
--		rstn	=> rstn
--	);
	
	FDC_READYm<=FDC_READYn and (not opm_ct2);

	IOU	:IOcont port map(
		addr		=>abus(23 downto 0),
		rdat		=>IOU_rdat,
		wdat		=>dbus(7 downto 0),
		rd			=>b_rd,
		wr			=>b_wr(0),
		datoe		=>IOU_doe,
		int			=>INT1,
		ivect		=>IVECT1,
		iack		=>IACK1,
		iackvect	=>IOU_ivack,
		
		fd_dcontsel	=>open,
		fd_drvled	=>open,
		fd_drveject	=>open,
		fd_drvejen	=>open,
		fd_diskin	=>FDC_indisk,
		fd_diskerr	=>(others=>'0'),
		
		fd_drvsel	=>open,
		fd_usel		=>FD_USEL,
		fd_drvhd	=>FD_HD,
		fd_drvmt	=>FD_MOTOR,
		
		fd_feject	=>FDC_eject,
		fd_LED		=>open,
		fd_lock		=>open,

		fdc_cs		=>FDC_cs,
		fdc_int		=>FDC_INT,

		hdd_int		=>SCSI_INT,
		prn_int		=>'0',
		
		clk			=>sysclk,
		rstn		=>srstn
	);
	SCSI_IACK<='0';
	pFD_DS0<='0' when FD_DE(0)='0' else 'Z';
	pFD_DS1<='0' when FD_DE(1)='0' else 'Z';
	--pFD_MOTOR0<='0' when FDD_MOTORn(0)='0' else 'Z';
	--pFD_MOTOR1<='0' when FDD_MOTORn(1)='0' else 'Z';
	pFD_MOTORON<='0' when (FDD_MOTORn(0)='0' or FDD_MOTORn(1)='0') else 'Z';
	pFD_PIN14<='Z';
	
--	nv	:nvram port map(
--		addr	=>abus(13 downto 1),
--		ce		=>nv_ce,
--		rd		=>b_rd,
--		wr		=>b_wr,
--		wdat	=>dbus,
--		rdat	=>nv_rdat,
--		doe		=>nv_doe,
--		wp		=>nvwp,
--		
--		SCLin	=>I2Csclin,
--		SCLout	=>I2Csclout,
--		SDAin	=>I2Csdain,
--		SDAout	=>I2Csdaout,
--		
--		I2Csft	=>'1',
--		clk		=>sysclk,
--		rstn	=>srstn
--);

	ppi_csn<='0' when abus(23 downto 3)=(x"e9a00" & '0') else '1';

	PPI	: e8255 port map(
		CSn		=>ppi_csn,
		RDn		=>b_rdn,
		WRn		=>b_wrn(0),
		ADR		=>abus(2 downto 1),
		DATIN	=>dbus(7 downto 0),
		DATOUT	=>ppi_odat,
		DATOE	=>ppi_doe,
		
		PAi		=>ppi_pai,
		PAo		=>ppi_pao,
		PAoe	=>ppi_paoe,
		PBi		=>ppi_pbi,
		PBo		=>ppi_pbo,
		PBoe	=>ppi_pboe,
		PCHi	=>ppi_pchi,
		PCHo	=>ppi_pcho,
		PCHoe	=>ppi_pchoe,
		PCLi	=>ppi_pcli,
		PCLo	=>ppi_pclo,
		PCLoe	=>ppi_pcloe,
		
		clk		=>sysclk,
		rstn	=>srstn
	);

	ppi_pai<='1' & pJoyA(5 downto 4) & '1' & pJoyA(3 downto 0);
	ppi_pbi<='1' & pJoyB(5 downto 4) & '1' & pJoyB(3 downto 0);
	pStrA<=ppi_pcho(0) when ppi_pchoe='1' else 'Z';
	pStrB<=ppi_pcho(1) when ppi_pchoe='1' else 'Z';
	pJoyA(4)<='Z' when ppi_pcho(2)='0' else '0';
	pJoyA(5)<='Z' when ppi_pcho(3)='0' else '0';
	pcm_clkdiv<=ppi_pclo(3 downto 2);
	pcm_enL<=not ppi_pclo(0);
	pcm_enR<=not ppi_pclo(1);
	
	process(vidclk,srstn)begin
		if(srstn='0')then
			VID_HRTCd<='0';
		elsif(vidclk' event and vidclk='1')then
			VID_HRTCd<=VID_HRTC;
		end if;
	end process;
	
	VID_HRTCi<=VID_HRTCd and (vr_hfreq or vlineno(0));
	
	mfp_gpip7<=VID_HRTCi;
	mfp_gpip6<=not VID_RINT;
	mfp_gpip5<='1';
	mfp_gpip4<=VID_VVIDEN;
	mfp_gpip3<=opm_intn;
	mfp_gpip2<=pwrsw;
	mfp_gpip1<='1';
	mfp_gpip0<=not rtc_alarm;
	mfp_tai<=not VID_VVIDEN;

	UMFP	:MFP generic map(SCFREQ) port map(
		addr	=>abus(23 downto 0),
		rdat	=>mfp_odat,
		wdat	=>dbus(7 downto 0),
		rd		=>b_rd,
		wr		=>b_wr(0),
		datoe	=>mfp_doe,
		
		KBCLKIN	=>kb_clkin,
		KBCLKOUT=>kb_clkout,
		KBDATIN	=>kb_datin,
		KBDATOUT=>kb_datout,
		KBWAIT	=>'0',
		KBen	=>open,
		KBLED	=>open,

		kbsel	=>dem_conten,
		kbout	=>dem_kbdat,
		kbrx	=>dem_kbrx,

	
		GPIPI7	=>mfp_gpip7,
		GPIPI6	=>mfp_gpip6,
		GPIPI5	=>mfp_gpip5,
		GPIPI4	=>mfp_gpip4,
		GPIPI3	=>mfp_gpip3,
		GPIPI2	=>mfp_gpip2,
		GPIPI1	=>mfp_gpip1,
		GPIPI0	=>mfp_gpip0,

		GPIPO7	=>open,
		GPIPO6	=>open,
		GPIPO5	=>open,
		GPIPO4	=>open,
		GPIPO3	=>open,
		GPIPO2	=>open,
		GPIPO1	=>open,
		GPIPO0	=>open,

		GPIPD7	=>open,
		GPIPD6	=>open,
		GPIPD5	=>open,
		GPIPD4	=>open,
		GPIPD3	=>open,
		GPIPD2	=>open,
		GPIPD1	=>open,
		GPIPD0	=>open,

		TAI		=>mfp_tai,
		TAO		=>open,

		TBI		=>'0',
		TBO		=>open,

		TCO		=>open,

		TDO		=>open,

		INT		=>INT6,
		IVECT	=>IVECT6,
		INTack	=>IACK6,
		IVack	=>mfp_ivack,
			
		clk		=>sysclk,
		rstn	=>srstn
	);
	
	scc_u	:scc generic map(
		CLKCYC	=>SCFREQ
	)port map(
		addr	=>abus(23 downto 0),
		rd		=>b_rd,
		wr		=>b_wr(0),
		wdat	=>dbus(7 downto 0),
		rdat	=>scc_odat,
		doe		=>scc_doe,
		int		=>INT5,
		ivect	=>IVECT5,
		iack	=>IACK5,

		mclkin	=>ms_clkin,
		mclkout	=>ms_clkout,
		mdatin	=>ms_datin,
		mdatout	=>ms_datout,
		
		clk		=>sysclk,
		rstn	=>srstn
	);

	
	opm_cen<='0' when abus(23 downto 2)="1110100100000000000000" else '1';
	
--	process(sysclk,rstn)begin
--		if(rstn='0')then
--			opm_sft<='0';
--		elsif(sysclk' event and sysclk='1')then
--			opm_sft<=not opm_sft;
--		end if;
--	end process;
	
	dopmonoff<=	pDip(9 downto 2) when DEBUG(DBIT_OPMCH_ONOFF)='1' else
					(others=>'1');

    FM:OPM_JT51 generic map(16) port map( -- If you want to use OPM_JT51.vhd, replace OPM with OPM_JT51
    -- FM:OPM generic map(16) port map(
		DIN		=>dbus(7 downto 0),
		DOUT	=> opm_odat,
		DOE		=>opm_doe,
		CSn		=>opm_cen,
		ADR0	=>abus(1),
		RDn		=>b_rdn,
		WRn		=>b_wrn(0),
		INTn	=> opm_intn,
		
		sndL	=>opm_sndl,
		sndR	=>opm_sndr,
		
		CT1		=>pcm_clkmode,
		CT2		=>opm_ct2,
		
	--	monout	:out std_logic_vector(15 downto 0);
		chenable	=>dopmonoff,

		fmclk		=>sndclk,
		pclk		=>sysclk,
		rstn	=>srstn
	);
	
	--opm_doe    <= '1' when opm_cen='0' and b_rdn='0' else '0';
	opm_data_d <= pOPM_DATA;
	--opm_odat   <= opm_data_d;
	pOPM_RD_n  <= '1'; --'0' when opm_cen='0' and b_rdn='0' else '1';
	pOPM_RST   <= not srstn;
	pOPM_CLK   <= opm_clk_divider(2);

	process(sysclk,srstn)begin
		if(srstn='0')then
			opm_irq_n_d <= '1';
			--opm_intn    <= '1';
			opm_wr_n_d <= '1';
		elsif(sysclk' event and sysclk='1')then
			opm_irq_n_d <= pOPM_IRQ_n;
			--opm_intn    <= opm_irq_n_d;
			if(opm_cen='0' and b_wrn(0)='0')then
				pOPM_A0    <= abus(1);
				pOPM_DATA(7 downto 0) <= dbus(7 downto 0);
				pOPM_WR_n  <= '0';
				opm_wr_n_d <= '0';
			elsif(opm_wr_n_d='0')then
				-- keep pOPM_DATA and pOPM_A0 for 1 clock period.
				pOPM_WR_n  <= '1';
				opm_wr_n_d <= '1';
			else
				pOPM_A0    <= abus(1);
				pOPM_DATA(7 downto 0) <= (others=>'Z');
				pOPM_WR_n  <= '1';
				opm_wr_n_d <= '1';
			end if;
		end if;
   end process;

    -- fmclk 4mhz
    -- On X68000, YM2151 is driven by 4MHz.
    process(sndclk,srstn)begin
        if(srstn='0')then
            opm_clk_divider <= (others => '0');
        elsif(sndclk' event and sndclk='1')then
            opm_clk_divider <= opm_clk_divider + 1;
        end if;
    end process;
	
	em3012_0 :EM3012 port map (
        CLK_PHY1  => pOPM_CLK_PHY1,
        SDATA     => pOPM_SDATA,
        SAM_HOLD1 => pOPM_SAM_HOLD1,
        SAM_HOLD2 => pOPM_SAM_HOLD2,

        -- system side
        sndL      => em3012_sndL,
        sndR      => em3012_sndR,

        fmclk     => sndclk,
        rstn	  => srstn
	);

	--
	--
	--
	pcm_ce<='1' when abus(23 downto 2)="1110100100100000000000" else '0';
	pcm_wr<=b_wr(0) when pcm_ce='1' else '0';
	pcm_doe<=b_rd when pcm_ce='1' else '0';
		
	pcmc	:pcmclk port map(
		clkmode	=>pcm_clkmode,
		pcmsft	=>pcm_sft,
		
		clk		=>sndclk,
		rstn		=>srstn
	);
	
	pcm	:e6258 port map(
		addr		=>abus(1),
		datin		=>dbus(7 downto 0),
		datout	=>pcm_odat,
		datwr		=>pcm_wr,
		drq		=>pcm_drq,
		
		clkdiv	=>pcm_clkdiv,
		sft		=>pcm_sft,
		
		sndout	=>pcm_snd,
		
		sysclk	=>sysclk,
		sndclk	=>sndclk,
		rstn		=>srstn
	);
	
	pcm_sndL<=(pcm_snd(11) & pcm_snd & "000") when pcm_enL='1' else (others=>'0');
	pcm_sndR<=(pcm_snd(11) & pcm_snd & "000") when pcm_enR='1' else (others=>'0');
	
	process(sndclk,srstn)
	variable	sclk	:std_logic;
	begin
		if(srstn='0')then
			sclk:='0';
			opm_wstate<=0;
		elsif(sndclk' event and sndclk='1')then
			case opm_wstate is
			when 0 =>
				if(opm_cen='0' and (b_wrn(0)='0' or b_rdn='0'))then
					opm_wstate<=1;
				end if;
			when 1 =>
				opm_wstate<=2;
			when 2 =>
				if(opm_cen='1')then
					opm_wstate<=0;
				end if;
			when others =>
				opm_wstate<=0;
			end case;
			sclk:=sndclk;
		end if;
	end process;
	
	iowait_opm<='1' when (opm_cen='0' and (b_wrn(0)='0' or b_rdn='0') and opm_wstate/=2) else '0';

	process(sndclk,srstn)
	begin
		if(srstn='0')then
			opm_sndL_sel <= (others => '0');
			opm_sndR_sel <= (others => '0');
		elsif(sndclk' event and sndclk='1') then
		    case pOPM_SEL_L is
			     when '0' => opm_sndL_sel <= em3012_sndL(15) & em3012_sndL(15 downto 1);
			     when '1' => opm_sndL_sel <= opm_sndL(15)    & opm_sndL(   15 downto 1);
	       end case;
		    case pOPM_SEL_R is
			     when '0' => opm_sndR_sel <= em3012_sndR(15) & em3012_sndR(15 downto 1);
			     when '1' => opm_sndR_sel <= opm_sndR(15)    & opm_sndR(   15 downto 1);
	       end case;
		end if;
	end process;

--   opm_sndL_sel <= opm_sndL(15) & opm_sndL(15 downto 1);
--   opm_sndR_sel <= opm_sndR(15) & opm_sndR(15 downto 1);

	mixL	:addsat generic map(16) port map(opm_sndL_sel,pcm_sndL,mix_sndL,open,open);
	mixR	:addsat generic map(16) port map(opm_sndR_sel,pcm_sndR,mix_sndR,open,open);

	dacs	:sftclk generic map(ACFREQ,DACFREQ,1) port map("1",dacsft,sndclk,srstn);
	
	sndL<=mix_sndL;-- when pDip(7 downto 6)="11" else
--			opm_sndL when pDip(7 downto 6)="10" else
--			pcm_sndL	when pDip(7 downto 6)="01" else
--			(others=>'0');

	sndR<=mix_sndR;-- when pDip(7 downto 6)="11" else
--			opm_sndR when pDip(7 downto 6)="10" else
--			pcm_sndR	when pDip(7 downto 6)="01" else
--			(others=>'0');
	
	
	DacL	:deltasigmadac generic map(16) port map(
		data	=>(not sndL(15)) & sndL(14 downto 0),
		datum	=>pDac_SL,
		
		sft	=>dacsft,
		clk	=>sndclk,
		rstn	=>srstn
	);
	DacR	:deltasigmadac generic map(16) port map(
		data	=>(not sndR(15)) & sndR(14 downto 0),
		datum	=>pDac_SR,
		
		sft	=>dacsft,
		clk	=>sndclk,
		rstn	=>srstn
	);

--opm_doe<='1' when opm_cen='0' and b_rdn='1' else '0';
	
	
	pPs2Clk<='Z' when kb_clkout='1' else '0';
	pPs2Dat<='Z' when kb_datout='1' else '0';
	pPmsClk<='Z' when ms_clkout='1' else '0';
	pPmsDat<='Z' when ms_datout='1' else '0';
	process(sysclk,srstn)begin
		if(srstn='0')then
			kb_clkin<='1';
			kb_datin<='1';
			ms_clkin<='1';
			ms_datin<='1';
		elsif(sysclk' event and sysclk='1')then
			kb_clkin<=pPs2Clk;
			kb_datin<=pPs2Dat;
			ms_clkin<=pPmsClk;
			ms_datin<=pPmsDat;
		end if;
	end process;

	rtc_cs<='1' when abus(23 downto 5)=(x"e8a0" & "000") else '0';
	rtc_doe<=b_rd when rtc_cs='1' else '0';
	rtc_wr<=b_wr(0) when rtc_cs='1' else '0';

	rtc	:rp5c15 generic map(SCFREQ*1000) port map(
		addr	=>abus(4 downto 1),
		wdat	=>dbus(3 downto 0),
		rdat	=>rtc_odat,
		wr		=>rtc_wr,
		
		clkout	=>open,
		alarm	=>rtc_alarm,
		
	--I2C I/F
		TXOUT	=>I2C_TXDAT_PXY(0),
		RXIN	=>I2C_RXDAT_PXY(0),
		WRn		=>I2C_WRn_PXY(0),
		RDn		=>I2C_RDn_PXY(0),

		TXEMP	=>I2C_TXEMP_PXY(0),
		RXED	=>I2C_RXED_PXY(0),
		NOACK	=>I2C_NOACK_PXY(0),
		COLL	=>I2C_COLL_PXY(0),
		NX_READ	=>I2C_NX_READ_PXY(0),
		RESTART	=>I2C_RESTART_PXY(0),
		START	=>I2C_START_PXY(0),
		FINISH	=>I2C_FINISH_PXY(0),
		F_FINISH=>I2C_F_FINISH_PXY(0),
		INIT	=>I2C_INIT_PXY(0),

		clk		=>sysclk,
		rstn	=>srstn
	);

	--
	-- LED driver 
	--
	tlc59116 :I2C_TLC59116 port map(
		-- I2C I/F
		TXOUT	=>I2C_TXDAT_PXY(1),
		RXIN	=>I2C_RXDAT_PXY(1),
		WRn		=>I2C_WRn_PXY(1),
		RDn		=>I2C_RDn_PXY(1),

		TXEMP	=>I2C_TXEMP_PXY(1),
		RXED	=>I2C_RXED_PXY(1),
		NOACK	=>I2C_NOACK_PXY(1),
		COLL	=>I2C_COLL_PXY(1),
		NX_READ	=>I2C_NX_READ_PXY(1),
		RESTART	=>I2C_RESTART_PXY(1),
		START	=>I2C_START_PXY(1),
		FINISH	=>I2C_FINISH_PXY(1),
		F_FINISH=>I2C_F_FINISH_PXY(1),
		INIT	=>I2C_INIT_PXY(1),

		-- LED Control Ports
		LEDMODES => ledmodes,

		clk		=>sysclk,
		rstn	=>srstn
	);

	FP: X68_FRONTPANEL_CONTROLLER port map(
		LED_POWER       => LED_POWER,
		LED_HD_BUSY     => LED_HD_BUSY,
		LED_TIMER       => LED_TIMER,
		LED_FDD0_ACCESS => LED_FDD0_ACCESS,
		LED_FDD1_ACCESS => LED_FDD1_ACCESS,
		LED_FDD0_EJECT  => LED_FDD0_EJECT,
		LED_FDD1_EJECT  => LED_FDD1_EJECT,

		-- to TLC59116 module
		LEDMODES        => ledmodes,

		clk		=>sysclk,
		rstn	=>srstn
	);

	process(sysclk,srstn)begin
		if(srstn='0')then
			LED_POWER		<="11";
			LED_HD_BUSY     <= '0';
			LED_TIMER       <= '0';
			LED_FDD0_ACCESS <= "00";
			LED_FDD0_EJECT  <= '0';
			LED_FDD1_ACCESS <= "00";
			LED_FDD1_EJECT  <= '0';
		elsif(sysclk' event and sysclk='1')then
			LED_HD_BUSY     <= '0';
			-- pwrswは実機のフロント電源スイッチの状態（'0'の時オン、'1'の時オフ）
			-- willrstは電源がOFFになってからPLLが止まるまでの0.5秒ほどの期間'1'、通常は'0'
			if(pwrsw='0' and willrst='0')then
				-- 通常状態(電源ランプグリーン)
				LED_POWER<="11";
				if(SCSI_BSY='1')then
					LED_HD_BUSY<='1';
				end if;
				 if(FDD_INDISK(0)='0')then
					LED_FDD0_ACCESS	<="00";
					LED_FDD0_EJECT  	<= '0';
				else
					LED_FDD0_EJECT  	<= '1';
					if(FD_MOTOR='1' and FD_USEL="00")then
						LED_FDD0_ACCESS<="10";
					else
						LED_FDD0_ACCESS<="11";
					end if;
				end if;
				if(FDD_INDISK(1)='0')then
					LED_FDD1_ACCESS	<="00";
					LED_FDD1_EJECT  	<= '0';
				else
					LED_FDD1_EJECT  	<= '1';
					if(FD_MOTOR='1' and FD_USEL="01")then
						LED_FDD1_ACCESS<="10";
					else
						LED_FDD1_ACCESS<="11";
					end if;
				end if;
			elsif(pwrsw='1' and willrst='0')then
				-- シャットダウン中（電源ランプグリーン点滅）
				LED_POWER<="10";
			elsif(pwrsw='1' and willrst='1')then
				-- シャットダウン完了（電源ランプ赤、その他消灯）
				LED_POWER<="01";
				LED_HD_BUSY     <= '0';
				LED_TIMER       <= '0';
				LED_FDD0_ACCESS <= "00";
				LED_FDD0_EJECT  <= '0';
				LED_FDD1_ACCESS <= "00";
				LED_FDD1_EJECT  <= '0';
			else
				-- その他（想定外、全消灯）
				LED_POWER<="00";
				LED_HD_BUSY     <= '0';
				LED_TIMER       <= '0';
				LED_FDD0_ACCESS <= "00";
				LED_FDD0_EJECT  <= '0';
				LED_FDD1_ACCESS <= "00";
				LED_FDD1_EJECT  <= '0';
			end if;
		end if;
	end process;

	--
	-- I2C Interface
	--
	I2C	:I2CIF port map(
		DATIN	=>I2C_TXDAT,
		DATOUT	=>I2C_RXDAT,
		WRn		=>I2C_WRn,
		RDn		=>I2C_RDn,

		TXEMP	=>I2C_TXEMP,
		RXED	=>I2C_RXED,
		NOACK	=>I2C_NOACK,
		COLL	=>I2C_COLL,
		NX_READ	=>I2C_NX_READ,
		RESTART	=>I2C_RESTART,
		START	=>I2C_START,
		FINISH	=>I2C_FINISH,
		F_FINISH=>I2C_F_FINISH,
		INIT	=>I2C_INIT,
		

		SDAIN 	=>SDAIN,
		SDAOUT	=>SDAOUT,
		SCLIN	=>SCLIN,
		SCLOUT	=>SCLOUT,

		SFT		=>I2CCLKEN,
		clk		=>sysclk,
		rstn 	=>srstn
	);

	I2CMUX :I2C_MUX generic map(NUM_DRIVERS=>NUM_DRIVERS) port map(
		-- I2C
		TXOUT   => I2C_TXDAT,
		RXIN    => I2C_RXDAT,
		WRn     => I2C_WRn,
		RDn     => I2C_RDn,
    
		TXEMP   => I2C_TXEMP,
		RXED	=> I2C_RXED,
		NOACK	=> I2C_NOACK,
		COLL	=> I2C_COLL,
		NX_READ	=> I2C_NX_READ,
		RESTART	=> I2C_RESTART,
		START	=> I2C_START,
		FINISH	=> I2C_FINISH,
		F_FINISH=> I2C_F_FINISH,
		INIT	=> I2C_INIT,
    
		-- for Driver
		DATIN_PXY   => I2C_TXDAT_PXY,
		DATOUT_PXY	=> I2C_RXDAT_PXY,
		WRn_PXY		=> I2C_WRn_PXY,
		RDn_PXY		=> I2C_RDn_PXY,
    
		TXEMP_PXY   => I2C_TXEMP_PXY,
		RXED_PXY	=> I2C_RXED_PXY,
		NOACK_PXY	=> I2C_NOACK_PXY,
		COLL_PXY	=> I2C_COLL_PXY,
		NX_READ_PXY	=> I2C_NX_READ_PXY,
		RESTART_PXY	=> I2C_RESTART_PXY,
		START_PXY	=> I2C_START_PXY,
		FINISH_PXY	=> I2C_FINISH_PXY,
		F_FINISH_PXY => I2C_F_FINISH_PXY,
		INIT_PXY	=> I2C_INIT_PXY,
    
		clk			=> sysclk,
		rstn		=> srstn
	);

	pI2CSCL <= '0' when SCLOUT='0' else 'Z';
	pI2CSDA <= '0' when SDAOUT='0' else 'Z';
	process(sysclk,srstn)begin
		if(srstn='0')then
			SCLIN<='1';
			SDAIN<='1';
		elsif(sysclk' event and sysclk='1')then
			SCLIN<=pI2CSCL;
			SDAIN<=pI2CSDA;
		end if;
	end process;

	I2CCLK :sftclk
	generic map(SCFREQ,800,1)
	port map(
		SEL => "0",
		SFT =>I2CCLKEN,
		CLK =>sysclk,
		RSTN => srstn
	);

	INT2<='0';
	INT4<='0';
	IVECT2<=(others=>'0');
	IVECT4<=(others=>'0');

	INT7<=not pPsw(1);

	pSd_ck<=	SDC_SCLK;
	pSd_Cm<=	SDC_DI;
	pSd_Dt(3)<=	SDC_CS;
	SDC_DO<=	pSd_Dt(0);
	
	midi_cs<='1' when abus(23 downto 4)=x"eafa0" else '0';
	midi_rd<=b_rd when midi_cs='1' else '0';
	midi_wr<=b_wr(0) when midi_cs='1' else '0';
	midi_doe<=midi_rd;
	
	midi	:em3802 generic map(
		sysclk	=>SCFREQ,
		oscm		=>1000,
		oscf		=>614
	)port map(
		ADDR	=>abus(3 downto 1),
		DATIN	=>dbus(7 downto 0),
		DATOUT=>midi_odat,
		DATWR	=>midi_wr,
		DATRD	=>midi_rd,
		INT	=>midi_int,
		IVECT	=>midi_ivect,

		RxD	=>pMidi_in,
		TxD	=>pMidi_out,
		RxF	=>'1',
		TxF	=>open,
		SYNC	=>open,
		CLICK	=>open,
		GPOUT	=>open,
		GPIN	=>(others=>'1'),
		GPOE	=>open,
		
		clk	=>sysclk,
		rstn	=>srstn
	);

	-- 0xE96020 for internal SCSI (after X68000 SUPER)
	-- 0xEA0000 for external SCSI board (CZ-6BS1)
	SCSI_CS<='1' when abus(23 downto 5)=(x"e960" & "001") else '0';
	
	SCSI	:scsiif port map(
		cs		=>SCSI_CS,
		addr	=>abus(4 downto 1),
		rd		=>b_rd,
		wr		=>b_wr(0),
		wdat	=>dbus(7 downto 0),
		rdat	=>SCSI_RDAT,
		doe		=>SCSI_DOE,
		int		=>SCSI_INT,
		iack	=>SCSI_IACK,
		drq		=>SCSI_DRQ,
		dack	=>SCSI_DACK,
		iowait	=>iowait_scsi,
		
		IDAT	=>SCSI_C2H,
		IDATp	=>'0',
		ODAT	=>SCSI_H2C,
		ODATp	=>open,
		ODEN	=>open,
		SEL		=>SCSI_SEL,
		BSY		=>SCSI_BSYf,
		REQ		=>SCSI_REQf,
		ACK		=>SCSI_ACK,
		IO		=>SCSI_IOf,
		CD		=>SCSI_CDf,
		MSG		=>SCSI_MSGf,
		RST		=>SCSI_RST,
		
		clk		=>sysclk,
		rstn	=>srstn
	);
	SELf	:digifilter generic map(2,'0') port map(SCSI_SEL,SCSI_SELf,emuclk,srstn);
	BSYf	:digifilter generic map(2,'0') port map(SCSI_BSY,SCSI_BSYf,sysclk,srstn);
	REQf	:digifilter generic map(2,'0') port map(SCSI_REQ,SCSI_REQf,sysclk,srstn);
	ACKf	:digifilter generic map(2,'0') port map(SCSI_ACK,SCSI_ACKf,emuclk,srstn);
	IOf		:digifilter generic map(2,'0') port map(SCSI_IO,SCSI_IOf,sysclk,srstn);
	CDf		:digifilter generic map(2,'0') port map(SCSI_CD,SCSI_CDf,sysclk,srstn);
	MSGf	:digifilter generic map(2,'0') port map(SCSI_MSG,SCSI_MSGf,sysclk,srstn);
	RSTf	:digifilter generic map(2,'0') port map(SCSI_RST,SCSI_RSTf,emuclk,srstn);
	
	DISKE	:diskemuunit generic map(
		clkfreq		=>FCFREQ,
		VLwidth		=>6,
		VCwidth		=>7
	)port map(
	--video
		vaddr		=>dem_tramamod,
		vdata		=>dem_tramdat,
		vcursor_L	=>dem_curl,
		vcursor_C	=>dem_curc,
		vcursoren	=>dem_curen,

	--Keyboard
		kbdat		=>dem_kbdat,
		kbrx		=>dem_kbrx,

	--SDcard
		sdc_miso	=>SDC_DO,
		sdc_mosi	=>SDC_DI,
		sdc_sclk	=>SDC_SCLK,
		sdc_cs		=>SDC_CS,
		
	--SCSI
		sasi_din	=>SCSI_H2C,
		sasi_dout	=>SCSI_C2H,
		sasi_sel	=>SCSI_SELf,
		sasi_bsy	=>SCSI_BSY,
		sasi_req	=>SCSI_REQ,
		sasi_ack	=>SCSI_ACKf,
		sasi_io		=>SCSI_IO,
		sasi_cd		=>SCSI_CD,
		sasi_msg	=>SCSI_MSG,
		sasi_rst	=>SCSI_RSTf,

	--FDD
		fdc_useln	=>FDC_USELn,
		fdc_motorn	=>FDC_MOTORn,
		fdc_readyn	=>FDC_READYn,
		fdc_wrenn	=>FDC_wrenn,
		fdc_wrbitn	=>FDC_wrbitn,
		fdc_rdbitn	=>FDC_rdbitn,
		fdc_stepn	=>FDC_stepn,
		fdc_sdirn	=>FDC_sdirn,
		fdc_track0n	=>FDC_track0n,
		fdc_indexn	=>FDC_indexn,
		fdc_siden	=>FDC_siden,
		fdc_wprotn	=>FDC_wprotn,
		fdc_eject	=>FDC_eject,
		fdc_indisk	=>FDC_indisk,
		fdc_trackwid=>'1',
		fdc_dencity	=>FD_HDn,
		fdc_rpm		=>'1',
		fdc_mfm		=>FDC_MFM,
		
		fdd_useln	=>FD_USELn,
		fdd_motorn	=>FD_MOTORn,
		fdd_readyn	=>FDD_READYn,
		fdd_wrenn	=>pFd_WGATEn,
		fdd_wrbitn	=>pFd_WDATAn,
		fdd_rdbitn	=>pFd_RDATAn,
		fdd_stepn	=>FD_STEPn,
		fdd_sdirn	=>FD_DIRn,
		fdd_track0n	=>pFd_TRK00n,
		fdd_indexn	=>pFd_INDEXn,
		fdd_siden	=>pFd_SIDE1n,
		fdd_wprotn	=>pFd_WPTn,
		fdd_eject	=>FDD_eject,
		fdd_indisk	=>FDD_indisk,
		fdd_cpyen	=>FDCPY_BUSY,

	--FD emulator
		fde_tracklen=>dem_fdetracklen,
		fde_ramaddr	=>dem_fderamaddr,
		fde_ramrdat	=>dem_fderamrdat,
		fde_ramwdat	=>dem_fderamwdat,
		fde_ramwr	=>dem_fderamwr,
		fde_ramwait	=>'0',
		fec_ramaddrh =>dem_fecramaddrh,
		fec_ramaddrl =>dem_fecramaddrl,
		fec_ramwe	=>dem_fecramwe,
		fec_ramrdat	=>dem_fecramwdat,
		fec_ramwdat	=>dem_fecramrdat,
		fec_ramrd	=>dem_fecramrd,
		fec_ramwr	=>dem_fecramwr,
		fec_rambusy	=>dem_fecrambusy,
	--SRAM
		sram_cs		=>nv_ce,
		sram_addr	=>abus(13 downto 1),
		sram_rdat	=>nv_rdat,
		sram_wdat	=>dbus,
		sram_rd		=>b_rd,
		sram_wr		=>b_wr,
		sram_wp		=>nv_wren,
		
	--common
		model		=>x"02",
		initdone	=>dem_initdone,
		busy		=>pLed(0),
		pclk		=>emuclk,
		vclk		=>vidclk,
		fclk		=>fdcclk,
		sclk		=>sysclk,
		rclk		=>ramclk,
		rstn		=>dem_rstn
	);
	
	nv_wren<=	'0' when nvwp/=x"31" else
				'0' when nv_ce='0' else
				'1' when b_wr/="00" else
				'0';
				
	nv_doe<=b_rd when nv_ce='1' else '0';
	
	SCSI_BUSY<=SCSI_BSY;
	
	pLed(6 downto 2)<=INT7 & INT6 & INT5 & INT3 & INT1;
	
	monseg<=mpu_addr(23 downto 0);
	
	MSEG5	:HEX2SEGn port map(monseg(23 downto 20),'0',Seg5);
	MSEG4	:HEX2SEGn port map(monseg(19 downto 16),'0',Seg4);
	MSEG3	:HEX2SEGn port map(monseg(15 downto 12),'0',Seg3);
	MSEG2	:HEX2SEGn port map(monseg(11 downto  8),'1',Seg2);
	MSEG1	:HEX2SEGn port map(monseg( 7 downto  4),'0',Seg1);
	MSEG0	:HEX2SEGn port map(monseg( 3 downto  0),'0',Seg0);

	pSeg0<=(others=>'1') when pwr_rstn='0' else Seg0;
	pSeg1<=(others=>'1') when pwr_rstn='0' else Seg1;
	pSeg2<=(others=>'1') when pwr_rstn='0' else Seg2;
	pSeg3<=(others=>'1') when pwr_rstn='0' else Seg3;
	pSeg4<=(others=>'1') when pwr_rstn='0' else Seg4;
	pSeg5<=(others=>'1') when pwr_rstn='0' else Seg5;
	
	pFD_DENn<=pDip(2);
	
--	hang	:hangmon generic map(100) port map(
--		addr	=>abus,
--		data	=>dbus,
--		rd		=>b_rd,
--		wr		=>b_wr,
--		ack	=>b_ack,
--		drq	=>(others=>'0'),
--		irq	=>mpu_ipl,
--		
--		evnum	=>open,
--		eaddr	=>open,
--		edata	=>open,
--		erd	=>open,
--		ewr	=>open,
--		edrq	=>open,
--		eirq	=>open,
--		
--		hang	=>phang,
--		
--		sclk	=>sysclk,
--		mclk	=>ramclk,
--		rstn	=>srstn
--	);

	pF68kIO_I2S_BICK <= i2sclk;

	i2s_sndL(31 downto 16) <= sndL;
	i2s_sndR(31 downto 16) <= sndR;
	i2s_sndL(15 downto 0) <= (others => '0');
	i2s_sndL(15 downto 0) <= (others => '0');

    I2S	: i2s_encoder port map(
		snd_clk     => sndclk,
		snd_L       => i2s_sndL,
		snd_R       => i2s_sndR,
	
		i2s_data    => pF68kIO_I2S_DATA,
		i2s_lrck    => pF68kIO_I2S_LRCK,
		
		i2s_bclk    => i2sclk,
		rstn		=> srstn
	);

end rtl;
