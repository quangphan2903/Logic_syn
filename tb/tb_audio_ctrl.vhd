library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_audio_ctrl is
	generic(data_width_g : integer := 16);
end entity tb_audio_ctrl;

architecture testbench of tb_audio_ctrl is

	constant period_c                 : time    := 24 ns;
	constant wave_gen_sync_clear_time : time    := 4 ms;
	constant ref_clk_freq_c           : integer := 1000000000 ns / period_c;
	constant sample_rate_c            : integer := 38000;

	signal clk                   : std_logic := '0';
	signal rst_n                 : std_logic := '0';
	signal wave_gen_sync_clear_n : std_logic := '1';

	signal left_wave_gen_data  : std_logic_vector(data_width_g - 1 downto 0);
	signal right_wave_gen_data : std_logic_vector(data_width_g - 1 downto 0);

	signal left_audio_data  : std_logic_vector(data_width_g - 1 downto 0);
	signal right_audio_data : std_logic_vector(data_width_g - 1 downto 0);

	signal aud_bclk, aud_lrclk, aud_data : std_logic;

	component wave_gen
		generic(
			width_g : integer;
			step_g  : integer
		);
		port(
			clk, rst_n, sync_clear_n_in : in  std_logic;
			value_out                   : out std_logic_vector(width_g - 1 downto 0)
		);
	end component;

	component audio_ctrl
		generic(
			ref_clk_freq_g : integer;
			sample_rate_g  : integer;
			data_width_g   : integer
		);
		port(
			clk, rst_n                                : in  std_logic;
			left_data_in, right_data_in               : in  std_logic_vector(data_width_g - 1 downto 0);
			aud_bclk_out, aud_lrclk_out, aud_data_out : out std_logic);
	end component audio_ctrl;

	component audio_codec_module
		generic(data_width_g : integer);
		port(
			rst_n                                  : in  std_logic;
			aud_bclk_in, aud_lrclk_in, aud_data_in : in  std_logic;
			value_left_out, value_right_out        : out std_logic_vector(data_width_g - 1 downto 0)
		);
	end component audio_codec_module;

begin
	clk                   <= not clk after period_c / 2;
	rst_n                 <= '1' after period_c * 4;
	wave_gen_sync_clear_n <= '0' after wave_gen_sync_clear_time, '1' after wave_gen_sync_clear_time + period_c;

	i_wave_gen_left : component wave_gen
		generic map(
			width_g => data_width_g,
			step_g  => 2
		)
		port map(
			clk             => clk,
			rst_n           => rst_n,
			sync_clear_n_in => wave_gen_sync_clear_n,
			value_out       => left_wave_gen_data
		);

	i_wave_gen_right : component wave_gen
		generic map(
			width_g => data_width_g,
			step_g  => 10
		)
		port map(
			clk             => clk,
			rst_n           => rst_n,
			sync_clear_n_in => wave_gen_sync_clear_n,
			value_out       => right_wave_gen_data
		);

	i_audio_ctrl : component audio_ctrl
		generic map(
			ref_clk_freq_g => ref_clk_freq_c,
			sample_rate_g  => sample_rate_c,
			data_width_g   => data_width_g
		)
		port map(
			clk           => clk,
			rst_n         => rst_n,
			left_data_in  => left_wave_gen_data,
			right_data_in => right_wave_gen_data,
			aud_bclk_out  => aud_bclk,
			aud_lrclk_out => aud_lrclk,
			aud_data_out  => aud_data
		);

	i_audio_codec_module : component audio_codec_module
		generic map(
			data_width_g => data_width_g
		)
		port map(
			rst_n           => rst_n,
			aud_bclk_in     => aud_bclk,
			aud_lrclk_in    => aud_lrclk,
			aud_data_in     => aud_data,
			value_left_out  => left_audio_data,
			value_right_out => right_audio_data
		);

end architecture testbench;
