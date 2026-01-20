# syno-ssl-auto
## Synology DSM SSL 证书自动化配置脚本

为 Synology DSM 7.x 提供的一键式 SSL 证书自动化配置工具，支持 Let's Encrypt 免费证书申请与自动续期。

## ✨ 功能特性

- 🔒 **一键部署**: 自动申请并部署 SSL 证书到 Synology DSM
- 🔄 **自动续期**: 每3天自动检查并续期证书
- 🌐 **多 DNS 支持**: 支持 Cloudflare、HE.NET 等多种 DNS 服务商
- 🛠️ **环境修复**: 一键修复损坏的 acme.sh 环境
- ⚡ **强制更新**: 支持手动强制更新证书
- 📧 **邮件通知**: 证书到期前自动发送提醒邮件

## 📋 系统要求

- Synology DSM 7.x
- Root 权限（需要 sudo）
- 已有域名并配置 DNS
- 可访问公网（用于申请 Let's Encrypt 证书）

## 🚀 快速开始

### 1. 下载脚本

```bash
cd ~/Desktop/syno-ssl-auto
```

### 2. 配置 ssl.conf

编辑 `ssl.conf` 文件，填写必要的信息：

```bash
nano ssl.conf
```

配置项说明：

| 配置项 | 说明 | 示例 |
|--------|------|------|
| `ACME_ACCOUNT_EMAIL` | 账户邮箱（接收证书过期通知） | `abc@qq.com` |
| `CERT_DNS` | DNS 服务类型 | `dns_he` 或 `dns_cf` |
| `CERT_DOMAIN` | Synology DSM 域名 | `domain.com` |
| `SYNO_USERNAME` | DSM 管理员账号 | `admin` |
| `SYNO_PASSWORD` | DSM 管理员密码 | `yourpassword` |

### 3. 配置 DNS 服务商

#### 使用 HE.NET

```bash
export CERT_DNS="dns_he"
export HE_Username="HE.NET账号"
export HE_Password="HE.NET密码"
```

#### 使用 Cloudflare

```bash
export CERT_DNS="dns_cf"
export CF_Token="MY_SECRET_TOKEN_SUCH_SECRET"
export CF_Email="myemail@example.com"
```

**更多 DNS 服务商配置请参考**: [acme.sh DNS API 文档](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)

### 4. 运行脚本

```bash
sudo su
bash install_synology_ssl.sh
```

## 📖 使用说明

脚本提供交互式菜单，请根据需求选择操作：

```
====================================
   Synology DSM SSL 证书管理工具
====================================
1. 自动部署证书
2. 启用自动升级
3. 关闭自动升级
4. 修复损坏环境
5. 强制更新证书
0. 退出
====================================
```

### 菜单功能说明

1. **自动部署证书**: 首次使用，自动申请证书并部署到 DSM
2. **启用自动升级**: 启用 acme.sh 自动更新功能
3. **关闭自动升级**: 关闭 acme.sh 自动更新功能
4. **修复损坏环境**: 修复 acme.sh 安装损坏的问题
5. **强制更新证书**: 手动强制重新申请并部署证书

## 🔧 工作原理

1. **证书申请**: 使用 acme.sh 通过 DNS 验证申请 Let's Encrypt 证书
2. **证书部署**: 自动将证书部署到 Synology DSM 系统
3. **自动续期**: 添加 cron 任务，每3天凌晨2点自动检查并续期证书
4. **邮件通知**: 证书到期前发送提醒邮件到配置的邮箱

## 📝 Cron 任务详情

自动续期任务会在 `/etc/crontab` 中添加以下条目：

```cron
0 2 */3 * * root /usr/local/share/acme.sh/acme.sh --cron --home /usr/local/share/acme.sh
```

- **执行时间**: 每3天凌晨2点
- **任务内容**: 检查证书有效期，如需续期则自动续期
- **自动备份**: 添加任务前会自动备份原 crontab 文件

## ⚠️ 注意事项

1. **首次部署**: 首次使用必须选择选项「1. 自动部署证书」
2. **DNS 配置**: 确保 DNS 配置正确，否则证书申请会失败
3. **域名解析**: 确保域名已正确解析到你的 Synology NAS 公网 IP
4. **端口开放**: 确保 80/443 端口可访问（虽然使用 DNS 验证，但某些情况需要）
5. **备份建议**: 建议在修改系统配置前先备份重要数据
6. **密码安全**: 请妥善保管 `ssl.conf` 中的敏感信息，不要泄露

## 🔍 故障排查

### 证书申请失败

1. 检查 DNS 配置是否正确
2. 确认域名已正确解析
3. 检查 acme.sh 日志：`/usr/local/share/acme.sh/acme.sh --home /usr/local/share/acme.sh --list`

### 自动续期不工作

1. 检查 cron 任务是否添加：`cat /etc/crontab`
2. 手动测试续期：运行选项「5. 强制更新证书」
3. 查看系统日志检查错误

### 环境损坏

运行选项「4. 修复损坏环境」来重置 acme.sh 安装

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🙏 致谢

- [acme.sh](https://github.com/acmesh-official/acme.sh) - 让 SSL 证书申请变得简单
- [Let's Encrypt](https://letsencrypt.org/) - 提供免费 SSL 证书

## ☕ 赞赏/捐赠

如果这个项目对你有帮助，欢迎请我喝杯咖啡：

### 微信支付

<img src="images/wechat.png" alt="微信支付" width="200">



