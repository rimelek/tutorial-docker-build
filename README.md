# Build a Docker image without Dockerfile

A Dockerfile is basically a text file which contains a series of instructions
describing how we want to create the filesystem of the image and its metadata
like labels and the command we want to execute when we start the container.

This is the standard way when we use Docker so we can share our Dockerfile
with its commonly known syntax and versioning of the text file is not a problem
either.

Now you could ask: why would I build an image without Dockerfile?
Well, usually I wouldn't, but it can help us to understand
how docker build works so debugging can be easier and
our Dockerfile can become better.

In the following examples I use bash on Linux.
If you use Docker Desktop, you need to change some commands
like setting variables.

## Build with a base image

### Understand a simple Dockerfile

**v1.Dockerfile**

```Dockerfile
FROM ubuntu:20.04
RUN mkdir /app
RUN echo "version=1.0" > /app/config.ini
```

The above Dockerfile contains only two `RUN` instructions after the required `FROM`.
It can remind you to the `docker run` command and this is exactly what happens here.
Each `RUN` instruction means Docker will start a new temporary container and execute
the command inside it. When it finished executing the command it saves the container
as an image. The next instruction will use the previously built image as its base image
and build a new image.

The reason you usually don't see it is the fact that Docker deletes the containers
unless you tell it not to do that. Passing `--rm=false` to `docker build`
tells Docker it should keep the build containers. But... what if you have already built
the image earlier or at least some of the layers? In that case those layers will not
be created again so there will be no new containers for them unless you also use the 
`--no-cache` flag.

Let's open a terminal and run [./scripts/docker-watch-containers.sh](./scripts/docker-watch-containers.sh) from the project root.
It will continuously watch the available containers. Keep that terminal open and open a second terminal window in which you can run the build commands and see what happens.

Run the following command in the new terminal from the project root:

```bash
./scripts/docker-build-learn.sh v1
```

It actually executes the following code:

```bash
DOCKER_BUILDKIT=0 \
  docker image build . \
    -t localhost/buildtest:v1 \
    -f v1.Dockerfile \
    --rm=false \
    --no-cache
```

If you look into [docker-build-learn.sh](scripts/docker-build-learn.sh), you can see that I disabled buildkit since it is enabled on some systems and it changes
how images are built. If you don't have buildkit enabled, the first line is optional.

The output in the "watch" window is something like this:

```text
CONTAINER ID   STATE     COMMAND
f1c09b6ace9f   exited    "/bin/sh -c 'echo \"version=1.0\" > /app/config.ini'"
9a574344ad15   exited    "/bin/sh -c 'mkdir /app'"
```

You can see each command in the command column passed to `/bin/sh` as an argument.
This happens because I used the "shell form" to define the commands.
It is what makes the output redirection possible. 

### Use "RUN" instructions with the exec form

The previous Dockerfile could be a little different: Let's call it **v2.Dockerfile**.

```Dockerfile
FROM ubuntu:20.04
RUN [ "mkdir", "/app"]
RUN [ "touch", "/app/config.ini" ]
RUN [ "sed", "-i", "$ aversion=1.0", "/app/config.ini" ]
```

Without starting a shell, it takes three RUN instructions to achieve the same.
It's time to build the image:

```bash
./scripts/docker-build-learn.sh v2
```

The output in the "watch" window is the following:

```text
CONTAINER ID   STATE     COMMAND
0dec9af67b0a   exited    "sed -i '$ aversion=1.0' /app/config.ini"
009537754a31   exited    "touch /app/config.ini"
ca13b1945a00   exited    "mkdir /app"
f1c09b6ace9f   exited    "/bin/sh -c 'echo \"version=1.0\" > /app/config.ini'"
9a574344ad15   exited    "/bin/sh -c 'mkdir /app'"
```

You can see the missing shell, right?

### Other instructions also create containers

Now let's complicate things a little.
The following Dockerfile called **v3.Dockerfile** uses more instructions:

```Dockerfile
FROM ubuntu:20.04
ARG app_dir=/app

ENV version=1.0 \
    config_name=config.ini

RUN mkdir "$app_dir"
RUN echo "version=$version" > "$app_dir/$config_name"

CMD ["env"]
```

We have different kind of variables like environment variables (`ENV`) and
build arguments (`ARG`). At the end of the file we also have `CMD`
to specify the command that should run when the container starts.
In this example I used `env` so I can list the environment variables in the container
by default.

`RUN` is not the only instruction which creates a container. Although this is
the one which also starts the container to execute the commands. So why do we need
more containers? To understand that let's build the image:

```bash
./scripts/docker-build-learn.sh v3
```

Now we have five more containers in the other window.

```text
CONTAINER ID   STATE     COMMAND
0f2324b6ba71   created   "/bin/sh -c '#(nop) ' 'CMD [\"env\"]'"
cdb574642ea8   exited    "/bin/sh -c 'echo \"version=$version\" > \"$app_dir/$config_name\"'"
22d399354111   exited    "/bin/sh -c 'mkdir \"$app_dir\"'"
cc0d403dd1df   created   "/bin/sh -c '#(nop) ' 'ENV version=1.0 config_name=config.ini'"
3e4aa53e11c6   created   "/bin/sh -c '#(nop) ' 'ARG app_dir=/app'"
0dec9af67b0a   exited    "sed -i '$ aversion=1.0' /app/config.ini"
009537754a31   exited    "touch /app/config.ini"
ca13b1945a00   exited    "mkdir /app"
f1c09b6ace9f   exited    "/bin/sh -c 'echo \"version=1.0\" > /app/config.ini'"
9a574344ad15   exited    "/bin/sh -c 'mkdir /app'"
```

Wait... there is some strange commands in the output. 
As I wrote before, only the `RUN` instruction starts a new container,
however, each instruction (except `FROM`) creates a container which can be useful for caching
but these containers does not need to run. In these containers the command
is actually a comment (`#(nop)`) which gets the metadata definition as an argument. 
Obviously it wouldn't make sense to run them. If you are wondering what `nop` means it is "no operation".

Alright, we have containers, but we also know that each container must have an image
from which it was created. You can see those images by running the following command:

```bash
docker image ls --all
```

The output is the following in my case:

```text
REPOSITORY            TAG       IMAGE ID       CREATED          SIZE
localhost/buildtest   v3        8f1aad1750cd   3 minutes ago    72.8MB
<none>                <none>    454de17b2b2e   3 minutes ago    72.8MB
<none>                <none>    a66c12b47355   3 minutes ago    72.8MB
<none>                <none>    4e1f6025a35c   3 minutes ago    72.8MB
<none>                <none>    e5cc8f6ebbb3   3 minutes ago    72.8MB
localhost/buildtest   v2        5aa8350c2891   5 minutes ago    72.8MB
<none>                <none>    594c4ab64112   5 minutes ago    72.8MB
<none>                <none>    f8b86868aff2   5 minutes ago    72.8MB
localhost/buildtest   v1        ac80a8836633   20 minutes ago   72.8MB
<none>                <none>    1a5c9ef0a7c2   20 minutes ago   72.8MB
ubuntu                20.04     ba6acccedd29   6 weeks ago      72.8MB
```

Each line where "REPOSITORY" and "TAG" are `<none>` shows an image
created by the build processes without assigning a name to them.
The last layer got a name but it is not required, however, we usually
use `-t imagename` to set a name.

If you want to find an image what other images was built on, you can use
`docker image history`:

```bash
docker image history localhost/buildtest:v3
```

The output:

```text
IMAGE          CREATED         CREATED BY                                      SIZE      COMMENT
8f1aad1750cd   3 minutes ago   /bin/sh -c #(nop)  CMD ["env"]                  0B        
454de17b2b2e   3 minutes ago   |1 app_dir=/app dir /bin/sh -c echo "version…   12B       
a66c12b47355   3 minutes ago   |1 app_dir=/app dir /bin/sh -c mkdir "$app_d…   0B        
4e1f6025a35c   3 minutes ago   /bin/sh -c #(nop)  ENV version=1.0 config_na…   0B        
e5cc8f6ebbb3   3 minutes ago   /bin/sh -c #(nop)  ARG app_dir=/app dir         0B        
ba6acccedd29   6 weeks ago     /bin/sh -c #(nop)  CMD ["bash"]                 0B        
<missing>      6 weeks ago     /bin/sh -c #(nop) ADD file:5d68d27cc15a80653…   72.8MB
```


You can check that these images contain some metadata of the container
from which it was created.

```bash
docker image inspect localhost/buildtest:v3 --format '{{ .ContainerConfig.Cmd }}'
```

This shows you the command of that container like:

```text
[/bin/sh -c #(nop)  CMD ["env"]]
```

This can be familiar from the output of the `docker image history`.

### Create your own builder

The question arises, can we build an image without Dockerfile
knowing what we finally know about the build process? The answer is yes,
however, I wouldn't recommend using that in production. Let's do it anyway.

You can find [./scripts/custom-build.sh](./scripts/custom-build.sh) from the project root which takes one
optional argument, the image name.

It contains a function called `build_layer` which takes the following arguments:

- The source image
- The instruction known from the Dockerfile
- The arguments of the instruction.

I haven't implemented all the instructions, only some for the demonstration.
These are:

- FROM
- CMD
- ARG
- ENV
- RUN

You can implement more if you want to practice. Even `COPY` can be implemented easily
since we have `docker cp` to copy a file into a container even if that container is
not running since everything is actually on the host somewhere and Docker knows where.

I will not write about each line, but I highlight the main part of the script 
to see how similar can the build be to `docker build`

```bash
target_image_tag="$1"
target_image_name="$PROJECT_IMAGE_REPOSITORY:$target_image_tag"
image_id=""
step=0

build_layer "$image_id" FROM "ubuntu:20.04"
build_layer "$image_id" ARG app_dir=/app
build_layer "$image_id" ENV version=1.0 config_name=config.ini
build_layer "$image_id" RUN /bin/sh -c 'export app_dir=/app && mkdir $app_dir'
build_layer "$image_id" RUN /bin/sh -c 'export app_dir=/app && echo "version=$version" > "$app_dir/$config_name"'
build_layer "$image_id" RUN /bin/sh -c 'apt-get update && apt-get install nano'
build_layer "$image_id" CMD '["env"]'

printf 'Successfully built %.12s\n' "$(echo "$image_id" | cut -d: -f2)"

if [[ -n "$target_image_name" ]]; then
  docker image tag "$image_id" "$target_image_name"
  echo "Successfully tagged $target_image_name"
fi
```

Run the script and set the image name to `localhost/buildtest:v4`

```bash
./scripts/custom-build.sh v4
```

The output is something like this

```text
Step 1 : FROM ubuntu:20.04
 ---> ba6acccedd29
Step 2 : ARG app_dir=/app
 ---> Running in 133812f57bc1
 ---> 2f9cb987c067
Step 3 : ENV version=1.0 config_name=config.ini
 ---> Running in ed436991f98e
 ---> 99c07cd3dcf1
Step 4 : RUN /bin/sh -c export app_dir=/app && mkdir $app_dir
 ---> Running in c6d85646ab03
 ---> 0e64b8abece3
Step 5 : RUN /bin/sh -c export app_dir=/app && echo "version=$version" > "$app_dir/$config_name"
 ---> Running in 8b0246f8c190
 ---> 056213ce7313
Step 6 : RUN /bin/sh -c apt-get update && apt-get install nano
 ---> Running in 43049a418662
Get:1 http://archive.ubuntu.com/ubuntu focal InRelease [265 kB]
... (truncated to have a shorter output in the README) 
 ---> 65f8c63875c0
Step 7 : CMD ["env"]
 ---> Running in c54a622e46ae
 ---> f1a726e108d1
Successfully built f1a726e108d1
Successfully tagged localhost/buildtest:v4
```

Is it familiar? It should be.

One noticeable difference is that the original `docker build` shows you 
how many steps are in the build and which step it is running at the moment.
This small bash script only shows the number of the current step. Not a big deal.

Now the image history will be a little different but the final image will be the same:

```text
IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
f1a726e108d1   5 hours ago   /bin/sh -c #(nop) CMD ["env"]                   0B        
65f8c63875c0   5 hours ago   /bin/sh -c apt-get update && apt-get install…   32.9MB    
056213ce7313   5 hours ago   /bin/sh -c export app_dir=/app && echo "vers…   12B       
0e64b8abece3   5 hours ago   /bin/sh -c export app_dir=/app && mkdir $app…   0B        
99c07cd3dcf1   5 hours ago   /bin/sh -c #(nop) ARG version=1.0 config_nam…   0B        
2f9cb987c067   5 hours ago   /bin/sh -c #(nop) ARG app_dir=/app              0B        
ba6acccedd29   6 weeks ago   /bin/sh -c #(nop)  CMD ["bash"]                 0B        
<missing>      6 weeks ago   /bin/sh -c #(nop) ADD file:5d68d27cc15a80653…   72.8MB
```

## Build without a base image

### Without filesystem

So far, we have used an Ubuntu base image for each build,
so someone actually had to build an image before we could build ours.
But how was that image built?

We can use `FROM scratch` at the beginning of our Dockerfile,
which doesn't do anything at all. You can't build an image with only this line
in the Dockerfile. You have to have at least some metadata or
copy files into the image.

To see what it creates after the build we will start a new, empty environment.
You can do it in a virtual machine or use [Docker in Docker](https://hub.docker.com/_/docker).
I will just replace my old docker data folder with an empty one.

> **DO NOT** touch this folder on a system where you have actually used Docker containers
> unless you know exactly what you are doing.

The following scripts are using [./env.default.sh](./env.default.sh) as a configuration file
to set `PROJECT_DOCKER_DATA_DIR` (default value: `/var/lib/docker`) and
`PROJECT_DOCKER_DATA_DIR_ARCHIVED_BASE` (default value: `"${PROJECT_DOCKER_DATA_DIR}.archived"`).
You can change those settings by copying `./env.default.sh` as `./env.custom.sh`
and changing the values. The scripts are using `systemctl` to stop and start the Docker daemon. 
If you have a different environment like "Windows Subsystem for Linux", it will not work, but
you can check the scripts to get an idea how you can do it.

If you want to make a backup of your docker data directory, run the following script:

```bash
./scripts/docker-data-archive.sh
```
This is where `PROJECT_DOCKER_DATA_DIR_ARCHIVED_BASE` is important, because if you don't have
enough space on the disk of the default location, you can change it to save your current data
to another disk. Each backup directory will get a number as a suffix.

Now we need to reset the docker data dir, so run the script below.
Note that this script is called `docker-data-destroy.sh` because I wanted to make sure you understand
that it will really destroy all of your data if you don't have a backup.

```bash
./scripts/docker-data-destroy.sh
```

Let's see the files in this new folder after starting the Docker daemon.

```bash
./scripts/docker-data-files.sh
```

```text
volumes/metadata.db
image/overlay2/repositories.json
network/files/local-kv.db
buildkit/snapshots.db
buildkit/containerdmeta.db
buildkit/cache.db
buildkit/metadata_v2.db
```

We have database files and one json to store information about our image tags.

```bash
./scripts/docker-data-repositories.sh | jq
```

```json
{
  "Repositories": {}
}
```

The next command is not optional. We need to archive the docker data folder, so we can compare that and the modified
folder after docker build.

```bash
./scripts/docker-data-archive.sh
```

It's time to build our first image from scratch. In this case, we don't want to keep the build containers,
so we will use [./scripts/docker-build.sh](./scripts/docker-build.sh) which runs `docker build` without 
`--no-cache` and `--rm=false`.

```bash
./scripts/docker-build.sh v5
```

Check the newly created files

```bash
./scripts/docker-data-files.sh
```

```text
volumes/metadata.db
image/overlay2/repositories.json
image/overlay2/imagedb/content/sha256/18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00
image/overlay2/imagedb/metadata/sha256/18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00/lastUpdated
network/files/local-kv.db
buildkit/snapshots.db
buildkit/containerdmeta.db
buildkit/cache.db
buildkit/metadata_v2.db
```

Since the files with the "db" extension are binaries, we can't just use `diff` command to see what changed.
Run the following command to build `dockerdb-reader` written in GO

```bash
./scripts/go-build-dockerdb-reader.sh
```

List the changed files including the binary database files.
Use `1` as argument instead of `2` if did not archive your
original, non-empty directory.

```bash
./scripts/docker-data-diff.sh 2
```

The output is something similar:

```text
Only in /var/lib/docker/image/overlay2/imagedb/content/sha256: 18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00
Only in /var/lib/docker/image/overlay2/imagedb/metadata/sha256: 18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00
Files /var/lib/docker/image/overlay2/repositories.json and /var/lib/docker.archived.1/image/overlay2/repositories.json differ
Files /var/lib/docker/network/files/local-kv.db and /var/lib/docker.archived.1/network/files/local-kv.db differ
```

We can check the content of the database using the following command:

```bash
./scripts/docker-data-db-reader.sh network/files/local-kv.db | jq
```

The output is long so I leave here only a part of it as an example:

```json
{
  "libnetwork": {
    "docker/network/v1.0/bridge/a4ffccb66f2ac86cc6aee6c4e2319d6b64887adf6b832c09e94484fa5d2f4736/": "{\"AddressIPv4\":\"172.17.0.1/16\",\"BridgeIfaceCreator\":2,\"BridgeName\":\"docker0\",\"ContainerIfacePrefix\":\"\",\"DefaultBindingIP\":\"0.0.0.0\",\"DefaultBridge\":true,\"DefaultGatewayIPv4\":\"\\u003cnil\\u003e\",\"DefaultGatewayIPv6\":\"\\u003cnil\\u003e\",\"EnableICC\":true,\"EnableIPMasquerade\":true,\"EnableIPv6\":false,\"HostIP\":\"\\u003cnil\\u003e\",\"ID\":\"a4ffccb66f2ac86cc6aee6c4e2319d6b64887adf6b832c09e94484fa5d2f4736\",\"InhibitIPv4\":false,\"Internal\":false,\"Mtu\":1500}"
  }
}
```
As you can see, there is a hash in the first key of the network settings.
This is what changes every time I reset the docker folder.

Let's check the content of the `repositories.json` again.

```bash
./scripts/docker-data-repositories.sh | jq
```

```json
{
  "Repositories": {
    "localhost/buildtest": {
      "localhost/buildtest:v5": "sha256:18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00"
    }
  }
}
```

This is a very simple json containing the image tags and their IDs.
If you need proof, run the following command:

```bash
docker image ls --no-trunc --format '{{.ID}}'
```

You can get the ID of `localhost/buildtest:v5` instead of listing every image:

```bash
docker image inspect localhost/buildtest:v5 --format '{{ .ID }}'
```

Using this ID you can get the metadata of this image by reading the file we have just discovered in `image/overlay2/imagedb/content/sha256/`:

```bash
hash="$(docker image inspect localhost/buildtest:v5 --format '{{ .ID }}' | tr ':' '/')"
./scripts/docker-data-cat.sh "image/overlay2/imagedb/content/$hash" | jq .
```

```json
{
  "architecture": "amd64",
  "config": {
    "Hostname": "",
    "Domainname": "",
    "User": "",
    "AttachStdin": false,
    "AttachStdout": false,
    "AttachStderr": false,
    "Tty": false,
    "OpenStdin": false,
    "StdinOnce": false,
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": null,
    "Image": "",
    "Volumes": null,
    "WorkingDir": "",
    "Entrypoint": null,
    "OnBuild": null,
    "Labels": {
      "maintainer": "itsziget"
    }
  },
  "container": "ccf2c0a1c387fd3ec67a5da061ddbb63a0c18aedfee9b7c35a86eda13d4bb763",
  "container_config": {
    "Hostname": "ccf2c0a1c387",
    "Domainname": "",
    "User": "",
    "AttachStdin": false,
    "AttachStdout": false,
    "AttachStderr": false,
    "Tty": false,
    "OpenStdin": false,
    "StdinOnce": false,
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": [
      "/bin/sh",
      "-c",
      "#(nop) ",
      "LABEL maintainer=itsziget"
    ],
    "Image": "",
    "Volumes": null,
    "WorkingDir": "",
    "Entrypoint": null,
    "OnBuild": null,
    "Labels": {
      "maintainer": "itsziget"
    }
  },
  "created": "2021-12-19T19:39:16.963499812Z",
  "docker_version": "20.10.12",
  "history": [
    {
      "created": "2021-12-19T19:39:16.963499812Z",
      "created_by": "/bin/sh -c #(nop)  LABEL maintainer=itsziget",
      "empty_layer": true
    }
  ],
  "os": "linux",
  "rootfs": {
    "type": "layers"
  }
}
```

This is similar to what you can see using `docker image inspect`

```bash
docker image inspect localhost/buildtest:v5 --format '{{ json . }}' | jq .
```

```json
{
  "Id": "sha256:18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00",
  "RepoTags": [
    "localhost/buildtest:v5"
  ],
  "RepoDigests": [],
  "Parent": "",
  "Comment": "",
  "Created": "2021-12-19T19:39:16.963499812Z",
  "Container": "ccf2c0a1c387fd3ec67a5da061ddbb63a0c18aedfee9b7c35a86eda13d4bb763",
  "ContainerConfig": {
    "Hostname": "ccf2c0a1c387",
    "Domainname": "",
    "User": "",
    "AttachStdin": false,
    "AttachStdout": false,
    "AttachStderr": false,
    "Tty": false,
    "OpenStdin": false,
    "StdinOnce": false,
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": [
      "/bin/sh",
      "-c",
      "#(nop) ",
      "LABEL maintainer=itsziget"
    ],
    "Image": "",
    "Volumes": null,
    "WorkingDir": "",
    "Entrypoint": null,
    "OnBuild": null,
    "Labels": {
      "maintainer": "itsziget"
    }
  },
  "DockerVersion": "20.10.12",
  "Author": "",
  "Config": {
    "Hostname": "",
    "Domainname": "",
    "User": "",
    "AttachStdin": false,
    "AttachStdout": false,
    "AttachStderr": false,
    "Tty": false,
    "OpenStdin": false,
    "StdinOnce": false,
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": null,
    "Image": "",
    "Volumes": null,
    "WorkingDir": "",
    "Entrypoint": null,
    "OnBuild": null,
    "Labels": {
      "maintainer": "itsziget"
    }
  },
  "Architecture": "amd64",
  "Os": "linux",
  "Size": 0,
  "VirtualSize": 0,
  "GraphDriver": {
    "Data": null,
    "Name": "overlay2"
  },
  "RootFS": {
    "Type": "layers"
  },
  "Metadata": {
    "LastTagTime": "2021-12-19T20:39:17.006927699+01:00"
  }
}
```

Compared to the previous outputs the file called "lastUpdated" is not so interesting.

```bash
hash="$(docker image inspect localhost/buildtest:v5 --format '{{ .ID }}' | tr ':' '/')"
./scripts/docker-data-cat.sh -l "image/overlay2/imagedb/metadata/$hash/lastUpdated"
```

Note that I used `-l` flag to make sure the output ends with a line break, since the file does not contain it.

```text
2021-12-19T20:39:17.006927699+01:00
```

If you are wondering where that long ID comes from, check this out:

```bash
hash="$(docker image inspect localhost/buildtest:v5 --format '{{ .ID }}' | tr ':' '/')"
./scripts/docker-data-cat.sh "image/overlay2/imagedb/content/$hash" | sha256sum | cut -d " " -f1
```

```text
18391a6e324a1b804a02d7c07b303b68925ed6971bc955e64f4acd17f67d2b00
```

The ID is generated from the json file which contains everything about the image, even its build history.
Now you have the power to create your own image from scratch without a filesystem.
This is not really useful, is it?

Let's build our first go app which we can use in a container. I installed go as a snap package:

```bash
sudo snap install go --channel 1.17/stable --classic
```

Build `hello.go`

```bash
./scripts/go-build-hello.sh
```

Now I can use the empty image to create a container and run the hello app
in that container.

```bash
docker run -it --rm -v $PWD/var/bin/hello:/hello localhost/buildtest:v5 /hello
```

```text
Hello Go!
```

Now we are ready to create our first image from scratch without
Dockerfile and the `docker run` command.

The [meta.json](meta.json) will contain the metadata we saw earlier.
The `lastUpdated` file will be created dynamically. Yes, we can do it! We are good!
And finally, `v6.sh` will do the build.

Run the following command:

```bash
sudo ./v6.sh
```

If you list the images now, you won't see the v6. 

```bash
docker image ls
```

We have to restart the Docker daemon,
so it can reload the configuration. If you build a new image before you restart
the docker daemon, Docker will overwrite the `repositories.json` without
the tag which was added to the file by the script.

If you don't want your already running containers to stop, you have to enable
[live-restore](https://docs.docker.com/config/containers/live-restore/),
which is unfortunately not compatible with Docker Swarm.

**Note:** Apparently, if you use the `--rm` option with `docker run`, Docker will
remove the container even if you configure live restore.

```bash
systemctl restart docker
```

Now the magick is done, we have the new image:

```bash
docker image ls
```

```text
REPOSITORY            TAG       IMAGE ID       CREATED          SIZE
localhost/buildtest   v6        7b46d4496bd9   27 hours ago     0B
```

Let's try the new image:

```bash
docker run -it --rm -v $PWD/var/bin/hello:/hello localhost/buildtest:v5 /hello
```

### With a minimal filesystem

```bash
./v7.sh
```

TODO: 

- Find the layer
- Find the tar-split json
- docker save v8
- extract
- sha256sum on layer.tar
- Compare hash


That's it for now. Make sure you understand how Docker build works
so you will be able to optimize your build and use it the way nobody else could.

## What you can expect later

- Buildkit works different way so you wouldn't see the containers the way
  we did in these examples. You can expect some demonstration on buildkit
  in the future.

- There are other tools to build images compatible with Docker.
