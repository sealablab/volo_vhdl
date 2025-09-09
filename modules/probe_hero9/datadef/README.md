# ProbeHero9 Data Definitions

## 📋 Package Overview
This directory contains data definition packages for ProbeHero9, based on ProbeHero8 implementations.

## 📦 Package Files

| Package | Source | Purpose | Status |
|---------|--------|---------|--------|
| `Probe_Config_pkg_PH9.vhd` | ProbeHero8 | Probe configuration data types and constants | ✅ Renamed |
| `Global_Probe_Table_pkg_PH9.vhd` | ProbeHero8 | Global probe definitions and validation | ✅ Renamed |
| `Moku_Voltage_pkg_PH9.vhd` | ProbeHero8 | Voltage conversion utilities for MCC platform | ✅ Renamed |
| `PercentLut_pkg_PH9.vhd` | ProbeHero8 | Percentage-based lookup table utilities | ✅ Renamed |

## 🔄 Relationship to ProbeHero8

### Initial State
- **Copied from**: `modules/probe_hero8/datadef/` (commit: [to be filled])
- **Date copied**: $(date)
- **Purpose**: Start with proven, working data definitions

### Development Strategy
1. **Start with ProbeHero8 packages** - Use as baseline
2. **Identify needed changes** - Document requirements for ProbeHero9
3. **Implement enhancements** - Add new features while maintaining compatibility
4. **Track differences** - Document what changed and why

### Change Management
- **Minor changes**: Update packages in place
- **Major changes**: Create new versions (e.g., `Probe_Config_pkg_en_v2.vhd`)
- **Breaking changes**: Document compatibility impact

## 🎯 ProbeHero9 Enhancements

### Planned Improvements
- [ ] Enhanced error handling in validation functions
- [ ] Additional status reporting capabilities
- [ ] Extended parameter validation
- [ ] Better integration with platform systems

### Compatibility Requirements
- **Backward compatibility**: Maintain interface compatibility where possible
- **Forward compatibility**: Design for future enhancements
- **Platform compatibility**: Ensure MCC platform integration

## 📝 Development Notes

### Testing Strategy
- Unit tests for each package in `../tb/datadef/`
- Integration tests with ProbeHero9 core
- Regression tests against ProbeHero8 behavior

### Documentation
- Keep this README updated with changes
- Document any breaking changes
- Maintain compatibility matrix

## 🔗 Related Files
- **Source**: `../../probe_hero8/datadef/`
- **Requirements**: `../requirements/functional/`
- **Tests**: `../tb/datadef/`
- **Core**: `../core/`
