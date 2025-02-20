#!/bin/bash

# Created By Asi Givati 2024
# NOTE: This script must be located in the root directory of the framework's Xcode project.
# To run the script, navigate to its directory in the terminal and execute:
# ./create_xcframework.sh

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Function to run xcodebuild with optional silent mode
run_xcodebuild() {
    if [[ $silentFlag == "true" ]]; then
        "$@" > /dev/null 2>&1
    else
        "$@"
    fi
}

# Function to search for and replace existing XCFrameworks
replace_old_xcframeworks() {
    echo "Searching for existing XCFrameworks with name '$projectName.xcframework'..."

    searchPaths=("$HOME/Documents" "$HOME/Projects" "$HOME/Desktop" "$PWD")
    existingFiles=()

    for path in "${searchPaths[@]}"; do
        if [ -d "$path" ]; then
            while IFS= read -r -d '' file; do
                if [[ ! " ${existingFiles[*]} " =~ " ${file} " && "$file" != "$PWD/build/$projectName.xcframework" ]]; then
                    existingFiles+=("$file")
                fi
            done < <(find "$path" -type d -name "$projectName.xcframework" -print0 2>/dev/null)
        fi
    done

    if [ ${#existingFiles[@]} -gt 0 ]; then
        echo -e "${RED}The following locations have existing XCFrameworks:${RESET}"
        for file in "${existingFiles[@]}"; do
            echo -e "${RED}$file${RESET}"
        done

        while true; do
            read -p "Do you want to replace these files with the new XCFramework? (Y/N): " replaceChoice
            case $replaceChoice in
                [Yy])
                    echo "Replacing old XCFrameworks with the newly created one..."
                    for file in "${existingFiles[@]}"; do
                        destinationDir=$(dirname "$file")
                        echo "Replacing in $destinationDir..."
#                        rm -rf "$file"
                        if cp -R -f "$outputXCFramework" "$destinationDir"; then
                            echo -e "${GREEN}Replaced XCFramework in $destinationDir${RESET}"
                        else
                            echo -e "${RED}Failed to copy XCFramework to $destinationDir${RESET}"
                        fi
                    done
                    break
                    ;;
                [Nn])
                    echo -e "${GREEN}No files were replaced.${RESET}"
                    break
                    ;;
                *)
                    echo -e "${RED}Invalid choice. Please enter Y or N.${RESET}"
                    ;;
            esac
        done
    else
        echo -e "${GREEN}No previous locations to replace the XCFramework.${RESET}"
    fi
}

# Function to archive for iOS
archive_ios() {
    echo "Archiving for iOS..."
    if run_xcodebuild xcodebuild archive \
        -scheme "$projectName" \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -archivePath "$iosArchivePath" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES; then
        echo -e "${GREEN}iOS archive created.${RESET}"
    else
        echo -e "${RED}Failed to create iOS archive.${RESET}"
        exit 1
    fi
}

# Function to archive for iOS Simulator
archive_simulator() {
    echo "Archiving for iOS Simulator..."
    if run_xcodebuild xcodebuild archive \
        -scheme "$projectName" \
        -configuration Release \
        -destination 'generic/platform=iOS Simulator' \
        -archivePath "$simulatorArchivePath" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES; then
        echo -e "${GREEN}iOS Simulator archive created.${RESET}"
    else
        echo -e "${RED}Failed to create iOS Simulator archive.${RESET}"
        exit 1
    fi
}

# Function to archive for Mac
archive_mac() {
    echo "Archiving for Mac..."
    if run_xcodebuild xcodebuild archive \
        -scheme "$projectName" \
        -configuration Release \
        -destination 'platform=macOS' \
        -archivePath "$macArchivePath" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES; then
        echo -e "${GREEN}Mac archive created.${RESET}"
    else
        echo -e "${RED}Failed to create Mac archive.${RESET}"
        exit 1
    fi
}

# Function to create XCFramework
create_xcframework() {
    echo "Creating XCFramework..."
    if [ -d "$outputXCFramework" ]; then
        echo "Removing existing XCFramework..."
        rm -rf "$outputXCFramework"
    fi

    local args=()
    for framework in "$@"; do
        args+=("-framework" "$framework")
    done

    if run_xcodebuild xcodebuild -create-xcframework \
        "${args[@]}" \
        -output "$outputXCFramework"; then
        echo -e "${GREEN}XCFramework created successfully.${RESET}"
    else
        echo -e "${RED}Failed to create XCFramework.${RESET}"
        exit 1
    fi
}

# Main script logic
defaultProjectName=$(basename "$PWD")

read -p "Enter the project name (default: $defaultProjectName): " projectName

if [ -z "$projectName" ]; then
    projectName=$defaultProjectName
fi

# Define paths
iosArchivePath="./build/$projectName.framework-iphoneos.xcarchive"
simulatorArchivePath="./build/$projectName.framework-iphonesimulator.xcarchive"
macArchivePath="./build/$projectName.framework-catalyst.xcarchive"

iosFrameworkPath="$iosArchivePath/Products/Library/Frameworks/$projectName.framework"
simulatorFrameworkPath="$simulatorArchivePath/Products/Library/Frameworks/$projectName.framework"
macFrameworkPath="$macArchivePath/Products/Library/Frameworks/$projectName.framework"

outputXCFramework="./build/$projectName.xcframework"

# Silent mode
read -p "Do you want silent output? (Y/N, default: Y): " silentMode
silentMode=${silentMode:-Y}

if [[ $silentMode == "Y" || $silentMode == "y" ]]; then
    silentFlag="true"
else
    silentFlag="false"
fi

# Delete archive files option
read -p "Do you want to delete the archive files after creating the XCFramework? (Y/N, default: Y): " deleteArchives
deleteArchives=${deleteArchives:-Y}

# Platform selection
echo "Select the platform to archive (default: 1):"
echo "1) iOS & Simulator"
echo "2) Mac"
echo "3) All"
read -p "Enter your choice (1/2/3): " platformChoice
platformChoice=${platformChoice:-1}

case $platformChoice in
    1)
        archive_ios
        archive_simulator
        create_xcframework "$iosFrameworkPath" "$simulatorFrameworkPath"
        ;;
    2)
        archive_mac
        create_xcframework "$macFrameworkPath"
        ;;
    3)
        archive_ios
        archive_simulator
        archive_mac
        create_xcframework "$iosFrameworkPath" "$simulatorFrameworkPath" "$macFrameworkPath"
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting...${RESET}"
        exit 1
        ;;
esac

replace_old_xcframeworks

if [[ $deleteArchives == "Y" || $deleteArchives == "y" ]]; then
    echo "Deleting archive files..."
    if rm -rf ./build/*.xcarchive; then
        echo -e "${GREEN}Archive files deleted.${RESET}"
    else
        echo -e "${RED}Failed to delete archive files.${RESET}"
    fi
else
    echo -e "${GREEN}Archive files retained.${RESET}"
fi

echo -e "${GREEN}Archiving completed.${RESET}"
