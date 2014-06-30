if [ "$#" -ne 2 ]; then
    echo "Please provide the SpriteBuilder version and sku [default|pro]."
    echo "eg ./CreateAllGeneratedFiles 0.9 pro"
    exit 1
fi

if [ "$(basename "$(pwd)")" == "scripts" ]; then
    cd ..
fi

if [ ! -d "SpriteBuilder" ]; then
    echo "Please execute this script from within the SpriteBuilder's scripts folder"
    exit 1
fi


if [ "$2" = "pro" ]; then
	echo "=== GENERATING Android Plugin ==="
	rm "Generated/AndroidPlugin.zip";
	python "SpriteBuilder/libs/AndroidPlugin/plugin_installer.py" package "Generated/AndroidPlugin.zip";
	exit 1
fi



# Update version for about box
echo "Version: $1" > Generated/Version.txt
echo "Sku: $2" >> Generated/Version.txt
echo "GitHub: " >> Generated/Version.txt
git rev-parse --short=10 HEAD >> Generated/Version.txt
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
