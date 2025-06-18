#!/bin/bash

#----------------------------------------------------
#   Program name : has_update.sh
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
SERVER_DIR=$(get_config_value "SERVER_DIR" "$CONF_FILE")

# セッション配列の取得（共通関数を使用）
if ! eval "$(get_session_array "$CONF_FILE")"; then
  log_error "セッション名の取得に失敗しました。"
  exit 1
fi

# AUTO_START_SERVER の取得（共通関数を使用）
AUTO_START_SERVER=$(get_config_value "AUTO_START_SERVER" "$CONF_FILE" true true)

# スクリプト自身のディレクトリに移動
cd ${SCRIPT_DIR}

# Pythonスクリプトを呼び出し、結果を変数に格納
log_info "最新バージョン情報を取得中..."
PYTHON_OUTPUT=$(python3 ./get_mc.py 2>/dev/null)

# カンマで結果を分割し、VERSIONとDOWNLOAD_URLに代入
# IFSを一時的に設定して読み込む
IFS=',' read -r VERSION DOWNLOAD_URL <<< "$PYTHON_OUTPUT"

# デバッグ出力
log_info "Python出力: $PYTHON_OUTPUT"
log_info "取得したバージョン: $VERSION"
log_info "取得したURL: $DOWNLOAD_URL"

# バージョン取得に失敗した場合のチェック
if [ "$VERSION" = "UNKNOWN_VERSION" ] || [ -z "$VERSION" ]; then
  log_error "最新バージョンの取得に失敗しました。"
  exit 1
fi

# URLの検証
if ! validate_url "$DOWNLOAD_URL"; then
  log_error "不正なダウンロードURLです: '$DOWNLOAD_URL'"
  exit 1
fi

# バージョン情報の表示
log_info "=== Minecraft Bedrock Server Version Check ==="
log_info "Current version: ${old_ver}"
log_info "Latest version:  ${VERSION}"
log_info "Update needed:   $([ "${old_ver}" != "${VERSION}" ] && echo "Yes" || echo "No")"

# 現在のサーバーのバージョン値と最新のバージョン値を比較する
# バージョン値が異なる場合アップデートを行う。そうでない場合はそのままサーバーを起動する
if [ "${new_ver}" != "${VERSION}" ]; then

  log_info "アップデートを開始します: ${new_ver} → ${VERSION}"

  # 各セッション名でサーバー停止通知
  for session_name in "${sessions_array[@]}"; do
    screen -S ${session_name} -X stuff '\nsay This server will update after 1 minutes\n'
    screen -S ${session_name} -X stuff '\nsay The update will finish in a few minutes\n'
  done
  
  sleep 60  
  # サーバー停止用シェルの呼び出し
  log_info "サーバーを停止しています..."
  ./mcs_stop.sh
    
  # conf.txtを更新（共通関数を使用）
  log_info "設定ファイルを更新しています..."
  if ! update_multiple_config_values "$CONF_FILE" true \
       "DOWNLOAD_URL=${DOWNLOAD_URL}" \
       "new_ver=${VERSION}" \
       "old_ver=${new_ver}"; then
    log_error "設定ファイルの更新に失敗しました"
    exit 1
  fi

  # アップデート用シェルの呼び出し
  log_info "アップデートスクリプトを実行しています..."
  cd ${SCRIPT_DIR}
  ./mcs_update.sh
else
  log_info "バージョンは最新です。アップデートは不要です。"
fi

# サーバー自動起動チェック
if [ "$AUTO_START_SERVER" -eq 1 ]; then
  log_info "サーバーを自動起動しています..."
  cd ${SCRIPT_DIR}
  ./mcs_start.sh
fi

log_info "処理が完了しました。"
