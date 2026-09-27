# KijaniKiosk API Server - Triage Report

Date: 27 September 2026
Investigated by: Edwin Mathaga (DevOps Engineer)
Server: Local Dev-Cluster Node
ed-HP-EliteBook-840-G3

Incident start: 15 January 2024, approximately 03:45:10 UTC

## SUMMARY

The incident was caused by a database connection leak that gradually
exhausted the application's connection pool.

At approximately 04:07:55 UTC, the connection pool became exhausted.
The Node.js application then stopped listening on its normal ports
(3000/8080), leaving NGINX running on port 80 but unable to successfully
proxy requests to the application.

At the same time, an unmanaged Python process (PID 398246) was using
approximately 524 MB of RAM. This added additional memory pressure to
the system.

The root filesystem was not full. However, the NGINX access log had
grown to approximately 271 MB.

Application latency increased from approximately 120 ms to 480 ms as
requests began backing up while the backend was unavailable.

## PROCESS AND RESOURCE STATE

A review of the running processes showed significant resource pressure.

Rogue Python process:

* PID: 398246
* Memory usage: approximately 524,052 KB RSS
* This represents approximately 6.6% of total system RAM.

The Node.js application worker was also under memory pressure.

Node.js process:

* PID: 1842
* Memory warning: approximately 87% capacity
* Warning time: 04:09:12 UTC

The memory warning occurred shortly after the connection pool
exhaustion event.

No processes were found in Z (zombie) or D (uninterruptible sleep)
states. This suggests that the main issue was resource pressure and
database connection blocking rather than processes being stuck in an
unkillable state.

## FILESYSTEM AND DISK

The root filesystem is not currently showing signs of disk exhaustion.

Root filesystem:

* Device: /dev/sda2
* Used: approximately 29 GB
* Total: approximately 143 GB
* Utilization: 21%

The NGINX access log is relatively large:

/var/log/kijanikiosk/access.log.1
Size: approximately 271 MB

The large log file indicates a high volume of requests or repeated
traffic/errors being recorded by NGINX.

## LOG TIMELINE

The application log shows the following sequence of events.

03:45:10 UTC
The database connection pool reached approximately 85% utilization.
This was the first significant warning.

04:01:33 UTC
Connection usage increased to approximately 94%.

04:07:55 UTC
The database connection pool became exhausted.

At this point, incoming application requests began waiting for
available database connections.

04:08:01 UTC
Queries against the orders and products tables began timing out.

Examples include:

```
SELECT * FROM orders
SELECT * FROM products
```

Application response latency increased to approximately 480 ms.

04:09:12 UTC
The Node.js worker reported a memory usage warning at approximately
87% capacity.

06:22:18 UTC
The application began reporting database connection errors:

```
ECONNREFUSED database:5432
```

The application eventually exhausted its configured connection retry
attempts and entered a failed state.

## NETWORK AND SERVICE STATE

NGINX is still running and listening on port 80.

Observed NGINX worker processes:

```
PID 1827
PID 1828
PID 1829
PID 1830
```

The application itself is no longer listening on its expected ports:

```
3000
8080
```

This means NGINX is still accepting incoming connections, but the
backend application is no longer available on its expected local
socket/port.

As a result, requests reaching NGINX cannot be successfully forwarded
to the Node.js application.

## ROOT CAUSE

The primary cause was a database connection leak.

The application did not release database connection handles back to
the connection pool correctly during intensive queries.

The connection pool gradually increased in utilization:

```
03:45:10 - approximately 85%
04:01:33 - approximately 94%
04:07:55 - pool exhausted
```

Once the pool was exhausted, new database operations had to wait for
available connections. This increased request latency and eventually
caused database operations to time out.

The later database connection failure at 06:22:18 UTC caused the
application's retry mechanism to fail completely.

The rogue Python process was a secondary resource problem. Its
approximately 524 MB memory usage increased overall system pressure
and could have made recovery and worker creation more difficult.

## RECOMMENDED ACTIONS

1. Stop the rogue Python process.

   PID 398246 is consuming approximately 524 MB of RAM.

   If the process has been confirmed as unnecessary and safe to
   terminate:

   ```
   sudo kill -9 398246
   ```

   Before terminating it in a production environment, confirm that
   the process is not required by another service.

2. Restore the application.

   Restart the backend database service/container if required to clear
   stale database sessions.

   Then restart the Node.js application so that it can establish new
   database connections and bind again to its expected port.

3. Review the database connection handling.

   Check the application code to make sure every acquired database
   connection is released correctly, including when queries fail or
   throw exceptions.

   Connection cleanup should also occur when requests are cancelled
   or time out.

4. Add query timeouts.

   Review the current database query timeout configuration.

   A shorter timeout, such as 5 seconds instead of 30 seconds, can
   prevent long-running queries from holding connections indefinitely.

   The correct timeout should be confirmed against normal application
   query times before deployment.

5. Add connection leak monitoring.

   Monitor connection pool utilization and alert before the pool
   reaches exhaustion.

   Connection acquisition and release should also be tracked so that
   connections that are not returned to the pool can be identified.

6. Review NGINX logging.

   Investigate why the access log reached approximately 271 MB.

   Confirm that log rotation is configured correctly so that logs do
   not continue growing without limits.

## BLAST RADIUS

If the public application instance is compromised, an attacker could
potentially use that instance to access resources that explicitly
trust it.

In this configuration, the main remaining network exposure is the
private instance, where access is restricted to traffic originating
from the public instance's security group. The private instance has
no direct internet access.

The impact would also depend on the credentials and IAM permissions
available to the compromised instance. Keeping IAM permissions
restricted to only the required resources and actions limits what an
attacker could access if the public instance were compromised.
