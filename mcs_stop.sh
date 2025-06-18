#!/bin/bash

#----------------------------------------------------
#   Program name : mcs_stop.sh
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

# セッション配列の取得（共通関数を使用）
if ! eval "$(get_session_array "$CONF_FILE")"; then
  log_error "セッション名の取得に失敗しました。"
  exit 1
fi

log_info "Minecraftサーバーを停止しています..."

# 各セッション名でサーバー停止
for session_name in "${sessions_array[@]}"; do
  if does_screen_session_exist "$session_name"; then
    log_info "セッション '${session_name}' を停止しています..."
    
    # stopコマンドを送信
    screen -S ${session_name} -X stuff '\nstop\n'
    
    # サーバー停止を待機
    log_info "サーバー停止を待機中..."
    if wait_for_process_end "bedrock_server" 30; then
      log_info "セッション '${session_name}' が正常に停止しました"
    else
      log_error "セッション '${session_name}' の停止に時間がかかっています"
      # 強制終了
      screen -S ${session_name} -X quit 2>/dev/null || true
      log_info "セッション '${session_name}' を強制終了しました"
    fi
  else
    log_info "セッション '${session_name}' は実行されていません"
  fi
done

log_info "サーバー停止処理が完了しました"
