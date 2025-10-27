"""
DS1120-PD VOLO Progressive Test Suite

Following VOLO CocotB Testing Standard v1.0:
- P1: Basic functionality (3 tests, minimal output)
- P2: Intermediate with safety features (4 tests)
- P3: Comprehensive with edge cases (2 tests)

Module: DS1120-PD (EMFI probe driver for Riscure DS1120A)
Type: VOLO Application
"""

from .ds1120_pd_constants import MODULE_NAME, TestValues

__all__ = ['MODULE_NAME', 'TestValues']