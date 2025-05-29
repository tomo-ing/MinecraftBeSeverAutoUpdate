#!/bin/bash

# スクリプト自身のディレクトリを取得
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

CONF_FILE=${SCRIPT_DIR}/conf.txt

# conf.txt ファイルの存在確認
if [ ! -f "$CONF_FILE" ]; then
  echo "エラー: 設定ファイル '$CONF_FILE' が見つかりません。" >&2
  exit 1
fi

# 設定ファイルから変数取得
old_ver=`grep 'old_ver' $CONF_FILE | sed -e 's/[^0-9.]//g'`
new_ver=`grep 'new_ver' $CONF_FILE | sed -e 's/[^0-9.]//g'`

SESSION_NAME=`grep 'SESSION_NAME' $CONF_FILE | sed -e 's/^.\{16\}//' -e 's/.\{1\}$//'`

SERVER_PASS=`grep 'SERVER_PASS' $CONF_FILE | sed -e 's/^.\{16\}//' -e 's/.\{1\}$//'`

session_list=$(grep "^SESSION_NAME" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//")
# 公式サイトからサーバーの最新のバージョン値取得

VERSION=`curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" https://minecraft.net/en-us/download/server/bedrock/ 2>/dev/null | grep bin-linux/bedrock-server | sed -e 's/.*<a href=\"\(https:.*\/bin-linux\/.*\.zip\).*/\1/' -e 's/[^0-9.]//g' -e 's/^.\{2\}//' -e 's/.\{1\}$//'`
# 現在のサーバーのバージョン値と最新のバージョン値を比較する
# バージョン値が異なる場合アップデートを行う。そうでない場合はそのままサーバーを起動する
if [ ${new_ver} != ${VERSION} ]; then

  # conf.txtを更新
  OLD_VERSION=${new_ver}
  sed -e "s/ver='${new_ver}'/ver='${VERSION}'/" -e "s/old_ver='${old_ver}'/old_ver='${OLD_VERSION}'/" ${SERVER_PASS}/conf.txt > tmp
  mv tmp ${SERVER_PASS}/conf.txt
  cd ${SERVER_PASS}/

  #アップデート用シェルの呼び出し
  ./mcs_update.sh

else

  # bedrock_serverの起動
  # bedrock_serverのディレクトリ
  # verは設定ファイル内
  SERVER_DIR01=${SERVER_PASS}/server/bedrock_server${new_ver}
  # SERVER_DIR02=${SERVER_PASS}/server2/bedrock_server${new_ver}

  # SESSION_NAMEは設定ファイル内
  cd ${SERVER_DIR01}
  cp -pf ${SERVER_PASS}/server.properties server.properties
  cp -pf ${SERVER_PASS}/permissions.json permissions.json
  cp -pf ${SERVER_PASS}/allowlist.json allowlist.json
  LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME} ./bedrock_server > ./bedrock_server01.log &

  # sleep 30

  # cd ${SERVER_DIR02}
  # cp -pf ${SERVER_PASS}/server.properties2 server.properties
  # cp -pf ${SERVER_PASS}/permissions.json permissions.json
  # LD_LIBRARY_PATH=. screen -dmS ${SESSION_NAME02} ./bedrock_server > ./bedrock_server02.log &

fi
