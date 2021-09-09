# CEM Litmus Images

These Docker images are used in CEM Litmus testing. These are built automatically via Github Actions and uploaded to the Github Container Registry.

## Build Args

Each image has two build args: `collection` and `testuser1pw`.

- `collection` stands for Puppet Agent collection, or the version of the Puppet Agent that should be installed. Defaults to `puppet7`
- `testuser1pw` is the password of the test user that gets created on the container, `testuser1`. Defaults to `changeme`

## Customizing the Images

In each Dockerfile, there will be a comment indicating where you can start customizing the image. This is typically just after declaring the second run stage. When modifying the image, keep in mind [best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).

## Adding new images

Create a new directory with an operating system code. Codes should follow the convention `<name><version>`. The codename can be an abbreviation, such as `el` for enterprise linux, or the full operating system name. Once you have created the new directory, create a `Dockerfile` in that directory that works with Litmus. Finally, add the directory name to `matrix.oscode` in the workflow file `.github/workflows/build-containers.yml`.

## Writing Dockerfiles for Litmus

Litmus requires some configurations to be present in the Docker containers it uses, therefore the Dockerfiles must:

- Have a `CMD` statement in shell form
- Expose port 22
- Set `STOPSIGNAL` to `SIGRTMIN+3`
- Declare `VOLUME /run /tmp`
- Add the contents of `/etc/os-release` as metadata labels under the `com.puppetlabs.litmus.os-release` namespace
  - See [here](./el8/Dockerfile) and [here](el7/Dockerfile) for the required metadata labels
- Must have `ssh` and `puppet-agent` packages installed
- Must use a multistage build where these configurations are created in a `builder` container
  - All user modifications made for testing should exist in a second stage by declaring `FROM builder`
  - This allows us to cache as much of the build as possible
