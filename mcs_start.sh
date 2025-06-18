#!/bin/bash

#----------------------------------------------------
#   Program name : mcs_start.sh
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
new_ver=$(get_config_value "new_ver" "$CONF_FILE" true true)
SERVER_DIR=$(get_config_value "SERVER_DIR" "$CONF_FILE")

# セッション配列の取得（共通関数を使用）
if ! eval "$(get_session_array "$CONF_FILE")"; then
  log_error "セッション名の取得に失敗しました。"
  exit 1
fi

log_info "Minecraftサーバーを起動しています..."

# 各セッション名でサーバー起動
for session_name in "${sessions_array[@]}"; do
  if ! does_screen_session_exist "$session_name"; then
    log_info "セッション '${session_name}' を起動しています..."
    
    # bedrock_serverのディレクトリ
    SESSION_DIR=${SERVER_DIR}/${session_name}
    SERVER_SESSION_DIR=${SESSION_DIR}/bedrock_server${new_ver}
  
    # ディレクトリの存在確認
    if ! ensure_directory "$SERVER_SESSION_DIR" false; then
      log_error "サーバーディレクトリが見つかりません: $SERVER_SESSION_DIR"
      continue
    fi
    
    # SESSION_NAMEは設定ファイル内
    cd ${SERVER_SESSION_DIR}
    
    # 設定ファイルのコピー
    for config_file in server.properties permissions.json allowlist.json; do
      if [ -f "${SESSION_DIR}/${config_file}" ]; then
        cp -pf "${SESSION_DIR}/${config_file}" "${config_file}"
        log_info "設定ファイルをコピーしました: ${config_file}"
      else
        log_error "設定ファイルが見つかりません: ${SESSION_DIR}/${config_file}"
      fi
    done
  
    # bedrock_serverの起動
    if [ -f "./bedrock_server" ]; then
      LD_LIBRARY_PATH=. screen -dmS ${session_name} ./bedrock_server > "./${session_name}.log" &
      log_info "サーバーセッション '${session_name}' を起動しました"
      
      # サーバーの起動を待機
      sleep 20
    else
      log_error "bedrock_server実行ファイルが見つかりません: ${SERVER_SESSION_DIR}/bedrock_server"
    fi
  else
    log_info "セッション '${session_name}' は既に実行中です"
  fi
done

log_info "サーバー起動処理が完了しました"
