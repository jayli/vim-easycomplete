#!/usr/bin/env bash

# Based on https://github.com/codota/TabNine/blob/master/dl_binaries.sh
# Download latest TabNine binaries
set -e

#version=${version:-$(curl -sS https://update.tabnine.com/bundles/version)}
#4.280.0

version="4.251.0"
version="3.3.34"
version="3.3.126"

case $(uname -s) in
"Darwin")
    if [ "$(uname -m)" == "arm64" ]; then
        platform="aarch64-apple-darwin"
    else
        platform="$(uname -m)-apple-darwin"
    fi
    ;;
"Linux")
    platform="$(uname -m)-unknown-linux-musl"
    ;;
esac

# we want the binary to reside inside our plugin's dir
cd $(pwd)
path=$version/$platform

curl https://update.tabnine.com/bundles/${path}/TabNine.zip --create-dirs -o binaries/${path}/TabNine.zip
unzip -o binaries/${path}/TabNine.zip -d binaries/${path}
rm -rf binaries/${path}/TabNine.zip
chmod +x binaries/$path/*
# ln -sf $path "binaries/TabNine_$(uname -s)"

cat <<EOF >TabNine
#!/usr/bin/env bash
DIR=\$(cd \$(dirname \$0); pwd)
\$DIR/binaries/$path/TabNine \$*
EOF

cat <<EOF >version
$version
EOF

touch tabnine.log

chmod +x TabNine



