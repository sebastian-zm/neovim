{
  description = "Custom Neovim configuration with mini.nvim and plugins";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    mini-nvim = {
      url = "github:echasnovski/mini.nvim";
      flake = false;
    };

    guess-indent-nvim = {
      url = "github:NMAC427/guess-indent.nvim";
      flake = false;
    };

    netrw-nvim = {
      url = "github:prichrd/netrw.nvim";
      flake = false;
    };

    nvim-lspconfig = {
      url = "github:neovim/nvim-lspconfig";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, mini-nvim, guess-indent-nvim, netrw-nvim, nvim-lspconfig }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        mkNvimPlugin = { name, src }: {
          plugin = pkgs.vimUtils.buildVimPlugin {
            inherit name src;
          };
          optional = false;
          type = "lua";
        };

        plugins = map mkNvimPlugin [
          { name = "mini.nvim"; src = mini-nvim; }
          { name = "guess-indent.nvim"; src = guess-indent-nvim; }
          { name = "netrw.nvim"; src = netrw-nvim; }
          { name = "nvim-lspconfig"; src = nvim-lspconfig; }
        ];

        extraPackages = with pkgs; [
          pyright
          jdt-language-server
          vscode-langservers-extracted
          lemminx
        ];

        neovim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (
          (pkgs.neovimUtils.makeNeovimConfig {
            withPython3 = false;
            withNodeJs = false;
            withRuby = false;
            withPerl = false;
            waylandSupport = false;
            viAlias = true;
            vimAlias = true;
            inherit plugins;
            customLuaRC = ''
              require("mini.ai").setup()
              require("mini.basics").setup()
              require("mini.comment").setup()
              require("mini.cursorword").setup()
              require("mini.diff").setup()
              require("mini.icons").setup()
              require("mini.git").setup()
              require("mini.pairs").setup()
              require("mini.surround").setup()
              require("mini.statusline").setup()
              require("mini.tabline").setup()
              require("mini.trailspace").setup()
              require("guess-indent").setup()
              require("netrw").setup({})

              vim.lsp.enable('pyright')
              vim.lsp.enable('jdtls')
              vim.lsp.enable('html')
              vim.lsp.enable('cssls')
              vim.lsp.enable('jsonls')
              vim.lsp.enable('eslint')
              vim.lsp.enable('lemminx')
            '';
            customRC = ''
              set mouse=nvi
              set expandtab
              let g:netrw_liststyle = 3
              let g:netrw_winsize = 30
            '';
          }) // {
            wrapperArgs = "--prefix PATH : ${pkgs.lib.makeBinPath extraPackages}";
          }
        );
      in
      {
        packages.default = neovim;

        apps.default = {
          type = "app";
          program = "${neovim}/bin/nvim";
        };
      }
    );
}
