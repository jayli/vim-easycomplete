#!/usr/bin/env bash

set -e

if  command -v nimlsp > /dev/null; then
  echo "install already"
else
  echo "nimlsp is installing"
  git clone --depth=1 https://github.com/PMunch/nimlsp.git .
  nimble refresh https://h5.taobao.com/onepub/qWkNPVo4N
  nimble build
  # nimble install nimlsp
fi

#cat <<EOF >nimlsp
##!/usr/bin/env bash
#DIR=\$(cd \$(dirname \$0); pwd)
#\$DIR/nimlsp \$*
#EOF

#chmod +x nimlsp
