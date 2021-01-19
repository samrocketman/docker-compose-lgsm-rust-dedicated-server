# Dockerized LGSM Rust Dedicated Server

This project combines Docker, Rust Dedicated Server, and LGSM all in one!  The
intention is to lower the barrier of entry for Linux users to get a Rust
dedicated server up quickly with little to  no effort.

# Play on your server

By default your server is forwarding port `28015/UDP` to all interfaces so that
you can use router port forwarding to play multiplayer.

If you're playing on the same machine from Proton on Linux, then press F1 to
open console and connect with:

    client.connect 127.0.0.1:28015

You may need to enter a domain name or alternate IP address if you're playing
Rust from a different computer.

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
- Install [docker-compose][compose].  This typically comes separate from Docker.

# Getting started

If you don't want to customize anything, then start the server.  It will
generate a 3K map using a random seed which will persist when restarting the
server.

    docker-compose up -d

It may take 15 minutes or longer for the server to start the first time
depending on your internet connection.  This is because it has to download Rust
among other server setup tasks.  You can monitor the server logs at any time (to
see progress) with the following command.

    docker-compose logs -f

Press `CTRL+C` to exit logs.

# Server power management

### Starting the server

    docker-compose up -d

It may take at 5 minutes or longer to start depending on your internet
connection.

See logs with the following command (`CTRL+C` to cancel).

    docker-compose logs -f

### Graceful shutdown

    docker-compose down

### Uninstallation

To completely uninstall and delete all Rust data run the following command.

    docker-compose down -v --rmi all

Remove this Git repository for final cleanup.

# Game Server Administration

### Login shell

If you want a shell login to your server, then run the following command from
the root of this repository.

    ./admin/shell.sh

    # alternately if you need root shell access
    ./admin/shell.sh root

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

By default, the RCON interface is only accessible from `localhost`.  However, if
you require remote access, then you can set the `RUST_RCON_INTERFACE` variable
before starting the server.

```bash
docker-compose down
export RUST_RCON_INTERFACE=0.0.0.0
docker-compose up -d
```

### Limiting server resources

In the `docker-compose.yml` file, there's two settings you can adjust to limit
how much CPU and memory the dedicated server is allowed.  By default, it is set
to dedicated server recommended values for extremly high populations:

```yaml
cpu_count: 2
mem_limit: 8gb
```

You can adust the resources to your liking.  Generally, I recommend to not set
the server below `2` CPUs and  `2gb` of memory (RAM).  These policies ensure the
server can't use more than these limits.

### Easy Anti-Cheat

By default, EAC is disabled for Linux clients.  Enable EAC with the following
shell variable in [`rust-environment.sh`](rust-environment.sh).


```bash
export ENABLE_RUST_EAC=1
```

If EAC is enabled, Linux clients will not be able to connect and your server
will be listed in the in-game server browser.

# Server Mods

[Oxide mods](https://umod.org/) and custom mods are supported.

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

### Updating mod configuration

Plugins automatically generate plugin config which is accessible by editing
files in the [`mod-configs/`](mod-configs/) directory.  If you edit a JSON
config you can open up the web management RCON console to reload the plugin (See
[Server Admin Actions](#server-admin-actions) for how to access RCON console).

Use console command:

    oxide.reload plugin_name

Or to reload all plugins:

    oxide.reload *

Server mods are supported by oxide plugins.  Add your oxide plugins to
`mod-configs/plugins.txt` and then start the server normally.  Every time the
server start plugin updates are checked and downloaded.

If you remove a plugin from `mod-configs/plugins.txt`, then it will be
deleted from your server automatically.

Use the uMode download name of the plugin.  For example, if you download from
uMod `Backpacks.cs`, then you need only add `Backpacks` to
`mod-configs/plugins.txt`.

### plugins.txt code comments

Lines that start with `#` and blank lines are automatically skipped in
`mod-configs/plugins.txt`.

You can remove Rust server plugins from `mod-configs/plugins.txt` by starting
the line with a `#`.  This allows you to delete the plugin from the server but
also keep it around in case  you want to re-enable it later.

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

### Custom Maps

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

# Road Map

- :heavy_check_mark: Initial working vanilla server
- :heavy_check_mark: Basic admin actions like shell login and RCON access
- :heavy_check_mark: Support for adding server mods and automatic mod updates
- :heavy_check_mark: Limit server resources
- :heavy_check_mark: Support for customizing initial Map generation on first
  time startup.
- :heavy_check_mark: Support for custom server mods (Oxide plugins)
- :heavy_check_mark: Support for custom Maps.
- :x: Improve documentation

[compose]: https://docs.docker.com/compose/install/
[docker]: https://docs.docker.com/engine/install/
[git]: https://git-scm.com/
