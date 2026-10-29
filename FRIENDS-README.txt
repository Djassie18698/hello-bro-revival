PLAYING WITH A FRIEND
=====================
Everyone plays on YOUR PC's server. Each person gets their own character automatically (just press START).
Other players show up in the Spar (rival) list. Anyone can use the admin page to give themselves gold/characters.

A) Friend is on the SAME Wi-Fi / network as your PC
   1. On your PC: right-click OPEN-FIREWALL.bat -> Run as administrator (once).
   2. Start the server (START-SERVER.bat) and keep that window open.
   3. Give your friend HelloBro-revival.xapk (it is on the Desktop). They install it in BlueStacks or
      with an XAPK installer on an Android phone.
   NOTE: the game is set to connect to 192.168.178.111. If your PC's address changes (it can after a router restart),
   run MAKE-FRIEND-APK.bat with the new address and use that file for yourself and your friend.

B) Friend is somewhere else (different house)
   1. Both of you install a free virtual-network program such as Radmin VPN or Tailscale and join the same network.
      Your PC gets an address like 26.x.x.x (Radmin) or 100.x.x.x (Tailscale).
   2. Run MAKE-FRIEND-APK.bat, type that address. It creates HelloBro-for-<address>.apk on the Desktop.
   3. Friend installs that APK AND copies the data file main.28.com.hello.bro.yo.obb
      (inside HelloBro-revival.xapk, folder Android\obb\com.hello.bro.yo\) to their phone folder
      Android/obb/com.hello.bro.yo/ . In BlueStacks you can instead install the xapk once, then install the new apk over it.
   4. OPEN-FIREWALL.bat on your PC (once) and keep START-SERVER.bat running.

Admin page (give gold, characters, set level): http://<server address>:18080/admin
Known problems: Gacha result screens show placeholders but cards are added.
