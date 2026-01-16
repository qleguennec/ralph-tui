{
  description = "Ralph TUI - AI Agent Loop Orchestrator";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Package version from package.json
        version = "0.1.7";
        
        # Pre-fetch node_modules using a Fixed-Output Derivation (allows network)
        # To update hash: nix build .#ralph-tui 2>&1 | grep "got:" and copy the hash
        node_modules = pkgs.stdenvNoCC.mkDerivation {
          pname = "ralph-tui-node_modules";
          inherit version;
          
          src = ./.;
          
          nativeBuildInputs = with pkgs; [
            bun
            cacert
          ];
          
          impureEnvVars = pkgs.lib.fetchers.proxyImpureEnvVars ++ [
            "GIT_PROXY_COMMAND"
            "SOCKS_SERVER"
          ];
          
          buildPhase = ''
            export HOME=$(mktemp -d)
            export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
            bun install --frozen-lockfile --no-progress
          '';
          
          installPhase = ''
            mkdir -p $out
            cp -r node_modules $out/
          '';
          
          dontFixup = true;
          outputHashAlgo = "sha256";
          outputHashMode = "recursive";
          outputHash = "sha256-8RAilfP63HFxn+0ELzynzvFqg3V8wKuOg4l45C3JX7Y=";
        };
        
        # Build the project
        ralph-tui = pkgs.stdenv.mkDerivation {
          pname = "ralph-tui";
          inherit version;

          src = ./.;

          nativeBuildInputs = with pkgs; [
            bun
            nodejs
          ];

          buildPhase = ''
            export HOME=$TMPDIR
            
            # Copy pre-fetched dependencies
            cp -r ${node_modules}/node_modules .
            chmod -R u+w node_modules
            
            # Build the project using bun
            bun build ./src/cli.tsx --outdir ./dist --target bun --sourcemap=external
            bun build ./src/index.ts --outdir ./dist --target bun --sourcemap=external
            
            # Copy assets
            cp -r assets dist/
            
            # Generate TypeScript declarations using tsc directly via bun
            # Use || true to continue if types generation fails (not critical for runtime)
            bun x tsc --emitDeclarationOnly --declaration --outDir dist || true
          '';

          installPhase = ''
            mkdir -p $out/lib/ralph-tui
            mkdir -p $out/bin
            
            # Copy dist files
            cp -r dist $out/lib/ralph-tui/
            
            # Copy node_modules (needed for runtime dependencies)
            cp -r node_modules $out/lib/ralph-tui/
            
            # Copy skills directory
            cp -r skills $out/lib/ralph-tui/
            
            # Copy package.json for metadata
            cp package.json $out/lib/ralph-tui/
            
            # Create wrapper script for the CLI
            cat > $out/bin/ralph-tui <<EOF
            #!${pkgs.bash}/bin/bash
            exec ${pkgs.bun}/bin/bun $out/lib/ralph-tui/dist/cli.js "\$@"
            EOF
            chmod +x $out/bin/ralph-tui
          '';

          meta = with pkgs.lib; {
            description = "AI Agent Loop Orchestrator - A terminal UI for orchestrating AI coding agents";
            homepage = "https://github.com/subsy/ralph-tui";
            license = licenses.mit;
            maintainers = [ ];
            mainProgram = "ralph-tui";
          };
        };

      in
      {
        # Packages
        packages = {
          default = ralph-tui;
          ralph-tui = ralph-tui;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
            nodejs
            git
            jujutsu  # Since the project uses jj for version control
          ];

          shellHook = ''
            echo "Ralph TUI development environment"
            echo "Bun version: $(bun --version)"
            echo ""
            echo "Available commands:"
            echo "  bun install      - Install dependencies"
            echo "  bun run build    - Build the project"
            echo "  bun run dev      - Run in development mode"
            echo "  bun run typecheck - Type check"
            echo "  bun run lint     - Run linter"
            echo "  bun test         - Run tests"
            echo ""
            echo "To build with Nix:"
            echo "  nix build        - Build the package"
            echo "  nix run          - Run ralph-tui"
          '';
        };

        # Apps
        apps.default = {
          type = "app";
          program = "${ralph-tui}/bin/ralph-tui";
        };
      }
    );
}
