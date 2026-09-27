# SUID Analysis: Interpreted Scripts

Author: Edwin Mathaga

## 1. Why SUID Does Not Work Normally on Interpreted Scripts

The SUID bit allows an executable to run with the privileges of its
owner instead of the privileges of the user who started it. For
example, if a normal executable is owned by root and has the SUID bit
set, it can run with root privileges.

Scripts are different because the file is normally passed to an
interpreter such as `/bin/bash` or `/usr/bin/python`. Linux does not
generally honor SUID permissions on interpreted scripts. This is an
important security limitation because there can be a race between
checking the script and the interpreter actually reading and executing
it.

This type of problem is related to a TOCTOU (Time-of-Check to
Time-of-Use) vulnerability. If SUID scripts were trusted in the same
way as compiled executables, an attacker could potentially take
advantage of the gap between the permission check and the script being
read.

Because of these risks, simply adding SUID to a shell script does not
provide the same privilege behavior as adding SUID to a compiled
executable.

## 2. Why SUID and World-Writable Permissions Are Still Dangerous

Although the SUID bit on `deploy.sh` is not normally honored when the
script is executed directly, the file is still a serious security
problem if it is writable by everyone.

In this case, the important detail is that the script is used by a
root-owned cron job. The cron job does not rely on the SUID bit to
obtain its privileges. It is already running as root.

The file permissions allow other users to modify the script. A
low-privilege user could therefore change the contents of the script
and wait for the root cron job to execute it.

When that happens, the commands in the modified script would run with
the privileges of the cron job, which means they could have root-level
access to the system.

The main security issue is therefore the combination of a
root-executed automation task and a script that unprivileged users can
modify.

## 3. Possible Exploitation Path

The main attack path is not the SUID bit itself. It is the fact that a
root-owned automated task executes a script that can be modified by a
lower-privileged user.

For example, if an attacker already had access to a low-privilege
account or compromised another service running as a restricted user,
they could attempt to modify:

```
/opt/kijanikiosk/scripts/deploy.sh
```

The attacker could then place unauthorized commands in the script.

When the root cron job next executes the modified script, those
commands would run with the privileges of the cron process.

This is why scripts executed by root should normally be owned by root
and writable only by trusted administrators or the service account
that needs to maintain them. Removing unnecessary write permissions
would prevent a lower-privileged user from changing the commands that
the root automation process executes.
