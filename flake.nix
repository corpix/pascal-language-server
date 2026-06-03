{
  description = "Development shell and package for Pascal Language Server";

  inputs = {
    nixpkgs.url = "tarball+https://git.tatikoma.dev/corpix/nixpkgs/archive/corpix.tar.gz";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      mkPascalLanguageServer =
        pkgs:
        let
          lazarusDir = "${pkgs.lazarus}/share/lazarus";
          fpcBin = "${pkgs.fpc}/bin/fpc";
        in
        pkgs.stdenv.mkDerivation {
          pname = "pascal-language-server";
          version = "unstable";

          src = self;

          nativeBuildInputs = with pkgs; [
            bash
            fpc
            lazarus
            pkg-config
          ];

          buildInputs = with pkgs; [
            sqlite
          ];

          env = {
            FPC = fpcBin;
            LAZARUSDIR = lazarusDir;
          };

          buildPhase = ''
            runHook preBuild

            ${pkgs.bash}/bin/bash src/build_fpc.sh

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            mkdir -p "$out/bin"
            install -m755 dist/*/pasls "$out/bin/pasls"

            runHook postInstall
          '';

          meta = {
            homepage = "https://github.com/genericptr/pascal-language-server";
            description = "Language Server Protocol implementation for Pascal";
            license = pkgs.lib.licenses.gpl3Only;
            mainProgram = "pasls";
            platforms = pkgs.lib.platforms.linux;
          };
        };
    in
    {
      overlays.default = final: prev: {
        pascal-language-server = mkPascalLanguageServer final;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        lazarusDir = "${pkgs.lazarus}/share/lazarus";
        fpcBin = "${pkgs.fpc}/bin/fpc";
      in
      {
        packages.default = mkPascalLanguageServer pkgs;
        packages.pascal-language-server = mkPascalLanguageServer pkgs;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            fpc
            just
            lazarus
            pkg-config
            sqlite
          ];

          shellHook = ''
            export PASLS_LAZARUS_PCP="$PWD/.lazarus"
            mkdir -p "$PASLS_LAZARUS_PCP"

            export FPC="${fpcBin}"
            export PP="${fpcBin}"
            export FPCDIR="${pkgs.lazarus}/share/fpcsrc"
            export LAZARUSDIR="${lazarusDir}"
            export LAZARUS_DIR="${lazarusDir}"
            export FPCTARGET="${pkgs.stdenv.hostPlatform.parsed.kernel.name}"
            export FPCTARGETCPU="${pkgs.stdenv.hostPlatform.parsed.cpu.name}"

            echo "Pascal Language Server dev shell"
            echo "  lazarus pcp:     $PASLS_LAZARUS_PCP"
            echo "  build:           just build"
            echo "  test:            just test"
            echo "  clean:           just clean"
          '';
        };
      }
    );
}
