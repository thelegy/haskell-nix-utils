{ writeScriptBin
, lib
, zsh

, libraryName ? ""
, warnings ? false
}: with lib;

writeScriptBin "run-ghcid${optionalString warnings "-warnings"}" ''
  #!${zsh}/bin/zsh

  print -P %F{yellow}Cleaning repository%f
  nix develop -c cabal clean

  (git ls-files test; git ls-files '*.cabal'; git ls-files 'flake.*') | \
    entr -r \
      nix develop -c \
        ghcid \
          ${optionalString (!warnings) "--warnings"} \
          "--command=cabal repl lib:${libraryName}" \
          "--test=:! \
            cabal test --disable-optimisation --enable-debug-info=2 --test-show-details=direct --ghc-option -fdiagnostics-color=always && \
            cabal build --disable-optimisation --enable-debug-info=2 --ghc-option -fdiagnostics-color=always && \
            zsh -c 'print -P %F{green}Build and tests passed%f' \
          "
''
