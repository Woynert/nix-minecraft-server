
A reproducible minecraft server targeting VPS machines.

- Compressed image is 102 MiB.
- Stripped JRE with [jlink](https://docs.oracle.com/en/java/javase/11/tools/jlink.html).
- With [Pufferfish](https://github.com/pufferfish-gg/Pufferfish) server for Minecraft 1.20.4. Also provides [optimized settings](https://github.com/YouHaveTrouble/minecraft-optimization).
- Requires docker 20.10.10 or newer. [Relevant thread](https://github.com/SeleniumHQ/docker-selenium/issues/2014).

Usage:

- `$CPULIMIT`: Set CPU usage cap. Uses [limitcpu](https://limitcpu.sourceforge.net/).
- `$JAVAOPTS`: Set extra JVM options.
- Mount your server data folder at `/data`.

Build docker image:
```
nix-build docker-server.nix
```

Build, load, run:
```
docker load < $(nix-build docker-server.nix)
docker run -v ./data:/data -e "CPULIMIT=200" -p 25565:25565 pufferfish-1.20.4:1.0.0
```
