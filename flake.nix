{

  outputs = { self }: let

    internalOverlay = final: prev: with final.lib; {

      getHaskellPackages = pattern: pipe final.haskell.packages [
        attrNames
        (filter (x: !isNull (strings.match pattern x)))
        (sort (x: y: x>y))
        (map (x: final.haskell.packages.${x}))
        head
      ];

      run-ghcid = final.callPackage ./runGhcid.nix {};

      mkHaskellShell = inputsFrom: libraryName: final.mkShell {
        inherit inputsFrom;
        packages = [
          final.cabal-install
          final.entr
          final.ghcid
          final.haskell-language-server
          final.hlint
          (final.run-ghcid.override { inherit libraryName; })
          (final.run-ghcid.override { inherit libraryName; warnings = true; })
        ];
      };

    };

  in {

    lib = rec {

      withPkgsFor = systems: nixpkgs: extraOverlays: fn: with nixpkgs.lib; let
        overlays = extraOverlays ++ [ internalOverlay ];
      in genAttrs systems (system: fn (import nixpkgs { inherit system overlays; }));

      withPkgsForLinux = nixpkgs: withPkgsFor nixpkgs.lib.platforms.linux nixpkgs;
      withPkgsForUnix = nixpkgs: withPkgsFor nixpkgs.lib.platforms.unix nixpkgs;
      withPkgsForAll = nixpkgs: withPkgsFor nixpkgs.lib.platforms.all nixpkgs;

      haskellSimpleOverlay = fn: final: prev: {
        haskell = prev.haskell // {
          packageOverrides = hfinal: hprev: prev.haskell.packageOverrides hfinal hprev // (fn hfinal);
        };
      };

    };

  };

}
