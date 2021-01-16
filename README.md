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

# Server Management

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

# Easy Anti-Cheat

By default EAC is disabled for Linux clients.  If you want Windows-only clients,
then enable EAC with the following shell variable.

```bash
export ENABLE_RUST_EAC=1
```

# Road Map

- :heavy_check_mark: Initial working vanilla server
- :heavy_check_mark: Basic admin actions like shell login and RCON access
- :x: Support for automatically updating Oxide plugins
- :x: Support for custom Oxide plugins
- :x: Support for customizing initial Map generation.
- :x: Support for custom Maps.

[docker]: https://docs.docker.com/engine/install/
[git]: https://git-scm.com/
