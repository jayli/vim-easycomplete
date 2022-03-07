#!/usr/bin/env bash

set -e

## EmmyLua
#version="0.3.6"
#curl -L -o EmmyLua-LS-all.jar "https://github.com/EmmyLua/EmmyLua-LanguageServer/releases/download/$version/EmmyLua-LS-all.jar"

#cat <<EOF >emmylua-ls
##!/usr/bin/env bash
#DIR=\$(cd \$(dirname \$0); pwd)
#java -cp \$DIR/EmmyLua-LS-all.jar com.tang.vscode.MainKt
#EOF

#chmod +x emmylua-ls


os=$(uname -s | tr "[:upper:]" "[:lower:]")

version="2.6.6"

case $os in
linux)
  platform="linux-x64"
  ;;
darwin)
  platform="darwin-x64"
  ;;
esac

package_name="vscode-lua-v$version-$platform"

url="https://github.com/sumneko/vscode-lua/releases/download/v$version/$package_name.vsix"
# url="https://github.com/sumneko/vscode-lua/releases/download/v$version/lua-$version.vsix"
echo "downloading $url"

asset="vscode-lua.vsix"

curl -L "$url" -o "$asset"
unzip "$asset"
rm "$asset"

chmod +x extension/server/bin/lua-language-server

cat <<EOF >sumneko-lua-language-server
#!/usr/bin/env bash
DIR=\$(cd \$(dirname \$0); pwd)/extension/server
\$DIR/bin/lua-language-server -E -e LANG=en \$DIR/main.lua \$*
EOF

chmod +x sumneko-lua-language-server
