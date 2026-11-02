Signing key for every patched game file (apk / xapk). ALWAYS sign with this one, never make a new key:
the game only installs over an older copy when the key is the same.
keystore: revival.keystore   password: revival   alias: revival

Files here:
- classes-revival.dex      the game's Java code with the account window pointed at our server (gumplogin.js)
- HelloBro-for-*.apk       game files built for one server address (made by tools/make_game_for.py; not in git)
The downloadable game files (.xapk) are on the GitHub Releases page, tag "tailscale-play".
