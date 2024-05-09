let
  pkgs = import (builtins.fetchTarball {
    # https://hydra.nixos.org/eval/1804905
    name = "nixos-23.11-1804905";
    url =
      "https://github.com/nixos/nixpkgs/tarball/bb183e5637b6d48804a3ee0fc5ab38df51122d65";
    sha256 = "14zjy9h6z9a7pc9v08zddshm4xh5j3vw321n5d3d4fal8k9as9hm";
  }) { system = "x86_64-linux"; };

  pufferfish = pkgs.stdenv.mkDerivation {
    name = "pufferfish";
    src = pkgs.fetchurl {
      url =
        "https://ci.pufferfish.host/job/Pufferfish-1.20/49/artifact/build/libs/pufferfish-paperclip-1.20.4-R0.1-SNAPSHOT-reobf.jar";
      hash = "sha256-gw9QbqvfbsH/fxMtyKCxNUXAEu6tJEo+NFD4jVMRAP8=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/app
      cp $src $out/app/server.jar
    '';
  };

  jdk = pkgs.jdk21_headless;
  java_modules = [
    "java.base"
    "jdk.crypto.ec"
    "jdk.zipfs"
    "java.management"
    "java.logging"
    "java.xml"
    "java.desktop" # java.beans (only for gui but still required)
    "jdk.security.auth"
    "java.sql"
  ];
  minimal_java = (pkgs.jre_minimal.override { jdk = jdk; }).overrideAttrs
    (finalAttrs: previousAttrs: {
      buildPhase = ''
        runHook preBuild
        jlink --module-path ${jdk}/lib/openjdk/jmods --add-modules ${
          pkgs.lib.concatStringsSep "," java_modules
        } --no-header-files --no-man-pages --output $out
        runHook postBuild
      '';
    });

in {
  bash = pkgs.dockerTools.buildImage {
    name = "pufferfish-1.20.4";
    tag = "1.0.0";
    config = {
      Cmd = [
        "sh" "-c"
        ''
        if [ ! -z $CPULIMIT ]; then
          {
            # give some seconds of full cpu usage
            coproc read -t 8 && wait "$!" || true &&
            exec cpulimit -l $CPULIMIT -p "$(exec < server_pid; read pid; echo "$pid")"
          } &
        fi
        exec tini -g -- sh -c 'echo $$ > server_pid; exec java $JAVAOPTS -jar /app/server.jar --nogui'
        ''
      ];
      WorkingDir = "/data"; # user must mount their data folder
      ExposedPorts = { "25565" = { }; };
    };

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      paths = [
        pkgs.dockerTools.binSh
        pkgs.dockerTools.usrBinEnv
        pkgs.libudev-zero

        pkgs.limitcpu # don't confuse with cpulimit
        pkgs.tini
        minimal_java
        pufferfish
      ];
    };
  };
}
