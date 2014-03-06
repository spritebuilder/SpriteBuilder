#!/bin/bash

INPUTDIR=$1
OUTPUTDIR=$2

echo Generating Sprite Kit Texture Atlas: $3
#echo Input: $INPUTDIR
#echo Output: $OUTPUTDIR

# Modify path to TextureAtlas tool if you want to use the tool from a different Xcode version, ie an Xcode beta version
/Applications/Xcode.app/Contents/Developer/usr/bin/TextureAtlas "$INPUTDIR" "$OUTPUTDIR"
