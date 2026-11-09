# Nia's Comparison: Week 7 and Week 8 Deployment Approaches

Week 7 and Week 8 both focused on making the KijaniKiosk payments service
available and recovering it when something went wrong. However, they
approached deployment from different angles. Week 7 used a blue/green
deployment setup with separate application environments, while Week 8
introduced containers and Kubernetes to manage application instances. Both
approaches have advantages, and neither removes the need to understand how
the application is configured and monitored.

| Concern | How Week 7 addressed it | How Week 8 addresses it |
|---|---|---|
| Deployment mechanism | Blue/green environments used separate application versions and traffic switching. | A Kubernetes Deployment maintains two replicas and updates them through a rolling rollout. |
| Rollback mechanism | Traffic could be switched back to the previous environment using the rollback process. | A previous Deployment revision can be restored through Kubernetes rollout history. |
| Failure recovery | Monitoring and rollback scripts helped detect problems and restore the previous working environment. | The Kubernetes controller replaces failed or deleted Pods to maintain the requested replica count. |
| Scaling | Additional capacity required more environment and infrastructure preparation. | The replica count can be increased or reduced to change the number of running application instances. |

## Deployment and rollback

In Week 7, the blue/green approach gave us control over which environment
received production traffic. The application could run in one environment
while the other was prepared for a new release. This made it possible to
test a version before switching traffic. During the rollback exercise,
traffic was restored to the previous working version in approximately
one second. I found this useful because the rollback was easy to understand:
the previous version was still available, and the traffic switch did not
require rebuilding the application.

Week 8 uses a different approach. Instead of manually switching between
two environments, Kubernetes manages the desired number of application
instances. The Friday deployment used two replicas and updated the running
application through a rolling rollout. This reduces the amount of manual
work involved in replacing application instances. Kubernetes also keeps
track of the desired state, which is useful when a Pod disappears or fails.

## Failure recovery and scaling

The two approaches handle failure differently. In Week 7, recovery depended
on monitoring the application and using the rollback process when a release
was unhealthy. In Week 8, the Kubernetes controller noticed when one of the
two Pods was deleted and created a replacement. In Thursday's test, the
replacement became Ready in 46 seconds. During Friday's fresh test, recovery
took 34 seconds. These measurements show that Kubernetes can restore the
requested replica count automatically, although recovery is not
instantaneous.

Scaling is another difference. The Week 7 setup required preparation of
additional environments and consideration of how traffic would reach them.
With Kubernetes, changing the replica count is a simpler way to request
more application instances. However, adding replicas does not automatically
solve every capacity problem. The cluster still needs enough CPU and memory,
and the application must be able to handle requests across multiple
instances. Resource requests and limits help make those requirements more
visible.

## Container size and delivery

The container work also introduced a useful lesson about image size. The
Monday baseline and Tuesday production images both appear as 181 MB in the
Docker image listing available for this comparison. Based on those recorded
values, the measured reduction from Monday to Tuesday is 0 MB. This does
not demonstrate an improvement between those two stages, and I would not
claim otherwise. Friday's optimized image was 89.8 MB, which is below the
100 MB target. It was pushed to the private Nexus registry, removed from
the local Docker image store, and pulled again successfully.

For the Kubernetes exercise, the Friday image was loaded into Minikube
because the cluster could not reach the Nexus registry endpoint. The
deployment therefore used the locally loaded image rather than performing
an authenticated pull from Nexus. The registry push and fresh-pull test
succeeded separately, but the Kubernetes deployment did not prove
end-to-end registry authentication. This is an important limitation of
the Friday result.

## What I would improve in Week 9

Week 8 gives us a better foundation for container delivery and automated
recovery, but there is still work to do. The deployment currently uses
basic environment variables and does not yet demonstrate a complete
registry-to-cluster authentication flow. In Week 9, I would improve the
registry networking and credential setup so Kubernetes can pull images
directly from the private registry. I would also introduce ConfigMaps and
Secrets for configuration, improve monitoring and resource visibility,
and test scaling under load. Overall, Week 7 taught me how traffic
switching and rollback work, while Week 8 showed me how Kubernetes can
maintain application instances automatically. Both are useful skills
for operating a reliable service.
