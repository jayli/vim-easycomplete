
### Custom the complete menu

```vim
let g:easycomplete_menu_skin = {
      \   "buf": {
      \      "kind":"⚯",
      \      "menu":"[B]",
      \    },
      \   "snip": {
      \      "kind":"<>",
      \      "menu":"[S]",
      \    },
      \   "dict": {
      \      "kind":"d",
      \      "menu":"[D]",
      \    },
      \   "tabnine": {
      \      "kind":"",
      \    },
      \ }
let g:easycomplete_lsp_type_font = {
      \ 'text' : '⚯',         'method':'m',    'function': 'f',
      \ 'constructor' : '≡',  'field': 'f',    'default':'d',
      \ 'variable' : '𝘤',     'class':'c',     'interface': 'i',
      \ 'module' : 'm',       'property': 'p', 'unit':'u',
      \ 'value' : '𝘧',        'enum': 'e',     'keyword': 'k',
      \ 'snippet': '𝘧',       'color': 'c',    'file':'f',
      \ 'reference': 'r',     'folder': 'f',   'enummember': 'e',
      \ 'constant':'c',       'struct': 's',   'event':'e',
      \ 'typeparameter': 't', 'var': 'v',      'const': 'c',
      \ 'operator':'o',
      \ 't':'𝘵',   'f':'𝘧',   'c':'𝘤',   'm':'𝘮',   'u':'𝘶',   'e':'𝘦',
      \ 's':'𝘴',   'v':'𝘷',   'i':'𝘪',   'p':'𝘱',   'k':'𝘬',   'r':'𝘳',
      \ 'o':"𝘰",   'l':"𝘭",   'a':"𝘢",   'd':'𝘥',
      \ }
```

Config error sign text:

```vim
let g:easycomplete_sign_text = {
      \   'error':       "◉",
      \   'warning':     "▲",
      \   'information': '◎',
      \   'hint':        '▧'
      \ }
```

You can define icon alias via giving fullnames and shortname.

Enable colorful styled menu (experimental):

```
let g:easycomplete_colorful = 1
```
