# Dockerized LGSM Rust Dedicated Server

This project combines Docker, Rust Dedicated Server, and LGSM all in one!  The
intention is to lower the barrier of entry for Linux users to get a Rust
dedicated server up quickly with little to  no effort.

# Prerequisites

- Lots of RAM, especially if you're playing on the same machine as the dedicated
  server.  This project was developed with 32GB of RAM.
- Install [Docker on Linux][docker].  Docker on Windows or Mac would probably
  work but is entirely untested.  Docker for Mac has known performance issues
  unrelated to Rust.

# Easy Anti-Cheat

By default EAC is disabled for Linux clients.  If you want Windows-only clients,
then enable EAC with the following shell variable.

```bash
export ENABLE_RUST_EAC=1
```

# Road Map

- [x] Initial working vanilla server
- [X] Basic admin actions like shell login and RCON access
- [ ] Support for automatically updating Oxide plugins
- [ ] Support for custom Oxide plugins
- [ ] Support for customizing initial Map generation.
- [ ] Support for custom Maps.

[docker]: https://docs.docker.com/engine/install/
