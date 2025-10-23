--------------------------------------------------------------------------------
-- Waveform LUT Package - PulseStar Calibration Module
--
-- Description:
--   Lookup tables for sine and cosine waveforms (256 points, 16-bit signed).
--   Provides I/Q quadrature signals for calibration and testing.
--
-- LUT Details:
--   - Size: 256 entries (8-bit index)
--   - Format: signed 16-bit (-32768 to +32767)
--   - Amplitude: Full-scale (±32767)
--   - Phase: Sine[0] = 0, Cosine[0] = max (90° offset)
--
-- Usage:
--   signal phase_idx : unsigned(7 downto 0);
--   signal sine_out  : signed(15 downto 0);
--   signal cos_out   : signed(15 downto 0);
--
--   sine_out <= SINE_LUT(to_integer(phase_idx));
--   cos_out  <= COSINE_LUT(to_integer(phase_idx));
--
-- Verilog Conversion Strategy:
--   - LUT → parameter array or $readmemh from .mem file
--   - Functions → Verilog functions or inline indexing
--
-- Tier: 2 (Datadef - LUTs and data structures allowed)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package waveform_lut_pkg is

    -- LUT array type (256 entries, 16-bit signed)
    type waveform_lut_t is array (0 to 255) of signed(15 downto 0);

    -- Sine wave lookup table (starts at 0°)
    constant SINE_LUT : waveform_lut_t := (
        X"0000", X"0324", X"0648", X"096B", X"0C8C", X"0FAB", X"12C8", X"15E2",
        X"18F9", X"1C0C", X"1F1A", X"2224", X"2528", X"2827", X"2B1F", X"2E11",
        X"30FC", X"33DF", X"36BA", X"398D", X"3C57", X"3F17", X"41CE", X"447B",
        X"471D", X"49B4", X"4C40", X"4EC0", X"5134", X"539B", X"55F6", X"5843",
        X"5A82", X"5CB4", X"5ED7", X"60EC", X"62F2", X"64E9", X"66D0", X"68A7",
        X"6A6E", X"6C24", X"6DCA", X"6F5F", X"70E3", X"7255", X"73B6", X"7505",
        X"7642", X"776C", X"7885", X"798A", X"7A7D", X"7B5D", X"7C2A", X"7CE4",
        X"7D8A", X"7E1E", X"7E9D", X"7F0A", X"7F62", X"7FA7", X"7FD9", X"7FF6",
        X"7FFF", X"7FF6", X"7FD9", X"7FA7", X"7F62", X"7F0A", X"7E9D", X"7E1E",
        X"7D8A", X"7CE4", X"7C2A", X"7B5D", X"7A7D", X"798A", X"7885", X"776C",
        X"7642", X"7505", X"73B6", X"7255", X"70E3", X"6F5F", X"6DCA", X"6C24",
        X"6A6E", X"68A7", X"66D0", X"64E9", X"62F2", X"60EC", X"5ED7", X"5CB4",
        X"5A82", X"5843", X"55F6", X"539B", X"5134", X"4EC0", X"4C40", X"49B4",
        X"471D", X"447B", X"41CE", X"3F17", X"3C57", X"398D", X"36BA", X"33DF",
        X"30FC", X"2E11", X"2B1F", X"2827", X"2528", X"2224", X"1F1A", X"1C0C",
        X"18F9", X"15E2", X"12C8", X"0FAB", X"0C8C", X"096B", X"0648", X"0324",
        X"0000", X"FCDC", X"F9B8", X"F695", X"F374", X"F055", X"ED38", X"EA1E",
        X"E707", X"E3F4", X"E0E6", X"DDDC", X"DAD8", X"D7D9", X"D4E1", X"D1EF",
        X"CF04", X"CC21", X"C946", X"C673", X"C3A9", X"C0E9", X"BE32", X"BB85",
        X"B8E3", X"B64C", X"B3C0", X"B140", X"AECC", X"AC65", X"AA0A", X"A7BD",
        X"A57E", X"A34C", X"A129", X"9F14", X"9D0E", X"9B17", X"9930", X"9759",
        X"9592", X"93DC", X"9236", X"90A1", X"8F1D", X"8DAB", X"8C4A", X"8AFB",
        X"89BE", X"8894", X"877B", X"8676", X"8583", X"84A3", X"83D6", X"831C",
        X"8276", X"81E2", X"8163", X"80F6", X"809E", X"8059", X"8027", X"800A",
        X"8001", X"800A", X"8027", X"8059", X"809E", X"80F6", X"8163", X"81E2",
        X"8276", X"831C", X"83D6", X"84A3", X"8583", X"8676", X"877B", X"8894",
        X"89BE", X"8AFB", X"8C4A", X"8DAB", X"8F1D", X"90A1", X"9236", X"93DC",
        X"9592", X"9759", X"9930", X"9B17", X"9D0E", X"9F14", X"A129", X"A34C",
        X"A57E", X"A7BD", X"AA0A", X"AC65", X"AECC", X"B140", X"B3C0", X"B64C",
        X"B8E3", X"BB85", X"BE32", X"C0E9", X"C3A9", X"C673", X"C946", X"CC21",
        X"CF04", X"D1EF", X"D4E1", X"D7D9", X"DAD8", X"DDDC", X"E0E6", X"E3F4",
        X"E707", X"EA1E", X"ED38", X"F055", X"F374", X"F695", X"F9B8", X"FCDC"
    );

    -- Cosine wave lookup table (90° phase shift from sine)
    constant COSINE_LUT : waveform_lut_t := (
        X"7FFF", X"7FF6", X"7FD9", X"7FA7", X"7F62", X"7F0A", X"7E9D", X"7E1E",
        X"7D8A", X"7CE4", X"7C2A", X"7B5D", X"7A7D", X"798A", X"7885", X"776C",
        X"7642", X"7505", X"73B6", X"7255", X"70E3", X"6F5F", X"6DCA", X"6C24",
        X"6A6E", X"68A7", X"66D0", X"64E9", X"62F2", X"60EC", X"5ED7", X"5CB4",
        X"5A82", X"5843", X"55F6", X"539B", X"5134", X"4EC0", X"4C40", X"49B4",
        X"471D", X"447B", X"41CE", X"3F17", X"3C57", X"398D", X"36BA", X"33DF",
        X"30FC", X"2E11", X"2B1F", X"2827", X"2528", X"2224", X"1F1A", X"1C0C",
        X"18F9", X"15E2", X"12C8", X"0FAB", X"0C8C", X"096B", X"0648", X"0324",
        X"0000", X"FCDC", X"F9B8", X"F695", X"F374", X"F055", X"ED38", X"EA1E",
        X"E707", X"E3F4", X"E0E6", X"DDDC", X"DAD8", X"D7D9", X"D4E1", X"D1EF",
        X"CF04", X"CC21", X"C946", X"C673", X"C3A9", X"C0E9", X"BE32", X"BB85",
        X"B8E3", X"B64C", X"B3C0", X"B140", X"AECC", X"AC65", X"AA0A", X"A7BD",
        X"A57E", X"A34C", X"A129", X"9F14", X"9D0E", X"9B17", X"9930", X"9759",
        X"9592", X"93DC", X"9236", X"90A1", X"8F1D", X"8DAB", X"8C4A", X"8AFB",
        X"89BE", X"8894", X"877B", X"8676", X"8583", X"84A3", X"83D6", X"831C",
        X"8276", X"81E2", X"8163", X"80F6", X"809E", X"8059", X"8027", X"800A",
        X"8001", X"800A", X"8027", X"8059", X"809E", X"80F6", X"8163", X"81E2",
        X"8276", X"831C", X"83D6", X"84A3", X"8583", X"8676", X"877B", X"8894",
        X"89BE", X"8AFB", X"8C4A", X"8DAB", X"8F1D", X"90A1", X"9236", X"93DC",
        X"9592", X"9759", X"9930", X"9B17", X"9D0E", X"9F14", X"A129", X"A34C",
        X"A57E", X"A7BD", X"AA0A", X"AC65", X"AECC", X"B140", X"B3C0", X"B64C",
        X"B8E3", X"BB85", X"BE32", X"C0E9", X"C3A9", X"C673", X"C946", X"CC21",
        X"CF04", X"D1EF", X"D4E1", X"D7D9", X"DAD8", X"DDDC", X"E0E6", X"E3F4",
        X"E707", X"EA1E", X"ED38", X"F055", X"F374", X"F695", X"F9B8", X"FCDC",
        X"0000", X"0324", X"0648", X"096B", X"0C8C", X"0FAB", X"12C8", X"15E2",
        X"18F9", X"1C0C", X"1F1A", X"2224", X"2528", X"2827", X"2B1F", X"2E11",
        X"30FC", X"33DF", X"36BA", X"398D", X"3C57", X"3F17", X"41CE", X"447B",
        X"471D", X"49B4", X"4C40", X"4EC0", X"5134", X"539B", X"55F6", X"5843",
        X"5A82", X"5CB4", X"5ED7", X"60EC", X"62F2", X"64E9", X"66D0", X"68A7",
        X"6A6E", X"6C24", X"6DCA", X"6F5F", X"70E3", X"7255", X"73B6", X"7505",
        X"7642", X"776C", X"7885", X"798A", X"7A7D", X"7B5D", X"7C2A", X"7CE4",
        X"7D8A", X"7E1E", X"7E9D", X"7F0A", X"7F62", X"7FA7", X"7FD9", X"7FF6"
    );

end package waveform_lut_pkg;
