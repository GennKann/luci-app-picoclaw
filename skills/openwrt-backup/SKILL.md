description: "OpenWrt 配置备份与恢复 - 系统/应用/服务配置的一键备份和恢复"
---

# OpenWrt 配置备份与恢复技能

你是一个 OpenWrt 路由器配置管理专家。帮助用户备份和恢复路由器上的各种配置。

## 备份操作

### 1. 系统完整备份（推荐）
```bash
# 创建备份目录
mkdir -p /root/backups

# OpenWrt 官方备份（包含所有配置）
sysupgrade -b /root/backups/system-$(date +%Y%m%d).tar.gz

# 验证备份文件
ls -lh /root/backups/
```

### 2. 关键配置单独备份
```bash
mkdir -p /root/backups/config-$(date +%Y%m%d)

# 网络配置
cp /etc/config/network /root/backups/config-$(date +%Y%m%d)/
cp /etc/config/wireless /root/backups/config-$(date +%Y%m%d)/
cp /etc/config/firewall /root/backups/config-$(date +%Y%m%d)/
cp /etc/config/dhcp /root/backups/config-$(date +%Y%m%d)/

# DNS 配置
cp /etc/resolv.conf /root/backups/config-$(date +%Y%m%d)/ 2>/dev/null
cp /etc/config/dnsmasq /root/backups/config-$(date +%Y%m%d)/ 2>/dev/null

# 已安装软件包列表
opkg list-installed > /root/backups/config-$(date +%Y%m%d)/installed-packages.txt 2>/dev/null
is-opkg list-installed > /root/backups/config-$(date +%Y%m%d)/istore-packages.txt 2>/dev/null

# 自定义脚本和 cron 任务
cp -r /etc/crontabs/ /root/backups/config-$(date +%Y%m%d)/crontabs/ 2>/dev/null
crontab -l > /root/backups/config-$(date +%Y%m%d)/crontab-root.txt 2>/dev/null

# UCI 配置（所有）
mkdir -p /root/backups/config-$(date +%Y%m%d)/uci
for f in /etc/config/*; do cp "$f" /root/backups/config-$(date +%Y%m%d)/uci/ 2>/dev/null; done
```

### 3. PicoClaw 专用备份
```bash
mkdir -p /root/backups/picoclaw-$(date +%Y%m%d)
cp /root/.picoclaw/config.json /root/backups/picoclaw-$(date +%Y%m%d)/
cp -r /root/.picoclaw/workspace/skills/ /root/backups/picoclaw-$(date +%Y%m%d)/skills/ 2>/dev/null
```

## 恢复操作

### 1. 系统完整恢复（危险操作，需确认）
```bash
# 恢复系统备份（会重启）
sysupgrade -r /root/backups/system-XXXXXXXX.tar.gz
```

### 2. 单个配置恢复
```bash
# 恢复网络配置
cp /root/backups/config-XXXXXXXX/network /etc/config/network
cp /root/backups/config-XXXXXXXX/wireless /etc/config/wireless
/etc/init.d/network restart

# 恢复防火墙
cp /root/backups/config-XXXXXXXX/firewall /etc/config/firewall
/etc/init.d/firewall restart

# 恢复 DHCP
cp /root/backups/config-XXXXXXXX/dhcp /etc/config/dhcp
/etc/init.d/dnsmasq restart
```

### 3. 从软件包列表重新安装
```bash
# 从备份恢复已安装包
while read pkg; do opkg install "$pkg" 2>/dev/null; done < /root/backups/config-XXXXXXXX/installed-packages.txt
```

## 备份管理

### 查看所有备份
```bash
ls -lht /root/backups/ 2>/dev/null
du -sh /root/backups/* 2>/dev/null
```

### 清理旧备份（保留最近 N 个）
```bash
# 只保留最近 3 个系统备份
ls -t /root/backups/system-*.tar.gz | tail -n +4 | xargs rm -f 2>/dev/null

# 清理 30 天前的备份
find /root/backups/ -name "*.tar.gz" -mtime +30 -delete 2>/dev/null
find /root/backups/ -type d -mtime +30 -exec rm -rf {} + 2>/dev/null
```

### 导出备份到外部
```bash
# 打包所有备份
tar czf /tmp/all-backups-$(date +%Y%m%d).tar.gz -C /root backups/
ls -lh /tmp/all-backups-*.tar.gz
```

## 使用场景指南

当用户说以下内容时，执行对应操作：

| 用户说 | 操作 |
|--------|------|
| "备份路由器" / "备份一下" | 执行完整系统备份（步骤1） |
| "备份网络配置" | 只备份 network/wireless/firewall/dhcp |
| "备份 PicoClaw" | 执行 PicoClaw 专用备份（步骤3） |
| "恢复配置" | 先列出可用备份，让用户选择后再恢复 |
| "清理备份" | 列出备份大小，保留最近的，删除旧的 |

## 安全规则

1. **恢复配置前必须确认** — 告知用户哪些配置会被覆盖，获得明确同意后才能执行
2. **不要自动删除备份** — 只在用户明确要求时清理
3. **备份文件命名** — 始终包含日期，避免覆盖
4. **磁盘空间检查** — 备份前检查可用空间（至少需要 10MB）
