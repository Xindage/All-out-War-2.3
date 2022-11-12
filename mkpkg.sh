#!/bin/bash
echo "Cleaning old data."
rm OUTPUT/*

echo "Obtaining date variable."
vardate=$(date +"%y%m%d")
echo "Result is : $vardate"

# Generate data pk3.
# Here is compressed all visual and auditive data of the game but musics.
zip -Ar0 OUTPUT/aow2.3_data_r$vardate.pk3 animdefs.txt colormap.dat dbigfont.lmp decaldef.txt fontdefs.txt hirestex.txt hirestex.weapons.txt keyconf.txt modeldef.txt notch.dat playpal.pal sbarinfo.txt skininfo.txt sndinfo* sndseq.txt startup.dat terrain.txt textures.iwadfix.txt textures.txt textures/* sprites/* sounds/* patches/* models/* graphics/* flats/*

# Generate code pk3.
# Here is compressed all the actors and acs from the source into the file.
echo "Generating code package."
# Compile the acs.
acc source/aow2scrp.acs acs/aow2scrp.o
echo "ACS source was compiled successfully!"
zip -Ar0 OUTPUT/aow2.3_code_r$vardate.pk3 cvarinfo.txt decorate.txt gameinfo.txt gldefs.txt language.txt loadacs.txt teaminfo.txt TextColours.txt TextColours2.txt TextColours3.txt TextColours4.txt TextColours5.txt  acs/* source/* actors/* credits/*

# Generate maps pk3.
echo "Generating maps package."
zip -0 OUTPUT/aow2.3_maps_r$vardate.pk3 mapinfo.txt maps/* credmaps/*

# Generate music pk3.
zip -0 OUTPUT/aow2.3_music_r$vardate.pk3 music/* credmus/*
