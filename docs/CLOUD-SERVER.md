# Run the public server in the cloud (always on, free)

Your PC can be off: the server runs on a small free computer from **Oracle Cloud** ("Always Free").
Players keep the same game file: `ninjaonline.duckdns.org` is pointed at the new computer.

## 1. Make the Oracle account
1. Go to **cloud.oracle.com** and click **Sign up** (Free Tier).
2. Fill in your details. **Home region:** pick one close to you (e.g. *Netherlands Northwest (Amsterdam)* or *Germany Central (Frankfurt)*).
   You can't change it later.
3. It asks for a credit card to check you're a real person. Always Free things never cost anything.

## 2. Make the computer
1. Log in, open the menu **☰** > **Compute** > **Instances** > **Create instance**.
2. **Name:** `hellobro`.
3. **Image and shape** > **Edit**:
   - **Change image** > **Ubuntu** > *Canonical Ubuntu 24.04* > **Select image**.
   - **Change shape** > **Ampere** > *VM.Standard.A1.Flex*, 1 OCPU, 6 GB memory > **Select shape**.
     If it says *out of capacity*, pick **Specialty and previous generation** > *VM.Standard.E2.1.Micro* instead (also free, strong enough).
4. **Networking:** leave it as it is (it makes a new network; *Assign a public IPv4 address* stays on).
5. **Add SSH keys:** choose **Generate a key pair for me** and click **Save private key**. Keep that file (e.g. on your Desktop):
   it is the key to this computer.
6. Click **Create**. After a minute the instance says **Running**. Write down its **Public IP address**.

## 3. Open port 18080
1. On the instance page, under **Primary VNIC**, click the **Subnet** link.
2. **Security Lists** > **Default Security List for ...** > **Add Ingress Rules**:
   - Source CIDR: `0.0.0.0/0`
   - IP Protocol: `TCP`
   - Destination Port Range: `18080`
3. **Add Ingress Rules**.

## 4. Install the server
Close the public server on your PC first (both can't own the same save).
Then the install, copying your save `public.db` and its admin password are done from your PC over SSH
(Claude does this for you; by hand: `ssh -i <key file> ubuntu@<public IP>` and run
`curl -fsSL https://raw.githubusercontent.com/Djassie18698/hello-bro-revival/main/tools/vps/install.sh | sudo sh`).

## 5. Point DuckDNS at it
On **duckdns.org**, log in, type the computer's **Public IP** in the *current ip* box of `ninjaonline` and click **update ip**.
If a DuckDNS updater runs on your PC, turn it off, or it puts your PC's address back.

## Later
- Update to the newest version: `sudo sh /opt/hellobro/tools/vps/update.sh`
- Change the admin password: `sudo sh /opt/hellobro/tools/vps/password.sh`
- Control panel: `http://ninjaonline.duckdns.org:18080/manager` (your admin password). Backups are made every 6 hours in `/opt/hellobro/backups-public`.
- See what the server prints: `sudo journalctl -u hellobro -f`
