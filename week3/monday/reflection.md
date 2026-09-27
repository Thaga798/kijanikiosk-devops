# Operational Reflection: Incident Analysis & Linux Internals

Author: Edwin Mathaga Muritu 
Date: September 27, 2026

## 1. The /proc Boundary

During the triage, I used `ps aux` to inspect the processes running on
the system. Although `/proc` looks like a normal directory, it is
actually a virtual filesystem provided by the Linux kernel. The files
and directories inside it represent information about the current
state of the system, including running processes, memory usage, and
other kernel-maintained information.

This helped me understand why the information I saw for PID 398246 was
a snapshot of what was happening at that time. The process information
was not being read from a permanent database on the disk. If the
machine reboots, the running processes disappear and the corresponding
`/proc` entries are recreated based on the new system state.

This also showed me why collecting logs is important during an
incident. Information visible through `/proc` can disappear when the
system is restarted. Permanent records such as application logs,
system logs, and monitoring data are therefore needed if I want to
investigate what happened after the system has recovered.

## 2. Kernel Space and Process Isolation

The Python process with PID 398246 was running in user space. Even
though it was consuming approximately 524 MB of RAM, it could not
simply access arbitrary memory belonging to the Linux kernel or other
processes.

Linux provides this separation using virtual memory and hardware
memory protection. The CPU's Memory Management Unit (MMU), together
with page tables maintained by the kernel, controls which memory a
process is allowed to access. User-space programs therefore operate
within their own virtual address spaces rather than having unrestricted
access to physical memory.

This was important during my investigation because the Python process
was consuming too many resources, but it was not evidence that it was
corrupting the kernel. If this separation did not exist, a faulty or
malicious process could overwrite kernel data or memory belonging to
other applications. That could allow one process to interfere with
the entire system and would make isolation between applications much
less secure. The kernel/user-space boundary is therefore an important
part of both Linux stability and security.

## 3. The Triage Pipeline I Built

One of the more complex commands I used during the investigation was:

```
find /proc -maxdepth 3 -name fd -type d 2>/dev/null |
awk -F/ '{print $3}' |
grep -E '^[0-9]+$'
```

The first part, `find`, searches `/proc` for directories named `fd`.
These directories are associated with the file descriptors belonging
to processes. The `2>/dev/null` redirects error messages, such as
permission-related errors, so they do not appear in the command's
normal output.

The output from `find` is then passed to `awk`. Using `/` as the field
separator, `awk` extracts the third field from paths such as
`/proc/1842/fd`, giving me the PID `1842`.

Finally, `grep -E '^[0-9]+$'` filters the results so that only strings
containing entirely numeric PIDs are returned.

The order matters because each command is processing the output of the
previous command. If I put `awk` before `find`, for example, there
would be no useful `/proc/.../fd` paths for `awk` to process. Similarly,
running `grep` first would not search the results produced by `find`;
it would simply receive whatever input was available at that point.
The pipeline works because each stage produces the type of output
expected by the next stage.

## 4. Containers and the Kernel

If a Docker container had been running on the same host during my
investigation, its processes could still appear in the host's
`ps aux` output. A container is not the same thing as a virtual
machine. Containers normally share the host's Linux kernel rather than
running a separate kernel of their own.

Linux provides container isolation mainly through features such as
namespaces and cgroups. Namespaces give processes inside a container
their own view of things such as processes, networking, mounts, and
other system resources. Cgroups allow the system to control and
account for resources such as CPU and memory.

From inside a container, a process may only see the processes that its
namespace exposes. From the host, however, the kernel is managing all
of the processes, including those belonging to containers. This is why
a host administrator can still see and manage container processes with
normal Linux tools. The container provides isolation, but it does not
remove the host's control over the underlying processes and kernel.

## 5. Operational Consequence

The investigation showed that the Python process using approximately
524 MB of RAM was not the original cause of the API latency. It was a
secondary resource problem that made the situation worse.

The initial problem appeared at approximately 03:45:10 UTC, when the
database connection pool reached about 85% utilization. By 04:01:33
UTC, utilization had increased to approximately 94%. At 04:07:55 UTC,
the connection pool became exhausted.

Once the pool was exhausted, application requests could no longer
obtain database connections normally. Queries against tables such as
`orders` and `products` began timing out, and application latency
increased from approximately 120 ms to 480 ms.

At 04:09:12 UTC, the Node.js application also reported a high memory
usage warning. The situation eventually became more serious at
06:22:18 UTC when the application began reporting
`ECONNREFUSED database:5432` and exhausted its database connection
retries.

The result was that the Node.js application stopped listening on its
expected ports, while NGINX continued listening on port 80. The
Python process added additional memory pressure during this period,
but the evidence points to database connection exhaustion as the
primary failure that started the degradation.
