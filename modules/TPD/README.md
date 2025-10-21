  # From the TPD module directory
  make -f Makefile.cocotb          # Run test
  make -f Makefile.cocotb WAVES=1  # Run with waveform generation
  make -f Makefile.cocotb clean    # Clean artifacts
