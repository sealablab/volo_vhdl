-- platform_interface_pkg.vhd
-- SimpleWaveGen Platform Interface Package
-- Defines register interface types, constants, and utility functions
-- for the SimpleWaveGen top-level module register interface

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

package platform_interface_pkg is
    
    -- ============================================================================
    -- REGISTER INTERFACE CONSTANTS
    -- ============================================================================
    
    -- Register field bit positions and ranges
    -- Control0 Register (32-bit)
    constant CTRL0_GLOBAL_ENABLE_BIT    : natural := 31;
    constant CTRL0_CLK_DIV_SEL_MSB      : natural := 23;
    constant CTRL0_CLK_DIV_SEL_LSB      : natural := 20;
    
    -- Config0 Register (32-bit) - Safety Critical
    constant CONFIG0_WAVE_SELECT_MSB    : natural := 2;
    constant CONFIG0_WAVE_SELECT_LSB    : natural := 0;
    
    -- Config1 Register (32-bit)
    constant CONFIG1_AMPLITUDE_SCALE_MSB: natural := 15;
    constant CONFIG1_AMPLITUDE_SCALE_LSB: natural := 0;
    
    -- Status0 Register (32-bit)
    constant STATUS0_ENABLED_BIT        : natural := 7;
    constant STATUS0_WAVE_SELECT_MSB    : natural := 2;
    constant STATUS0_WAVE_SELECT_LSB    : natural := 0;
    
    -- Status1 Register (32-bit)
    constant STATUS1_GLOBAL_FAULT_BIT   : natural := 0;
    
    -- Output0 Register (32-bit)
    constant OUTPUT0_WAVE_OUT_MSB       : natural := 15;
    constant OUTPUT0_WAVE_OUT_LSB       : natural := 0;
    
    -- ============================================================================
    -- WAVE SELECTION CONSTANTS
    -- ============================================================================
    
    -- Valid wave selection values (Safety-Critical Parameter)
    constant WAVE_SELECT_SQUARE         : std_logic_vector(2 downto 0) := "000";
    constant WAVE_SELECT_TRIANGLE       : std_logic_vector(2 downto 0) := "001";
    constant WAVE_SELECT_SINE           : std_logic_vector(2 downto 0) := "010";
    
    -- Invalid wave selection values (trigger fault)
    constant WAVE_SELECT_INVALID_3      : std_logic_vector(2 downto 0) := "011";
    constant WAVE_SELECT_INVALID_4      : std_logic_vector(2 downto 0) := "100";
    constant WAVE_SELECT_INVALID_5      : std_logic_vector(2 downto 0) := "101";
    constant WAVE_SELECT_INVALID_6      : std_logic_vector(2 downto 0) := "110";
    constant WAVE_SELECT_INVALID_7      : std_logic_vector(2 downto 0) := "111";
    
    -- ============================================================================
    -- DEFAULT VALUES
    -- ============================================================================
    
    -- Default register values
    constant DEFAULT_CTRL_GLOBAL_ENABLE : std_logic := '0';
    constant DEFAULT_CLK_DIV_SEL        : std_logic_vector(3 downto 0) := "0000";
    constant DEFAULT_WAVE_SELECT        : std_logic_vector(2 downto 0) := "000";
    constant DEFAULT_AMPLITUDE_SCALE    : std_logic_vector(15 downto 0) := x"8000"; -- Unity scaling
    
    -- ============================================================================
    -- VALIDATION FUNCTIONS
    -- ============================================================================
    
    -- Safety-critical parameter validation function
    -- Returns '1' if wave_select is valid, '0' if invalid
    function is_wave_select_valid(wave_select : std_logic_vector(2 downto 0)) return std_logic;
    
    -- Clock divider selection validation function
    -- Returns '1' if div_sel is valid (0-15), '0' if invalid
    function is_clk_div_sel_valid(div_sel : std_logic_vector(3 downto 0)) return std_logic;
    
    -- Amplitude scale validation function
    -- Returns '1' if amplitude_scale is valid (0x0000-0xFFFF), '0' if invalid
    function is_amplitude_scale_valid(amplitude_scale : std_logic_vector(15 downto 0)) return std_logic;
    
    -- ============================================================================
    -- REGISTER FIELD EXTRACTION FUNCTIONS
    -- ============================================================================
    
    -- Extract control register fields
    function extract_ctrl_global_enable(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic;
    function extract_clk_div_sel(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic_vector;
    
    -- Extract configuration register fields
    function extract_wave_select(config0_data : std_logic_vector(31 downto 0)) return std_logic_vector;
    function extract_amplitude_scale(config1_data : std_logic_vector(31 downto 0)) return std_logic_vector;
    
    -- ============================================================================
    -- REGISTER FIELD ASSEMBLY FUNCTIONS
    -- ============================================================================
    
    -- Assemble status register fields
    function assemble_status0_reg(enabled : std_logic; wave_select : std_logic_vector(2 downto 0)) return std_logic_vector;
    function assemble_status1_reg(global_fault : std_logic) return std_logic_vector;
    function assemble_output0_reg(wave_out : std_logic_vector(15 downto 0)) return std_logic_vector;
    
    -- ============================================================================
    -- AMPLITUDE SCALING FUNCTIONS
    -- ============================================================================
    
    -- Amplitude scaling function
    -- Applies amplitude scaling to waveform output
    -- Returns scaled 16-bit signed output
    function apply_amplitude_scaling(wave_out : std_logic_vector(15 downto 0); 
                                   amplitude_scale : std_logic_vector(15 downto 0)) return std_logic_vector;
    
    -- ============================================================================
    -- FAULT AGGREGATION FUNCTIONS
    -- ============================================================================
    
    -- Fault aggregation function
    -- ORs together all fault sources
    function aggregate_faults(core_fault : std_logic; clk_div_fault : std_logic) return std_logic;
    
end package platform_interface_pkg;

-- ============================================================================
-- PACKAGE BODY
-- ============================================================================

package body platform_interface_pkg is
    
    -- Safety-critical parameter validation function
    function is_wave_select_valid(wave_select : std_logic_vector(2 downto 0)) return std_logic is
    begin
        if (wave_select = WAVE_SELECT_SQUARE) or
           (wave_select = WAVE_SELECT_TRIANGLE) or
           (wave_select = WAVE_SELECT_SINE) then
            return '1';
        else
            return '0';
        end if;
    end function is_wave_select_valid;
    
    -- Clock divider selection validation function
    function is_clk_div_sel_valid(div_sel : std_logic_vector(3 downto 0)) return std_logic is
    begin
        -- All 4-bit values (0-15) are valid for clock divider
        return '1';
    end function is_clk_div_sel_valid;
    
    -- Amplitude scale validation function
    function is_amplitude_scale_valid(amplitude_scale : std_logic_vector(15 downto 0)) return std_logic is
    begin
        -- All 16-bit values (0x0000-0xFFFF) are valid for amplitude scaling
        return '1';
    end function is_amplitude_scale_valid;
    
    -- Extract control register fields
    function extract_ctrl_global_enable(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic is
    begin
        return ctrl0_data(CTRL0_GLOBAL_ENABLE_BIT);
    end function extract_ctrl_global_enable;
    
    function extract_clk_div_sel(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return ctrl0_data(CTRL0_CLK_DIV_SEL_MSB downto CTRL0_CLK_DIV_SEL_LSB);
    end function extract_clk_div_sel;
    
    -- Extract configuration register fields
    function extract_wave_select(config0_data : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return config0_data(CONFIG0_WAVE_SELECT_MSB downto CONFIG0_WAVE_SELECT_LSB);
    end function extract_wave_select;
    
    function extract_amplitude_scale(config1_data : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return config1_data(CONFIG1_AMPLITUDE_SCALE_MSB downto CONFIG1_AMPLITUDE_SCALE_LSB);
    end function extract_amplitude_scale;
    
    -- Assemble status register fields
    function assemble_status0_reg(enabled : std_logic; wave_select : std_logic_vector(2 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(31 downto 0);
    begin
        result := (others => '0');
        result(STATUS0_ENABLED_BIT) := enabled;
        result(STATUS0_WAVE_SELECT_MSB downto STATUS0_WAVE_SELECT_LSB) := wave_select;
        return result;
    end function assemble_status0_reg;
    
    function assemble_status1_reg(global_fault : std_logic) return std_logic_vector is
        variable result : std_logic_vector(31 downto 0);
    begin
        result := (others => '0');
        result(STATUS1_GLOBAL_FAULT_BIT) := global_fault;
        return result;
    end function assemble_status1_reg;
    
    function assemble_output0_reg(wave_out : std_logic_vector(15 downto 0)) return std_logic_vector is
        variable result : std_logic_vector(31 downto 0);
    begin
        result := (others => '0');
        result(OUTPUT0_WAVE_OUT_MSB downto OUTPUT0_WAVE_OUT_LSB) := wave_out;
        return result;
    end function assemble_output0_reg;
    
    -- Amplitude scaling function
    function apply_amplitude_scaling(wave_out : std_logic_vector(15 downto 0); 
                                   amplitude_scale : std_logic_vector(15 downto 0)) return std_logic_vector is
        variable temp_mult : signed(32 downto 0);
        variable result : std_logic_vector(15 downto 0);
    begin
        -- Perform signed multiplication: wave_out * amplitude_scale
        temp_mult := signed(wave_out) * signed('0' & amplitude_scale);
        
        -- Take upper 16 bits for scaling result
        result := std_logic_vector(temp_mult(31 downto 16));
        
        return result;
    end function apply_amplitude_scaling;
    
    -- Fault aggregation function
    function aggregate_faults(core_fault : std_logic; clk_div_fault : std_logic) return std_logic is
    begin
        return core_fault or clk_div_fault;
    end function aggregate_faults;
    
end package body platform_interface_pkg;