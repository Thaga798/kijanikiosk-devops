# Week 8 Monday – Docker Fundamentals Reflection

## Question 1: The Layer Caching Decision

I arranged the Dockerfile so that the package files are copied before the rest of the application source code. This is useful because the dependencies do not normally change every time I edit the application.

For example, if I edit one line in `src/payments.js`, Docker can reuse the cached `FROM`, `WORKDIR`, package manifest `COPY`, and `RUN npm ci` steps. The first cache miss happens at the `COPY` instruction that copies the application source files. Docker then processes the remaining instructions after that point again. This saves time because npm does not need to install all the dependencies again.

If I add a new dependency, the situation is different. Both `package.json` and `package-lock.json` change, so the manifest-copy layer is no longer reusable. Docker must run `npm ci` again to install the updated dependencies. The later application-copy and remaining instructions are then processed again as part of the new build. This helped me understand why the order of instructions in a Dockerfile matters.

## Question 2: Containers and the Week 7 Deployment

In Week 7, our deployment process depended on the VM already having the correct environment. For example, the correct Node.js version had to be installed. If the VM had a different version, the application could behave differently or fail to run.

The deployment also depended on a particular directory structure being available on the VM. The tarball had to be extracted into the expected location, and the deployment script had to know where the application files were. The systemd service account also had to exist and have the correct permissions before the service could start.

With Docker, these requirements can be handled more consistently. The `FROM node:18-alpine` instruction provides the Node.js runtime inside the image instead of depending on Node.js installed directly on the VM. `WORKDIR /app` establishes the application's working directory, while the `COPY` instructions place the required files in the image. The `RUN npm ci` instruction installs the production dependencies during the image build.

When the container is started, Docker uses the image's configured working directory and command. This reduces the amount of manual preparation needed on the host. The host still needs Docker installed, but it does not need the same Node.js installation or application directory structure as the old deployment approach.

## Question 3: CMD Exec Form vs Shell Form

Tendo pointed out that using `CMD ["npm", "start"]` is not the best choice for this service. Although it can start the application, npm becomes the main process in the container and starts the Node.js application as another process.

This can cause problems when Docker sends a `SIGTERM` signal during a container shutdown. The signal is sent to the main process, which is npm, and the Node.js child process may not receive it as expected. This can prevent the application from completing its graceful shutdown properly.

Using `CMD ["node", "dist/index.js"]` starts Node.js directly as the container's main process. Node.js can then receive `SIGTERM` directly and handle the shutdown. For a payment service, poor shutdown handling could interrupt requests or transactions while the container is stopping. That could result in failed payments or requests that do not complete cleanly. I understand now why the application should be started directly where possible.

## Question 4: What the Container Does Not Yet Solve

The container image should not contain sensitive information such as database passwords, API keys, or other credentials. These details are different between environments and should not be permanently stored inside an image. Including them could expose secrets to anyone who can access the image.

The image should also avoid containing environment-specific configuration, such as database addresses, service URLs, or settings that differ between development, testing, and production. If these values were built into the image, I would need a different image for each environment. That would reduce portability.

Instead, configuration can be provided when starting a container using the `-e` flag with `docker run`. This allows the same image to run with different environment variables. The `.env` anti-pattern discussed in the lesson is to copy a local `.env` file into the image or otherwise bake its contents into the image. This is risky because the values can remain in image layers and the image becomes tied to one environment.

Later in Week 8, the configuration will be supplied at runtime using Kubernetes ConfigMaps and Secrets. ConfigMaps can hold ordinary application configuration, while Secrets are intended for sensitive values. This allows multiple containers using the same image to receive different configuration without rebuilding the image.

