# Architectural Vulnerability Risk: Broad systemctl Sudo Permission

Author: Edwin Mathaga 

## Overview

A sudo rule that allows a user to run `/bin/systemctl` as root without
any restrictions is potentially dangerous. `systemctl` is a powerful
administrative utility and can be used to manage system services.
Giving an unprivileged user unrestricted access to it can therefore
create paths to elevated privileges.

## 1. Custom Service Units

One potential issue is that `systemctl` can manage service units. If a
user is allowed to run systemctl commands as root without restrictions,
they may be able to interact with service definitions that they should
not otherwise control.

For example, if an attacker can create or modify a service definition
in a location they control, and the unrestricted sudo permission allows
that service to be linked or started, the service could potentially
execute commands with root privileges.

The important point is that the sudo rule is not limiting the user to
a specific trusted service. Instead, it gives them access to a general
system administration tool. This creates a privilege-escalation risk
because systemd services normally run with the permissions of the
service manager, which in many cases is root.

A safer configuration would restrict sudo access to only the specific
service-management commands and services that the user actually needs.

## 2. systemctl and the Pager

Another consideration is how command output is displayed. Some
`systemctl` commands can send long output through a pager such as
`less`. When a privileged command starts a pager, the environment in
which that pager runs needs to be considered as part of the overall
security boundary.

If an unrestricted sudo rule allows a user to run systemctl as root,
features of the programs involved in displaying its output can
potentially become relevant to privilege escalation. This is another
reason why giving users unrestricted access to system administration
utilities through sudo should be avoided.

The broader lesson from this is that sudo permissions should be based
on the minimum functionality a use
