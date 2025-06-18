#!/bin/bash

#----------------------------------------------------
#   Program name : common_functions.sh
#   Date of program : 2025/6/19
#   Author : GitHub Copilot
#   Description : 共通関数ライブラリ
#----------------------------------------------------

# 設定値取得関数
get_config_value() {
    local key="$1"
    local config_file="$2"
    local remove_quotes="${3:-true}"
    local numeric_only="${4:-false}"
    
    # ファイル存在確認
    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file not found: $config_file" >&2
        return 1
    fi
    
    # 値の抽出（空白も考慮）
    local value=$(grep "^${key}\s*=" "$config_file" 2>/dev/null | head -n1 | cut -d'=' -f2-)
    
    # クォートと空白の除去
    if [ "$remove_quotes" = "true" ]; then
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed "s/^['\"]//;s/['\"]$//")
    fi
    
    # 数字とドットのみ抽出（バージョン用）
    if [ "$numeric_only" = "true" ]; then
        value=$(echo "$value" | sed 's/[^0-9.]//g')
    fi
    
    if [ -n "$value" ]; then
        echo "$value"
        return 0
    else
        echo "Error: $key not found or empty in $config_file" >&2
        return 1
    fi
}

# セッション配列取得関数
get_session_array() {
    local config_file="$1"
    local session_list
    
    # セッション名の取得
    if ! session_list=$(get_config_value "SESSION_NAME" "$config_file"); then
        return 1
    fi
    
    # 空のセッション名チェック
    if [ -z "$session_list" ]; then
        echo "Error: SESSION_NAME is empty in configuration file" >&2
        return 1
    fi
    
    # カンマ区切りでの分割と空白除去
    IFS=',' read -r -a sessions_array_with_spaces <<< "$session_list"
    
    # 空白除去処理
    sessions_array=()
    for item in "${sessions_array_with_spaces[@]}"; do
        # 前後の空白を除去
        item_no_leading_space="${item#"${item%%[![:space:]]*}"}"
        item_trimmed="${item_no_leading_space%"${item_no_leading_space##*[![:space:]]}"}"
        sessions_array+=("$item_trimmed")
    done
    
    # 配列を出力（呼び出し元でeval使用）
    declare -p sessions_array
}

# 設定値更新関数を修正（正しい置換処理）
update_config_value() {
    local key="$1"
    local value="$2"
    local config_file="$3"
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    local temp_file="${config_file}.tmp.$$"
    
    # 既存の行を削除してから新しい値を追加する方式に変更
    {
        # 指定されたキーの行以外をコピー
        grep -v "^${key}=" "$config_file"
        # 新しい値を追加
        echo "${key}='${value}'"
    } > "$temp_file"
    
    # 更新結果を確認
    if [ $? -eq 0 ] && [ -s "$temp_file" ]; then
        mv "$temp_file" "$config_file"
        log_info "Updated ${key} = '${value}'"
        return 0
    else
        rm -f "$temp_file"
        log_error "Failed to update ${key}"
        return 1
    fi
}

# 複数値更新関数も修正
update_multiple_config_values() {
    local config_file="$1"
    shift
    
    if [ ! -f "$config_file" ]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    log_info "Updating configuration file: $config_file"
    
    local temp_file="${config_file}.tmp.$$"
    cp "$config_file" "$temp_file"
    
    # 各key=value ペアを処理
    while [ $# -gt 0 ]; do
        local key="$1"
        local value="$2"
        shift 2
        
        log_info "Processing: ${key} = ${value}"
        
        # 指定されたキーの行を削除してから新しい値を追加
        {
            grep -v "^${key}=" "$temp_file"
            echo "${key}='${value}'"
        } > "${temp_file}.new"
        
        if [ $? -eq 0 ] && [ -s "${temp_file}.new" ]; then
            mv "${temp_file}.new" "$temp_file"
        else
            log_error "Failed to update $key in configuration"
            rm -f "$temp_file" "${temp_file}.new"
            return 1
        fi
    done
    
    # 最終的な更新
    if [ -s "$temp_file" ]; then
        mv "$temp_file" "$config_file"
        log_info "All configuration values updated successfully"
        return 0
    else
        rm -f "$temp_file"
        log_error "Failed to update configuration file"
        return 1
    fi
}


# ログ出力関数
log_message() {
    local message="$1"
    local log_file="${2:-${SCRIPT_DIR}/update.log}"
    local level="${3:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 画面出力
    echo "[$level] $message"
    
    # ログファイル出力
    echo "[$timestamp] [$level] $message" >> "$log_file" 2>/dev/null || {
        echo "Warning: Failed to write to log file: $log_file" >&2
    }
}

# エラーログ関数
log_error() {
    local message="$1"
    local log_file="${2:-${SCRIPT_DIR}/update.log}"
    
    log_message "$message" "$log_file" "ERROR"
}

# 情報ログ関数
log_info() {
    local message="$1"
    local log_file="${2:-${SCRIPT_DIR}/update.log}"
    
    log_message "$message" "$log_file" "INFO"
}

# バージョン比較関数
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # バージョン形式の検証
    if [[ ! "$version1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
       [[ ! "$version2" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format" >&2
        return 2
    fi
    
    # バージョン比較
    if [ "$version1" = "$version2" ]; then
        return 0  # 同じ
    elif [ "$version1" != "$version2" ]; then
        return 1  # 異なる
    fi
}

# URLバリデーション関数
validate_url() {
    local url="$1"
    
    # 空のURLチェック
    if [ -z "$url" ]; then
        echo "Error: URL is empty or not provided" >&2
        return 1
    fi
    
    # 基本的なURL形式チェック（より寛容な正規表現）
    if [[ "$url" =~ ^https?://[a-zA-Z0-9.-]+/.*$ ]]; then
        return 0
    else
        echo "Error: Invalid URL format: '$url'" >&2
        return 1
    fi
}

# ディレクトリ存在確認・作成関数
ensure_directory() {
    local dir_path="$1"
    local create_if_missing="${2:-true}"
    
    if [ -d "$dir_path" ]; then
        return 0
    elif [ "$create_if_missing" = "true" ]; then
        mkdir -p "$dir_path" 2>/dev/null && {
            echo "✅ Created directory: $dir_path"
            return 0
        } || {
            echo "Error: Failed to create directory: $dir_path" >&2
            return 1
        }
    else
        echo "Error: Directory not found: $dir_path" >&2
        return 1
    fi
}

# スクリーンセッション存在確認関数
does_screen_session_exist() {
    local session_name="$1"
    
    if screen -list | grep -q "\\.${session_name}\\s"; then
        return 0  # セッションが存在
    else
        return 1  # セッションが存在しない
    fi
}

# プロセス終了待機関数
wait_for_process_end() {
    local process_name="$1"
    local max_wait="${2:-30}"
    local count=0
    
    while [ $count -lt $max_wait ]; do
        if ! pgrep -f "$process_name" >/dev/null 2>&1; then
            return 0  # プロセス終了
        fi
        sleep 1
        count=$((count + 1))
    done
    
    echo "Warning: Process '$process_name' did not terminate within ${max_wait} seconds" >&2
    return 1
}
