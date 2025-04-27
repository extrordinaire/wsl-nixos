{
  description = "NixOS WSL config with flakes";

  inputs = {
    ndsadwixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-wsl,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      # authorizedSshKeys =  let
      #   rawKeys = builtins.readFile ./.authorized_ssh_keys;
      # in builtins.filter (key: key != "") (builtins.lines rawKeys);
      # propietarySshKeys = let
      #   rawKeys = builtins.readFile ./.propietary_ssh_keys;
      # in
      fhsEnv =
        let
          wslinterop = builtins.getEnv "WSL_INTEROP";
        in
        pkgs.buildFHSEnv {
          name = "fhs-shell";
          # unsharePid = false;  # Inherit the host's /proc instead of creating a new one.
          targetPkgs =
            pkgs: with pkgs; [
              tmux
              neovim
              git
              curl
              fnm
              python3
              gcc
              pkg-config
              rustc
              cargo
              unzip
	      ripgrep
	      verilator
            ];
          profile = ''
            export EDITOR=nvim
            export PATH=$PATH:$HOME/.local/bin
          '';
          runScript = "bash -c '\
# if [ ! -f /tmp/.init_fixed ]; then \
    rm -f /init && ln -s /tools/init /init; \
# fi; \
if [ -n \"$NVIM_SHORTCUT_PATH\" ]; then \
    sess_name=fhs-temp-$(date +%s);  \
    exec tmux new-session -s $sess_name \"nvim $NVIM_SHORTCUT_PATH; tmux kill-server\"; \
else \
    exec tmux new-session -s fhs-session \"exec zsh; tmux kill-server\"; \
fi'";
          bindMounts = [ "/etc/nixos" ];
          extraBwrapArgs = [
            "--dir"
            "/tools" # Create /tools directory.
            "--ro-bind"
            "/init"
            "/tools/init" # Expose the host’s /init as /tools/init.
            "--dir"
            "/binfmt_misc" # Create a dedicated directory.
            # "--ro-bind" "/proc/sys/fs/binfmt_misc" "/binfmt_misc" # Bind host's binfmt_misc to /binfmt_misc.
            # "--symlink" "/binfmt_misc" "/proc/sys/fs/binfmt_misc" # Symlink it to where the kernel expects.
            "--setenv"
            "WSL_INTEROP"
            wslinterop # Pass through WSL_INTEROP.
            "--" # End of options; the command will follow.
          ];
        };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nixos-wsl.nixosModules.default
          home-manager.nixosModules.home-manager

          {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            services.openssh = {
              enable = true;
            };

            # WSL support
            wsl.enable = true;

            # Your username here
            users.users.maximo = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              shell = pkgs.zsh;
              # openssh.authorizedKeys.keys = sshKeys;
            };

            wsl.defaultUser = "maximo";

            programs.zsh.enable = true;
            environment.shells = with pkgs; [ zsh ];

            # Enable and configure Git
            programs.git = {
              enable = true;
            };

            # Define global shell aliases
            environment.shellAliases = {
              wpaste = "win32yank.exe -o --lf";
	      wcopy = "win32yank.exe -i --crlf";
              # Add more aliases as needed
            };

            environment.systemPackages = with pkgs; [
              nixfmt-rfc-style
              gcc # The GNU Compiler Collection
              gnumake # GNU Make (often just “make”)
              binutils # A collection of binary tools
              cmake # For C/C++ projects
              git # Version control (if needed)
              gdb # The GNU Debugger
              pnpm
              fnm
              temurin-bin-23
              rustup
	      verilator
            ];

            # Home Manager user config
            home-manager.users.maximo = {

              home = {
                packages = [ fhsEnv ];
              };

              programs.zsh = {
                enable = true;
                oh-my-zsh = {
                  enable = true;
                  plugins = [
                    "git"
                    "z"
                  ];
                  theme = "";
                };

                enableCompletion = true;
                autosuggestion.enable = true;
                syntaxHighlighting.enable = true;
                history.size = 10000;

                # Define global shell aliases
                shellAliases = {
                  ps_paste = "powershell.exe -c Get-Clipboard";
                  # Add more aliases as needed
                };

                initExtra = ''
                  eval "$(fnm env --use-on-cd --shell zsh)";
                  export COLORTERM=truecolor;

                  export XDG_CONFIG_HOME="$HOME/.config"
                  export XDG_DATA_HOME="$HOME/.local/share"
                  export XDG_CACHE_HOME="$HOME/.cache"
                '';
              };

              programs.oh-my-posh = {
                enable = true;
                enableZshIntegration = true;
                settings = builtins.fromJSON (
                  builtins.unsafeDiscardStringContext (builtins.readFile ./catppuccin_theme.json)
                );
              };

              # Enable and configure Git
              programs.git = {
                enable = true;
                userName = "extrordinaire"; # Replace with your actual name
                userEmail = "maximoverzini@gmail.com"; # Replace with your actual email
                extraConfig = {
                  core.autocrlf = false;
                };
              };

              programs.neovim = {
                enable = true;
                defaultEditor = true;
              };

              programs.tmux = {
                enable = true;
                clock24 = true;
                mouse = true;
                baseIndex = 1;
                keyMode = "vi";
                # sensibleOnTop = true;
                prefix = "C-Space";
                extraConfig = ''
# Enable OSC-8 hyperlinks for all terminal types (or use a pattern like xterm* if preferred)
set -as terminal-features "xterm*:hyperlinks"
set -g allow-passthrough on
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",*256col*:Tc"
set -ga terminal-overrides ',*256col*:XT'
set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
set-environment -g COLORTERM "truecolor"

bind -n M-H previous-window
bind -n M-L next-window

# For a horizontal split (new pane below)
unbind '"'
bind '"' split-window -v -c "#{pane_current_path}"

# For a vertical split (new pane to the right)
unbind %
bind % split-window -h -c "#{pane_current_path}"

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'christoomey/vim-tmux-navigator'
#set -g @plugin 'dreamsofcode-io/catppuccin-tmux'
#set -g @plugin 'catppuccin/tmux#latest'

# Make the status line pretty and add some modules
run '~/.tmux/plugins/tpm/tpm'
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
set -g status-right-length 100
set -g status-left-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_application}"
set -ag status-right "#{E:@catppuccin_status_session}"
set -ag status-right "#{E:@catppuccin_status_uptime}"
# Or, if using TPM, just run TPM
'';
              };

              home.stateVersion = "24.05";
            };

            system.stateVersion = "24.05";
          }
        ];
      };
    };
}
