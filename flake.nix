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
      authorizedSshKeys =  let
         rawKeys = builtins.readFile ./.authorized_ssh_keys;
      in builtins.filter (key: key != "") (builtins.lines rawKeys);
      propietarySshKeys = let
         rawKeys = builtins.readFile ./.propietary_ssh_keys;
      in 
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
              ps_paste = "powershell.exe -c Get-Clipboard";
              # Add more aliases as needed
            };

            environment.systemPackages = with pkgs; 
	    [ 
	    	nixfmt-rfc-style
		gcc              # The GNU Compiler Collection
                gnumake          # GNU Make (often just “make”)
	        binutils         # A collection of binary tools
	        cmake            # For C/C++ projects
	        git              # Version control (if needed)
	        gdb              # The GNU Debugger
		pnpm             #
		fnm              #
		temurin-bin-23   #
		rustup           #
	    ];

            # Home Manager user config
            home-manager.users.maximo = {

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
                  eval "$(fnm env --use-on-cd --shell zsh)"
		'';
              };

              programs.oh-my-posh = {
                enable = true;
                enableZshIntegration = true;
                settings = builtins.fromJSON (builtins.unsafeDiscardStringContext (builtins.readFile ./catpuccin_theme.json));
              };

              # Enable and configure Git
              programs.git = {
                enable = true;
                userName = "extrordinaire"; # Replace with your actual name
                userEmail = "maximoverzini@gmail.com"; # Replace with your actual email
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
		sensibleOnTop = true;
		prefix = "C-Space";
		extraConfig = ''

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
