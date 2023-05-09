{
  description = "A simple tool to run nix flake checks";
  inputs.utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" "aarch64-linux" ] (system:
      let pkgs = import nixpkgs { inherit system; };
      in
      with pkgs;
      rec {
        packages.default =
          let runtimeInputs = [ python3 jq ];
          in runCommand "nix-check"
            {
              buildInputs = [ makeWrapper ];
            }
            ''
              mkdir -p $out/bin
              cp ${self}/nix-check $out/nix-check-inner
              makeWrapper $out/nix-check-inner $out/bin/nix-check \
                --prefix PATH : ${lib.makeBinPath runtimeInputs}
              substituteInPlace $out/nix-check-inner \
                --replace !/usr/bin/env !${pkgs.coreutils}/bin/env
            '';
        apps.default = {
          type = "app";
          program = "${packages.default}/bin/nix-check";
        };
        checks.default = runCommand "print help" { }
          ''
            touch $out
            ${packages.default}/bin/nix-check --help
          '';
      });
}
