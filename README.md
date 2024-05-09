# Dockerized LGSM Rust Dedicated Server 
This project combines Docker, [Rust][rust] Dedicated Server, and [Linux
GSM][lgsm] all in one!  Self-hosted Rust dedicated server management made easy.

- [Play on your server](#play-on-your-server)
- [Playing multiplayer](#playing-multiplayer)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Server power management](#server-power-management)
  - [Starting the server](#starting-the-server)
  - [Graceful shutdown](#graceful-shutdown)
  - [Uninstallation](#uninstallation)
- [Game Server Administration](#game-server-administration)
  - [Login shell](#login-shell)
  - [RCON: Remote Admin Console](#rcon-remote-admin-console)
    - [RCON remote access](#rcon-remote-access)
  - [Limiting server resources](#limiting-server-resources)
  - [Backup and restore from backup](#backup-and-restore-from-backup)
  - [Log management](#log-management)
  - [Easy Anti-Cheat](#easy-anti-cheat)
- [Server Mods](#server-mods)
  - [Oxide mods](#oxide-mods)
  - [Custom mods](#custom-mods)
  - [Troubleshooting: Mods failing to load](#troubleshooting-mods-failing-to-load)
  - [Updating mod configuration](#updating-mod-configuration)
- [Customize Map](#customize-map)
  - [Generated Maps](#generated-maps)
  - [Custom Maps](#custom-maps)
    - [Self-hosted custom maps](#self-hosted-custom-maps)
    - [Remotely hosted custom maps](#remotely-hosted-custom-maps)
    - [Observer Island](#observer-island)

# Play on your server

By default your server is forwarding port `28015/UDP` to all interfaces so that
you can use router port forwarding to play multiplayer.

If you're playing on the same machine from Proton on Linux, then press F1 to
open console and connect with:

    client.connect 127.0.0.1:28015

You may need to enter a domain name or alternate IP address if you're playing
Rust from a different computer.

# Playing multiplayer

Enable port forwarding on your router for the following ports.

- `28015/udp` (required for game clients)
- `8000/tcp` (optional: only required if self-hosting a custom map)

# Prerequisites

- 4GB of RAM if the server is remotely hosted (total memory including OS).
  Alternately, 16GB of RAM if you're going to host a dedicated server and play
  on the same machine.  These memory recommendations are just estimates and
  minimum requirements for memory could be much lower.
- You have [Git installed][git] and cloned this repository to work with locally.

  ```
  git clone https://github.com/samrocketman/docker-compose-lgsm-rust-dedicated-server
  ```

- Install [Docker on Linux][docker].  Docker on Windows or Mac would probably
  work but is entirely untested.  Docker for Mac has known performance issues
  unrelated to Rust.
- Install [docker compose][compose].  This typically comes separate from Docker.

# Getting started

If you don't want to customize anything, then start the server.  It will
generate a 3K map using a random seed which will persist when restarting the
server.

    docker compose up -d

It may take 15 minutes or longer for the server to start the first time
depending on your internet connection.  This is because it has to download Rust
among other server setup tasks.  You can monitor the server logs at any time (to
see progress) with the following command.

    docker compose logs -f

Press `CTRL+C` to exit logs.

# Server power management

### Starting the server

    docker compose up -d

It may take at 5 minutes or longer to start depending on your internet
connection.

See logs with the following command (`CTRL+C` to cancel).

    docker compose logs -f

### Graceful shutdown

    docker compose down

### Uninstallation

To completely uninstall and delete all Rust data run the following command.

    docker compose down -v --rmi all

Remove this Git repository for final cleanup.

# Game Server Administration

### Login shell

If you want a shell login to your server, then run the following command from
the root of this repository.

```bash
./admin/shell.sh

# alternately if you need root shell access
./admin/shell.sh root
```

### RCON: Remote Admin Console

You can access the Rust RCON interface using any RCON client.  I recommend one
of the following clients.

- https://facepunch.github.io/webrcon Facepunch official client
- http://rcon.io/login community RCON client

The RCON interface is password protected.  Reveal the password using the
following command.

    ./admin/get-rcon-pass.sh

The script will output your RCON password as well as additional instructions for
your web browser to access the RCON console.

##### RCON remote access

Rust RCON connection uses `ws://` websocket protocol.  It does not support
secure websockets (`wss://`).  Because of this, it is not fit for secure
internet communication.  All of your passwords would be sent over plain text.

The recommended way to access RCON remotely from Linux is to forward the RCON
port to your machine over SSH and connecting to the remote host over localhost
on your own machine.  The following SSH command makes RCON available on
localhost.

    ssh -vNL 127.0.0.1:28016:127.0.0.1:28016 user@example.com

If you still want your RCON interface to be publicy available (I don't recommend
this), then you can set the `RUST_RCON_INTERFACE` variable before starting the
server.

```bash
docker compose down
export RUST_RCON_INTERFACE=0.0.0.0
docker compose up -d
```

### Limiting server resources

In the [`docker-compose.yml`](docker-compose.yml) file, there's two settings you
can adjust to limit how much CPU and memory the dedicated server is allowed.  By
default, it is set to dedicated server recommended values for extremly high
populations:

```yaml
cpu_count: 2
mem_limit: 8gb
```

You can adust the resources to your liking.  Generally, I recommend to not set
the server below `2` CPUs and  `2gb` of memory (RAM).  These policies ensure the
server can't use more than these limits.

You can inspect server resource usage with the following command.

    docker stats

If you see heavy resource usage and your server is performing poorly, then you
might need to allocate more resources.  100% CPU usage is fine but if you start
seeing 600% usage, then that's an indicator you need to start increasing the
`cpu_count` limit for Rust.

### Backup and restore from backup

The following command is compatible with cron jobs and running from the root of
the repository.

    ./admin/backup/create-backup.sh

If you run `create-backup.sh` from a cron job, then be sure to reference it by
its full path.

List backups,

    ./admin/backup/list-backups.sh

Will show you what backup files have been created along with their date and time
of creation.  You could then restore a backup of your choice which would
destroy the running server in order to restore it from a backup.

    ./admin/backup/restore-backup.sh ./backups/file.tgz

### Log management

There's a few scripts to help you manage logs and log size on disk in the Rust
server.  The following script will create a backup of all LGSM and server logs.

    ./admin/logs/create-backup.sh

To list known log file backups run the following command.

    ./admin/logs/list-backups.sh

Logs over time can take up a lot of disk storage.  To reclaim disk space and
deleted unused logs, run the following command.

    ./admin/logs/clean.sh

### Easy Anti-Cheat

By default, EAC is disabled for Linux clients.  Enable EAC with the following
shell variable in [`rust-environment.sh`](rust-environment.sh).


```bash
export ENABLE_RUST_EAC=1
```

If EAC is enabled, Linux clients will not be able to connect and your server
will be listed in the in-game server browser.

# Server Mods

[Oxide plugins](https://umod.org/) and custom mods are supported.  I use the
term mods and plugins interchangeably.

Oxide mods are installed and updated automatically on every server start.
However, if you have a custom mod that has a name conflict with an official
Oxide mod, then the custom mod will be used.

### Oxide mods

To automatically install mods, create a new text file:
[`mod-configs/plugins.txt`](mod-configs).  Add what plugins you would like
in your rust server; one plugin per line.

For example, let's say you want the following plugins:

* [Backpacks](https://umod.org/plugins/backpacks)
* [Chest Stacks](https://umod.org/plugins/chest-stacks)

The download links for both of those plugins would be `Backpacks.cs` and
`ChestStacks.cs`.  Your `mod-configs/plugins.txt` would need to have the
following contents.

```bash
# example mod-configs/plugins.txt
# code comments are supported along with blank lines
Backpacks
ChestStacks
```

When the server boots, the mods will be automatically downloaded from uMod.  If
they already exist, then updates will be checked instead.

If you edit `mod-configs/plugins.txt`, then you can reload plugins without
restarting the server.  Run the following command.

    ./admin/get-or-update-oxide-plugins.sh

If you remove a plugin from `mod-configs/plugins.txt`, then it will be
deleted from your server automatically.

You can also remove mods from `mod-configs/plugins.txt` by starting the line
with a `#`.  This allows you to delete the plugin from the server but also keep
it around in case you want to re-enable it later.

### Custom mods

If you're writing your own custom mod, then the file name must end with `.cs`.
For example, `MyCustomMod.cs`.  Place any `.cs` files into the
[`custom-mods/`](custom-mods) directory.  Next time your server


You can edit your mods as much as you want without affecting the mod used by the
server.  You can copy and update to your custom mod to the server using the
following command.

    ./admin/get-or-update-oxide-plugins.sh

If you delete a custom mod from `custom-mods/` folder, then it will be removed
from the server automatically.

### Harmony mods

Add Harmony mods to [`harmony-mods`](harmony-mods) folder.  It will be available
to your Rust maps such as [Observer Island][map-obs-isle].

### Troubleshooting: Mods failing to load

Sometimes, mods will fail to load into Oxide because of differences between
Windows and Linux.   An example is the following error message.

```
FurnaceSplitter was compiled successfully in 2345ms
Unable to find main plugin class: FurnaceSplitter
No previous version to rollback plugin: FurnaceSplitter
```

To fix this error run the following command.

    ./admin/bugfix-oxide-plugins.sh

Then, in the RCON console try reloading the oxide plugin.

    oxide.reload FurnaceSplitter

### Updating mod configuration

Oxide Mods automatically generate plugin config which is accessible by editing
files in the [`mod-configs/`](mod-configs/) directory.  If you edit a JSON
config you can open up the web management RCON console to reload the plugin (See
[RCON: Remote Admin Console](#rcon-remote-admin-console) for how to access RCON
console).

Use console command:

    oxide.reload plugin_name

Or to reload all plugins:

    oxide.reload *

Use the uMod download name of the plugin.  For example, if you download from
uMod `Backpacks.cs`, then you need only add `Backpacks` to
`mod-configs/plugins.txt`.

# Customize Map

You can have a randomly generated map with a seed or a custom map.

### Generated Maps

> Note: Generated Map settings are completely ignored if you've configured a
> Custom Map.

You can uncomment and change the following variables in
[`rust-environment.sh`](rust-environment.sh).

- seed
- salt
- worldsize

If you want to wipe the map and start from another random see, then use
[`./admin/regenerate-map.sh`](./admin/regenerate-map.sh).  You can also
reference this script by its full path from a cron job (it will not wipe
blueprints.

Weekly map wipe (but not BP wipe) cron job:

    @weekly /path/to/admin/regenerate-map.sh skip-prompt

    # or specify time of cron; e.g. every sunday at 1am
    0 1 * * 7 /path/to/admin/regenerate-map.sh skip-prompt


### Custom Maps

Please note:

> _Your map file should be hosted on a public web-site that works 24/7, since
> new players of your server will download the map from that URL, not from your
> Rust server. If your URL link doesn't work then players that haven't
> downloaded the map yet won't be able to join the server._
> - [facepunch Wiki: Hosting a custom map][fp-custom-maps]

There's two ways a custom map is supported.

1. Self-hosted
2. Remotely hosted

##### Self-hosted custom maps

If you're playing multi-player and self hosting your Map, then there's two extra
configuration items you must toggle.

- Port forward port `8000/tcp` to your router.
- Set `MAP_BASE_URL` variable in [`rust-environment.sh`](rust-environment.sh) to
  your public IP where clients can download the map.

Your custom map file name must end with `.map`.  Download your custom map
locally to your computer and place it in the [`custom-maps/`](custom-maps/)
directory.

If you have more than one map, then the first map alphabetically is used.  If
you would like to have multiple custom maps and change the map, then it is
recommended you prefix all maps with a 4 digit number.  For example,

```
0001_custom-map.map
0002_custom-map.map
0003_custom-map.map
... etc
```

If you wish to use a Generated Map, then all files ending with `.map` must be
removed from `custom-maps/` directory.  Just having the custom map file in that
directory is what enables the Custom Map logic.

##### Remotely hosted custom maps

If you're using a public file serving service separate from your game server
(such as Dropbox), then set `CUSTOM_MAP_URL` variable in
[`rust-environment.sh`](rust-environment.sh).  No extra configuration is
required.

##### Observer Island

If you want to play locally for yourself only, then setup is very straight
forward.

```bash
cd custom-maps/
unzip ~/Downloads/observer-island.zip

# the map should be in the current directory
ls
# next move the harmony mods to the appropriate location
mv Mods/* ../harmony-mods/

# clean up remaining files so that only the map remains
rm -r changelog.txt Mods observer-island-* Prefabs/

# go back to the root of this repository and start the dedicated server
cd ..
docker compose up -d
```

After about 5 minutes you should be able to connect to `localhost:28015`.  If
you want to make this map available for multiplayer within your LAN or worldwide
refer to the previous sections for custom map hosting for remote play.

# Road Map

- :heavy_check_mark: Initial working vanilla server
- :heavy_check_mark: Basic admin actions like shell login and RCON access
- :heavy_check_mark: Support for adding server mods and automatic mod updates
- :heavy_check_mark: Limit server resources
- :heavy_check_mark: Support for customizing initial Map generation on first
  time startup.
- :heavy_check_mark: Support for custom server mods (Oxide plugins)
- :heavy_check_mark: Support for custom Maps.
- :heavy_check_mark: Improve documentation

[compose]: https://docs.docker.com/compose/install/
[docker]: https://docs.docker.com/engine/install/
[fp-custom-maps]: https://wiki.facepunch.com/rust/Hosting_a_custom_map
[git]: https://git-scm.com/
[lgsm]: https://linuxgsm.com/
[map-obs-isle]: https://lone.design/product/observer-island/
[rust]: https://rust.facepunch.com/
