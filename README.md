# Dockerized LGSM Rust Dedicated Server

This project combines Docker, Rust Dedicated Server, and LGSM all in one!  The
intention is to lower the barrier of entry for Linux users to get a Rust
dedicated server up quickly with little to  no effort.

# Prerequisites

- Lots of RAM, especially if you're playing on the same machine as the dedicated
  server.  This project was developed with 32GB of RAM.
- You have [Git installed][git] and cloned this repository to work with locally.

  ```
  git clone https://github.com/samrocketman/docker-compose-lgsm-rust-dedicated-server
  ```

- Install [Docker on Linux][docker].  Docker on Windows or Mac would probably
  work but is entirely untested.  Docker for Mac has known performance issues
  unrelated to Rust.

# Server Uptime Management

### Starting the server

    docker-compose up -d

### Graceful shutdown

    docker-compose down

### Uninstallation

To completely uninstall and delete all Rust data run the following command.

    docker-compose down -v --rmi all

Remove this Git repository for final cleanup.

### Server Admin Actions

If you want a shell login to your server, then run the following command from
the root of this repository.

    ./admin-actions/shell-login.sh

If you want to log into the Rust web RCON interface, then run the following
command.

    ./admin-actions/get-rcon-pass.sh

The script will output your RCON password as well as additional instructions for
your web browser to access the RCON console.

# Easy Anti-Cheat

By default EAC is disabled for Linux clients.  If you want Windows-only clients,
then enable EAC with the following shell variable.

```bash
export ENABLE_RUST_EAC=1
```

# Server Mods

This server automatically adds and updates uMod oxide plugins through an easy to
use `plugins.txt` file.  Add what plugins you would like in your rust server;
one plugin per line.

For example, let's say you want the following plugins:

* [Backpacks](https://umod.org/plugins/backpacks)
* [Chest Stacks](https://umod.org/plugins/chest-stacks)

The download links for both of those plugins would be `Backpacks.cs` and
`ChestStacks.cs`.  Your `plugins.txt` would need to have the following contents.

```bash
# example plugins.txt
# code comments are supported along with blank lines
Backpacks
ChestStacks
```

### Updating plugin configuration

Plugins automatically generate plugin config which is accessible by editing
files in the `plugin-configs/` directory.  If you edit a JSON config you can
open up the web management RCON console to reload the plugin (See [Server Admin
Actions](#server-admin-actions) for how to access RCON console).

Use console command:

    oxide.reload plugin_name

Server mods are supported by oxide plugins.  Add your oxide plugins to
`plugins.txt` and then start the server normally.  Every time the server start
plugin updates are checked and downloaded.

If you remove a plugin from `plugins.txt`, then it will be deleted from your
server automatically.

Use the uMode download name of the plugin.  For example, if you download from
uMod `Backpacks.cs`, then you need only add `Backpacks` to `plugins.txt`.

### plugins.txt code comments

Lines that start with `#` and blank lines are automatically skipped in
`plugins.txt`.

You can remove Rust server plugins from `plugins.txt` by starting the line with
a `#`.  This allows you to delete the plugin from the server but also keep it
around in case  you want to re-enable it later.

# Road Map

- :heavy_check_mark: Initial working vanilla server
- :heavy_check_mark: Basic admin actions like shell login and RCON access
- :heavy_check_mark: Support for automatically updating Oxide plugins
- :x: Support for custom Oxide plugins
- :x: Support for customizing initial Map generation.
- :x: Support for custom Maps.

[docker]: https://docs.docker.com/engine/install/
[git]: https://git-scm.com/
