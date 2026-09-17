#!/usr/bin/env bash
set -euo pipefail

repository_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
install_dir="${CODENCE_INSTALL_DIR:-${HOME}/Applications}"
derived_data_dir="${repository_dir}/.build/xcode-derived-data"
destination="${install_dir}/Codence.app"
build_log="${derived_data_dir}/codence-build.log"

if ! xcodebuild -version >/dev/null 2>&1; then
    echo "Codence needs the full Xcode app to build from source. Install Xcode, open it once, then rerun this script." >&2
    exit 1
fi

if [[ -e "$destination" || -L "$destination" ]]; then
    echo "An app already exists at $destination" >&2
    echo "Quit Codence and move that app to Trash before installing this build." >&2
    exit 1
fi

echo "Building Codence (Release, local unsigned build)..."
mkdir -p "$derived_data_dir"
if ! xcodebuild -quiet \
    -project "${repository_dir}/Codence.xcodeproj" \
    -scheme Codence \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$derived_data_dir" \
    CODE_SIGNING_ALLOWED=NO \
    build >"$build_log" 2>&1; then
    echo "Build failed. The last 60 lines of the Xcode log follow:" >&2
    tail -n 60 "$build_log" >&2
    exit 1
fi

built_app="${derived_data_dir}/Build/Products/Release/Codence.app"
if [[ ! -x "${built_app}/Contents/MacOS/Codence" ]]; then
    echo "Build finished without a runnable Codence.app." >&2
    exit 1
fi

mkdir -p "$install_dir"
ditto "$built_app" "$destination"

echo "Installed: $destination"
echo "Open it with: open \"$destination\""
echo "Codence only appears in the menu bar; it does not open a Dock window."
