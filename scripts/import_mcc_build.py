#!/usr/bin/env python3
"""
Import MCC CloudCompile build results from module's incoming/ folder.

Usage:
    python scripts/import_mcc_build.py modules/buffer_waveform_gen

Workflow:
1. After CloudCompile synthesis, download files to ~/Downloads/
2. Move them to modules/<module>/incoming/
3. Run this script to import them into modules/<module>/latest/

This script:
1. Scans modules/<module>/incoming/ for 25ff*_synthesis.log and 25ff*_bitstreams.tar
2. Moves them to modules/<module>/latest/
3. Creates BUILD_INFO.txt linking manifest to bitstream
4. Cleans up incoming/ folder

Benefits of incoming/ folder pattern:
- No ambiguity about which build to import
- Can stage multiple builds before deciding which to use
- Clear separation: incoming = staging, latest = active

Author: Claude Code
Date: 2025-10-24
"""

import os
import sys
import glob
import shutil
from pathlib import Path
from datetime import datetime


def find_mcc_files_in_incoming(incoming_dir):
    """Find MCC build files in module's incoming/ directory."""
    pattern = os.path.join(incoming_dir, "25ff*_mokugo_*")

    synthesis_logs = glob.glob(f"{pattern}_synthesis.log")
    bitstreams = glob.glob(f"{pattern}_bitstreams.tar")

    if not synthesis_logs or not bitstreams:
        return None, None

    # Sort by modification time, take newest
    synthesis_logs.sort(key=os.path.getmtime, reverse=True)
    bitstreams.sort(key=os.path.getmtime, reverse=True)

    return synthesis_logs[0], bitstreams[0]


def extract_mcc_job_id(filename):
    """Extract MCC job ID from filename (e.g., 25ff362 from 25ff362_mokugo_4.0.3_2_synthesis.log)."""
    basename = os.path.basename(filename)
    return basename.split("_")[0]


def read_build_manifest(cloudcompile_dir):
    """Read BUILD_MANIFEST.txt if it exists."""
    manifest_path = os.path.join(cloudcompile_dir, "BUILD_MANIFEST.txt")
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r') as f:
            return f.read()
    return None


def create_build_info(latest_dir, log_file, bitstream_file, manifest_content):
    """Create BUILD_INFO.txt linking manifest to bitstream."""
    job_id = extract_mcc_job_id(log_file)
    timestamp = datetime.fromtimestamp(os.path.getmtime(bitstream_file)).strftime("%Y-%m-%d %H:%M:%S")

    info_path = os.path.join(latest_dir, "BUILD_INFO.txt")

    with open(info_path, 'w') as f:
        f.write("=" * 70 + "\n")
        f.write("MCC CloudCompile Build Info\n")
        f.write("=" * 70 + "\n\n")
        f.write(f"MCC Job ID: {job_id}\n")
        f.write(f"Download Time: {timestamp}\n")
        f.write(f"Synthesis Log: {os.path.basename(log_file)}\n")
        f.write(f"Bitstream: {os.path.basename(bitstream_file)}\n")
        f.write("\n")

        if manifest_content:
            f.write("-" * 70 + "\n")
            f.write("Build Manifest (source code at build time):\n")
            f.write("-" * 70 + "\n")
            f.write(manifest_content)
        else:
            f.write("⚠ No BUILD_MANIFEST.txt found in cloudcompile_package/\n")
            f.write("Run build_mcc_package.py to generate manifest\n")

    return info_path


def main():
    if len(sys.argv) < 2:
        print("Usage: python scripts/import_mcc_build.py modules/<module_name>")
        print("Example: python scripts/import_mcc_build.py modules/buffer_waveform_gen")
        sys.exit(1)

    module_path = sys.argv[1]
    module_name = os.path.basename(module_path)

    # Resolve paths
    repo_root = Path(__file__).parent.parent
    module_dir = repo_root / module_path
    incoming_dir = module_dir / "incoming"
    latest_dir = module_dir / "latest"
    cloudcompile_dir = module_dir / "cloudcompile_package"

    # Validate module directory
    if not module_dir.exists():
        print(f"❌ Module directory not found: {module_dir}")
        sys.exit(1)

    # Check if incoming/ directory exists
    if not incoming_dir.exists():
        print(f"❌ incoming/ directory not found: {incoming_dir}")
        print(f"\nCreate it and place your CloudCompile files there:")
        print(f"  mkdir -p {incoming_dir}")
        print(f"  mv ~/Downloads/25ff*_mokugo_* {incoming_dir}/")
        sys.exit(1)

    # Create latest/ directory if needed
    latest_dir.mkdir(exist_ok=True)

    print("=" * 70)
    print(f"Importing MCC Build Results for: {module_name}")
    print("=" * 70)
    print()

    # Find MCC files in incoming/
    print(f"🔍 Scanning {incoming_dir}/...")
    log_file, bitstream_file = find_mcc_files_in_incoming(incoming_dir)

    if not log_file or not bitstream_file:
        print(f"❌ No MCC build files found in {incoming_dir}/")
        print("   Looking for: 25ff*_mokugo_*_synthesis.log and 25ff*_mokugo_*_bitstreams.tar")
        print(f"\nPlace your CloudCompile files in incoming/:")
        print(f"  mv ~/Downloads/25ff*_mokugo_* {incoming_dir}/")
        sys.exit(1)

    job_id = extract_mcc_job_id(log_file)
    print(f"✓ Found MCC build: {job_id}")
    print(f"  Synthesis log: {os.path.basename(log_file)}")
    print(f"  Bitstream: {os.path.basename(bitstream_file)}")
    print()

    # Check if files already exist
    dest_log = latest_dir / os.path.basename(log_file)
    dest_bitstream = latest_dir / os.path.basename(bitstream_file)

    if dest_log.exists() or dest_bitstream.exists():
        print(f"⚠ Files already exist in latest/ directory")
        response = input("  Overwrite? (y/n): ")
        if response.lower() != 'y':
            print("❌ Import cancelled")
            sys.exit(0)

    # Move files
    print(f"📦 Moving files to {latest_dir}/...")
    shutil.move(log_file, dest_log)
    shutil.move(bitstream_file, dest_bitstream)
    print("  ✓ Files moved")
    print()

    # Read build manifest
    manifest_content = read_build_manifest(cloudcompile_dir)

    # Create BUILD_INFO.txt
    print("📝 Creating BUILD_INFO.txt...")
    info_path = create_build_info(latest_dir, dest_log, dest_bitstream, manifest_content)
    print(f"  ✓ Created: {info_path}")
    print()

    # Clean up incoming/ directory (files have been moved)
    print(f"🧹 Cleaning up incoming/ directory...")
    # incoming/ should now be empty or contain only other unrelated files
    remaining_files = list(incoming_dir.glob("25ff*_mokugo_*"))
    if not remaining_files:
        print(f"  ✓ incoming/ directory cleaned")
    else:
        print(f"  ⚠ {len(remaining_files)} other build file(s) remain in incoming/")

    # Show summary
    print()
    print("=" * 70)
    print("✅ Import Complete!")
    print("=" * 70)
    print(f"MCC Job ID: {job_id}")
    print(f"Location: {latest_dir}/")
    print()
    print("Next steps:")
    print(f"  1. Test on hardware:")
    print(f"     cd tests")
    print(f"     uv run python test_{module_name}_mokubench.py \\")
    print(f"       --ip <IP_ADDRESS> \\")
    print(f"       --bitstream {dest_bitstream}")
    print()
    print(f"  2. View build info:")
    print(f"     cat {info_path}")
    print()
    print(f"  3. Next iteration:")
    print(f"     mv ~/Downloads/25ff*_mokugo_* {incoming_dir}/")
    print(f"     python scripts/import_mcc_build.py {module_path}")
    print()


if __name__ == "__main__":
    main()
