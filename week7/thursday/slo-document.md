# KijaniKiosk Service Level Objectives

These SLOs are proposed operational targets for KijaniKiosk. They are not
claims about measured historical production performance. All objectives use
a rolling 30-day measurement window unless stated otherwise.

## kk-api (API Service)

### SLIs

1. **Availability SLI**

   Measures the proportion of requests to the API health endpoint that
   return a successful HTTP 200 response. It is collected by polling
   `/health` through the Nginx proxy and recording successful responses
   against total health-check requests.

2. **Latency SLI**

   Measures the proportion of API health requests completed within
   500 milliseconds, using the p95 latency percentile. It is collected
   from the response time reported by curl and aggregated over the
   measurement window.

3. **Error Rate SLI**

   Measures the proportion of requests to the `/health` endpoint that
   return HTTP 5xx responses or fail to receive a valid HTTP response.
   It is collected by counting failed and non-2xx responses against
   the total requests to that endpoint.

### SLOs

| SLI | Target | Window | Error budget |
|---|---|---|---|
| Availability | At least 99.9% successful requests | 30 days | 0.1% downtime, equivalent to 43.2 minutes |
| Latency | At least 95% of requests complete within 500 ms | 30 days | Up to 5% of requests may exceed 500 ms |
| Error rate | No more than 0.1% failed requests | 30 days | 0.1% of eligible requests |

### Rollback thresholds and SLO relationship

The post-deploy monitor checks the active API through the Nginx proxy
every five seconds. Three consecutive failed health checks trigger an
automatic rollback. This detects an availability failure within
approximately 15 seconds of sustained failure.

The monitor also triggers rollback when more than two errors occur
within a ten-poll window, or when at least three of the latest five
responses exceed two seconds.

These are deployment safety thresholds, not replacements for the
30-day SLOs. They are deliberately much more sensitive because a
deployment failure should be corrected before it consumes a significant
part of the monthly error budget.

The three-consecutive-failure rule is especially useful because it
detects sustained unavailability quickly instead of waiting for the
monthly availability objective to be breached.

## kk-payments (Payments Service)

### SLIs

1. **Availability SLI**

   Measures the proportion of payment-service requests that receive
   successful responses from the service. It is collected from payment
   endpoint response status codes and total requests.

2. **Latency SLI**

   Measures the proportion of payment requests completed within
   750 milliseconds, using the p95 latency percentile. It is collected
   from request duration measurements and aggregated over the
   measurement window.

3. **Transaction Error Rate SLI**

   Measures the proportion of attempted payment transactions that fail
   or return an unsuccessful result. It is collected by counting failed
   payment transactions against all attempted transactions, excluding
   requests rejected before transaction processing for reasons defined
   by the payment-service measurement policy.

### SLOs

| SLI | Target | Window | Error budget |
|---|---|---|---|
| Availability | At least 99.95% successful requests | 30 days | 0.05% downtime, equivalent to 21.6 minutes |
| Latency | At least 95% of payment requests complete within 750 ms | 30 days | Up to 5% of requests may exceed 750 ms |
| Transaction error rate | No more than 0.1% failed transactions | 30 days | 0.1% of eligible payment transactions |

### Monitoring and rollback relationship

Payment transactions require particular care because failed or delayed
payments can directly affect customers and revenue. The payment service
should therefore be monitored for availability, response latency and
transaction failures.

The API post-deployment monitor provides an early warning mechanism for
the API health endpoint. Its three-consecutive-failure, latency and
error-window thresholds are deployment safeguards. They do not by
themselves measure the complete payment transaction SLI.

Payment transaction outcomes must be collected separately from
application transaction records or structured application logs so that
the transaction error-rate SLO can be measured accurately.

The stricter 99.95% availability objective gives the payments service
a smaller monthly downtime budget than the API service. This reflects
the importance of keeping payment processing available.
