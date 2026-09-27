# Engineering Decision: /usr/sbin/nologin vs /bin/false

Author: Edwin Mathaga
Project: KijaniKiosk Infrastructure Hardening Baseline

## 1. Selected Mechanism

For the three KijaniKiosk service accounts (`kk-api`, `kk-payments`,
and `kk-logs`), I chose `/usr/sbin/nologin` as the default shell.

These accounts are intended to run application services and do not
need interactive login access. Using `nologin` makes that restriction
explicit while still allowing the accounts to be used by the services
they are assigned to.

## 2. How the Two Options Work

The main difference between `/bin/false` and `/usr/sbin/nologin` is
what happens when they are used as a user's login shell.

`/bin/false` is a simple program that immediately exits with a failure
status. If an interactive login attempts to use it as the user's shell,
the session terminates without providing a shell.

`/usr/sbin/nologin` also prevents the user from receiving an interactive
shell, but it is specifically intended for accounts that should not be
allowed to log in. It can display a message explaining that the account
is not available for login.

Both options therefore prevent normal interactive shell access, but
`nologin` communicates the intended purpose of the account more
clearly.

## 3. Reasoning for the KijaniKiosk Accounts

The KijaniKiosk service accounts do not need interactive access. Their
purpose is to run individual services rather than provide a way for
administrators or other users to obtain a shell.

Using `/usr/sbin/nologin` makes this restriction clear when the account
is inspected or when someone attempts to use it for an interactive
login.

It is also important to distinguish the login shell from system
logging. The choice of `nologin` does not by itself guarantee that
every failed login attempt will appear in `/var/log/auth.log` or
`journald`. Authentication logging depends on the authentication
mechanism and the system's logging configuration.

For this baseline, `/usr/sbin/nologin` provides a clear and appropriate
default for service accounts while reducing unnecessary interactive
access.

