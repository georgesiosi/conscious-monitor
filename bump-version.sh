#!/bin/bash

# Version Bump Script for FocusMonitor
# Usage: ./bump-version.sh [major|minor|patch]

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get current version from CHANGELOG.md
CURRENT_VERSION=$(grep -E "## \[Unreleased\]" -A 50 CHANGELOG.md | grep -E "## \[[0-9]+\.[0-9]+\.[0-9]+\]" | head -1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+")

if [ -z "$CURRENT_VERSION" ]; then
    CURRENT_VERSION="0.0.0"
    echo -e "${YELLOW}No version found in CHANGELOG. Starting from 0.0.0${NC}"
fi

# Parse version components
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR="${VERSION_PARTS[0]}"
MINOR="${VERSION_PARTS[1]}"
PATCH="${VERSION_PARTS[2]}"

# Determine version bump type
BUMP_TYPE="${1:-patch}"

case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo -e "${RED}Invalid bump type. Use: major, minor, or patch${NC}"
        exit 1
        ;;
esac

NEW_VERSION="${MAJOR}.${MINOR}.${PATCH}"
DATE=$(date +%Y-%m-%d)

echo -e "${GREEN}Bumping version from ${CURRENT_VERSION} to ${NEW_VERSION}${NC}"

# Update CHANGELOG.md
echo "📝 Updating CHANGELOG.md..."
# Create a temporary file with the new version section
cat > /tmp/changelog_update.tmp << EOF
## [Unreleased]

### Added
- 

### Changed
- 

### Fixed
- 

## [${NEW_VERSION}] - ${DATE}
EOF

# Get the content after [Unreleased] section
sed -n '/## \[Unreleased\]/,/## \[[0-9]/p' CHANGELOG.md | sed '1d;$d' >> /tmp/changelog_update.tmp

# Get the rest of the changelog
sed -n '/## \[[0-9]/,$p' CHANGELOG.md >> /tmp/changelog_update.tmp

# Create the new changelog
head -n $(grep -n "## \[Unreleased\]" CHANGELOG.md | cut -d: -f1 | head -1) CHANGELOG.md | sed '$d' > /tmp/new_changelog.tmp
cat /tmp/changelog_update.tmp >> /tmp/new_changelog.tmp

# Replace the original file
mv /tmp/new_changelog.tmp CHANGELOG.md
rm /tmp/changelog_update.tmp

echo -e "${GREEN}✓ CHANGELOG.md updated${NC}"

# Instructions for Xcode
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Manual Xcode Updates Required${NC}"
echo ""
echo "Please update the following in Xcode:"
echo "1. Select your project in the navigator"
echo "2. Select the FocusMonitor target"
echo "3. Under 'General' tab:"
echo "   - Set Version to: ${NEW_VERSION}"
echo "   - Increment Build number"
echo "4. Also update the bundle identifier if needed:"
echo "   - Current: gsd.FocusMonitor-v0"
echo "   - Suggested: com.yourname.focusmonitor"
echo ""
echo "After updating Xcode, you can:"
echo "1. Archive the app (Product → Archive)"
echo "2. Run ./create-installer.sh to create the DMG"
echo "3. Create a git tag: git tag -a v${NEW_VERSION} -m \"Release version ${NEW_VERSION}\""
echo "4. Push the tag: git push origin v${NEW_VERSION}"
