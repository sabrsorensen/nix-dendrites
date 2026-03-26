{
  flake.modules.homeManager.vim =
    {
      pkgs,
      ...
    }:
    let
      vim-night-owl = pkgs.vimUtils.buildVimPlugin {
        name = "vim-night-owl";
        src = pkgs.fetchFromGitHub {
          owner = "haishanh";
          repo = "night-owl.vim";
          rev = "783a41a27f7fe55ed91d1ec0f0351d06ae17fbc7";
          hash = "sha256-dI/Ag3FXiSy2ec7wC9wNJ15uAiYZEtu6gyyqU6BT98k=";
        };
      };
    in
    {
      programs.vim = {
        enable = true;
        defaultEditor = true;
        plugins = with pkgs.vimPlugins; [
          vim-fish
          vim-night-owl
        ];
        settings = { };
        extraConfig = ''
          set expandtab
          set ignorecase
          set number
          set shiftwidth=4
          set smartcase
          set tabstop=4
          set backspace=indent,start,eol
          set incsearch
          set hlsearch
          set softtabstop=4
          set autoindent
          set scrolloff=10
          " Use jj to exit insert mode
          imap jj <ESC>
          " Use 0 to jump to the beginning of the line
          map 0 ^

          set nocompatible
          filetype off
          set smartindent
          set smarttab
          set cindent
          set showmatch
          set ruler
          syntax on
          " Set <F4> to toggle pastemode
          set pastetoggle=<F4>
          " Set <F5> to toggle line numbers
          nnoremap <F5> :set nonumber!<CR>
          set splitbelow
          set splitright
          set encoding=utf-8

          " Make certain characters (tab, trailing spaces, wrapped text) be more visible
          set list
          set listchars=tab:»·,trail:·,extends:>,precedes:<,nbsp:+

          " Enable highlighting of the current line
          set cursorline
          set cursorcolumn
          " Show command mode on the last line
          set showcmd

          " Enhanced command-line completion
          set wildmenu
          " Tab-complete to longest common match, second press will list matches
          set wildmode=list:longest,full
          " Ignore compiled files
          set wildignore=*.o,*~,*.pyc,*.hi

          " When a new bracket is inserted, briefly jump to the matching bracket
          set showmatch
          " Display matching bracket for 0.2 seconds
          set matchtime=2

          " Scroll when the cursor is close to the bottom line/last column
          if !&scrolloff
              set scrolloff=10
          endif
          if !&sidescrolloff
              set sidescrolloff=10
          endif

          " Display as much of the last line as possible
          set display+=lastline

          " Read the file when it changes elsewhere
          set autoread
          set laststatus=2

          " Return to last edit position when opening files
          autocmd BufReadPost *
              \ if line("'\"") > 0 && line("'\"") <= line("$") |
              \   exe "normal! g`\"" |
              \ endif

          " Returns true if paste mode is enabled
          function! HasPaste()
              if &paste
                return 'PASTE MODE  '
              en
              return \'\'
          endfunction

          if has('autocmd')
            " Enable detection of filetypes, loading plugins based on filetype, and
            " specific indentation rules based on type
            filetype plugin indent on
          endif

          if (has("termguicolors"))
            set termguicolors
          endif
          colorscheme night-owl

          " To enable the lightline theme
          let g:lightline = { 'colorscheme': 'nightowl' }
        '';
      };
    };
}
