# Build a Docker image without Dockerfile

You could ask: why would I build an image without Dockerfile?
Well, usually I wouldn't, but it can help us to understand
how docker build works so debugging can be easier and
we our Dockerfile can become better.

In the following examples I use bash on Linux.
If you use Docker Desktop, you need to change some commands
like setting variables.

## Understand a simple Dockerfile

**Dockerfile.v1**

```
FROM ubuntu:20.04
RUN mkdir /app
RUN echo "version=1.0" > /app/config.ini
```

The above Dockerfile contains only two `RUN` instruction after the required `FROM`.
It can remind you to the `docker run` command and this is exactly what happens here.
Each `RUN` instruction means Docker will start a new temporary container and execute
the command inside it. When it finished executing the command it saves the container
as an image. The next instriction will use the previously built image as its base image
and builds a new image.

The reason you usually don't see it is the fact that Docker deletes the containers
unless you tell it not to do that. Passing `--rm=false` to `docker build`
tells Docker it should keep the build containers. But... what if you have already built
the image earlier or at least some of the layers? In that case those layers will not
be created again so there will be no new containers for them unless you also use the 
`--no-cache` flag.

Lets open a terminal and run [./list-containers.sh](./list-containers.sh) from the project root.
It will continuously watch the available containers. Keep that terminal open and open a second terminal window in which you can run the build commands and see what happens.

Run the following command in the new terminal from the project root:

```bash
DOCKER_BUILDKIT=0 \
  docker image build . \
    -t localhost/buildtest:v1 \
    -f Dockerfile.v1 \
     --rm=false \
     --no-cache
```

Note that I disabled buildkit since it is enabled on some systems and it changes
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

# Use "RUN" instructions without the shell form

The previous Dockerfile could be a little different: Let's call it **Dockerfile.v2**.

```
FROM ubuntu:20.04
RUN [ "mkdir", "/app"]
RUN [ "touch", "/app/config.ini" ]
RUN [ "sed", "-i", "$ aversion=1.0", "/app/config.ini" ]
```

Without starting a shell, it takes three RUN instructions to achieve the same.
It's time to build the image:

```bash
DOCKER_BUILDKIT=0 \
  docker image build . \
    -t localhost/buildtest:v2 \
    -f Dockerfile.v2 \
     --rm=false \
     --no-cache
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

## Other instructions also create containers

Now let's complicate things a little.
The following Dockerfile called **Dockerfile.v3** uses more instructions:

```
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
DOCKER_BUILDKIT=0 \
  docker image build . \
    -t localhost/buildtest:v3 \
    -f Dockerfile.v3 \
     --rm=false \
     --no-cache
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
Obviosuly it wouldn't make sense to run them. If you are wondering what `nop` means it is "no operation".

Alright, we have containers but we also know that each container must have an image
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
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
8f1aad1750cd  3 minutes ago   /bin/sh -c #(nop)  CMD ["env"]                  0B        
454de17b2b2e   3 minutes ago   |1 app_dir=/app dir /bin/sh -c echo "version…   12B       
a66c12b47355   3 minutes ago   |1 app_dir=/app dir /bin/sh -c mkdir "$app_d…   0B        
4e1f6025a35c   3 minutes ago   /bin/sh -c #(nop)  ENV version=1.0 config_na…   0B        
e5cc8f6ebbb3   3 minutes ago   /bin/sh -c #(nop)  ARG app_dir=/app dir         0B        
ba6acccedd29   6 weeks ago      /bin/sh -c #(nop)  CMD ["bash"]                 0B        
<missing>      6 weeks ago      /bin/sh -c #(nop) ADD file:5d68d27cc15a80653…   72.8MB
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

## Create your own builder

The question arises, can we build an image without Dockerfile
knowing what we finally know about the build process? The answer is yes,
however, I wouldn't recommend to use that in production. Let's do it anyway.

You can find [./build.sh](build.sh) in the project root which takes one
optional argument, the image name.

It contains a function called `build_layer` which takes the following arguments:

- The source image
- The instruction known from the Dockerfile
- The arguments of the instruction.

I haven't impelemented all the instructions, only some for the demonstration.
These are:

- FROM
- CMD
- ARG
- ENV
- RUN

You can implement more if you want to practice. Even `COPY` can be implemented easily
since we have `docker cp` to copy a file into a container even if that container is
not running since everything is actually on the host somewhere and Docker knows where.

I will not write about each line but I highlight the main part of the script 
to see how similar can the build be to `docker build`

```bash
target_image_name="${1:-}"
image_id=""
step=0

build_layer "$image_id" FROM "ubuntu:20.04"
build_layer "$image_id" ARG app_dir=/app
build_layer "$image_id" ENV version=1.0 config_name=config.ini
build_layer "$image_id" RUN /bin/sh -c 'export app_dir=/app && mkdir $app_dir'
build_layer "$image_id" RUN /bin/sh -c 'export app_dir=/app && echo "version=$version" > "$app_dir/$config_name"'
build_layer "$image_id" RUN /bin/sh -c 'apt-get update && apt-get install nano'
build_layer "$image_id" CMD '["env"]'

printf 'Successfully built %.12s\n' $(echo $image_id | cut -d: -f2)

if [[ -n "$target_image_name" ]]; then
  docker tag "$image_id" "$target_image_name"
  echo "Successfully tagged $target_image_name"
fi
```

Run the script and set the image name to `localhost/buildtest:v4`

```bash
./build.sh localhost/buildtest:v4
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

That's it for now. Make sure you understand how Docker build works
so you will be able to optimize your build and use it the way nobody else could.

## What you can expect later

- Buildkit works different way so you wouldn't see the containers the way
  we did in these examples. You can expect some demonstration on buildkit
  in the future.

- There are other tools to build images compatible with Docker.