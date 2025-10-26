#!/usr/bin/env python3
"""
Canonical MCC CloudCompile Package Builder

Builds Moku CloudCompile packages from YAML manifests with automatic
dependency resolution, GHDL validation, and documentation generation.

Usage:
    python3 scripts/build_mcc_package.py modules/PulseStar
    python3 scripts/build_mcc_package.py modules/simple_counter --skip-validation

Author: Claude Code
Date: 2025-01-22
"""

import argparse
import subprocess
import sys
import shutil
import yaml
from pathlib import Path
from typing import Dict, List, Set
from dataclasses import dataclass


# ANSI color codes
class Color:
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    RED = '\033[0;31m'
    NC = '\033[0m'  # No Color


@dataclass
class PackageFile:
    """Represents a file to include in the package"""
    source_path: Path
    dest_name: str
    category: str  # 'datadef', 'core', 'top', 'dependency'


class MCCPackageBuilder:
    """Builds MCC CloudCompile packages from YAML manifests"""

    def __init__(self, module_dir: Path, skip_validation: bool = False):
        self.module_dir = module_dir.resolve()
        self.skip_validation = skip_validation
        self.project_root = self._find_project_root()
        self.is_volo_app = self._detect_volo_app()
        self.manifest = self._load_manifest()
        self.package_dir = self.module_dir / "cloudcompile_package"
        self.collected_files: List[PackageFile] = []

    def _find_project_root(self) -> Path:
        """Find project root (contains mcc_templates/)"""
        current = self.module_dir
        while current.parent != current:
            if (current / "mcc_templates").exists():
                return current
            current = current.parent
        raise RuntimeError("Could not find project root (no mcc_templates/ found)")

    def _detect_volo_app(self) -> bool:
        """Check if module is a volo-app (has *_app.yaml)"""
        app_yamls = list(self.module_dir.glob("*_app.yaml"))
        return len(app_yamls) > 0

    def _load_manifest(self) -> Dict:
        """Load mcc_package.yaml or auto-generate from volo-app YAML"""
        manifest_path = self.module_dir / "mcc_package.yaml"

        if manifest_path.exists():
            # Traditional MCC package with explicit manifest
            with open(manifest_path, 'r') as f:
                return yaml.safe_load(f)

        elif self.is_volo_app:
            # VoloApp: Auto-generate manifest from *_app.yaml
            return self._generate_volo_manifest()

        else:
            raise FileNotFoundError(
                f"No mcc_package.yaml or *_app.yaml found in {self.module_dir}\n"
                f"Create mcc_package.yaml with: name, description, files, control_registers, outputs\n"
                f"Or create <AppName>_app.yaml for a volo-app"
            )

    def _generate_volo_manifest(self) -> Dict:
        """Auto-generate manifest from VoloApp YAML"""
        app_yaml_path = list(self.module_dir.glob("*_app.yaml"))[0]

        with open(app_yaml_path, 'r') as f:
            app_config = yaml.safe_load(f)

        # Extract app name and info
        app_name = app_config['name']

        # Auto-discover files from volo_main/ directory
        volo_main_dir = self.module_dir / "volo_main"
        if not volo_main_dir.exists():
            raise FileNotFoundError(
                f"volo_main/ directory not found in {self.module_dir}\n"
                f"Run: python tools/generate_volo_app.py --config {app_yaml_path.name} --output volo_main/"
            )

        # Build file lists
        shim_file = f"{app_name}_volo_shim.vhd"
        main_file = f"{app_name}_volo_main.vhd"

        files = {
            'top': [
                f"volo_main/{shim_file}",
                f"volo_main/{main_file}"
            ]
        }

        # Build control register documentation from VoloApp YAML
        control_registers = [
            {
                'register': 0,
                'bits': [
                    {'range': '31', 'name': 'VOLO_READY', 'description': 'Loader ready (set after deployment)'},
                    {'range': '30', 'name': 'user_enable', 'description': 'User enable/disable'},
                    {'range': '29', 'name': 'clk_enable', 'description': 'Clock enable'}
                ]
            },
            {
                'register': '10-14',
                'bits': [
                    {'range': 'all', 'name': 'BRAM Loader', 'description': '4KB buffer streaming protocol'}
                ]
            }
        ]

        # Add app-specific registers (CR20-CR30)
        for reg in app_config.get('registers', []):
            control_registers.append({
                'register': reg['cr_number'],
                'bits': [
                    {'range': 'all', 'name': reg['name'], 'description': reg['description']}
                ]
            })

        # Generate manifest
        manifest = {
            'name': app_name,
            'description': app_config.get('description', 'VoloApp generated package'),
            'version': app_config.get('version', '1.0.0'),
            'author': app_config.get('author', 'VoloApp'),
            'files': files,
            'dependencies': [
                {
                    'module': 'shared/volo',
                    'files': [
                        'volo_common_pkg.vhd',
                        'volo_bram_loader.vhd',
                        'MCC_TOP_volo_loader.vhd'
                    ]
                }
            ],
            'control_registers': control_registers,
            'outputs': [
                {'port': 'OutputA', 'description': f'{app_name} output A'},
                {'port': 'OutputB', 'description': f'{app_name} output B'}
            ],
            'example_code': '# See VoloApp YAML for usage examples'
        }

        return manifest

    def collect_files(self):
        """Collect all files to include in package"""
        print(f"{Color.YELLOW}[1/5] Collecting files from manifest...{Color.NC}")

        # Collect module files
        for category, file_list in self.manifest.get('files', {}).items():
            for file_path in file_list:
                source = self.module_dir / file_path
                if not source.exists():
                    raise FileNotFoundError(f"File not found: {source}")

                self.collected_files.append(PackageFile(
                    source_path=source,
                    dest_name=source.name,
                    category=category
                ))
                print(f"  ✓ {category}: {source.name}")

        # Collect dependencies
        for dep in self.manifest.get('dependencies', []):
            dep_module = dep['module']

            # Handle different dependency path formats
            if dep_module.startswith('shared/'):
                # Shared library (e.g., shared/volo)
                dep_dir = self.project_root / dep_module
            else:
                # Module dependency (e.g., volo_common)
                dep_dir = self.project_root / "modules" / dep_module

            if not dep_dir.exists():
                raise FileNotFoundError(f"Dependency module not found: {dep_dir}")

            for file_path in dep['files']:
                source = dep_dir / file_path
                if not source.exists():
                    raise FileNotFoundError(f"Dependency file not found: {source}")

                self.collected_files.append(PackageFile(
                    source_path=source,
                    dest_name=source.name,
                    category='dependency'
                ))
                print(f"  ✓ dependency ({dep_module}): {source.name}")

        print(f"{Color.GREEN}  ✓ Collected {len(self.collected_files)} files{Color.NC}")

    def validate_with_ghdl(self) -> bool:
        """Validate package compiles with GHDL"""
        if self.skip_validation:
            print(f"{Color.YELLOW}[2/5] Skipping GHDL validation (--skip-validation){Color.NC}")
            return True

        print(f"{Color.YELLOW}[2/5] Validating with GHDL...{Color.NC}")

        # Check if GHDL is available
        if not shutil.which('ghdl'):
            print(f"{Color.YELLOW}  ! GHDL not found, skipping validation{Color.NC}")
            return True

        # Create temporary work directory
        work_dir = self.module_dir / "ghdl_test_work"
        work_dir.mkdir(exist_ok=True)

        try:
            # Compile mcc-Top.vhd (CustomWrapper entity)
            mcc_top = self.project_root / "mcc_templates" / "mcc-Top.vhd"
            if not mcc_top.exists():
                raise FileNotFoundError(f"mcc-Top.vhd not found: {mcc_top}")

            print("  Analyzing mcc-Top.vhd...")
            subprocess.run(
                ['ghdl', '-a', '--std=08', f'--workdir={work_dir}', str(mcc_top)],
                check=True,
                capture_output=True,
                text=True
            )

            # Compile collected files in order: datadef → dependency → core → top
            # Special handling for volo-apps: compile *_main.vhd before *_shim.vhd
            categories_order = ['datadef', 'dependency', 'core', 'top']

            for category in categories_order:
                category_files = [f for f in self.collected_files if f.category == category]

                # For 'top' category in volo-apps, sort so *_main.vhd comes before *_shim.vhd
                if category == 'top' and self.is_volo_app:
                    # Sort: *_main.vhd first, then *_shim.vhd
                    category_files.sort(key=lambda f: (
                        0 if '_volo_main.vhd' in f.dest_name else
                        1 if '_volo_shim.vhd' in f.dest_name else
                        2
                    ))

                for pkg_file in category_files:
                    print(f"  Analyzing {pkg_file.dest_name}...")
                    subprocess.run(
                        ['ghdl', '-a', '--std=08', f'--workdir={work_dir}', str(pkg_file.source_path)],
                        check=True,
                        capture_output=True,
                        text=True
                    )

            # Elaborate CustomWrapper
            print("  Elaborating CustomWrapper...")
            subprocess.run(
                ['ghdl', '-e', '--std=08', f'--workdir={work_dir}', 'CustomWrapper'],
                check=True,
                capture_output=True,
                text=True
            )

            print(f"{Color.GREEN}  ✓ GHDL validation successful!{Color.NC}")
            return True

        except subprocess.CalledProcessError as e:
            print(f"{Color.RED}  ✗ GHDL validation failed:{Color.NC}")
            print(e.stderr)
            return False

        finally:
            # Clean up test artifacts
            shutil.rmtree(work_dir, ignore_errors=True)

    def create_package_directory(self):
        """Create clean package directory and copy files"""
        print(f"{Color.YELLOW}[3/5] Creating package directory...{Color.NC}")

        # Clean and create
        if self.package_dir.exists():
            shutil.rmtree(self.package_dir)
        self.package_dir.mkdir(parents=True)

        # Copy all collected files
        for pkg_file in self.collected_files:
            dest = self.package_dir / pkg_file.dest_name
            shutil.copy2(pkg_file.source_path, dest)
            print(f"  ✓ Copied: {pkg_file.dest_name}")

        print(f"{Color.GREEN}  ✓ Package directory created{Color.NC}")

    def generate_readme(self):
        """Generate README.txt from manifest"""
        print(f"{Color.YELLOW}[4/5] Generating README.txt...{Color.NC}")

        readme_path = self.package_dir / "README.txt"
        module_name = self.manifest['name']
        description = self.manifest['description']

        # Build file list
        file_list = []
        for pkg_file in self.collected_files:
            file_list.append(f"- {pkg_file.dest_name}: {pkg_file.category} layer")

        # Build control register documentation
        control_regs = []
        for reg in self.manifest.get('control_registers', []):
            reg_num = reg['register']
            control_regs.append(f"\nControl{reg_num}:")
            for bit in reg['bits']:
                control_regs.append(f"  [{bit['range']}]: {bit['name']} - {bit['description']}")

        # Build output documentation
        outputs = []
        for out in self.manifest.get('outputs', []):
            outputs.append(f"- {out['port']}: {out['description']}")

        # Generate README content
        readme_content = f"""{module_name.upper()} - Moku Cloud Compile Package
{'=' * (len(module_name) + 30)}

Module: {module_name}
Description: {description}
Version: {self.manifest.get('version', '1.0.0')}
Author: {self.manifest.get('author', 'Unknown')}

Files Included:
{chr(10).join(file_list)}

IMPORTANT: This package does NOT include mcc-Top.vhd because Moku Cloud
Compile already provides the CustomWrapper entity. Only upload the
architecture (Top.vhd) and your module logic.

Control Register Map:
{''.join(control_regs)}

Output Map:
{chr(10).join(outputs)}

Python MokuBench Usage Example:
{self.manifest.get('example_code', '# No example provided')}

Upload Instructions:
1. Zip this package: zip -r {module_name}.zip *.vhd README.txt
2. Go to Moku Cloud Compile: https://cloud-compile.liquidinstruments.com/
3. Upload {module_name}.zip
4. Wait for synthesis (Vivado takes ~5-10 minutes)
5. Download resulting bitstream.tar.gz
6. Save as: {module_name}.tar.gz
7. Use with MokuBench!

Note: MCC provides CustomWrapper entity automatically. This package only
contains your module logic and CustomWrapper architecture.

Generated by: scripts/build_mcc_package.py
Date: {self.manifest.get('date', 'Unknown')}
"""

        with open(readme_path, 'w') as f:
            f.write(readme_content)

        print(f"{Color.GREEN}  ✓ README.txt generated{Color.NC}")

    def generate_build_manifest(self):
        """Generate BUILD_MANIFEST.txt with git hash and file checksums"""
        import hashlib
        import subprocess
        from datetime import datetime

        manifest_path = self.package_dir / "BUILD_MANIFEST.txt"

        # Get git info
        try:
            git_hash = subprocess.check_output(
                ['git', 'rev-parse', 'HEAD'],
                cwd=self.module_dir,
                stderr=subprocess.DEVNULL
            ).decode().strip()
            git_branch = subprocess.check_output(
                ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
                cwd=self.module_dir,
                stderr=subprocess.DEVNULL
            ).decode().strip()
            git_status = subprocess.check_output(
                ['git', 'status', '--porcelain'],
                cwd=self.module_dir,
                stderr=subprocess.DEVNULL
            ).decode().strip()
            has_uncommitted = len(git_status) > 0
        except:
            git_hash = "Unknown (not in git repo)"
            git_branch = "Unknown"
            has_uncommitted = False

        # Compute file checksums
        file_checksums = []
        for vhd_file in sorted(self.package_dir.glob("*.vhd")):
            with open(vhd_file, 'rb') as f:
                sha256 = hashlib.sha256(f.read()).hexdigest()
            file_checksums.append(f"  {vhd_file.name:40} SHA256: {sha256}")

        manifest_content = f"""{'=' * 70}
BUILD MANIFEST
{'=' * 70}

Build Time: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}
Module: {self.manifest['name']}
Version: {self.manifest.get('version', '1.0.0')}

Git Information:
  Commit: {git_hash}
  Branch: {git_branch}
  {"⚠ UNCOMMITTED CHANGES PRESENT!" if has_uncommitted else "✓ Clean working tree"}

Files Included (with SHA256 checksums):
{chr(10).join(file_checksums)}

Notes:
  - This manifest tracks the exact source code used for Cloud Compile
  - Compare checksums to verify bitstream matches source
  - Git hash allows reproduction of exact build

Generated by: scripts/build_mcc_package.py
"""

        with open(manifest_path, 'w') as f:
            f.write(manifest_content)

        print(f"{Color.GREEN}  ✓ BUILD_MANIFEST.txt generated{Color.NC}")

    def create_zip(self):
        """Create ZIP archive of package"""
        print(f"{Color.YELLOW}[5/5] Creating ZIP archive...{Color.NC}")

        module_name = self.manifest['name']
        zip_path = self.package_dir / f"{module_name}.zip"

        # Remove old zip if exists
        if zip_path.exists():
            zip_path.unlink()

        # Create zip archive
        shutil.make_archive(
            str(self.package_dir / module_name),
            'zip',
            self.package_dir,
            '.'
        )

        zip_size = zip_path.stat().st_size / 1024  # KB
        print(f"{Color.GREEN}  ✓ Created: {zip_path.name} ({zip_size:.1f} KB){Color.NC}")

    def build(self) -> bool:
        """Execute full build pipeline"""
        print(f"{Color.GREEN}{'=' * 70}{Color.NC}")
        print(f"{Color.GREEN}MCC Package Builder - {self.manifest['name']}{Color.NC}")
        print(f"{Color.GREEN}{'=' * 70}{Color.NC}")
        print()

        try:
            self.collect_files()
            if not self.validate_with_ghdl():
                return False
            self.create_package_directory()
            self.generate_readme()
            self.generate_build_manifest()
            self.create_zip()

            print()
            print(f"{Color.GREEN}{'=' * 70}{Color.NC}")
            print(f"{Color.GREEN}✓ Package ready: {self.package_dir}{Color.NC}")
            print(f"{Color.GREEN}{'=' * 70}{Color.NC}")
            print()
            print("Next steps:")
            print(f"1. Upload to CloudCompile:")
            print(f"   • Open {self.package_dir}/")
            print(f"   • Upload {self.manifest['name']}.zip to Moku Cloud Compile")
            print()
            print(f"2. After synthesis completes (~5-10 min):")
            print(f"   • Download 25ff*_synthesis.log and 25ff*_bitstreams.tar from CloudCompile")
            print(f"   • Create incoming/ folder if needed:")
            print(f"     mkdir -p {self.module_dir}/incoming")
            print(f"   • Move files to incoming/:")
            print(f"     mv ~/Downloads/25ff*_mokugo_* {self.module_dir}/incoming/")
            print()
            print(f"3. Import and test:")
            print(f"   python scripts/import_mcc_build.py {self.module_dir}")
            print()
            return True

        except Exception as e:
            print(f"{Color.RED}✗ Build failed: {e}{Color.NC}")
            return False


def main():
    parser = argparse.ArgumentParser(
        description='Build MCC CloudCompile package from YAML manifest',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Build PulseStar package
  python3 scripts/build_mcc_package.py modules/PulseStar

  # Build without GHDL validation
  python3 scripts/build_mcc_package.py modules/simple_counter --skip-validation

  # Build from any directory (uses absolute paths)
  cd modules/PulseStar
  python3 ../../scripts/build_mcc_package.py .
        """
    )

    parser.add_argument(
        'module_dir',
        type=Path,
        help='Path to module directory (must contain mcc_package.yaml)'
    )

    parser.add_argument(
        '--skip-validation',
        action='store_true',
        help='Skip GHDL compilation validation'
    )

    args = parser.parse_args()

    # Build package
    builder = MCCPackageBuilder(args.module_dir, skip_validation=args.skip_validation)
    success = builder.build()

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
