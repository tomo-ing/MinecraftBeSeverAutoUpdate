#!/bin/bash

#----------------------------------------------------
#   Program name : mcs_start.sh
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

does_screen_session_exist() {
  local session_name="$1"
  if [ -z "$session_name" ]; then
    echo "エラー: セッション名が指定されていません。" >&2
    return 2 # 不正な引数を示す終了ステータス
  fi
  screen -ls | grep -q -w "$session_name"
  return $? # grepの終了ステータスをそのまま返す
}
  
# 各セッション名でサーバー起動
for session_name in "${sessions_array[@]}"; do
  if !does_screen_session_exist "$session_name"; then
    # bedrock_serverのディレクトリ
    SESSION_DIR=${SERVER_DIR}/${session_name}
    SERVER_SESSION_DIR=${SESSION_DIR}/bedrock_server${new_ver}
  
    # SESSION_NAMEは設定ファイル内
    cd ${SERVER_SESSION_DIR}
    cp -pf ${SESSION_DIR}/server.properties server.properties
    cp -pf ${SESSION_DIR}/permissions.json permissions.json
    cp -pf ${SESSION_DIR}/allowlist.json allowlist.json
  
    # bedrock_serverの起動
    LD_LIBRARY_PATH=. screen -dmS ${session_name} ./bedrock_server > ./${session_name}.log &
  
    # サーバーの起動を待機
    sleep 20
  fi
done
