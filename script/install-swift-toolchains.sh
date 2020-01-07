#!/bin/bash

declare -a toolchains=("swift-5.0-RELEASE" "swift-5.1-RELEASE")

is_toolchain_installed() {

  [[ $1 =~ [0-9\.]+ ]]
  version="${BASH_REMATCH[0]}"

  toolchain_id=$(plutil -extract CFBundleIdentifier xml1 -o - "/Library/Developer/Toolchains/${1}.xctoolchain/Info.plist" | sed -n "s/.*<string>\(.*\)<\/string>.*/\1/p")
  reported_version=$(xcrun --toolchain "$toolchain_id" swift --version)
  
  regex="Apple Swift version $version \($1\)"
  if [[ $reported_version =~ $regex ]]; then
    true
  else
    false
  fi  
}

for toolchain in "${toolchains[@]}"; do

  echo ""

  echo "Checking for toolchain ${toolchain}..."
  if is_toolchain_installed $toolchain; then
    echo "Already installed, skipping..."
    continue
  else
    echo "Not found"
  fi

  mkdir -p "Toolchains"

  echo "Downloading toolchain ${toolchain}..."
  lower=$(echo "$toolchain" | awk '{print tolower($0)}')
  (cd Toolchains && curl -O "https://swift.org/builds/${lower}/xcode/${toolchain}/${toolchain}-osx.pkg")

  echo "Extracting package..."
  (cd Toolchains && xar -xf "${toolchain}-osx.pkg")
  
  echo "Creating destination directory..."
  sudo mkdir -p "/Library/Developer/Toolchains/${toolchain}.xctoolchain"
  
  echo "Installing toolchain..."
  sudo tar -xzf "Toolchains/${toolchain}-osx-package.pkg/Payload" -C "/Library/Developer/Toolchains/${toolchain}.xctoolchain"

  echo "Verifying installation..."
  if is_toolchain_installed $toolchain; then
    echo "Installed successfully"
  else
    echo "ERROR: Failed to install toolchain ${toolchain}"
    exit 1
  fi

done

echo ""
