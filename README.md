# Dockerfile for MaYoR
__Source:__ http://www.mayor.hu/index.php?page=portal&f=download
__License (original):__ http://www.mayor.hu/LICENSE.txt
__License (current):__ Everything is permitted, which should be permitted according to the [original license](http://www.mayor.hu/LICENSE.txt). For further questions, please get in touch with [me](mailto:lezsakdomi1@gmail.com). So you should be fair, or [pm](https://fb.com/lezsakdomi) [me](https://github.com/lezsakdomi).

## About
These files are made nearly just-for-fun, by a student who tried to try out this software in a secure way.
Altough this work could be usable for system administrators too.

Please note, that the first developer of these scripts is (was) learning in Békásmegyeri Veres Péter Gimnázium. He is proud of this :)

## Usage
In short:
0. You need first install the essential _GNU_ build tools (`make` and `m4`, as of writing), and the [Docker](https://www.docker.com/) containerization software. Good luck upon the steps of getting started in using source-distributed microservices!
1. Then do a `make build` (optionally a `make tag` (aka `make install`))
2. And for running the software, `make run`
3. You could reset the container any time by `make clean-container run`, restart by `make stop start` (or just `make restart`).
4. How to delete this shit from your machine? `make clean && rm -r .`.

### Stage 1 - Building Dockerfile
The Dockerfile is wrapped with `m4`. The macros are documented in the `Makefile`, but make sure for yourself: `grep 'm4_ifdef' Dockerfile.m4`. They are self-explaining.
Oh, and I almost forgot: To build the Dockerfile, issue `m4 -P Dockerfile` or `make Dockerfile`.

Note that the code is distributed with prebuilt dockerfile. To make this step yourself, delete the product(`rm Dockerfile`), or clean first (`make clean Dockerfile`)

### Stage 2 - Building docker images
After you have the `Dockerfile`, you could basically continue it in the docker way:
```
:; docker build . -t mayor:latest
:; export container=$(docker run -d -p 443:443 mayor)	# Pass `-D NO_SSL` to m4 when building Dockerfile (buggy) for port 80
# evaluate the software: https://localhost/
:; docker stop $container
:; docker rm $container
:; docker rmi mayor	# Optional
```

... but we have a wrapper for it in the Makefile: `make build`. This (second) method is more sofisticated, stores the container id in a file and basnishes having multiple instances of the same image running in a container, etc.. See the head of the `Makefile` for the documentation of possible build parameters!
For example, if you want to change the configured domain name:
```
make clean build HOSTNAME=newhost.domain
```

We don't care about the caching here by make, docker does it nicely: We just doing a macro substitution, and deleting/recreating a few files unnecessary.


Docker sends the context to the daemon. Here isn't any `.dockerignore`, but we don't have mouch hassle. The most of the scripts are needed!

Please do note, that there is `KEEP_CONTAINER` make variable exists, but not recommended. This doesn't cleans up trash before rebuilds. May be good for heavy cachers.

#### Build arguments
Those are redundant documented both in the `Makefile` (after the veriable declaration, using comments) and in the `Dockerfile` (in the lines preceding the `ARG ...` statement)

### Stage 3 - Running the container
For the docker way, please see [other documentations](https://docs.docker.com/engine/docker-overview/).

But! We have a nice make wrapper!

#### Running
To get up and running the software, just issue `make run`. Everything is preconfigured.

#### Stopping/Starting/Restarting
Issue `make stop`, `make run` or `make restart`, respectively.

#### Deleting (`rm`/`rmi`)
Use the clean-rules here:
```
make clean-container
```
and/or
```
make clean-image
```

BTW, cleaning: Not recommended, but possible: `make KEEP_CONTAINER=1 build`

## Authors
Mainly [Domonkos Lezsák](https://plus.google.com/+DomonkosLezs%C3%A1k) is responsible for these files.
For the real content, please search for the [MaYoR](http://www.mayor.hu/) team.

## Changelog
A fully-functional `Makefile`, `Dockerfile.m4` and helper scripts were made on __October, 2017__. This is the codebase.
