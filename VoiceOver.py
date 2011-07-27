#!/usr/bin/python

##
# Script that generates VoiceOver files for iPod shuffle. Taken from:
# http://pastebin.com/LJt97Gqb
##
import gpod
import os
import subprocess

ipod_mpoint = "/media/IPOD"
speakable_path = os.path.join(ipod_mpoint,
				"iPod_Control",
				"Speakable")

tracks_speakable_path = os.path.join(speakable_path, "Tracks")
playlists_speakable_path = os.path.join(speakable_path, "Playlists")

voiceover_format = "%s from %s."

def get_voiceovers():
	db = gpod.Database(ipod_mpoint)
	
	# Create voiceovers for tracks
	for track in db:
		dbid = hex(track["dbid"])[2:-1].upper()
		dbid = dbid.rjust(16, '0')

		out_file = os.path.join(tracks_speakable_path, dbid + ".wav")

		if os.path.exists(out_file):
			continue
		
		voiceover = voiceover_format % (track["title"], track["artist"])
		yield (voiceover, out_file)

	# Create voiceovers for playlists
	for pl in db.get_playlists():
		if pl.master or pl.podcast:
			continue

		id = hex(pl.id)[2:-1].upper()
		id = id.rjust(16, '0')
		
		out_file = os.path.join(playlists_speakable_path, id + ".wav")

		if os.path.exists(out_file):
			continue
		
		yield (pl.name, out_file)

for voiceover, out_file in get_voiceovers():
	print "Creating voiceover %s" % out_file
	convert = subprocess.Popen(
			("espeak", "-w", out_file, "-ven-rp", "-s 150"),
			stdin = subprocess.PIPE)
	convert.communicate(voiceover)