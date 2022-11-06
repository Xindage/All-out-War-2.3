#!/bin/bash
echo "Cleaning old data."
rm OUTPUT/*

echo "Obtaining date variable."
vardate=$(date +"%y%m%d")
echo "Result is : $vardate"

# Generate data pk7.
# Here is compressed all visual and auditive data of the game but musics.
7z a OUTPUT/aow2.3_data_r$vardate.pk7 animadef.txt colormap.dat dbigfont.lmp decaldef.txt fontdefs.txt hirestex.txt keyconf.txt modeldef.txt notch.dat playpal.pal sbarinfo.txt skininfo.txt sndinfo.txt sndseq.txt startup.dat terrain.txt textures.iwadfix.txt textures.txt -r textures/* sprites/* sounds/* patches/* models/* graphics/* flats/* -m0=copy

# Generate code pk7.
# Here is compressed all the actors and acs from the source into the file.
echo "Generating code package."
# Compile the acs.
acc source/aow2scrp.acs acs/aow2scrp.o
echo "ACS source was compiled successfully!"
7z a OUTPUT/aow2.3_code_r$vardate.pk7 cvarinfo.txt decorate.txt gameinfo.txt gldefs.txt language.txt loadacs.txt teaminfo.txt TextColours.txt TextColours2.txt TextColours3.txt TextColours4.txt TextColours5.txt -r acs/* source/* actors/* credits/* -m0=copy

# Generate maps pk7.
echo "Generating maps package."
7z a OUTPUT/aow2.3_maps_r$vardate.pk7 mapinfo.txt maps/* credmaps/* -m0=copy

# Generate music pk7.
7z a OUTPUT/aow2.3_music_r$vardate.pk7 music/* credmus/* -m0=copy
