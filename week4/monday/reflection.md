# Question 1: The Idempotency Gap

Terraform uses a state file to keep track of the
infrastructure it manages. The state file records the
resources that Terraform has created and important
details about them. This can include the resource ID,
IP address, settings, and other attributes.

When Terraform runs, it compares the desired
configuration with the state file and the actual
infrastructure. If everything already matches,
Terraform does not make changes. If something needs
to change, Terraform creates, updates, or removes
resources as needed.

The state file can sometimes say that everything is
correct even when the real infrastructure has changed.
For example, someone could manually change a firewall
rule or delete a resource from the cloud console.
Terraform's configuration and state may still show the
old situation.

The correct response is to refresh or run Terraform
planning so that Terraform can detect the difference.
The infrastructure should then be brought back to the
desired state. Manual changes should generally be
avoided because Terraform should be the source of truth
for infrastructure it manages.

# Question 2: Declarative Specification Quality

My desired-state specification gives a good overview
of the VM, but it is not detailed enough for another
engineer to reproduce the exact same server in a
different cloud provider without asking questions.

One gap is the network configuration. I specified the
subnet and that the VM should not have a public IP,
but I did not specify enough cloud-specific information
about the VPC, subnet, routing, and security group.
Different cloud providers use different networking
models. Terraform could therefore make assumptions
that produce a different network setup.

Another gap is the instance type. I specified 1 CPU
and 1 GB of RAM, but I did not specify an exact
instance type for a cloud provider. Different
providers have different instance types. Terraform
could choose a default or require another decision.
The result could have different performance or cost.

The storage section also has some uncertainty. I
specified a 10 GB root disk, but the exact disk type
and performance requirements are not fully defined
for a cloud environment.

This shows that automation is only as reliable as the
specification it is based on. If important decisions
are missing, the automation has to guess or use
defaults. That can lead to infrastructure that works
but is not what was actually intended.

# Question 3: Tool Boundary

Creating a firewall rule that allows port 80 from
anywhere should be handled by Terraform. A firewall
rule is part of the infrastructure and networking
configuration. Terraform can create the rule and keep
it consistent with the desired infrastructure.

If I used Ansible for this, the firewall could still
be configured, but the infrastructure definition would
be mixed with server configuration. It would also be
harder to manage the rule as part of the overall
infrastructure.

Installing nginx 1.24.0 on a running VM should be
handled by Ansible. Installing and configuring
software on an existing server is configuration
management. Ansible can make sure the correct version
is installed and that the service is configured and
running.

Using Terraform for this would make the Terraform
configuration more complicated. Terraform can run
commands, but that is not its main purpose. It would
also make software configuration harder to maintain.

Verifying that nginx is responding to HTTP requests
can be done with Ansible or bash. I would use Ansible
as part of the configuration process because it can
verify the service after installation. A simple bash
command such as curl can also be useful for a quick
manual test.

If I used only Terraform for the HTTP check, I would
be using an infrastructure tool for a server-level
verification task. If I used only bash for everything,
I would lose the repeatability and structure provided
by Ansible.

The main idea is that Terraform should handle the
infrastructure, Ansible should handle the server
configuration, and bash is useful for simple commands
and checks.

# Question 4: From Script to Spec

Some parts of the Week 3 provisioning script
translated easily into the desired-state specification.
Things such as the server name, operating system,
resources, storage, networking, and access rules can
be described as a desired end state.

The difficult parts were the steps that depended on
a sequence of actions. For example, installing
packages, creating users, changing configuration files,
starting services, and checking the result are easier
to describe as tasks that need to happen in order.

A script mainly tells the computer how to do something.
A specification describes what the final result should
look like.

This difference is important for configuration
management. Terraform does not need a list of commands
such as "create this, then run this command." It works
from the desired state and works out what changes are
required.

The difficulty I found in converting the Week 3 script
into a specification also showed me that not everything
belongs in Terraform. Infrastructure decisions such as
servers, networks, storage, and firewall rules fit well
into Terraform. Software installation and server
configuration fit better into Ansible.

This is why Terraform and Ansible work well together.
Terraform creates the infrastructure, while Ansible
makes sure the systems running on that infrastructure
are configured correctly.
