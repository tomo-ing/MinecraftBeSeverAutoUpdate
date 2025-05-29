#!/bin/bash

# 設定ファイルから変数取得
pass='Your Directory'

config=${pass}/conf.txt
old_ver=`grep 'old_ver' $config | sed -e 's/[^0-9.]//g'`
new_ver=`grep 'new_ver' $config | sed -e 's/[^0-9.]//g'`

SESSION_NAME01=`grep 'SESSION_NAME01' $config | sed -e 's/^.\{16\}//' -e 's/.\{1\}$//'`
# SESSION_NAME02=`grep 'SESSION_NAME02' $config | sed -e 's/^.\{16\}//' -e 's/.\{1\}$//'`

# 公式サイトからサーバーの最新のバージョン値取得

VERSION=`curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" https://minecraft.net/en-us/download/server/bedrock/ 2>/dev/null | grep bin-linux/bedrock-server | sed -e 's/.*<a href=\"\(https:.*\/bin-linux\/.*\.zip\).*/\1/' -e 's/[^0-9.]//g' -e 's/^.\{2\}//' -e 's/.\{1\}$//'`
# 現在のサーバーのバージョン値と最新のバージョン値を比較する
# バージョン値が異なる場合アップデートを行う。そうでない場合はそのままサーバーを起動する
if [ ${new_ver} != ${VERSION} ]; then

  # conf.txtを更新
  OLD_VERSION=${new_ver}
  sed -e "s/ver='${new_ver}'/ver='${VERSION}'/" -e "s/old_ver='${old_ver}'/old_ver='${OLD_VERSION}'/" ${pass}/conf.txt > tmp
  mv tmp ${pass}/conf.txt
  cd ${pass}/

  #アップデート用シェルの呼び出し
  ./mcs_update.sh

else

  # bedrock_serverの起動
  # bedrock_serverのディレクトリ
  # verは設定ファイル内
  SERVER_DIR01=${pass}/server/bedrock_server${new_ver}
  # SERVER_DIR02=${pass}/server2/bedrock_server${new_ver}

  # SESSION_NAMEは設定ファイル内
  cd ${SERVER_DIR01}
  cp -pf ${pass}/server.properties server.properties
  cp -pf ${pass}/permissions.json permissions.json
  cp -pf ${pass}/allowlist.json allowlist.json
  LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME01} ./bedrock_server > ./bedrock_server01.log &

  # sleep 30

  # cd ${SERVER_DIR02}
  # cp -pf ${pass}/server.properties2 server.properties
  # cp -pf ${pass}/permissions.json permissions.json
  # LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME02} ./bedrock_server > ./bedrock_server02.log &

fi
