# Docker dev environment setup for php

This is a development env setup based on docker suitable for php.

The docker setup uses the [docker-sync] with [unison strategy] 
this allows to avoid the performance penalty of default docker use
on OSX.

For linux users, it is smooth sailing.

**WARNING: THIS IS NOT TO BE USED IN PRODUCTION**

## Prerequisites for OSX

You need to have [docker for mac][docker-for-mac] installed.

You will need to install a gem for [docker-sync], `fswatch`, [unison] and `macfsevents`, 
by executing the following commands from your terminal

Docker-sync 0.2.0 now supports the use of environment variables for configuration, 
you can then install it just by running

```bash
gem install docker-sync
```

And then you continue with installing the rest of the prerequisites

```bash
brew install fswatch

brew install unison

sudo pip install macfsevents
```

## Prerequisites for Linux

Docker runs the daemon as root, and all the files created by volumes by default will belong to `root:root`, which is, 
well, bad... And I'm going to ignore the security implications, and just go with usual dev business, that you would
have to run your IDE/editor with elevated privileges.

Luckily the answer exists, and it is user namespaces which are present since Linux 3.5, and stable since Linux 4.3.
Depending on your distribution, the steps needed to enable user namespaces may vary, and as such are not covered by this
document, google is your friend.

First you need to find out your user id and group id, this document will assume they are 1000:1000.

Edit `/etc/subuid` to look along the lines of
```bash
vranac:1000:1
vranac:100000:65536
```

Replace `vranac` with your username, and replace `1000` with your userid in the first line.
The second line, if it exist, should match your username, the numbers themselves are of less importance.

Then you should edit `/etc/subgid` to look along the lines of
```bash
vranac:1000:1
vranac:100000:65536
```

Replace `vranac` with your username, and replace `1000` with your userid in the first line.
The second line, if it exist, should match your username, the numbers themselves are of less importance.

The changes you made read as “let user vranac use his own uid as well as 65535 uids, 
starting at 100000 and making the total of uids to 65536”.

And this won’t break anything.

When starting docker with docker daemon with user namespace remap to `vranac`, docker will parse the `subuid` and `subgid` files for 
vranac, sort all read entries by growing start id and generate kernel userns mapping rules. 
Without diving too much into the details, this will generate the following rules in `/proc/[PID]/uid_map`:

```bash
         0       1000          1
         1     100000      65535
```

Which should look familiar. This structures looks like the one above, but the meaning it slightly different. 
This time, it reads as:

“Let uid 1000 outside the container act as root inside the container”
“Let the 65535 uids starting with 100000 outside the container act the 65535 uids starting with 1 inside“
In other words, 1000 will be 1 and 100002 will be 3.

So to enable this, the final step is to edit the `/etc/docker/daemon.json` to look along the lines of

```bash
{
        "userns-remap": "vranac"
}
```

You need to replace `vranac` with yout username.

After this, restart the docker daemon, and from now on, all your host mounted volumes will be under your user:group

## Networking setup

### OSX Setup

When the docker moved to the new engine, one of the things to go is docker0 network interface.
To quote the [docs][docker-for-mac-networking] on networking

> I want to connect from a container to a service on the host
> The Mac has a changing IP address (or none if you have no network access). 
> Our current recommendation is to attach an unused IP to the lo0 interface on the Mac; 
> for example: sudo ifconfig lo0 alias 10.200.10.1/24, and make sure that your service is 
> listening on this address or 0.0.0.0 (ie not 127.0.0.1). Then containers can connect to this address.


What this essentially mean is that you don't have a network address to target with xdebug.

But there is a workaround...
You can either execute the following in your terminal to create a loopback interface alias to an ip 
address

```bash
sudo ifconfig lo0 alias 10.254.254.254 255.255.255.0
```

You would, of course, have to reexecute it on restarts, as this is not a permanent solution.

Or if you want a more permanent solution, you can copy the `com.docker_alias.plist` file from `osx-config` to 
`/Library/LaunchDaemons/com.docker_alias.plist` and from then on, on every reboot the loopback 
will be setup.

To verify that everything has been setup properly, execute `ifconfig` from terminal and the output
should look along the lines of this

```bash
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=3<RXCSUM,TXCSUM>
	inet6 ::1 prefixlen 128
	inet 127.0.0.1 netmask 0xff000000
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
	inet 10.254.254.254 netmask 0xff000000  <--- here you can see it has been setup properly
	nd6 options=1<PERFORMNUD>
```

If you want to use a different ip, go ahead, but make a note of it, and put it into your `.env` for `HOST_IP` key.

The plist file is based on this [gist][gist-lo0-alias]

### Linux Setup

For linux users running `ifconfig` will give you the list of defined network interfaces, you want the `docker0` info.
The output would look something like this

```bash
﻿docker0   Link encap:Ethernet  HWaddr 02:42:43:64:dc:98  
          inet addr:172.17.0.1  Bcast:0.0.0.0  Mask:255.255.0.0 <-- This is what you want
          UP BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

The ip address is `172.17.0.1`.

So now you take the ip address you got, and put it into your `.env` for `HOST_IP` key.

## Integrating Docker in PhpStorm

PhpStorm integrates docker api by using a port, but, from recenlty docker only allows api interaction via sock.

### Prerequisites

To solve this, you will need to install socat.
Installation instructions for it on linux differ by your particular flavor.
To install socat on OSX, you need to execute the following

```bash
brew install socat
```

So once you have socat installed, you would need to start it, by running

```bash
socat TCP-LISTEN:2375,reuseaddr,fork,bind=localhost UNIX-CONNECT:/var/run/docker.sock
```

If you want this to be setup automatically on each start, for linux create an init script and place the above command in it.

On OSX you need to do the following steps:

1. copy the `docker.sock.plist.dist` in `osx-config` directory to `docker.sock.plist`
2. in `docker.sock.plist` update the UserName and GroupName
3. copy `docker.sock.plist` to `~/Library/LaunchAgents/`
4. start with launchctl load ~/Library/LaunchAgents/docker.sock.plist

And now on every restart the socat will be automatically setup.

### PhpStorm setup

To configure PhpStorm you will need to do the following:

1. open preferences
2. under `Build, Execution, Deployment` select `Docker`.
3. if there is no Docker instances defined, create one by clicking on the `+` icon, and give it a name
4. In Api URL enter `tcp://localhost:2375`
5. clear the certificates folder input
6. set the docker compose executable to `/usr/local/bin/docker-compose` or wherever it is (you can find out by running `which docker-compose`)
7. make sure `Import credentials from docker machine` is checked off
8. Click OK

PhpStorm will now be able to interact with docker api, and you will be able to setup remote interpreter etc.

## Dropin environment

If you are using this as a dropin environment in your project via git submodule or subtree.

### Subtree setup

To use the new docker development setup you should add it as a git subtree.
The process is simple, you need to execute a few commands to get started.
Adding the subtree as a remote allows us to refer to it in shorter form:

```bash
git remote add -f docker-dev-setup https://github.com/code4hire/docker-dev-setup.git
```

Now we can add the subtree, but now we can refer to the remote in short form:

```bash
git subtree add --prefix docker docker-dev-setup master --squash
```

The command to update the sub-project at a later date becomes:

```bash
git fetch docker-dev-setup master
git subtree pull --prefix docker docker-dev-setup master --squash
```

### Dropin development setup

You need to symlink the `docker/bin` to `bin` in your project root.
You can do this by executing

```bash
ln -sf docker/bin bin
```

Copy the `docker/.env.dist` to `.env` in your project root.

**PAY ATTENTION TO THE COMMENTS** and edit the `.env` to modify the following:
- `APP_PATH`
- `DATA_PATH`
- `SYNC_NAME`
- `DOCKER_SYNC_LOCATION`
- `COMPOSE_PROJECT_NAME`
- `COMPOSE_FILE`

If you are using `docker-sync`, you can start it in the terminal by executing

```bash
bin/docker-sync-daemon.sh start
```

After this is done, build your containers for the first time by executing 

```bash
bin/docker-compose.sh build
```

### Before first run

Create `application` directory, if not already present, by executing 

```bash
mkdir application
```

## Starting the project up

Once your `.env` has been edited right, and your containers have been build for the first time, and docker-sync is running
(all these steps were described above), you can start this project by running

```bash
bin/docker-compose.sh up -d
```

this will start up all your containers and services in detached mode.

You can check on their status by running

```bash
bin/docker-compose.sh ps
```


## What's in the box

The following services have been setup for use:

- [nginx] server
- [php-fpm] 5.6, 7.0, 7.1
- php cli 5.6, 7.0, 7.1
- [node]
- [mailhog]
- [redis]
- [RabbitMq]

Optional:
- [elk]
- [Ngrok]
- [Selenium] standalone with firefox and chrome

Official docker images are used whenever possible, but some had to be
built from scratch, or a popular one was used

For php and php-fpm, the official images available at [docker hub][cli] are being used.

For node, the official images available at [docker hub][docker-hub-node] are being used.

For mailhog, the official images available at [docker hub][docker-hub-mailhog] are being used.

For nginx, alpine 3.5 official image available at [docker hub][docker-hub-alpine] is being used, and then nginx is
installed on top of it.

For elk, the images available at [docker hub][docker-hub-elk] are being used.

For ngrok image available at [docker hub][docker-hub-ngrok] is being uses.

For Selenium standalone, the images available for [chrome][docker-hub-selenium-chrome] and 
[firefox][docker-hub-selenium-firefox] are being used

## Before first run

1. copy .env.dist to .env
2. edit the .env variable values and follow instructions in the comments
3. edit the docker-sync.yml and give syncs unique names __OSX ONLY__
4. edit the `docker-compose-dev.yml` and update the sync names with the ones you set
in the docker-sync.yml __OSX ONLY__

## Using and building

If you are starting the setup for the first time, or you changed some info in the dockerfiles, or configs,
you need to (re)build the containers and images by executing

### Building

```bash
docker-compose build
```

This command will download all the images, build them up into containers and prepare everything for you.
Depending on your machine specs and internet connection, this can take anywhere beteen 10 and 30 minutes 
(maybe more), as usual YMMV.

### Starting

If you are on __OSX__ all you need to do now is to execute

```bash
docker-sync-stack start
```

If this is your first run, all the images will be build, linked and started, depending on your codebase size
unison might take a while to sync them all up, as explained [here][unison-delay]
 
This basically executes two commands as one, it starts the unison sync container with your mounts, 
and starts the defined containers, this is equivalent to these two commands

```bash
docker-sync start

docker-compose -f docker-compose.yml -f docker-compose-dev.yml up
```

As this covers the linux users as well, I will contine with the second form going forward.

So, for __OSX__ users in one terminal (tab) run

```bash
docker-sync start
```

and in another terminal (tab) you should run

```bash
OSX: docker-compose -f docker-compose.yml -f docker-compose-dev.yml up

linux: docker-compose up
```

OSX needs two config files to setup the volumes correctly, linux does not have the performance penalty,
so it can run with the default `docker-compose.yml`.

What this does is run all the containers but in foreground, if you want to run them in background 
(aka detached mode), you need to add the `-d` switch

```bash
OSX: docker-compose -f docker-compose.yml -f docker-compose-dev.yml up -d

linux: docker-compose up -d
```

### Stopping

So now you need to stop the containers and services.
It is quite easy, if you are running `docker-sync-stack` or are NOT in detached mode, all you need to do is 
press `ctrl+c` this will stop the containers, and might throw some errors (that is ok, and ymmv).

If on the other hand, you are running in detached mode then you need to execute the following

```bash
OSX: docker-compose -f docker-compose.yml -f docker-compose-dev.yml stop

linux: docker-compose stop
```

### Cleanup

To cleanup, on __OSX__, if you run the whole stack at once, you need to execute

```bash
docker-sync-stack clean
```

on the other hand if you are running docker-sync separately from the containers, you need to run

```bash
docker-sync clean
```

and then for linux and osx, you need to run

```bash
OSX: docker-compose -f docker-compose.yml -f docker-compose-dev.yml down

linux: docker-compose down
```

At the end of all this, you will have your syncs cleaned up, and your containers stopped and destroyed.

## PHP Version

If you need to specify the php version that will be used with cli (default is 7.1), you can set
the `PHP_VERSION` in the `.env` file

## Helper scripts

In the `bin` directory there are some shell script helpers to make your life easier.

## Data

The log files from nginx, php-fpm, and xdebug are being dumped into `data/logs` directory.
The mysql database files are located in `data/mysql` directory, so your db data can survive accidents.
The redis data files are located in `data/redis` directory.

## Website

As you have php 5.6, 7.0 and 7.1 at your disposal, the port setup for php without debug is 80 + php version,
meaning 8056, 8070, 8071, and for debugging you have the 90 + php version ports, meaning 9056, 9070, 9071.

Your application will point to url `localhost` + port you need, for example to use php 7.1 without debug,
you would point your browser to `localhost:8071`

If you need to have your website debugged with php 7.1 xdebug, use url `localhost:9071`

## Debugging

By default the idekey for xdebug is `docker-xdebug`, you can change this in the `.env` file under `IDEKEY`,
and then ofc restart the containers.

In PhpStorm, go to preferences, then Languages & Frameworks -> PHP -> Servers, and add a new server for php 7.1
named `docker 7.1`, for the host set `localhost`, for port set `9071`, check `Use path mappings`, and lastly
map `application` in your directory to `/application` as absolute path on server.
Add another server for php 7.0 named `docker 7.0`, for the host set `localhost`, for port set `9070`, 
check `Use path mappings`, and lastly map `application` in your directory to `/application` as absolute path on server.
Add another server for php 5.6 named `docker 5.6`, for the host set `localhost`, for port set `9056`, 
check `Use path mappings`, and lastly map `application` in your directory to `/application` as absolute path on server.

In the `Edit Configurations` add a new PHP Remote Debug, select `docker` + php version as server, and set `docker-xdebug` as
ide key, or whatever else you set in the `.env` file.
You should repeat the process to cover the other versions of php available if needed.

## Mailhog

To send emails to mailhog, use `mailhog` as smtp/mailer host, and use port 1025

When you need to access the mailhog web ui, you need to open url `localhost:8025` in your browser

## RabbitMq

To access the RMQ management plugin you need to open url `localhost:15672` in your browser and 
use admin/admin as username/password.

This can be modified by editing the `docker-compose.yml`

## Optional containers

The optional containers are in `docker-compose-project.yml`
If you want to use any of them, copy the `docker/docker-compose-project.yml` to your project root.
Uncomment the containers you need, and edit your `.env` `COMPOSE_FILE` values to look like

```bash
COMPOSE_FILE=./docker-compose.yml:./docker-compose-project.yml:./docker-compose-dev.yml
```

After that rebuild your images
```bash
bin/docker-compose.sh build
```

and start as usual.

### ELK

To access the ELK stack, you need to open url `localhost:8100` in your browser.

By default this container has been commented out from the `docker-compose-project.yml`.

### Ngrok

When you want to expose a local server behind a NAT or firewall to the internet.

By default this container has been commented out from the `docker-compose-project.yml` so it is not
started by accident.
When you need it, you will need to uncomment the code, edit the `docker-compose-project.yml` lines 13-14 

```yaml
#    environment:
#      HTTP_PORT: nginx:9071
```

to match the port on nginx you want to expose.
Then restart the containers

### Selenium

To use selenium containers, uncomment them in `docker-compose-project.yml` and lines 47-54 so php cli 
will start them up when needed.

The url of the selenium hub/host is `http://selenium-chrome:4444/wd/hub` or `http://selenium-firefox:4444/wd/hub`
as we are using these inside of docker network, the container names get resolved, and you use ports 4444.

If you want to use the selenium containers from outside of docker, the hub/host url is
`http://localhost:49338/wd/hub` or `http://localhost:49339/wd/hub`.

As we are using the debug versions of the container, each of them has a vnc installed.
To access them use ports `5901` and `5902` for chrome and firefox respectively.
The password is `secret`.

## Sylius users

Running `sylius:install` might cause the OOM exception, if this happens, run every part of the install as separate command

[docker-sync]: http://docker-sync.io/
[unison]: https://www.cis.upenn.edu/~bcpierce/unison/
[unison strategy]: https://github.com/EugenMayer/docker-sync/wiki/8.-Strategies#unison
[nginx]: https://www.nginx.com/
[cli]: https://hub.docker.com/_/php/
[php-fpm]: https://php-fpm.org/
[node]: https://nodejs.org/en/
[elk]: https://www.elastic.co/webinars/introduction-elk-stack
[mailhog]: https://github.com/mailhog/MailHog
[docker-hub-node]: https://hub.docker.com/_/node/
[docker-hub-mailhog]: https://hub.docker.com/r/mailhog/mailhog/
[docker-hub-elk]: https://hub.docker.com/r/willdurand/elk/
[docker-hub-alpine]: https://hub.docker.com/_/alpine/
[unison-delay]: https://github.com/EugenMayer/docker-sync/wiki/8.-Strategies#initial-startup-delays-with-unison
[docker-for-mac]: https://www.docker.com/products/overview#/install_the_platform
[redis]: https://redis.io/
[RabbitMq]: https://www.rabbitmq.com/
[Ngrok]: https://ngrok.com/
[docker-hub-ngrok]: https://hub.docker.com/r/fnichol/ngrok/
[gist-lo0-alias]: https://gist.githubusercontent.com/ralphschindler/535dc5916ccbd06f53c1b0ee5a868c93/raw/com.ralphschindler.docker_10254_alias.plist
[docker-for-mac-networking]: https://docs.docker.com/docker-for-mac/networking/
[Selenium]:http://www.seleniumhq.com
[docker-hub-selenium-chrome]:https://hub.docker.com/r/selenium/standalone-chrome/
[docker-hub-selenium-firefox]:https://hub.docker.com/r/selenium/standalone-firefox/
