# nvim-config

Портативный конфиг Neovim, заточенный под Python-разработку: LSP
(pyright + ruff), автоматическое определение venv, Telescope, дерево
файлов, встроенный терминал, undo-tree, тема monokai-pro. Ставится
на новой машине (macOS / Linux) одной командой, без Homebrew на маке.

Репозиторий: https://gl.pivlab.dev/rnd/nvim-config

**Документация:**
- [KEYMAPS.md](KEYMAPS.md) — полный список хоткеев этого конфига, подробно, с пояснениями и примерами
- [VIM-BASICS.md](VIM-BASICS.md) — база самого vim (режимы, движения, текстовые объекты, регистры, макросы...), не зависит от этого конфига

## Быстрый старт

**Уже есть SSH-ключ в GitLab (обычный рабочий кейс):**
```bash
curl -fsSL https://gl.pivlab.dev/rnd/nvim-config/-/raw/master/bootstrap.sh | bash
```
Один `curl`, который: ставит Neovim/ripgrep/fd/Node.js как бинарники в
`~/.local`, клонирует этот репозиторий в `~/.config/nvim`, синхронизирует
плагины и ставит pyright/ruff/lua_ls/stylua через mason.

После этого откройте новый терминал (чтобы подхватился PATH) и запустите
`nvim`.

Если что-то пошло не так с одной командой — то же самое руками:
```bash
git clone git@gl.pivlab.dev:rnd/nvim-config.git ~/.config/nvim
~/.config/nvim/bootstrap.sh
```

## Что внутри

```
~/.config/nvim/
├── init.lua                   # options -> keymaps -> autocmds -> lazy
├── lua/
│   ├── config/
│   │   ├── options.lua        # отступы, номера строк, undofile, ...
│   │   ├── keymaps.lua        # общие маппинги
│   │   ├── autocmds.lua       # автопереход cwd на корень проекта (.git)
│   │   └── lazy.lua           # bootstrap lazy.nvim
│   └── plugins/                # один файл = один plugin spec
│       ├── colorscheme.lua    # monokai-pro
│       ├── telescope.lua      # поиск файлов/текста/символов
│       ├── neo-tree.lua       # дерево файлов
│       ├── toggleterm.lua     # терминал внутри nvim
│       ├── treesitter.lua     # подсветка синтаксиса
│       ├── completion.lua     # blink.cmp — автодополнение
│       ├── lsp.lua            # mason + pyright + ruff + lua_ls
│       ├── formatting.lua     # conform.nvim (ruff format, stylua)
│       ├── python.lua         # venv-selector.nvim
│       ├── undotree.lua       # визуальное дерево истории отмены
│       ├── autopairs.lua      # авто-закрытие скобок/кавычек
│       └── align.lua          # mini.align — ручное выравнивание по столбцам
├── bootstrap.sh                # установщик (см. ниже)
├── KEYMAPS.md                  # все хоткеи этого конфига, подробно
├── VIM-BASICS.md                # база самого vim, без привязки к конфигу
└── lazy-lock.json              # точные версии всех плагинов — коммитится
```

## Установка по ОС

`bootstrap.sh` сам определяет ОС и архитектуру (Intel/Apple Silicon,
x86_64/arm64) и ставит всё нужное как **бинарники** с официальных
релизов — Neovim, ripgrep, fd, `tree-sitter` CLI (нужен nvim-treesitter,
чтобы компилировать парсеры) и Node.js (нужен mason'у, чтобы поставить
pyright — это npm-пакет) кладутся в `~/.local/opt/*` и симлинкаются в
`~/.local/bin`. Никакого sudo для самих инструментов nvim не требуется.

### macOS

**Без Homebrew.** Единственное, что нужно из системного — компилятор
и git из Xcode Command Line Tools (это не Homebrew, а часть macOS).
`bootstrap.sh` пробует поставить их сам без диалоговых окон:

```bash
touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
softwareupdate -i "Command Line Tools for Xcode-XX.X" --verbose
```

Если автоматика не сработала (бывает на новых версиях macOS) —
поставьте вручную командой `xcode-select --install` (появится GUI-диалог,
нажмите Install) и запустите `bootstrap.sh` заново.

Дальше всё как в Linux-ветке: Neovim/rg/fd/Node качаются с
`github.com/.../releases` и `nodejs.org/dist` под вашу архитектуру
(`arm64` для Apple Silicon, `x86_64` для Intel).

### Debian / Ubuntu

Проверяет наличие `git`, `curl`, `tar`, компилятора; если чего-то нет —
ставит через `apt-get install -y git curl tar build-essential` (нужен
sudo). ripgrep/fd НЕ ставятся через apt — версии в репозиториях Ubuntu
LTS часто старые, поэтому они тоже качаются как бинарники, как и на
маке.

### RockyLinux (и вообще RHEL-семейство: CentOS, Fedora, AlmaLinux)

Аналогично, только `dnf install -y git curl tar gcc gcc-c++ make`.
Отдельно поднимать EPEL ради ripgrep/fd не нужно — та же причина: они
идут как бинарники с GitHub, а не из системных репозиториев.

### Общее для Linux

- Скрипт ничего не трогает через sudo, если `git`/компилятор уже стоят
  (типично для дев-серверов) — тогда весь `bootstrap.sh` отрабатывает
  вообще без прав root.
- PATH на `~/.local/bin` дописывается в `~/.zshrc`/`~/.bashrc`/`~/.profile`
  (в те, что реально существуют у вас), так что в новых терминалах всё
  работает само.

## Тема и прозрачность

`monokai-pro.nvim`, `filter = "spectrum"`, `transparent_background = true`.
Сама прозрачность рисует терминал (Ghostty/iTerm2/Alacritty —
`background-opacity` в его настройках), nvim только не закрашивает фон
поверх неё. Другие фильтры темы: `classic | machine | octagon | pro |
ristretto` — поменять в `lua/plugins/colorscheme.lua`.

## Python: LSP, venv, ООП-навигация

- **pyright** — типы, автодополнение, переходы по коду.
- **ruff** — линт и форматирование (`<leader>mp` или автоматически при
  сохранении).
- **venv**: `pyright` сам смотрит на `<корень-проекта>/.venv`, если venv
  назван иначе или лежит не в корне — `<leader>cv` открывает список всех
  найденных окружений (poetry/conda/pyenv/hatch/...) через Telescope.
- Корень проекта (`cwd`) переключается автоматически при открытии файла
  по ближайшему `.git`/`pyproject.toml` вверх по дереву — не нужно
  помнить `cd` перед `nvim`.

## Редактирование

- **Скобки/кавычки** закрываются сами, как в IDE (`nvim-autopairs`):
  набрали `(` — получили `()`, курсор между ними; вложенность работает
  корректно, включая строки/комментарии (treesitter-aware, лишний раз не
  навязывает пару там, где это мешает).
- **Форматирование** — ruff (`python`) / stylua (`lua`) через
  `conform.nvim`, включено автоматически на `:w`, либо по хоткею в любой
  момент, не дожидаясь сохранения.
- **Выравнивание по столбцам** (не то же самое, что форматирование —
  ruff это сознательно не делает) — `mini.align`.

Хоткеи для всего этого, как и остальные — в [KEYMAPS.md](KEYMAPS.md).

## Горячие клавиши

Полный список с пояснениями и примерами — в отдельном файле:
**[KEYMAPS.md](KEYMAPS.md)**.

Самое частое, что нужно в первый день:

| Клавиши | Действие |
|---|---|
| `<leader>ff` / `<leader>fg` | Найти файл / найти текст в проекте |
| `<leader>e` | Дерево файлов (открыть/сфокусировать/закрыть) |
| `<C-\>` | Терминал внутри nvim |
| `gd` / `K` | Перейти к определению / посмотреть тип и документацию |
| `<leader>rn` | Переименовать символ во всём проекте |
| `<leader>mp` | Отформатировать буфер прямо сейчас |
| `<leader>u` | Дерево истории отмены |

Про сам vim (режимы, `dd`/`ciw`/макросы и т.п.), а не про этот
конфиг — см. **[VIM-BASICS.md](VIM-BASICS.md)**.

## Про `Ctrl+\` на macOS отдельно

`Ctrl+\` — это не «специальная комбинация nvim», а стандартный POSIX
символ FS (0x1C), который терминальный драйвер по умолчанию трактует
как **SIGQUIT** (аварийное завершение foreground-процесса). Так на
Linux и на macOS одинаково: пока nvim — активная программа в терминале,
он сам переводит tty в raw-режим и перехватывает этот байт как обычный
ввод, поэтому в норме `Ctrl+\` просто попадает в toggleterm, а не убивает
nvim. Но на маке есть несколько мест, где это может сломаться ещё до
nvim:

1. **tmux** — если вы открываете nvim внутри tmux, а у tmux в
   `~/.tmux.conf` `\` завязан на что-то своё (например, split-pane) —
   комбинация перехватится tmux'ом раньше, чем дойдёт до nvim.
2. **Karabiner-Elements** — если стоит и есть кастомные ремапы
   клавиатуры, `\`/`Ctrl` может быть переопределён на уровне ОС ещё до
   терминала.
3. **Раскладка клавиатуры** — на не-US раскладках (например, ISO/RU-раскладка
   на встроенной клавиатуре Mac) физическая `\` часто уезжает на другую
   клавишу или требует `Option`/доп. модификатор — тогда `Ctrl+\`
   попросту не набирается в один жест.
4. **Настройки самого терминала** (iTerm2/Terminal.app/Ghostty) — в
   Preferences → Keys иногда что-то из системных шорткатов перехватывает
   `\`-комбинации на уровне приложения.

Поэтому в конфиге есть запасной биндинг **`<leader>tt`** (Space, затем
дважды `t`) — делает ровно то же самое, что `<C-\>`, но не зависит ни от
раскладки, ни от tmux/Karabiner. Если `Ctrl+\` у вас не работает — просто
пользуйтесь `<leader>tt` и не тратьте время на диагностику raw-режима tty.

## Обновление

```bash
cd ~/.config/nvim
nvim --headless -c "lua require('lazy').sync({ wait = true, show = false })" -c "qa"
git add lazy-lock.json && git commit -m "bump plugins" && git push
```
(`require('lazy').sync({wait=true})`, а не голое `+Lazy! sync` — тот не
дожидается build-хуков вроде компиляции treesitter-парсеров, см.
`bootstrap.sh`.)
На остальных машинах — `git pull`, версии подтянутся при следующем
запуске nvim.

## Troubleshooting

- **`nvim --version` показывает старую версию / плагинов нет** — скорее
  всего в PATH раньше находится системный neovim (`/usr/bin/nvim` из
  apt/dnf). Откройте новый терминал (PATH обновляется в rc-файле только
  для новых сессий) и проверьте `which -a nvim` — `~/.local/bin/nvim`
  должен быть первым.
- **`fd`/`rg` не найдены** — тоже проблема PATH, см. выше; либо
  `bootstrap.sh` не был запущен целиком (упал на середине) — прогоните
  его ещё раз, он идемпотентен.
- **pyright не резолвит импорты** — see раздел про venv выше:
  `<leader>cv` и выберите нужное окружение, либо просто назовите venv
  `.venv` и положите в корень проекта — подхватится сам.
- **Ctrl+\ не открывает терминал на маке** — см. раздел выше, пользуйтесь
  `<leader>tt`.
