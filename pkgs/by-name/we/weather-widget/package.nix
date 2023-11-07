{ lib
, stdenvNoCC
, fetchFromGitHub
, gettext
, makeWrapper
, libsForQt5
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "weather-widget";
  version = "unstable-2023-09-19";

  # Pulling unstable build for now since Sunrise 2.0 is deprecated:
  # https://github.com/blackadderkate/weather-widget-2/pull/151
  src = fetchFromGitHub {
    owner = "blackadderkate";
    repo = "weather-widget-2";
    rev = "a0628b252c8b8e8737811e89a7213ad8a54cead9";
    hash = "sha256-2quUU08vDMNryaB4PM0I/fe/BXe5bO8x0TKMVf/qxGU=";
  };

  nativeBuildInputs = [
    gettext
    makeWrapper
    libsForQt5.kconfig
  ];

  dontWrapQtApps = true;

  installerDeps = with libsForQt5; [
    kde-cli-tools
    kconfig
    kpackage
  ];

  uninstallerDeps = with libsForQt5; [ kpackage ];

  buildPhase = ''
    runHook preBuild

    sh translations/po/build.sh

    echo ${ lib.strings.escapeShellArg ( builtins.readFile ./install-weather-widget ) } > install-weather-widget
    substituteInPlace install-weather-widget \
      --replace PACKAGE_DIR $out/share/weather-widget \
      --replace VERSION ${finalAttrs.version}
    chmod +x install-weather-widget

    echo ${ lib.strings.escapeShellArg ( builtins.readFile ./uninstall-weather-widget ) } > uninstall-weather-widget
    substituteInPlace uninstall-weather-widget --replace PACKAGE_DIR $out/share/weather-widget
    chmod +x uninstall-weather-widget

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share
    cp -r package $out/share/weather-widget
    mkdir $out/bin
    cp install-weather-widget uninstall-weather-widget $out/bin
    wrapProgram $out/bin/install-weather-widget --prefix PATH : ${ lib.makeBinPath finalAttrs.installerDeps }
    wrapProgram $out/bin/uninstall-weather-widget --prefix PATH : ${ lib.makeBinPath finalAttrs.uninstallerDeps }

    runHook postInstall
  '';

  meta = with lib; {
    description = "Plasmoid for displaying the weather";
    homepage = "https://github.com/blackadderkate/weather-widget-2";
    sourceProvenance = with sourceTypes; [ fromSource ];
    license = licenses.gpl2;
    maintainers = with maintainers; [ prominentretail ];
    platforms = platforms.linux;
    mainProgram = "install-weather-widget";
  };
})
