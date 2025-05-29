#!/bin/bash

# 設定ファイルから変数取得
config=/home/minecraft/command/conf.txt
old_ver=`grep 'old_ver' $config | sed -e 's/[^0-9.]//g'`
new_ver=`grep 'new_ver' $config | sed -e 's/[^0-9.]//g'`
SESSION_NAME01=`grep 'SESSION_NAME01' $config | sed -e 's/^.\{16\}//' -e 's/.\{1\}$//'`
# SESSION_NAME02=`grep 'SESSION_NAME02' $config | sed -e 's/^.\{16\}//' -e 's/.\{1\}$//'`

# 公式サイトからサーバーの最新のバージョン値取得
VERSION=`curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537># 現在のサーバーのバージョン値と最新のバージョン値を比較する
# バージョン値が異なる場合アップデートを行う
if [ ${new_ver} != ${VERSION} ]; then

  echo "現在のサーバーは最新バージョンのものでないためこれよりサーバーを停止し、アップデートを開始します"
  screen -S ${SESSION_NAME01} -X stuff '\nsay This server will update after 1 minutes\n'
  # screen -S ${SESSION_NAME02} -X stuff '\nsay This server will update after 1 minutes\n'

  # conf.txtを更新
  OLD_VERSION=${new_ver}
  sed -e "s/ver='${new_ver}'/ver='${VERSION}'/" -e "s/old_ver='${old_ver}'/old_ver='${OLD_VERSION}'/" /home/minecraft/command/conf.txt>  mv tmp /home/minecraft/command/conf.txt
  cd /home/minecraft/command/

  #サーバー停止用シェルの呼び出し
  sleep 1
  screen -S ${SESSION_NAME01} -X stuff '\nsay The update will take about 20 minutes\n'
  # screen -S ${SESSION_NAME02} -X stuff '\nsay The update will take about 20 minutes\n'
  sleep 1
  ./eme_stop.sh

  #アップデート用シェルの呼び出し
  ./mcs_update.sh

else

  echo "現在のサーバーは最新バージョンです"

fi
