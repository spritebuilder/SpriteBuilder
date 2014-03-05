#!/bin/bash

INPUTDIR=$1
OUTPUTDIR=$2

echo Generating Sprite Kit Texture Atlas
echo Input: $INPUTDIR
echo Output: $OUTPUTDIR

/Applications/Xcode.app/Contents/Developer/usr/bin/TextureAtlas -v "$INPUTDIR" "$OUTPUTDIR"
