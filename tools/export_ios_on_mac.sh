#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
preset_file="$project_root/export_presets.cfg"
output_dir="$project_root/build/ios-xcode"
output_path="$output_dir/AksoyTank.ipa"

if grep -q 'application/app_store_team_id="YOURTEAMID"' "$preset_file"; then
	echo 'HATA: Once gercek Apple Team ID ile tools/configure_ios.ps1 calistirilmali.' >&2
	exit 1
fi

sdk_version="$(xcrun --sdk iphoneos --show-sdk-version)"
sdk_major="${sdk_version%%.*}"
if (( sdk_major < 26 )); then
	echo "HATA: App Store yuklemesi icin iOS 26 SDK veya yenisi gerekli. Bulunan: $sdk_version" >&2
	exit 1
fi

mkdir -p "$output_dir"
"$godot_bin" --headless --path "$project_root" --import --quit
"$godot_bin" --headless --path "$project_root" --export-release 'iOS' "$output_path"

xcode_project="$(find "$output_dir" -maxdepth 2 -name '*.xcodeproj' -print -quit)"
if [[ -z "$xcode_project" ]]; then
	echo 'HATA: Godot Xcode projesi olusturmadi.' >&2
	exit 1
fi

echo "Xcode projesi hazir: $xcode_project"
echo 'Projeyi Xcode ile ac, Signing & Capabilities altinda Team sec, sonra Product > Archive kullan.'
