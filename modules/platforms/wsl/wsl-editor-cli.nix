{ ... }:
{
  flake.modules.nixos.wsl-editor-cli =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      vim-night-owl = pkgs.vimUtils.buildVimPlugin {
        pname = "vim-night-owl";
        version = "unstable-2021-05-16";
        src = pkgs.fetchFromGitHub {
          owner = "haishanh";
          repo = "night-owl.vim";
          rev = "783a41a27f7fe55ed91d1ec0f0351d06ae17fbc7";
          hash = "sha256-dI/Ag3FXiSy2ec7wC9wNJ15uAiYZEtu6gyyqU6BT98k=";
        };
      };
    in
    lib.mkIf (config.my.host.platform == "wsl" && config.my.host.home.enable) {
      home-manager.users.ssorensen.programs = {
        gh = {
          enable = true;
          gitCredentialHelper.enable = true;
        };

        vim = {
          enable = true;
          defaultEditor = true;
          plugins = [
            pkgs.vimPlugins.vim-fish
            vim-night-owl
          ];
          extraConfig = ''
            set expandtab ignorecase number smartcase
            set shiftwidth=4 tabstop=4 softtabstop=4
            set backspace=indent,start,eol incsearch hlsearch autoindent
            set scrolloff=10 sidescrolloff=10
            imap jj <ESC>
            map 0 ^
            set smartindent smarttab cindent showmatch ruler
            syntax on
            set pastetoggle=<F4>
            nnoremap <F5> :set nonumber!<CR>
            set splitbelow splitright encoding=utf-8
            set list listchars=tab:»·,trail:·,extends:>,precedes:<,nbsp:+
            set cursorline cursorcolumn showcmd wildmenu
            set wildmode=list:longest,full
            set wildignore=*.o,*~,*.pyc,*.hi
            set matchtime=2 display+=lastline autoread laststatus=2
            autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
            filetype plugin indent on
            if has("termguicolors") | set termguicolors | endif
            colorscheme night-owl
          '';
        };
      };
    };
}
