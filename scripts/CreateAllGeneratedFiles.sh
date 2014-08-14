if [ "$(basename "$(pwd)")" == "scripts" ]; then
    cd ..
fi

if [ ! -d "SpriteBuilder" ]; then
    echo "Please execute this script from within the SpriteBuilder's scripts folder"
    exit 1
fi

# Update version for about box
echo "Version: $1" > Generated/Version.txt
GITHUB_SKU=$(git rev-parse --short=10 HEAD)
echo "GitHub: $GITHUB_SKU" >> Generated/Version.txt

echo "=== GENERATING SpriteBuilder version file ==="
touch Generated/Version.txt

# Copy cocos2d version file to generated
echo "=== GENERATING COCOS2D version file ==="
cp SpriteBuilder/libs/cocos2d-iphone/VERSION Generated/cocos2d_version.txt

# Generate default projects
echo "=== GENERATING COCOS2D SB-PROJECT ==="
bash scripts/GenerateTemplateProject.sh PROJECTNAME

echo "=== GENERATING SPRITE KIT SB-PROJECT ==="
bash scripts/GenerateTemplateProject.sh SPRITEKITPROJECTNAME
