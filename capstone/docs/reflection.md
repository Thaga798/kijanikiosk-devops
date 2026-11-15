# Capstone Project Reflection

## 1. What went wrong during the project?

One of the biggest challenges I faced was getting Jenkins to communicate properly with my Kubernetes cluster. Jenkins was running inside a Docker container, while the Kubernetes cluster was managed through Minikube. At first, Jenkins could not reach the Kubernetes API because the two containers were not connected through the same Docker network. After fixing the network connection, I also had to correct the Kubernetes certificate configuration and permissions.

I initially assumed that the certificate information would be included in the kubeconfig file, but my configuration referenced a certificate file on the host instead. I had to make that certificate available to Jenkins and configure its kubeconfig correctly. I also encountered a permissions issue because the staging RoleBinding was initially connected to a different service account from the one Jenkins was using. Using a dedicated service account with the required namespace permissions was a better approach than giving Jenkins unnecessary administrator access.

These issues taught me that having a working Kubernetes deployment is not enough. The tools involved in delivering it also need the correct network access, authentication and permissions.

## 2. What was the most important concept I learned?

The most important concept for me was Kubernetes self-healing and declarative management, which I worked with during Week 8. Before this, I mainly thought about deploying an application as starting containers and making sure they stayed running. Working with Deployments helped me understand that Kubernetes continuously compares the actual state of an application with the desired state.

I tested this by deleting one of the running application Pods and observing Kubernetes create a replacement. I also worked with readiness and liveness checks, resource requests and limits, and separate staging and production environments. This changed how I think about deployment because I now understand that a reliable application should not depend entirely on someone manually checking and restarting it whenever something goes wrong.

## 3. What would I do differently if I started again?

If I were starting the project again, I would spend more time planning and automating the infrastructure before concentrating on application deployment. I would use Terraform and Ansible to make environment provisioning more repeatable instead of relying on manual setup for some of the infrastructure.

I would also build the container image as part of the Jenkins pipeline and configure the pipeline to start automatically when changes are merged into the main branch. This would make the delivery process more complete and reduce the number of manual steps. I would improve monitoring by integrating Prometheus alerting rather than relying only on my error-rate checking script. I would also complete and test the receipt-processing integration as part of the delivery workflow.

The project has helped me understand how the different parts of DevOps fit together. I have made progress with containerisation, Kubernetes, deployment automation and monitoring, but I can also see where the implementation still needs improvement. My main lesson is that a successful deployment is only one part of building a system that can be maintained and delivered reliably.
