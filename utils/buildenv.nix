#{ pkgs ? import <nixpkgs> {} }:
let

  pkgs = import
    (builtins.fetchTarball {
      # https://hydra.nixos.org/eval/1806129
      # WARNING: Not stable rev. Required because it has writeClosure
      name = "nixos-1806129";
      url = "https://github.com/nixos/nixpkgs/tarball/860e65d27036476edfb85dd847d982277880b143";
      sha256 = "0bk5kkzjir3a094z21asl9z7yb10ym1fwgq73crz8nl69dmngnad";
    })
    { system = "x86_64-linux"; };

  buildEnvWithClosure = import ./buildEnvWithClosure.nix;

  pufferfish = pkgs.stdenv.mkDerivation {
      name = "pufferfish";
      src = pkgs.fetchurl {
          url = "https://ci.pufferfish.host/job/Pufferfish-1.20/49/artifact/build/libs/pufferfish-paperclip-1.20.4-R0.1-SNAPSHOT-reobf.jar";
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
  minimal_java = (pkgs.jre_minimal.override { jdk = jdk; }).overrideAttrs (finalAttrs: previousAttrs: {
    pname = previousAttrs.pname + "-bar";
    buildPhase = ''
      runHook preBuild
      jlink --module-path ${jdk}/lib/openjdk/jmods --add-modules ${pkgs.lib.concatStringsSep "," java_modules} --no-header-files --no-man-pages --output $out
      runHook postBuild
      '';
  });

  #javarun = pkgs.runCommand "javarun" { } ''
    #javaBin=".java-wrapped"
    #mkdir -p $out/bin
    #cp ${pkgs.temurin-jre-bin-21}/bin/$javaBin $out/bin/$javaBin
    ##cp ${pkgs.temurin-jre-bin-21}/bin/fio $out/bin/fio
  #'';

in

buildEnvWithClosure {
  pkgs = pkgs;
  onlyLinks = false;
  name = "my-env";
  paths = [
      minimal_java
      #pufferfish

      #pkgs.coreutils
      #pkgs.dockerTools.binSh
      #pkgs.lf
      #pkgs.dockerTools.usrBinEnv
      #pkgs.dockerTools.caCertificates
  ];
  pathsToLink = [ "/bin" "/app" "/nix" "/lib" ];
  #extraOutputsToInstall = [ "lib" ];
  #ignoreCollisions = true;
}

#pkgs.mkShell {
  #name = "dev-environment";
  #buildInputs = with pkgs; [
    #minimal_java
  #];
#}


