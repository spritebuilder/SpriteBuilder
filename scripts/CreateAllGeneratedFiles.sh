if [ "$(basename "$(pwd)")" == "scripts" ]; then
    cd ..
fi

if [ ! -d "SpriteBuilder" ]; then
    echo "Please execute this script from within the SpriteBuilder's scripts folder"
    exit 1
fi

mkdir -p Generated

# Update version for about box
echo "{" > Generated/Version.txt
echo "\"version\": $1 , ">> Generated/Version.txt
echo "\"sku\": \"$2\" ," >> Generated/Version.txt
git rev-parse --short=10 HEAD | tr '\n' '\0' | xargs -0 -I % echo "\"github\" : \"%\"" >> Generated/Version.txt
echo "}" >> Generated/Version.txt
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
