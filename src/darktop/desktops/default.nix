{
  inputs,
  cell,
}: let
  pkgs = inputs.nixpkgs.appendOverlays [inputs.nixgl.overlay];
  config = pkgs.substituteAll {
    name = "sway-config";
    src = ./sway/config;
    background = ./art/bg-basic.png;
    term = "${pkgs.kitty}/bin/kitty";
    termconfig = builtins.path {
      name = "kitty-config";
      path = ./kitty/kitty.conf;
    };
    waybar = builtins.path {
      name = "waybar";
      path = ./sway/waybar-config;
    };
    waybarstyle = builtins.path {
      name = "waybar-style";
      path = ./sway/waybar.css;
    };
    loadlayout = builtins.path {
      path = ./sway/ws-1.py;
      name = "ws-1.py";
    };
    layout = builtins.path {
      path = ./sway/layout.json;
      name = "layout.json";
    };
    btmcpu = builtins.path {
      path = ./bottom/cpu.toml;
      name = "btmcpu";
    };
    btmproc = builtins.path {
      path = ./bottom/proc.toml;
      name = "btmproc";
    };
    bashinit = builtins.path {
      path = ./bash/bashrc;
      name = "bashinit";
    };
  };

  #container = builtins.path { path = ./container.nix; name = "container"; };
  container = pkgs.writeText "container" ''
    {
      containers.demo = {
        privateNetwork = true;
        hostAddress = "10.250.0.1";
        localAddress = "10.250.0.2";

        config = { pkgs, ... }: {
          systemd.services.hello = {
            wantedBy = [ "multi-user.target" ];
            script = "
              while true; do
                echo hello | ${pkgs.netcat}/bin/nc -lN 50
              done
            ";
          };
          services.tor = {
            enable = true;
            client = {
              enable = true;
            };
          };
          networking.firewall.allowedTCPPorts = [ 50 9050 ];
        };
      };
    }
  '';

  python-with-i3ipc = python-packages:
    with python-packages; [
      i3ipc
    ];
  python-pkgs = pkgs.python38.withPackages python-with-i3ipc;

  # Let these pkgs be available in darktop's PATH
  includedPackages = let
    pkgsList = with pkgs;
      map (x: "--prefix PATH : ${x}/bin ")
      [
        nixgl.nixGLIntel
        #inputs.nixgl.nixVulkanIntel
        #extraContainer
        bottom
        neofetch
        cage
        sway
        waybar
        i3status
        zsh
        ranger
        #pcmanfm
        mpv
        autotiling
        #vlc
        #python-pkgs
      ];
  in
    toString pkgsList;
in {
  #inherit (inputs.nixpkgs) hello;
  default = pkgs.symlinkJoin {
    name = "darktop";
    paths = with pkgs; [
      /*
      extraContainer
      */
      sway
      nixgl.nixGLIntel
      #nixGL.nixVulkanIntel
    ];
    buildInputs = with pkgs; [makeWrapper nixos-container];
    # removing extra-container from the command below, for now
    #--run "$out/bin/extra-container create --nixpkgs-path ${nixpkgs} --start ${container}" \
    postBuild = ''

      mv $out/bin/nixGLIntel $out/bin/darktop
      wrapProgram $out/bin/sway \
      --add-flags "--config ${config}" \
      ${includedPackages}


      wrapProgram $out/bin/darktop \
       --add-flags "$out/bin/sway"
      (cd $out && ${pkgs.zip}/bin/zip -r $out/darktop.zip etc/ bin/)
    '';
    #     --run "${python-pkgs}/bin/python ${layout}"
  };
}
