#!/bin/bash

#----------------------------------------------------
#   Program name : has_update.sh
#   Date of program : 2025/5/29
#   Author : tomo-ing
#----------------------------------------------------

# スクリプト自身のディレクトリを取得
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

CONF_FILE=${SCRIPT_DIR}/conf.txt

# conf.txt ファイルの存在確認
if [ ! -f "$CONF_FILE" ]; then
  echo "エラー: 設定ファイル '$CONF_FILE' が見つかりません。" >&2
  exit 1
fi

# 設定ファイルから変数取得
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去後、数字とドット以外を削除
old_ver=$(grep "^old_ver=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//" | sed 's/[^0-9.]//g')
new_ver=$(grep "^new_ver=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//" | sed 's/[^0-9.]//g')

# SERVER_DIR の取得 (例: SERVER_DIR='/home/minecraft')
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去
SERVER_DIR=$(grep "^SERVER_DIR=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//")

# session_list の取得 (例: SESSION_NAME='s1, s2')
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去 
session_list=$(grep "^SESSION_NAME=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//")

if [ -z "$session_list" ]; then
  echo "エラー: '$CONF_FILE' に SESSION_NAME の設定が見つからないか、値が空です。" >&2
  exit 1
fi

# カンマを区切り文字としてセッション名を一つずつ処理
#    - `IFS=','` で内部フィールドセパレータをカンマに設定。
#    - `read -r -a sessions_array <<< "$raw_session_list"` でカンマ区切りの文字列を配列に格納。
#      (`-r` はバックスラッシュを解釈しない、`-a array` で配列に読み込む)
IFS=',' read -r -a sessions_array_with_spaces <<< "$session_list"

# 次に、各要素から前後の空白を除去した新しい配列を作成
sessions_array=()
for item in "${sessions_array_with_spaces[@]}"; do
  # Bashのパラメータ展開を使用して前後の空白を除去
  # まず先頭の空白を除去
  item_no_leading_space="${item#"${item%%[![:space:]]*}"}"
  # 次に末尾の空白を除去
  item_trimmed="${item_no_leading_space%"${item_no_leading_space##*[![:space:]]}"}"
  sessions_array+=("$item_trimmed")
done

# SERVER_DIR の取得 (例: SERVER_DIR='/home/minecraft')
# '^キー名=' で行を特定し、'='以降を取得、シングルクォートを除去
AUTO_START_SERVER=$(grep "^AUTO_START_SERVER=" "$CONF_FILE" | cut -d'=' -f2- | sed "s/^'//;s/'$//" | sed 's/[^0-9]//g')

# 公式サイトからサーバーの最新のバージョン値取得
VERSION=`curl -H "Accept-Encoding: identity" -H "Accept-Language: en" -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.33 (KHTML, like Gecko) Chrome/90.0.$RandNum.212 Safari/537.33" https://minecraft.net/en-us/download/server/bedrock/ 2>/dev/null | grep bin-linux/bedrock-server | sed -e 's/.*<a href=\"\(https:.*\/bin-linux\/.*\.zip\).*/\1/' -e 's/[^0-9.]//g' -e 's/^.\{2\}//' -e 's/.\{1\}$//'`

# スクリプト自身のディレクトリに移動
cd ${SCRIPT_DIR}

# 現在のサーバーのバージョン値と最新のバージョン値を比較する
# バージョン値が異なる場合アップデートを行う。そうでない場合はそのままサーバーを起動する
if [ "${new_ver}" != "${VERSION}" ]; then

  # 各セッション名でサーバー停止通知
  for session_name in "${sessions_array[@]}"; do
    screen -S ${session_name} -X stuff '\nsay This server will update after 1 minutes\n'
    screen -S ${session_name} -X stuff '\nsay The update will finish in a few minutes\n'
  done
  
  sleep 60
  
  #サーバー停止用シェルの呼び出し
  ./mcs_stop.sh
    
  # conf.txtを更新
  OLD_VERSION=${new_ver}
  sed -e "s/ver='${new_ver}'/ver='${VERSION}'/" -e "s/old_ver='${old_ver}'/old_ver='${OLD_VERSION}'/" ${SCRIPT_DIR}/conf.txt > tmp
  mv tmp ${SCRIPT_DIR}/conf.txt

  #アップデート用シェルの呼び出し
  cd ${SCRIPT_DIR}
  ./mcs_update.sh
fi

if [ "$AUTO_START_SERVER" -eq 1 ]; then
  cd ${SCRIPT_DIR}
  #サーバーを起動
  ./mcs_start.sh
fi
