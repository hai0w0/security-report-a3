# Master Lab Setup Guide — Sections 1 (SQL Injection) and 2 (XSS)

Single quick-reference for getting either lab running on the `seed@VM`,
switching between them, and recovering from the gotchas already hit and
fixed this session. For the full narrative of how each problem was
diagnosed, see `section1-lab-setup.md` and `section2-lab-setup.md` — this
file only holds the condensed, operational version for day-to-day use while
recording.

## At a glance

| | Section 1 — SQL Injection | Section 2 — XSS |
|---|---|---|
| Folder | `Labsetup-sql-3/Labsetup` | `Labsetup-xss/Labsetup` |
| App | `unsafe_home.php` etc. ("Employee Profile Login") | Elgg ("Elgg For SEED Labs") |
| URL | `http://www.seed-server.com/` | `http://www.seed-server.com/` (same host) |
| Web container | `www-10.9.0.5` | `elgg-10.9.0.5` |
| DB container | `mysql-10.9.0.6` | `mysql-10.9.0.6` (**same name**) |
| DB data persistence | Bind-mounted `mysql_data/` — survives `docker-compose down` | **Not** bind-mounted — `docker-compose down` destroys it |
| Accounts | Ted, Boby, Alice, ... (see `section1-lab-guide.md`) | admin/seedadmin, alice/seedalice, boby/seedboby, charlie/seedcharlie, samy/seedsamy |

## The one rule: only one lab can be up at a time

Both compose files use the identical Docker network name (`net-10.9.0.0`),
identical subnet (`10.9.0.0/24`), identical container IPs (`10.9.0.5`,
`10.9.0.6`), and — critically — an **identical MySQL container name**
(`mysql-10.9.0.6`). A *stopped* container still reserves its name, so
`docker-compose stop` on one lab is not enough to start the other — you must
fully remove it with `docker-compose down`.

`docker-compose down` is safe for the SQL lab (its data lives in the
bind-mounted `mysql_data/` folder on disk) but **destroys** the XSS lab's
database (no bind mount) — so once the XSS lab is up, avoid `down`-ing it
until you're completely done recording Section 2.

---

## Cold start after the VM boots — bringing up Section 1 (SQL lab)

```bash
cd ~/.../Labsetup-sql-3/Labsetup
docker-compose up -d
docker ps
# expect www-10.9.0.5 and mysql-10.9.0.6 both Up
docker logs mysql-10.9.0.6 2>&1 | grep -i error
# expect no output
docker exec -it mysql-10.9.0.6 mysql -uroot -pdees sqllab_users -e "SELECT userIdMaxTasks();"
# expect one numeric row — confirms the userIdMaxTasks() fix survived
curl -I http://www.seed-server.com/
# expect HTTP/1.1 200 OK
```
If any of these fail (containers missing entirely, or the `userIdMaxTasks()`
error reappears), see `section1-lab-setup.md` §2–§3 for the full recovery
procedure.

## Cold start after the VM boots — bringing up Section 2 (XSS lab)

```bash
cd ~/.../Labsetup-sql-3/Labsetup
docker-compose down          # only if the SQL lab is currently up — safe, data persists

cd ~/.../Labsetup-xss/Labsetup
docker-compose up -d
docker ps
# expect elgg-10.9.0.5 and mysql-10.9.0.6 both Up
docker logs mysql-10.9.0.6 2>&1 | grep -i error
# expect no output
curl -I http://www.seed-server.com/
# expect HTTP/1.1 200 OK
```

---

## Switching between the two labs mid-session

**SQL lab → XSS lab** (safe both ways):
```bash
cd ~/.../Labsetup-sql-3/Labsetup && docker-compose down
cd ~/.../Labsetup-xss/Labsetup   && docker-compose up -d
```

**XSS lab → SQL lab** (⚠️ destroys any unsaved XSS-lab state — About Me
payloads, worm-modified profiles — since it has no persistent volume; redo
those payloads if you switch back to Section 2 later):
```bash
cd ~/.../Labsetup-xss/Labsetup   && docker-compose down
cd ~/.../Labsetup-sql-3/Labsetup && docker-compose up -d
```

## Browser caching after a switch

Both labs share the same hostname, `www.seed-server.com`. A Firefox tab that
already loaded one lab's page can keep showing it after you've switched
containers underneath, because a plain reload may be served from cache
instead of hitting the server again. Confirmed on this VM: a normal tab kept
showing Section 1's login page even after `docker ps` showed the XSS
containers healthy.

- **Use a Private Browsing window (Ctrl+Shift+P)** for the lab you're
  currently working in — it has no cache to reuse and always fetches live.
- If you'd rather stay in a normal window: hard-refresh with
  **Ctrl+Shift+R**, or close and reopen the tab. If still stale, clear cached
  content via `about:preferences#privacy` → Clear Data → Cached Web Content.

## Health check cheat-sheet

```bash
# Which lab is actually up right now?
docker ps

# SQL lab specifics
docker exec -it mysql-10.9.0.6 mysql -uroot -pdees sqllab_users -e "SELECT userIdMaxTasks();"

# Either lab
docker logs mysql-10.9.0.6 2>&1 | grep -i error
curl -I http://www.seed-server.com/
```

## Recommended recording workflow

1. Bring up the SQL lab, record **all** of Section 1 (Q1.1–Q1.5) in one
   sitting, in a Private window.
2. Switch once (SQL → XSS, as above).
3. Record **all** of Section 2 (Q2.1–Q2.4) in one sitting, same Private
   window, without running `docker-compose down` on the XSS lab in between —
   Q2.4 reuses the worm payload built in Q2.3.
4. Only switch back to the SQL lab afterwards if you need to redo a Section 1
   screenshot; expect to redo any unsaved Q2.x profile payload if you then
   return to Section 2.

## Troubleshooting index

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot create container ... name "/mysql-10.9.0.6" is already in use` | The other lab's same-named container was only `stop`ped, not removed | `docker-compose down` the other lab first |
| `Pool overlaps with other one on this address space` | Another Docker network (for example a firewall lab) already holds `10.9.0.0/24` | `docker network rm` the conflicting network — see `section1-lab-setup.md` §1.2 |
| `This function has none of DETERMINISTIC, ...` in `mysql-10.9.0.6` logs (SQL lab only) | Binary logging + missing `DETERMINISTIC` broke `userIdMaxTasks()` and friends on first boot | Re-run the fix in `section1-lab-setup.md` §1.4 |
| Browser shows the wrong lab's page after switching | Firefox cache/tab still holds the old page | Private window, or Ctrl+Shift+R — see above |
| XSS lab's saved profile payloads vanished | Someone ran `docker-compose down` on the XSS lab | Expected — no persistent volume (see "The one rule" above); redo the payload |

---

For the full setup history, first-boot walkthroughs, and every error message
actually seen while diagnosing each lab, see `section1-lab-setup.md` and
`section2-lab-setup.md`. For the exploit steps and payloads themselves, see
`section1-lab-guide.md` (written) and the in-chat walkthrough for Section 2
(not yet written to a standalone guide file).
