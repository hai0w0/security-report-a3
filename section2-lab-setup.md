# Section 2 Lab — Environment Setup, Fixes, and Restart Guide

This documents the exact setup process for the `Labsetup-xss` Docker lab
(Section 2, Cross-Site Scripting) on the `seed@VM`, the real conflict hit
while bringing it up alongside the Section 1 lab, and how to bring either lab
back up after the VM is rebooted. This is infrastructure setup only — it does
not contain any of the XSS payloads themselves (see `section2-lab-guide.md`
for those, once written).

## 0. Location

All commands below are run from the folder that contains `docker-compose.yml`
for this lab, e.g.:
```bash
cd ~/.../Labsetup-xss/Labsetup
```
(adjust to your actual path — this is the folder produced by extracting
`Labsetup-xss.zip`, containing `docker-compose.yml`, `image_mysql/`,
`image_www/`).

## 1. Verified accounts and target

The target is the same hostname as Section 1, `http://www.seed-server.com/`,
but a different application (Elgg, not the SQL lab's PHP app). Confirmed from
page 6 of the Assignment 3 brief and cross-checked against the seeded
usernames in `image_mysql/elgg.sql`:

| Username | Password    |
|----------|-------------|
| admin    | seedadmin   |
| alice    | seedalice   |
| boby     | seedboby    |
| charlie  | seedcharlie |
| samy     | seedsamy    |

---

## 2. ⚠️ Critical: this lab cannot run at the same time as `Labsetup-sql-3`

`Labsetup-xss/Labsetup/docker-compose.yml` and `Labsetup-sql-3/Labsetup/docker-compose.yml`
both define:
- the same Docker network name, `net-10.9.0.0`, on the same subnet `10.9.0.0/24`;
- a MySQL container with the **identical name** `mysql-10.9.0.6`, on IP `10.9.0.6`;
- a web container on IP `10.9.0.5` (named `www-10.9.0.5` for the SQL lab,
  `elgg-10.9.0.5` for the XSS lab).

Because the MySQL container name is identical, you cannot have both labs'
`mysql` containers created at once — `docker-compose up -d` fails with:
```
ERROR: for mysql-10.9.0.6  Cannot create container for service mysql: Conflict.
The container name "/mysql-10.9.0.6" is already in use by container ...
```
This is a **name reservation**, not just a running-container conflict: a
*stopped* container still holds its name. `docker-compose stop` on the other
lab is **not enough** — you must `docker-compose down` it first.

`docker-compose down` is safe for the SQL lab specifically, because its MySQL
data lives in the bind-mounted `./mysql_data/` folder on the VM's disk (see
`section1-lab-setup.md`) — removing the container does not delete that data.

## 3. ⚠️ Critical: this lab's MySQL container has no persistent bind mount

Unlike the SQL lab, `Labsetup-xss/Labsetup/docker-compose.yml`'s `mysql`
service has **no `volumes:` entry**. Its database lives only in the
container's own writable layer. This means:

- Stopping/starting the container (`docker-compose stop` / `start`, or a VM
  reboot with `restart: always` bringing it back) **preserves data** — the
  same container keeps running.
- **`docker-compose down` destroys the database**, including any saved "About
  me" XSS payloads or profile edits from Q2.1–Q2.4 — a fresh `up -d`
  afterwards recreates the container from the original `elgg.sql` seed data.

**Practical consequence:** once this lab is up, avoid `docker-compose down`
on it until you are completely finished recording Section 2. If you must
switch back to the SQL lab and then return to this one, plan to redo whatever
"About me" payload you were demonstrating (it only takes a few seconds to
re-paste).

---

## 4. First-time setup (from a clean checkout)

### 4.1 Make sure the SQL lab is fully removed, not just stopped

```bash
cd ~/.../Labsetup-sql-3/Labsetup
docker-compose down
```
Expect `Removing www-10.9.0.5 ... done`, `Removing mysql-10.9.0.6 ... done`.
The network removal itself may print:
```
ERROR: error while removing network: network net-10.9.0.0 id ... has active endpoints
```
This is harmless if the XSS lab's `elgg-10.9.0.5` container already exists and
is still attached to that network — the network stays and gets reused, which
is exactly what the XSS lab needs.

### 4.2 Build the images

```bash
cd ~/.../Labsetup-xss/Labsetup
docker-compose build
```
Expect `Successfully tagged seed-image-www:latest` and `Successfully tagged
seed-image-mysql:latest`. (These tag names have no `-sqli` suffix, so they do
not collide with the SQL lab's `seed-image-www-sqli` / `seed-image-mysql-sqli`
images.)

### 4.3 Start the containers

```bash
docker-compose up -d
```
Expect `Creating network "net-10.9.0.0"` (or it reusing an existing one),
then `Creating elgg-10.9.0.5 ... done` and `Creating mysql-10.9.0.6 ... done`.

### 4.4 Verify both containers are running

```bash
docker ps
```
Expect two rows, both `Up`: `elgg-10.9.0.5` and `mysql-10.9.0.6`.

### 4.5 Check the MySQL init log for errors

```bash
docker logs mysql-10.9.0.6 2>&1 | grep -i error
```
Expect no output — this confirms the `elgg.sql` seed dump (the five accounts
above, Elgg's schema, and site configuration) loaded without errors.

### 4.6 Hostname mapping

No change needed: the `/etc/hosts` entry added for Section 1,
```
10.9.0.5        www.seed-server.com
```
already points at the correct IP for this lab too, since both labs put their
web container on `10.9.0.5`.

### 4.7 Verify everything end-to-end

```bash
ping -c 2 www.seed-server.com
curl -I http://www.seed-server.com/
```
Expect replies from `10.9.0.5` and `HTTP/1.1 200 OK`. Then open
`http://www.seed-server.com/` in Firefox — hard-refresh or clear cache if it
still shows the SQL lab's "Employee Profile Login" page — and log in as
**samy / seedsamy** to confirm the Elgg UI loads and the credential works.

**Confirmed working on this VM on 2026-09-05** (student verified `docker ps`,
the MySQL log check, and the site load all succeeded after the fix in §5
below).

---

## 5. What actually went wrong the first time, and the fix

On the first `docker-compose up -d` attempt (SQL lab only `stop`ped, not
`down`ed), the result was:
```
Creating mysql-10.9.0.6 ... error
Creating elgg-10.9.0.5  ... done
ERROR: for mysql-10.9.0.6  Cannot create container for service mysql: Conflict.
The container name "/mysql-10.9.0.6" is already in use by container "1c9c7135aa1a..."
```
`elgg-10.9.0.5` succeeded (no name conflict with the SQL lab's `www-10.9.0.5`),
but `mysql-10.9.0.6` failed because the SQL lab's same-named, merely-stopped
container still held that name.

Fix applied:
```bash
cd ~/.../Labsetup-sql-3/Labsetup
docker-compose down
# Removing mysql-10.9.0.6 ... done
# Removing www-10.9.0.5   ... done
# Removing network net-10.9.0.0 ... ERROR: ... has active endpoints  (harmless, see §4.1)

docker ps -a
# confirms www-10.9.0.5 and mysql-10.9.0.6 are gone; elgg-10.9.0.5 already Up

cd ~/.../Labsetup-xss/Labsetup
docker-compose up -d
# only needs to create mysql-10.9.0.6 this time — succeeds
```

---

## 6. Restarting the lab after the VM reboots

- `mysql` service has `restart: always` — it comes back on its own once the
  Docker daemon starts, **as long as the container was never removed** (see
  §3 — a VM reboot does not remove it, only `docker-compose down` does).
- `elgg` (`www`) service has **no restart policy** (defaults to `no`) — it
  will **not** auto-start after a reboot.

So after a reboot, from the lab directory:
```bash
cd ~/.../Labsetup-xss/Labsetup
docker-compose up -d
```
This is idempotent — if `mysql-10.9.0.6` is already `Up` (restarted itself)
and `elgg-10.9.0.5` is not, it only starts `elgg-10.9.0.5`, without touching
the existing MySQL data.

Then verify, same as first-time setup:
```bash
docker ps
# expect elgg-10.9.0.5 and mysql-10.9.0.6 both Up

docker logs mysql-10.9.0.6 2>&1 | grep -i error
# expect no output

curl -I http://www.seed-server.com/
# expect HTTP/1.1 200 OK
```

If `docker ps -a` shows neither container at all, something removed the
Compose state (someone ran `docker-compose down` on this lab, or the VM was
reverted to an older snapshot) — repeat **§4 First-time setup** from the top,
and note that any saved "About me" payloads from earlier Q2.x work will be
gone (see §3) and must be redone.

---

## 7. Switching between the SQL lab and the XSS lab

Because of §2 and §3, only one of the two labs can be up at a time, and
switching away from the XSS lab loses its stored data. Recommended workflow
for recording the report:

1. Finish and record **all** of Section 1 (Q1.1–Q1.5) first, with the SQL lab
   up, following `section1-lab-setup.md` / `section1-lab-guide.md`.
2. Switch over once:
   ```bash
   cd ~/.../Labsetup-sql-3/Labsetup
   docker-compose down          # safe — mysql_data/ bind mount persists on disk

   cd ~/.../Labsetup-xss/Labsetup
   docker-compose up -d
   ```
3. Finish and record **all** of Section 2 (Q2.1–Q2.4) in this same XSS-lab
   session, without running `docker-compose down` on it in between, so the
   "About me" payloads from earlier sub-questions stay in place for later
   ones that build on them (Q2.3/Q2.4 reuse the worm from Q2.3 in Q2.4's
   profile field).
4. If you need the SQL lab again afterwards (for example, to redo a Section 1
   screenshot), switch back the same way: `docker-compose down` the XSS lab
   (accepting that its stored payloads will need to be redone if you return
   to it later) and `docker-compose up -d` the SQL lab.

**Browser caching after a switch:** after switching the containers, Firefox
may keep showing the *previous* lab's page at `http://www.seed-server.com/`
on a tab that already had it open — both labs share the same hostname, so a
plain reload can be served from cache instead of hitting the server again.
Confirmed on this VM: a normal tab kept showing Section 1's "Employee Profile
Login" page after the XSS containers were already up and correct
(`docker ps` showed `elgg-10.9.0.5`/`mysql-10.9.0.6` healthy). A **Private
Browsing window** (Ctrl+Shift+P) always fetched the live page correctly,
since it has no cache to reuse. If you'd rather keep using a normal window,
force a real reload with **Ctrl+Shift+R**, or close and reopen the tab; if it
still shows the stale page, clear cached content for the site (Firefox:
`about:preferences#privacy` → Clear Data → Cached Web Content). Recommendation:
just do all XSS-lab work in one Private window for the rest of Section 2 to
avoid this entirely.

---

## 8. Full reset (only if you need to start completely from scratch)

⚠️ This destroys all data changes made inside the XSS lab, since there is no
bind mount to preserve (see §3):
```bash
docker-compose down
docker-compose up -d
```
There is no `mysql_data/` folder to `rm -rf` for this lab — `down` alone
already discards everything. Repeat from **§4.4** onward afterwards.

---

## 9. Quick reference — one-touch health check

```bash
docker ps
docker logs mysql-10.9.0.6 2>&1 | grep -i error
curl -I http://www.seed-server.com/
```
All three should come back clean (`elgg-10.9.0.5` and `mysql-10.9.0.6` both
`Up`, no error lines, `HTTP/1.1 200 OK`) before you start or resume any of
Q2.1–Q2.4. If `docker ps` doesn't show `mysql-10.9.0.6`, check first whether
the SQL lab's identically-named container is the one occupying Docker's
attention (§2) before assuming this lab is broken.
