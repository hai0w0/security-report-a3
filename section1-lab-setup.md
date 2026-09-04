# Section 1 Lab — Environment Setup, Fixes, and Restart Guide

This documents the exact setup process for the `Labsetup-sql-3` Docker lab
(Section 1, SQL Injection) on the `seed@VM`, including the two problems that
were actually hit and fixed during setup, and how to bring the lab back up
after the VM is rebooted. This is infrastructure setup only — it does not
contain any of the SQL injection payloads themselves (see
`section1-lab-guide.md` for those).

## 0. Location

All commands below are run from the folder that contains `docker-compose.yml`
for this lab, e.g.:
```bash
cd ~/.../Labsetup-sql
```
(adjust to your actual path — this is the folder produced by extracting
`Labsetup-sql-3.zip`, containing `docker-compose.yml`, `image_mysql/`,
`image_www/`, and `mysql_data/`).

---

## 1. First-time setup (from a clean checkout)

### 1.1 Build the images

This VM has the older standalone Compose binary, **not** the newer `docker
compose` (space) plugin. Confirmed on this VM:
```bash
docker-compose version
# docker-compose version 1.27.4, build 40524192
```
So always use the hyphenated form here:
```bash
docker-compose build
```
Expected: both `www` and `mysql` images build successfully, ending with
`Successfully tagged seed-image-www-sqli:latest` and
`Successfully tagged seed-image-mysql-sqli:latest`.

### 1.2 Start the containers

```bash
docker-compose up -d
```

**Known issue — subnet conflict:** this lab's network (`net-10.9.0.0`,
subnet `10.9.0.0/24`) can fail to create with:
```
Creating network "net-10.9.0.0" with the default driver
ERROR: Pool overlaps with other one on this address space
```
On this VM the cause was the **firewall lab**: its
`firewall-lab_net-outside` network was already bound to `10.9.0.0/24`.

Check for the conflict:
```bash
docker network ls
docker network inspect <suspect_network_name> | grep -A2 Subnet
```
If another lab's network already owns `10.9.0.0/24` and you don't need that
lab running right now, remove it (first check nothing is attached):
```bash
docker network inspect <network_name> --format '{{range .Containers}}{{.Name}} {{end}}'
# if empty output, safe to remove:
docker network rm <network_name>
```
On this VM this meant:
```bash
docker network rm firewall-lab_net-outside firewall-lab_net-inside
```
Then retry:
```bash
docker-compose up -d
```
Expected: `Creating network "net-10.9.0.0" ... done`, `Creating
www-10.9.0.5 ... done`, `Creating mysql-10.9.0.6 ... done`.

⚠️ **This conflict can come back** if you ever bring the firewall lab back
up while this lab's network still exists (both want `10.9.0.0/24`). Don't
run both labs' containers at the same time; `docker-compose down` this lab
first if you need the firewall lab, or vice versa.

### 1.3 Verify both containers are running

```bash
docker ps
```
Expected: two rows, both `Up`, named `www-10.9.0.5` and `mysql-10.9.0.6`.

### 1.4 Check the MySQL init log for errors

```bash
docker logs mysql-10.9.0.6 2>&1 | grep -i error
```

**Known issue — missing stored functions:** on this VM this printed:
```
ERROR 1418 (HY000) at line 135: This function has none of DETERMINISTIC, NO SQL, or READS SQL DATA in its declaration and binary logging is enabled
```
Line 135 of `sqllab_users.sql` is `CREATE FUNCTION userIdMaxTasks()`. MySQL's
init script runner stops at the first error, so `userIdMaxTasks()`,
`generateRandomUser()`, `getNewestUserId()`, and `copyTasksToUser` never got
created — everything **before** that line (the `credential`, `tasks`, and
`preference` tables and their seed rows) loaded fine. This matters because
**Q1.5 requires `userIdMaxTasks()` to exist.**

Fix — recreate just the missing routines (does not touch existing table
data):

1. Create the fix file:
   ```bash
   nano /tmp/fix_functions.sql
   ```
2. Paste this exact content, then save (`Ctrl+O`, `Enter`, `Ctrl+X`):
   ```sql
   SET GLOBAL log_bin_trust_function_creators = 1;

   DELIMITER $$

   DROP FUNCTION IF EXISTS userIdMaxTasks $$

   CREATE FUNCTION userIdMaxTasks() returns int(6) UNSIGNED
   BEGIN
   DECLARE result int(6) UNSIGNED;
   DECLARE countCheck int(6) UNSIGNED;

   select tasks.owner, count(tasks.owner)
   into result,countCheck
   from tasks group by tasks.owner
   order by count(tasks.owner) desc
   limit 1;
   return result;
   END$$

   DROP FUNCTION IF EXISTS generateRandomUser $$

   CREATE FUNCTION generateRandomUser() returns varchar(300)
   BEGIN
   DECLARE temprndName varchar(300);
   DECLARE temppassword varchar(300);
   DECLARE result int(6) UNSIGNED;

   SET temprndName = lpad(conv(floor(rand()*pow(36,8)), 10, 36), 8, 0);
   SET temppassword = lpad(conv(floor(rand()*pow(36,8)), 10, 36), 15, 0);
   INSERT INTO `credential` (`Name`,`Password`) VALUES (temprndName,temppassword);
   select ID into result from credential order by id desc limit 1;
   INSERT INTO `preference` (`favourite`, `Owner`) VALUES ('Hours DESC', result);
   return 'Created';
   END$$

   DROP FUNCTION IF EXISTS getNewestUserId $$

   CREATE FUNCTION getNewestUserId() returns int(6) UNSIGNED
   BEGIN
   DECLARE result int(6) UNSIGNED;
   select ID into result from credential order by id desc limit 1;
   return result;
   END$$

   DROP PROCEDURE IF EXISTS copyTasksToUser $$

   CREATE PROCEDURE copyTasksToUser(in userID int(6) UNSIGNED)
   BEGIN

   DECLARE cursor_name varchar(5000);
   DECLARE cursor_hours int(10);
   DECLARE cursor_amount int(100);
   DECLARE cursor_description TEXT;
   DECLARE cursor_type TEXT;

   DECLARE done TINYINT DEFAULT FALSE;

   DECLARE cursor1 CURSOR FOR
   SELECT t1.Name, t1.Hours,t1.Amount,t1.Description,t1.Type
   FROM tasks t1
   WHERE NOT t1.Owner = userID;

   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

   OPEN cursor1;

   read_loop: LOOP
     FETCH NEXT FROM cursor1 INTO cursor_name,cursor_hours,cursor_amount,cursor_description,cursor_type;
     IF done THEN
         LEAVE read_loop;
     ELSE
         INSERT INTO `tasks` (`Name`, `Hours`, `Amount`, `Description`,`Owner`,`Type`) VALUES
         (cursor_name, cursor_hours, cursor_amount, cursor_description,userID,cursor_type);

     END IF;

   END LOOP;

   CLOSE cursor1;

   END$$

   DELIMITER ;
   ```
3. Copy it into the container and run it interactively (interactive `source`
   is more reliable than piping a heredoc through `docker exec -i`, which is
   what failed the first time on this VM):
   ```bash
   docker cp /tmp/fix_functions.sql mysql-10.9.0.6:/fix_functions.sql
   docker exec -it mysql-10.9.0.6 mysql -uroot -pdees sqllab_users
   ```
   At the `mysql>` prompt:
   ```
   source /fix_functions.sql
   ```
   Expected: a series of `Query OK` lines, no `ERROR`.
4. Verify, still at the `mysql>` prompt:
   ```
   SELECT userIdMaxTasks();
   ```
   Expected: one row with a numeric user ID, no error.
5. Exit:
   ```
   exit
   ```

This fix is written into the `mysql_data/` bind-mounted volume, so it
persists across container restarts and VM reboots — you should **not** need
to redo it unless `mysql_data/` is deleted or the container is rebuilt from
an empty volume (see §3, full reset).

### 1.5 Map the hostname

The Apache vhost in `image_www/apache_sql_injection.conf` is:
```
ServerName   www.seed-server.com
```
This exact hostname must resolve to `10.9.0.5`. On this VM, `/etc/hosts`
already had entries for other SEED labs (including an *older-style* name for
this lab, `www.SeedLabSQLInjection.com`, which does **not** match the vhost
above and won't work) but no entry for `www.seed-server.com`. Add one:
```bash
sudo nano /etc/hosts
```
Add this line under the `# For SQL Injection Lab` section (keep the existing
line, just add a new one under it):
```
10.9.0.5        www.seed-server.com
```
Save and exit: `Ctrl+O`, `Enter`, `Ctrl+X`.

`/etc/hosts` is part of the VM's own filesystem, so this survives Docker
restarts and VM reboots — you only need to do this once per VM (unless the
VM disk is reverted to a snapshot from before this edit).

### 1.6 Verify everything end-to-end

```bash
ping -c 2 www.seed-server.com
curl -I http://www.seed-server.com/
```
Expected: `ping` replies from `10.9.0.5`; `curl -I` returns `HTTP/1.1 200
OK`. Then open `http://www.seed-server.com/` in the browser and confirm the
"Employee Profile Login" page loads.

At this point the lab is fully set up and ready for Q1.1–Q1.5 in
`section1-lab-guide.md`.

---

## 2. Restarting the lab after the VM reboots

Rebooting the VM stops the Docker daemon and, depending on each container's
restart policy, may or may not stop the containers themselves:
- `mysql` service has `restart: always` in `docker-compose.yml` — it
  generally comes back on its own once the Docker daemon starts.
- `www` service has **no** restart policy set (defaults to `no`) — it will
  **not** auto-start on its own after a reboot.

So always run this after a reboot, from the lab directory, rather than
assuming either container is already up:

```bash
cd ~/.../Labsetup-sql
docker-compose up -d
```

This is safe/idempotent:
- If the containers already exist (just stopped), it starts them without
  rebuilding or recreating anything.
- If the `net-10.9.0.0` network still exists from before, it reuses it
  (no "Pool overlaps" error) — that error only happens when a network has to
  be **created** and something else already holds the same subnet.

Then verify, same as initial setup:
```bash
docker ps
# expect www-10.9.0.5 and mysql-10.9.0.6 both Up

docker logs mysql-10.9.0.6 2>&1 | grep -i error
# expect no output

docker exec -it mysql-10.9.0.6 mysql -uroot -pdees sqllab_users -e "SELECT userIdMaxTasks();"
# expect one numeric row, no error — confirms the §1.4 fix survived

curl -I http://www.seed-server.com/
# expect HTTP/1.1 200 OK
```

If `docker ps` doesn't show the containers at all (not even `Exited`), or
`docker network ls` no longer lists `net-10.9.0.0`, something removed the
Compose state (e.g. someone ran `docker-compose down` before shutting the VM
off, or the VM was reverted to an older snapshot) — in that case, repeat the
full **§1 First-time setup** from the top, including re-checking for the
network overlap and re-applying the `userIdMaxTasks()` fix if `mysql_data/`
was also reset.

If `www-10.9.0.5` and `mysql-10.9.0.6` show as `Up` already (mysql restarted
itself, and you'd previously left `www` running too), you can skip straight
to the verification block above.

---

## 3. Full reset (only if you need to start completely from scratch)

⚠️ This destroys all data changes made inside the lab (including any Q1.2/
Q1.3 profile edits you've made to Boby's row, and the `userIdMaxTasks()` fix
— you would need to redo §1.4 afterwards).

```bash
docker-compose down          # stops and removes the containers + network
rm -rf mysql_data/*          # wipes the MySQL data directory (bind mount)
docker-compose build
docker-compose up -d
```
Then repeat from **§1.3** onward (container check → error log check →
§1.4 function fix → §1.5 hosts entry, which should already be in place from
before → §1.6 verification).

---

## 4. Quick reference — one-touch health check

Run this any time you want to confirm the whole stack is healthy before
resuming Q1.1–Q1.5:

```bash
docker ps
docker logs mysql-10.9.0.6 2>&1 | grep -i error
docker exec -it mysql-10.9.0.6 mysql -uroot -pdees sqllab_users -e "SELECT userIdMaxTasks();"
curl -I http://www.seed-server.com/
```

All four should come back clean (containers `Up`, no error lines, a numeric
`userIdMaxTasks()` result, and `HTTP/1.1 200 OK`) before you start or resume
any of Q1.1–Q1.5.
