-- SimpleWaveGen_core.vhd
-- Simple Waveform Generator Core Module
-- Generates three distinct waveform types: square, triangle, and sine waves
-- Educational example demonstrating proper VHDL-2008 coding practices

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;
use WORK.Moku_Voltage_pkg.all;

entity SimpleWaveGen_core is
    generic (
        VOUT_MAX : integer := 32767;  -- 16-bit signed maximum
        VOUT_MIN : integer := -32768  -- 16-bit signed minimum
    );
    port (
        -- Clock and Control Inputs
        clk                     : in  std_logic;                    -- System clock input
        clk_en                  : in  std_logic;                    -- Clock enable from clock divider
        rst                     : in  std_logic;                    -- Synchronous reset (active high)
        en                      : in  std_logic;                    -- Module enable (active high)
        
        -- Configuration Inputs
        cfg_safety_wave_select  : in  std_logic_vector(2 downto 0); -- Wave type selection (Safety-Critical)
        
        -- Outputs
        wave_out                : out std_logic_vector(15 downto 0); -- 16-bit signed waveform output
        fault_out               : out std_logic;                    -- Error indicator (high when invalid config)
        stat                    : out std_logic_vector(7 downto 0)  -- 8-bit status register
    );
end entity SimpleWaveGen_core;

architecture rtl of SimpleWaveGen_core is
    
    -- Wave selection constants
    constant WAVE_SQUARE    : std_logic_vector(2 downto 0) := "000";
    constant WAVE_TRIANGLE  : std_logic_vector(2 downto 0) := "001";
    constant WAVE_SINE      : std_logic_vector(2 downto 0) := "010";
    
    -- State machine states for triangle wave
    constant TRI_STATE_UP   : std_logic_vector(1 downto 0) := "00";
    constant TRI_STATE_DOWN : std_logic_vector(1 downto 0) := "01";
    
    -- Internal signals
    signal wave_select_valid    : std_logic;
    signal wave_select_reg      : std_logic_vector(2 downto 0);
    signal enabled_reg          : std_logic;
    signal fault_reg            : std_logic;
    
    -- Square wave signals
    signal square_output        : std_logic_vector(15 downto 0);
    signal square_toggle        : std_logic;
    
    -- Triangle wave signals
    signal triangle_output      : std_logic_vector(15 downto 0);
    signal triangle_state       : std_logic_vector(1 downto 0);
    signal triangle_counter     : unsigned(15 downto 0);
    
    -- Sine wave signals
    signal sine_output          : std_logic_vector(15 downto 0);
    signal sine_phase           : unsigned(6 downto 0);  -- 7-bit phase counter (0-127)
    
    -- Status register
    signal status_reg           : std_logic_vector(7 downto 0);
    
    -- Sine lookup table (128 points covering 0° to 360°)
    type sine_lut_type is array (0 to 127) of std_logic_vector(15 downto 0);
    constant sine_lut : sine_lut_type := (
        x"0000", x"0324", x"0647", x"096A", x"0C8B", x"0FAB", x"12C8", x"15E2",
        x"18F8", x"1C0B", x"1F19", x"2223", x"2528", x"2826", x"2B1F", x"2E11",
        x"30FB", x"33DE", x"36BA", x"398C", x"3C56", x"3F17", x"41CE", x"447A",
        x"471C", x"49B4", x"4C3F", x"4EBF", x"5133", x"539B", x"55F5", x"5842",
        x"5A82", x"5CB4", x"5ED7", x"60EC", x"62F2", x"64E8", x"66CF", x"68A6",
        x"6A6D", x"6C24", x"6DCA", x"6F5F", x"70E2", x"7254", x"73B5", x"7504",
        x"7641", x"776C", x"7884", x"798A", x"7A7D", x"7B5D", x"7C29", x"7CE2",
        x"7D89", x"7E1C", x"7E9C", x"7F09", x"7F62", x"7FA7", x"7FD8", x"7FF6",
        x"7FFF", x"7FF6", x"7FD8", x"7FA7", x"7F62", x"7F09", x"7E9C", x"7E1C",
        x"7D89", x"7CE2", x"7C29", x"7B5D", x"7A7D", x"798A", x"7884", x"776C",
        x"7641", x"7504", x"73B5", x"7254", x"70E2", x"6F5F", x"6DCA", x"6C24",
        x"6A6D", x"68A6", x"66CF", x"64E8", x"62F2", x"60EC", x"5ED7", x"5CB4",
        x"5A82", x"5842", x"55F5", x"539B", x"5133", x"4EBF", x"4C3F", x"49B4",
        x"471C", x"447A", x"41CE", x"3F17", x"3C56", x"398C", x"36BA", x"33DE",
        x"30FB", x"2E11", x"2B1F", x"2826", x"2528", x"2223", x"1F19", x"1C0B",
        x"18F8", x"15E2", x"12C8", x"0FAB", x"0C8B", x"096A", x"0647", x"0324"
    );
    
begin
    
    -- Safety-critical parameter validation
    -- cfg_safety_wave_select MUST be validated on reset and continuously monitored
    wave_select_valid <= '1' when (cfg_safety_wave_select = WAVE_SQUARE) or
                                  (cfg_safety_wave_select = WAVE_TRIANGLE) or
                                  (cfg_safety_wave_select = WAVE_SINE)
                        else '0';
    
    -- Main synchronous process
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset all registers
            wave_select_reg <= (others => '0');
            enabled_reg <= '0';
            fault_reg <= '0';
            square_toggle <= '0';
            triangle_state <= TRI_STATE_UP;
            triangle_counter <= (others => '0');
            sine_phase <= (others => '0');
            status_reg <= (others => '0');
            -- Initialize wave outputs to zero
            square_output <= (others => '0');
            triangle_output <= (others => '0');
            sine_output <= (others => '0');
            
        elsif rising_edge(clk) then
            -- Update enable register
            enabled_reg <= en;
            
            -- Validate safety-critical parameters
            if wave_select_valid = '1' then
                wave_select_reg <= cfg_safety_wave_select;
                fault_reg <= '0';
            else
                -- Invalid selection - maintain last valid selection and set fault
                fault_reg <= '1';
            end if;
            
            -- Wave generation only occurs when enabled and clock enable is active
            if (enabled_reg = '1') and (clk_en = '1') then
                
                case wave_select_reg is
                    when WAVE_SQUARE =>
                        -- Square wave: toggle between high and low
                        square_toggle <= not square_toggle;
                        if square_toggle = '1' then
                            square_output <= std_logic_vector(to_signed(VOUT_MAX, 16));
                        else
                            square_output <= std_logic_vector(to_signed(VOUT_MIN, 16));
                        end if;
                        
                    when WAVE_TRIANGLE =>
                        -- Triangle wave: ramp up then down
                        case triangle_state is
                            when TRI_STATE_UP =>
                                if triangle_counter >= to_unsigned(VOUT_MAX, 16) then
                                    triangle_state <= TRI_STATE_DOWN;
                                    triangle_counter <= to_unsigned(VOUT_MAX, 16);
                                else
                                    triangle_counter <= triangle_counter + 1;
                                end if;
                                
                            when TRI_STATE_DOWN =>
                                if triangle_counter <= to_unsigned(VOUT_MIN, 16) then
                                    triangle_state <= TRI_STATE_UP;
                                    triangle_counter <= to_unsigned(VOUT_MIN, 16);
                                else
                                    triangle_counter <= triangle_counter - 1;
                                end if;
                                
                            when others =>
                                triangle_state <= TRI_STATE_UP;
                                triangle_counter <= (others => '0');
                        end case;
                        triangle_output <= std_logic_vector(triangle_counter);
                        
                    when WAVE_SINE =>
                        -- Sine wave: use lookup table
                        if sine_phase >= 127 then
                            sine_phase <= (others => '0');
                        else
                            sine_phase <= sine_phase + 1;
                        end if;
                        sine_output <= sine_lut(to_integer(sine_phase));
                        
                    when others =>
                        -- Invalid selection - maintain last output
                        null;
                end case;
            end if;
            
            -- Update status register
            -- Bit [7]: Enabled status
            -- Bits [6:3]: Reserved
            -- Bits [2:0]: Current wave selection
            status_reg(7) <= enabled_reg;
            status_reg(6 downto 3) <= "0000";
            status_reg(2 downto 0) <= wave_select_reg;
        end if;
    end process;
    
    -- Output assignments
    wave_out <= square_output when wave_select_reg = WAVE_SQUARE else
                triangle_output when wave_select_reg = WAVE_TRIANGLE else
                sine_output when wave_select_reg = WAVE_SINE else
                (others => '0');  -- Default to zero for invalid selections
    
    fault_out <= fault_reg;
    stat <= status_reg;
    
end architecture rtl;