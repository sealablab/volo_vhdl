--------------------------------------------------------------------------------
-- Platform Interface Package for probe_driver
-- Purpose: Defines constants and configuration for platform interface mapping
-- Author: AI Assistant
-- Date: 2025-01-27
-- 
-- This package contains the constants and configuration needed to map between
-- the probe_driver_top module and the platform interface (e.g., Moku CustomWrapper).
-- It separates platform-specific configuration from core module logic.
--------------------------------------------------------------------------------

library IEEE;
use IEEE.Std_Logic_1164.all;
use IEEE.Numeric_Std.all;

package platform_interface_pkg is
    -- =============================================================================
    -- CONTROL REGISTER BIT POSITIONS
    -- =============================================================================
    -- Control0 register bit definitions
    constant GLOBAL_ENABLE_BIT     : natural := 31;
    constant SOFT_TRIG_BIT         : natural := 23;
    constant CLK_DIV_SEL_START     : natural := 20;
    constant CLK_DIV_SEL_END       : natural := 23;
    constant INTENSITY_INDEX_START : natural := 16;
    constant INTENSITY_INDEX_END   : natural := 22;
    
    -- Control1 register bit definitions
    constant DURATION_START        : natural := 16;
    constant DURATION_END          : natural := 31;
    
    -- =============================================================================
    -- DEFAULT CONFIGURATION VALUES
    -- =============================================================================
    -- Default cooldown value (1000 clock cycles)
    constant DEFAULT_COOLDOWN      : std_logic_vector(15 downto 0) := x"03E8";
    
    -- Default trigger threshold (mid-scale for 16-bit signed)
    constant DEFAULT_TRIGGER_THRESHOLD : std_logic_vector(15 downto 0) := x"4000";
    
    -- =============================================================================
    -- PLATFORM INTERFACE CONSTANTS
    -- =============================================================================
    -- Clock divider selection width (4 bits for 0-15 range)
    constant CLK_DIV_SEL_WIDTH     : natural := 4;
    
    -- Intensity index width (7 bits for 0-100 range)
    constant INTENSITY_INDEX_WIDTH  : natural := 7;
    
    -- Duration width (16 bits for consistency)
    constant DURATION_WIDTH         : natural := 16;
    
end package platform_interface_pkg;
