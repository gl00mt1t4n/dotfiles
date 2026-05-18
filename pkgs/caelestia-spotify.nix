{
  lib,
  stdenvNoCC,
  spotify,
  spicetify-cli,
  theme,
}:

stdenvNoCC.mkDerivation {
  pname = "spotify-caelestia";
  inherit (spotify) version;

  dontUnpack = true;
  nativeBuildInputs = [ spicetify-cli ];

  installPhase = ''
    runHook preInstall

    cp -R ${spotify} $out
    chmod -R u+w $out

    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_STATE_HOME="$TMPDIR/state"

    mkdir -p \
      "$XDG_CONFIG_HOME/spicetify/Themes/caelestia" \
      "$XDG_CONFIG_HOME/spotify" \
      "$XDG_STATE_HOME/spicetify"

    touch "$XDG_CONFIG_HOME/spotify/prefs"
    cp -R ${theme}/* "$XDG_CONFIG_HOME/spicetify/Themes/caelestia/"

    spicetify -q config \
      spotify_path "$out/share/spotify" \
      prefs_path "$XDG_CONFIG_HOME/spotify/prefs" \
      current_theme caelestia \
      color_scheme caelestia \
      check_spicetify_update 0

    spicetify -q backup apply -n

    chmod -R a-w $out

    runHook postInstall
  '';

  meta = spotify.meta // {
    description = "Spotify with the vendored Caelestia Spicetify theme applied";
    mainProgram = "spotify";
    license = spotify.meta.license or lib.licenses.unfree;
  };
}
