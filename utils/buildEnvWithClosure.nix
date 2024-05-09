# Writes all path nix store dependencies (nix closure) to the env.

{ pkgs, paths, onlyLinks ? true, ... }@args:
let
  closure = pkgs.writeClosure paths;

  linkClosure = pkgs.runCommand "linkClosure" { } ''
    mkdir -p $out/nix

    # remove preffix
    sed 's|^/nix/store/||' "${closure}" > references

    # link each derivation
    while IFS= read -r file; do
      ${if !onlyLinks then ''#'' else ''''} ln -s "/nix/store/$file" "$out/nix/$file"
      ${if onlyLinks then ''#'' else ''''} ${pkgs.rsync}/bin/rsync -aK --chown=0:0 "/nix/store/$file" "$out/nix"
      

    done < references
  '';

  finalPaths = paths ++ [ linkClosure ];
  buildEnvArgs = removeAttrs args [ "pkgs" "onlyLinks" ];

  # TODO: ensure /nix is always linked

in
  # pass args overriding 'paths' using // operator
  pkgs.buildEnv (buildEnvArgs // { paths = finalPaths; })
