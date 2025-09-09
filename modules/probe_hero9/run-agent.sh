# Navigate to the project root
cd /Users/johnycsh/volo_codes/volo_vhdl

# Use Cursor agent with the prompt file
cursor-agent agent --prompt-file ai-workflow/prompts/generate-datadef-testbench.md \
  --prompt "Package: Probe_Config_pkg_PH9
Path: modules/probe_hero9/datadef/Probe_Config_pkg_PH9.vhd" \
  --print \
  --output-format text
