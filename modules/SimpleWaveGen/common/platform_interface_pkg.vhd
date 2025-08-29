-- platform_interface_pkg.vhd
-- SimpleWaveGen Platform Interface Package
-- Defines register interface types, constants, and utility functions
-- for the SimpleWaveGen top-level module register interface

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

package platform_interface_pkg is
    
    -- ============================================================================
    -- WAVE SELECTION CONSTANTS
    -- ============================================================================
    
    -- Valid wave selection values (Safety-Critical Parameter)
    constant WAVE_SELECT_SQUARE         : std_logic_vector(2 downto 0) := "000";
    constant WAVE_SELECT_TRIANGLE       : std_logic_vector(2 downto 0) := "001";
    constant WAVE_SELECT_SINE           : std_logic_vector(2 downto 0) := "010";
    
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
    
    -- ============================================================================
    -- REGISTER FIELD EXTRACTION FUNCTIONS
    -- ============================================================================
    
    -- Extract control register fields
    function extract_ctrl_global_enable(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic;
    function extract_clk_div_sel(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic_vector;
    
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
    
    -- Extract control register fields
    function extract_ctrl_global_enable(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic is
    begin
        return ctrl0_data(31); -- Global enable is bit 31
    end function extract_ctrl_global_enable;
    
    function extract_clk_div_sel(ctrl0_data : std_logic_vector(31 downto 0)) return std_logic_vector is
    begin
        return ctrl0_data(23 downto 20); -- Clock divider selection is bits 23:20
    end function extract_clk_div_sel;
    
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