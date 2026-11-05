# Week 8 Thursday Reflection

### 1. Declarative Model

One thing I noticed when working with Kubernetes is that I do not have to keep giving it commands to maintain the deployment. I can describe what I want in the YAML file and apply it using `kubectl apply`. When I applied the same manifest again without making any changes, Kubernetes reported that the deployment was unchanged. It did not create new Pods because the actual state already matched what I had specified.

If I changed the number of replicas from two to three, Kubernetes would update the desired replica count and create another Pod to reach that number. The existing Pods would continue running while the new one was being created. This helped me understand the reconciliation loop. Kubernetes keeps checking the actual state against the desired state and tries to correct any differences. For example, when I deleted one of my Pods during the self-healing test, the Deployment automatically created a replacement without me having to create it manually.

### 2. Resource Requests and Limits

In my Deployment, I set the resource requests to 64Mi of memory and 100m of CPU, while the limits were set to 256Mi of memory and 500m of CPU. I now understand that requests and limits serve different purposes. Requests help Kubernetes decide where a Pod can be scheduled, while limits control how much of a resource a container can use.

If the application tried to use 300MB of memory, it would go beyond its 256Mi memory limit. The container could then be terminated with an OOMKilled status and restarted by Kubernetes. If I wanted to add a third replica and the node only had 100MB of unallocated memory, the Pod could still be scheduled because its memory request is 64Mi, assuming enough CPU and other resources are available. Kubernetes uses the requests when making scheduling decisions, not the memory limit.

For another workload that has no resource requests or limits, Kubernetes has less information to use when scheduling it. If it has neither requests nor limits, it falls under the BestEffort QoS class and is more vulnerable to eviction when the node experiences memory pressure. This showed me why setting resource requests and limits is important, especially when several applications share the same node.

### 3. Service Selectors During an Update

The Service uses the label `app: kk-payments` to find the Pods that should receive traffic. This means that if I deploy a new version of the application while the old version is still running, the Service can send traffic to both versions as long as they have the same label. It does not check the image version when selecting Pods.

This is important during a rolling update because there can be a period when both versions are running. The Service continues providing one stable address while Kubernetes replaces the old Pods with the new ones. My Deployment uses `maxSurge` and `maxUnavailable` settings of 25% to control how the update happens. Compared with the Week 7 blue-green deployment, this approach allows Kubernetes to manage the replacement of Pods within the same Deployment instead of relying on separate environments and switching traffic manually.

### 4. Kubernetes Compared with Week 7

The self-healing test was one of the most interesting parts for me. I deleted one of the running Pods and watched Kubernetes create a replacement. It took 46 seconds for the replacement Pod to become Ready, while the other Pod continued running. At the end of the test, the Deployment was back to having two available replicas. This showed me that Kubernetes can recover from a failed or deleted Pod without requiring me to manually deploy another one.

In Week 7, the blue-green rollback took approximately one second because the previous environment was already running and the rollback mainly involved switching traffic back to it. The Kubernetes recovery took longer because it had to create and start a new Pod. The two measurements are not exactly the same kind of operation, but they helped me see the difference between switching traffic to an existing environment and replacing a failed application instance.

One thing our Kubernetes deployment does not handle yet is environment-specific configuration. In my Deployment, `NODE_ENV=production` is currently written directly in the manifest. If I wanted to use the same application in staging and production, I would need a better way to manage values that change between environments. Week 9 will introduce ConfigMaps and Secrets for this. That will allow the Deployment manifest to remain mostly the same while the configuration is changed separately.

Overall, this exercise helped me understand how Deployments, Pods, Services and resource settings work together. I also got to see self-healing happen in practice rather than just reading about it. I can now see how the Kubernetes work builds on what we did in Week 7, while introducing a different way of managing and maintaining applications.
