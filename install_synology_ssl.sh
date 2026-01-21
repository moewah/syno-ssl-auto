#!/bin/bash

# acme.sh 下载地址
ACME_ARCHIVE_URL="https://gh-proxy.com/github.com/acmesh-official/acme.sh/archive/master.tar.gz"

CONFIG_FILE="./ssl.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "错误: 配置文件 $CONFIG_FILE 不存在"
    exit 1
fi

source "$CONFIG_FILE"

if [ "$EUID" -ne 0 ]; then
    echo "错误: 此脚本需要root权限才能运行"
    echo "请先执行以下命令后重新运行脚本"
    echo "  sudo su "
    exit 1
fi

show_menu() {
    echo ""
    echo "===================================="
    echo "   Synology DSM SSL 证书管理工具"
    echo "===================================="
    echo "1. 自动部署证书"
    echo "2. 启用自动升级"
    echo "3. 关闭自动升级"
    echo "4. 修复损坏环境"
    echo "5. 强制更新证书"
    echo "0. 退出"
    echo "===================================="
}

add_cron_job() {
    if [ ! -f /etc/crontab ]; then
        echo "错误: /etc/crontab 文件不存在"
        return 1
    fi

    if grep -q "/usr/local/share/acme.sh/acme.sh --cron" /etc/crontab; then
        echo "Cron任务已存在，跳过添加"
        return 0
    fi

    local backup_file="/etc/crontab.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/crontab "$backup_file"
    echo "已备份原crontab文件到: $backup_file"

    local cron_entry="0 2 */3 * * root /usr/local/share/acme.sh/acme.sh --cron --home /usr/local/share/acme.sh"

    echo "" >> /etc/crontab
    echo "$cron_entry" >> /etc/crontab

    # 改进验证逻辑：检查最后一行是否匹配，或使用固定字符串搜索
    local last_line=$(tail -1 /etc/crontab)
    if [ "$last_line" = "$cron_entry" ] || grep -F "/usr/local/share/acme.sh/acme.sh --cron" /etc/crontab >/dev/null 2>&1; then
        echo "✅ 已成功添加SSL证书自动续期任务"
        echo "📅 执行时间: 每3天凌晨2点"
        echo "📝 任务内容: $cron_entry"

        # 重启 crond 服务使任务生效
        if command -v systemctl >/dev/null 2>&1; then
            echo "🔄 正在重启 crond 服务..."
            systemctl restart crond
            if [ $? -eq 0 ]; then
                echo "✅ crond 服务重启成功"
            else
                echo "⚠️  crond 服务重启失败，请手动重启系统或 crond 服务"
            fi
        else
            echo "⚠️  系统不支持 systemctl，请手动重启系统或 crond 服务"
        fi
        return 0
    else
        echo "❌ 添加cron任务失败，正在恢复备份..."
        mv "$backup_file" /etc/crontab
        return 1
    fi
}

deploy_certificate() {
    cd ~
    # 检查本地是否有 master.tar.gz，没有则下载
    if [ ! -f "master.tar.gz" ]; then
        echo "本地未找到 master.tar.gz，正在下载..."
        wget "$ACME_ARCHIVE_URL"
    else
        echo "使用本地已下载的 master.tar.gz"
    fi
    tar xvf master.tar.gz
    cd acme.sh-master/

    ./acme.sh --install --nocron --home /usr/local/share/acme.sh --accountemail "$ACME_ACCOUNT_EMAIL"

    cd /usr/local/share/acme.sh

    ./acme.sh --issue --server letsencrypt --home . -d "$CERT_DOMAIN" --dns "$CERT_DNS" --keylength ec-384

    ./acme.sh --deploy --home . -d "$CERT_DOMAIN" --deploy-hook synology_dsm

    echo "✅ 证书申请和部署完成！"

    echo "🔄 正在配置自动续期任务..."
    add_cron_job

    if [ $? -eq 0 ]; then
        echo "🎉 SSL证书配置完成！系统将每3天自动检查并续期证书。"
    else
        echo "⚠️  证书部署成功，但自动续期任务配置失败，请手动配置。"
    fi
}

enable_auto_upgrade() {
    /usr/local/share/acme.sh/acme.sh --upgrade --auto-upgrade
    echo "已启用自动升级"
}

disable_auto_upgrade() {
    /usr/local/share/acme.sh/acme.sh --upgrade --auto-upgrade 0
    echo "已关闭自动升级"
}

fix_broken_environment() {
    # 在 /root/.profile 文件追加 acme.sh 环境配置
    if [ ! -f "/root/.profile" ]; then
        echo "创建 /root/.profile 文件"
        touch /root/.profile
    fi

    # 检查是否已经添加过
    if ! grep -q "/usr/local/share/acme.sh/acme.sh.env" /root/.profile; then
        echo "正在添加 acme.sh 环境配置到 /root/.profile..."
        echo "" >> /root/.profile
        echo "# acme.sh environment" >> /root/.profile
        echo ". "/usr/local/share/acme.sh/acme.sh.env"" >> /root/.profile
        echo "✅ 已添加 acme.sh 环境配置到 /root/.profile"
    else
        echo "acme.sh 环境配置已存在于 /root/.profile 中，跳过添加"
    fi

    # 添加后立即 source 使配置生效
    source /root/.profile
    echo "✅ 已加载 /root/.profile 配置文件"
}

force_renew_certificate() {
    cd /usr/local/share/acme.sh
    ./acme.sh --issue --server letsencrypt --home . -d "$CERT_DOMAIN" --dns "$CERT_DNS" --keylength ec-384 --force
    ./acme.sh --deploy --home . -d "$CERT_DOMAIN" --deploy-hook synology_dsm

    echo "证书强制更新和部署完成！"
}

while true; do
    show_menu
    read -p "请选择操作 [0-5]: " choice

    case $choice in
        1)
            deploy_certificate
            ;;
        2)
            enable_auto_upgrade
            ;;
        3)
            disable_auto_upgrade
            ;;
        4)
            fix_broken_environment
            ;;
        5)
            force_renew_certificate
            ;;
        0)
            echo "退出"
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择"
            ;;
    esac
done
