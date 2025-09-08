# Curated list of Mac OsX developer tools

### homebrew (https://brew.sh/)

The missing package manager for macOS.

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### SDKman (https://sdkman.io/)

Managinge multiple Software Development Kits and Java Development Tools.

```
curl -s "https://get.sdkman.io" | bash
```

### httpie (https://httpie.org/)

HTTPie is a command line HTTP client with an intuitive UI, JSON support, syntax highlighting, wget-like downloads, plugins, and more.

```
brew install httpie
```

### HTTP Prompt (http://http-prompt.com/)

HTTP Prompt is an interactive command-line HTTP client featuring autocomplete and syntax highlighting.

```
pip install http-prompt
```

### htop (https://hisham.hm/htop/)

An interactive process viewer for Unix systems, a replacement for the regular **top** command.

```
brew install htop
```

### glances (https://nicolargo.github.io/glances/)

Another replacement for **top**, and an alternative to htop. Glances is a cross-platform monitoring 
tool which aims to present a maximum of information in a minimum of space through a curses or 
Web based interface. It can adapt dynamically the displayed information depending on the terminal size.

```
brew install glances
```

### ripgrep (https://github.com/BurntSushi/ripgrep)

Grep replacement, optimized for developers

```
brew install ripgrep
```

### fd (https://github.com/sharkdp/fd)

Simple, fast and user-friendly alternative to find

```
brew install fd
```

### fzf ([https://github.com/sharkdp/fd](https://github.com/junegunn/fzf))

Command-line fuzzy finder

```
brew install fzf
```

### iterm2 (https://www.iterm2.com/)

Terminal replacement on stereoids

```
brew cask install iterm2
```

### clipy (https://github.com/Clipy/Clipy)

Clipboard history manager

```
brew cask install clipy
```

### bat (https://github.com/sharkdp/bat)

cat and less replacement with syntax highlighting and git integration

```
brew install bat
```

### JetBrains Mono font (https://www.jetbrains.com/lp/mono/)

Best font for development

```
brew tap homebrew/cask-fonts
brew cask install font-jetbrains-mono
```

### Visual Studio Code (https://code.visualstudio.com/) (https://github.com/microsoft/vscode)

Free code editor

```
brew cask install visual-studio-code
```

### Duf (https://github.com/muesli/duf)

A better df cli command

```
brew install duf
```


# Online services for developers (not only Mac)

### httpbin (https://httpbin.org/)

Online service to test HTTP requests.

### IT-Tools (https://it-tools.tech/)

Random simple tools for encryption, hashing, conversion etc.

### JSON Hero (https://jsonhero.io/)

Amazing visualization tool for JSON files.


### Installation

Use the following command to install Homebrew the apps

#### Homebrew Core


```sh
curl -s https://bjfr.github.io/mac-developer-tools/homebrew-core.md | grep '^[[:alnum:]]' | xargs brew install
```

#### Homebrew Development

```sh
curl -s https://bjfr.github.io/mac-developer-tools/homebrew-development.md | grep '^[[:alnum:]]' | xargs brew install
```

#### SDKMan

```sh
curl -s "https://bjfr.github.io/mac-developer-tools/sdkman.sh" | bash
```


[Homebrew](./homebrew-core.md)




