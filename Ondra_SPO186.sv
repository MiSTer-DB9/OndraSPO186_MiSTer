//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + USER_PP, USER_IN/OUT widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

//assign ADC_BUS  = 'Z;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driver
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = 1'b0;            // 1P-only: joy_2p unused
wire         snac_active     = 1'b0;
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire         pad_1_6btn, pad_2_6btn;
wire  [15:0] joy_raw_payload;

// [MiSTer-DB9 BEGIN] - DB9 programmable-remap matrix wires
// joydb_*_mapped = MiSTer-standard joystick words (consumed in Layer B);
// db9_remap_* = 0xFD selector stream driven by the hps_io instance.
wire  [15:0] joydb_1_mapped, joydb_2_mapped;
wire         db9_remap_cmd;
wire   [5:0] db9_remap_byte_cnt;
wire  [15:0] db9_remap_din;
// [MiSTer-DB9 END]
joydb joydb (
  .clk             ( CLK_JOY         ),
  .clk_sys         ( clk_sys            ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .remap_cmd       ( db9_remap_cmd      ),
  .remap_byte_cnt  ( db9_remap_byte_cnt ),
  .remap_din       ( db9_remap_din      ),
  .joydb_1_mapped  ( joydb_1_mapped     ),
  .joydb_2_mapped  ( joydb_2_mapped     ),
  .pad_1_6btn      ( pad_1_6btn      ),
  .pad_2_6btn      ( pad_2_6btn      ),
  .joy_raw         ( joy_raw_payload )
);

assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]

assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {UART_RTS, UART_DTR} = 0;

//assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;

assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign AUDIO_S = 0;
assign AUDIO_MIX = 3;

wire LED_GREEN;
wire LED_YELLOW;
wire LED_RED;

assign LED_POWER = { 1'b1, LED_GREEN };
assign LED_USER  = LED_RED;
assign LED_DISK  = { 1'b1, LED_YELLOW };
assign BUTTONS   = 0;


//////////////////////////////////////////////////////////////////

assign VIDEO_ARX = 8'd4;
assign VIDEO_ARY = 8'd3;

`include "build_id.v"
localparam CONF_STR = {
   "Ondra SPO 186;;",
   "-;",
   "O56,ROM,ViLi,Tesla v5,Ondra PLUS 1.4,Test ROM;",
   "-;",
   "O7,ADC line pass through,On,Off;",
   "O8,Cassette out to audio,On,Off;",
   "-;",
   "O9,Ondra SD,On,Off;",
   "OA,Ondra Melodik,On,Off;",
   "-;",
   "R0,Reset Ondra;",
   // [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
   "-;",
   "O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
   // [MiSTer-DB9-Pro END]
   "J,Fire 1;",
   "V,v",`BUILD_DATE
};

wire  [1:0] buttons;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: status widened to 128 bits
wire [127:0] status;
// [MiSTer-DB9 END]
wire [10:0] ps2_key;

wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_data;
wire        ioctl_download;
wire  [7:0] ioctl_index;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USB-side joystick renamed + joydb mux
wire [15:0] joy_USB;
wire [15:0] joy = joydb_1ena ? (OSD_STATUS ? 16'b0 : joydb_1_mapped[15:0]) : joy_USB;
// [MiSTer-DB9 END]
// RTC MSM6242B layout
(* keep *) wire [64:0] RTC;


hps_io #(.CONF_STR(CONF_STR), .STRLEN($size(CONF_STR)>>3)) hps_io
(
   .clk_sys(clk_sys),
   .HPS_BUS(HPS_BUS),

   .buttons(buttons),
   .status(status),
   .ps2_key(ps2_key),
   // [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USB-side joystick renamed
   .joystick_0(joy_USB),
   // [MiSTer-DB9 END]
   // [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw for OSD autodetect
   .joy_raw(OSD_STATUS ? joy_raw_payload : 16'b0),
   // programmable remap matrix selector load (UIO_DB9_MAP 0xFD)
   .db9_remap_cmd(db9_remap_cmd),
   .db9_remap_byte_cnt(db9_remap_byte_cnt),
   .db9_remap_din(db9_remap_din),
   // [MiSTer-DB9 END]
   // [MiSTer-DB9-Pro BEGIN] - Saturn key gate
   .saturn_unlocked(saturn_unlocked),
   // [MiSTer-DB9-Pro END]
   .RTC(RTC),

   .ioctl_wr(ioctl_wr),
   .ioctl_addr(ioctl_addr),
   .ioctl_dout(ioctl_data),
   .ioctl_download(ioctl_download),
   .ioctl_index(ioctl_index)
);



//-------------------------------------------------------------------------------
//  Clocks
//
wire locked;
wire clk_sys;  // 8 MHz Ondra sys clock
wire clk_snen; // 4 MHz Ondra MELODIK - sn76489_audio

pll pll
(
   .refclk(CLK_50M),
   .rst(0),
   .outclk_0(clk_sys),
   .outclk_1(clk_snen),
   .locked(locked)
);

wire reset = RESET | status[0] | buttons[1];


//-------------------------------------------------------------------------------
//  Cassette audio in
//
wire tape_adc, tape_adc_act;

ltc2308_tape ltc2308_tape
(
   .clk(CLK_50M),
   .ADC_BUS(ADC_BUS),
   .dout(tape_adc),
   .active(tape_adc_act)
);


//-------------------------------------------------------------------------------
//  Ondra MELODIK - sn76489_audio
//
wire  [7:0] Parallel_Data_OUT;
wire        NON_STB;
wire [13:0] mix_audio_o;
reg         ondra_melodik_clk_enable;


always @(posedge reset or negedge NON_STB)
begin
  if (reset)
    ondra_melodik_clk_enable <= 1'b0;
  else
    ondra_melodik_clk_enable <= 1'b1 & ~status[10];
end

sn76489_audio #(.MIN_PERIOD_CNT_G(17)) sn76489_audio
(  .clk_i(clk_sys),                                     //System clock
   .en_clk_psg_i(clk_snen & ondra_melodik_clk_enable),  //PSG clock enable
   .ce_n_i(0),                                          //chip enable, active low
   .wr_n_i(NON_STB),                                    // write enable, active low
   .data_i(Parallel_Data_OUT),
   .mix_audio_o(mix_audio_o)
);


//------------------------------------------------------------
//  Keyboard controls
//

reg kbd_reset               = 1'b0;
reg kbd_ROM_change          = 1'b0;
reg kbd_scandoublerOverride = 1'b0;
reg old_stb                 = 1'b0;
reg kbd_enter               = 1'b0;

wire       pressed      = ps2_key [9];
wire       input_strobe = ps2_key[10];
wire       extended     = ps2_key [8];
wire [7:0] scancode     = ps2_key[7:0];

always @(posedge clk_sys)
begin
   old_stb <= input_strobe;
   if ((old_stb != input_strobe) & (~extended))
   begin
      case(scancode)
//         8'h03: kbd_reset <= pressed;         // F5 = RESET
//         8'h01: kbd_ROM_change <= pressed;    // F9 =  change ROM & reset!
         8'h5a : kbd_enter <= pressed; // ENTER
      endcase
   end
end


//-------------------------------------------------------------------------------
//  Ondra SD
//

wire OndraSD_signal_led;
wire OndraSD_rxd;
wire OndraSD_txd;

OndraSD #(.sysclk_frequency(50_000_000)) OndraSD // 50MHz
(
   .clk(CLK_50M),
   .reset_in(~reset),
   .enter_key(kbd_enter & ~status[9]),
   .signal_led(OndraSD_signal_led),
   // SPI signals
   .spi_miso(SD_MISO),
   .spi_mosi(SD_MOSI),
   .spi_clk(SD_SCK),
   .spi_cs(SD_CS),
   // UART
   .rxd(OndraSD_rxd),
   .txd(OndraSD_txd)
);

assign LED_RED = ~SD_CS;


//-------------------------------------------------------------------------------
//  Ondra core
//
wire       clk_video;
wire       HSync;
wire       VSync;
wire       HBlank;
wire       VBlank;
wire       pixel;
wire       beeper;
wire       TXD;
wire       MGF_OUT;
wire [4:0] joystick  = { (joy[7:4] == 4'b0000), ~joy[2], ~joy[3], ~joy[1], ~joy[0] }; // FIRE DOWN UP LEFT RIGHT


Ondra_SPO186_core Ondra_SPO186_core
(
   .clk_50M(CLK_50M),
   .clk_sys(clk_sys),
   .reset(reset),
   .ps2_key(ps2_key),
   .joystick(joystick),

   .clk_video(clk_video),
   .HSync(HSync),
   .VSync(VSync),
   .HBlank(HBlank),
   .VBlank(VBlank),
   .pixel(pixel),
   .beeper(beeper),

   .LED_GREEN(LED_GREEN),
   .LED_YELLOW(LED_YELLOW),
   //.RELAY(LED_RED), // red led will indicate RELAY activity

   .RESERVA_IN(OndraSD_txd),  //rxd
   .RESERVA_OUT(OndraSD_rxd), // txd
   .MGF_IN(tape_adc),
   .MGF_OUT(MGF_OUT),
   .Parallel_Data_OUT(Parallel_Data_OUT),
   .NON_STB(NON_STB),

   .ROMVersion(status[6:5])
);


assign AUDIO_L = (beeper ? 16'h0FFF : 16'h00) |
                 (~status[7] & tape_adc ? 16'h07F0 : 16'h00) |
                 (~status[8] & MGF_OUT  ? 16'h07F0 : 16'h00) |
                 { 2'b00, mix_audio_o };
assign AUDIO_R = (beeper ? 16'h0FFF : 16'h00) |
                 (~status[7] & tape_adc ? 16'h07F0 : 16'h00) |
                 (~status[8] & MGF_OUT  ? 16'h07F0 : 16'h00) |
                 { 2'b00, mix_audio_o };

assign CLK_VIDEO = clk_sys;
assign CE_PIXEL  = 1'b1;
assign VGA_R     = pixel ? 8'hFF : 8'h00;
assign VGA_G     = pixel ? 8'hFF : 8'h00;
assign VGA_B     = pixel ? 8'hFF : 8'h00;
assign VGA_HS    = HSync;
assign VGA_VS    = VSync;
assign VGA_DE    = ~(HBlank | VBlank);

endmodule
