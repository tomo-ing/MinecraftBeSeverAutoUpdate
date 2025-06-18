#!/bin/bash

#----------------------------------------------------
#   Program name : mcs_update.sh
#   Date of program : 2025/5/29
#   Author : tomo-ing
#   Modified : 2025/6/19 - 共通関数を使用するように更新
#----------------------------------------------------

# スクリプト自身のディレクトリを取得
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# 共通関数の読み込み
source "${SCRIPT_DIR}/common_functions.sh"

CONF_FILE=${SCRIPT_DIR}/conf.txt

# conf.txt ファイルの存在確認
if [ ! -f "$CONF_FILE" ]; then
  log_error "設定ファイル '$CONF_FILE' が見つかりません。"
  exit 1
fi

# 設定ファイルから変数取得（共通関数を使用）
old_ver=$(get_config_value "old_ver" "$CONF_FILE" true true)
new_ver=$(get_config_value "new_ver" "$CONF_FILE" true true)
DOWNLOAD_URL=$(get_config_value "DOWNLOAD_URL" "$CONF_FILE")
SERVER_DIR=$(get_config_value "SERVER_DIR" "$CONF_FILE")

# URL検証
if ! validate_url "$DOWNLOAD_URL"; then
  log_error "不正なダウンロードURLです: $DOWNLOAD_URL"
  exit 1
fi

# セッション配列の取得（共通関数を使用）
if ! eval "$(get_session_array "$CONF_FILE")"; then
  log_error "セッション名の取得に失敗しました。"
  exit 1
fi

log_info "Minecraftサーバーのアップデートを開始します"
log_info "アップデート: ${old_ver} → ${new_ver}"

start_date=`date "+%Y/%m/%d/%H:%M:%S"`
start_time=`date +%s`

echo -n ${old_ver} - ${new_ver}, ${start_date} >> ${SCRIPT_DIR}/updatelog.txt

# 配列の要素数をチェック (オプション)
array_length="${#sessions_array[@]}"

if [ "$array_length" -eq 1 ]; then
  first_session="${sessions_array[0]}"
  remaining_sessions=() # 空の配列
else
  # 最初の1つの要素を取得
  first_session="${sessions_array[0]}"

  # それ以外の要素 (2番目以降のすべての要素) を新しい配列として取得
  remaining_sessions=("${sessions_array[@]:1}")
fi

# serverのディレクトリ
FIRST_SERVER_DIR=${SERVER_DIR}/${first_session}

# 現在のbedrock_serverのディレクトリ
OLD_FIRST_SERVER_DIR=${FIRST_SERVER_DIR}/bedrock_server${old_ver}

# 新しいbedrock_serverのディレクトリ
NEW_FIRST_SERVER_DIR=${FIRST_SERVER_DIR}/bedrock_server${new_ver}

# 指定したフォルダが存在しない場合に作成
if ! ensure_directory "$NEW_FIRST_SERVER_DIR"; then
  log_error "ディレクトリの作成に失敗しました: $NEW_FIRST_SERVER_DIR"
  exit 1
fi

# サーバーのダウンロード
cd ${NEW_FIRST_SERVER_DIR}

log_info "Minecraftサーバーをダウンロード中..."
download_success=false

if command -v curl >/dev/null 2>&1; then
    if curl -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -o "bedrock-server-${new_ver}.zip" "$DOWNLOAD_URL"; then
        download_success=true
    fi
elif command -v wget >/dev/null 2>&1; then
    if wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" -O "bedrock-server-${new_ver}.zip" "$DOWNLOAD_URL"; then
        download_success=true
    fi
else
    log_error "curl または wget が必要です"
    exit 1
fi

if [ "$download_success" = false ]; then
    log_error "サーバーファイルのダウンロードに失敗しました"
    exit 1
fi

echo "✅ Download completed successfully"

# ファイル存在確認
if [ ! -f "bedrock-server-${new_ver}.zip" ]; then
    echo "❌ Error: Downloaded file not found"
    exit 1
fi

# ファイルの解凍
unzip bedrock-server-${new_ver}.zip
sleep 5

# サーバーの一時起動
# SESSION_NAMEは設定ファイル内
LD_LIBRARY_PATH=. screen -dmS ${first_session} ./bedrock_server > ./${first_session}.log &
sleep 10
screen -S ${first_session} -X stuff '\nstop\n'
sleep 5

# 新ワールドデータの削除
rm -r worlds
sleep 5

if [ "${#remaining_sessions[@]}" -gt 0 ]; then
  for session in "${remaining_sessions[@]}"; do
    # serverのディレクトリ
    SESSION_SERVER_DIR=${SERVER_DIR}/${session}
    # 指定したフォルダが存在しない場合に作成。
    mkdir -p "$SESSION_SERVER_DIR"
    # サーバー2以降へのファイルコピー
    cp -r ${NEW_FIRST_SERVER_DIR} ${SESSION_SERVER_DIR}
    sleep 5
  done
fi

# ワールドファイルコピー
for session in "${sessions_array[@]}"; do
    # serverのディレクトリ
    SESSION_SERVER_DIR=${SERVER_DIR}/${session}
    OLD_SESSION_SERVER_DIR=${SESSION_SERVER_DIR}/bedrock_server${old_ver}
    NEW_SESSION_SERVER_DIR=${SESSION_SERVER_DIR}/bedrock_server${new_ver}
    # ワールドファイルコピー
    cp -r ${OLD_SESSION_SERVER_DIR}/worlds ${NEW_SESSION_SERVER_DIR}
    sleep 10
done

# 前サーバーの削除
for session in "${sessions_array[@]}"; do
    # serverのディレクトリ
    SESSION_SERVER_DIR=${SERVER_DIR}/${session}
    OLD_SESSION_SERVER_DIR=${SESSION_SERVER_DIR}/bedrock_server${old_ver}
    # 前サーバーの削除
    if [ -d "$OLD_SESSION_SERVER_DIR" ]; then
      rm -r ${OLD_SESSION_SERVER_DIR}
      sleep 10
    fi
done

# サーバーアップデート完了ログ出力
end_date=`date "+%Y/%m/%d/%H:%M:%S"`
end_time=`date +%s`

echo , ${end_date}, $(($end_time - $start_time)) >> ${SCRIPT_DIR}/updatelog.txt
