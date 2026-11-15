#!/bin/sh
# ============================================
#  luci-app-picoclaw — APK (v3/ADB) Builder
#  适用于 OpenWrt 25.x（apk-tools 3.x 系统）
# ============================================
#
#  用法（把本脚本和仓库放到路由器上，在仓库根目录执行）：
#      sh scripts/build-apk-v3.sh
#
#  可选环境变量：
#      PC_VERSION=1.2.0-r1     包版本
#      PC_ALLOW_UNTRUSTED=1    额外输出未签名安装提示
#
#  产物：
#      luci-app-picoclaw_<version>.apk
#
#  说明：
#    * OpenWrt 25.x 用 apk-tools 3.x，包格式是 v3(ADB)，本脚本走官方 `apk mkpkg`
#    * 25.x 之前的系统（opkg）请用 ipk，格式不同不能用这个脚本
#    * 包体未签名，安装时需要 --allow-untrusted

set -e

# 自检：脚本自身必须是 LF。Windows 上 core.autocrlf=true 会把换行转成 CRLF，
# 那样 sh 会把 `\r` 当命令的一部分，直接失败。这里提前拦下并给出修法。
if ! tr -d '\r' < "$0" | cmp -s - "$0"; then
    echo "错误：$0 含 CRLF 换行，BusyBox ash 无法执行。" >&2
    echo "      请先转换：dos2unix $0   （或在 git 里设置 core.autocrlf=false）" >&2
    exit 1
fi

PKG_NAME="luci-app-picoclaw"
PC_VERSION="${PC_VERSION:-1.2.0-r1}"
PKG_MAINTAINER="GennKann <GennKann@users.noreply.github.com>"
PKG_URL="https://github.com/GennKann/luci-app-picoclaw"

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/${PKG_NAME}-apk-build"
OUT_DIR="$REPO_DIR/dist"

echo "=== luci-app-picoclaw APK (v3) 构建 ==="
echo "仓库:   $REPO_DIR"
echo "版本:   $PC_VERSION"
echo ""

# ---------- 0. 环境检查 ----------
command -v apk >/dev/null 2>&1 || {
    echo "错误：找不到 apk 命令。本脚本只适用于 OpenWrt 25.x（apk-tools 3.x）系统。" >&2
    echo "      25.x 以前的系统用 opkg，请改用 ipk 包。" >&2
    exit 1
}
[ "$(id -u)" = "0" ] || {
    echo "错误：必须用 root 运行（否则包内文件 owner 会写错）。" >&2
    exit 1
}

# ---------- 1. 准备构建根 ----------
echo "=== [1/4] 准备构建根 ==="
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/root"

# 文件清单：源文件 -> 包内路径 : 权限
add_file() {
    src="$1"; dst="$2"; mode="$3"
    if [ ! -f "$src" ]; then
        echo "  缺少源文件: $src" >&2
        exit 1
    fi
    mkdir -p "$BUILD_DIR/root/$(dirname "$dst")"
    # 统一转成 LF：LuCI 的 lua/htm 解析器只吃 LF，CRLF 会报 unfinished string
    tr -d '\r' < "$src" > "$BUILD_DIR/root/$dst"
    chmod "$mode" "$BUILD_DIR/root/$dst"
    echo "  $dst  ($(wc -c < "$BUILD_DIR/root/$dst") B, mode $mode)"
}

add_file "luci/controller/picoclaw.lua" \
         "usr/lib/lua/luci/controller/picoclaw.lua" 644
add_file "luci/view/picoclaw/main.htm" \
         "usr/lib/lua/luci/view/picoclaw/main.htm" 644
add_file "scripts/picoclaw.init" \
         "etc/init.d/picoclaw" 755
for s in openwrt-diagnostics openwrt-backup openwrt-app-installer; do
    add_file "skills/$s/SKILL.md" \
             "usr/lib/lua/luci/picoclaw-skills/$s/SKILL.md" 644
done

# ---------- 2. 隐私与换行扫描 ----------
echo ""
echo "=== [2/4] 隐私与换行扫描 ==="
PROBLEMS=""

scan_file() {
    f="$1"
    # CRLF
    if tr -d '\r' < "$f" | cmp -s - "$f"; then
        :
    else
        PROBLEMS="$PROBLEMS\n  $f: 含 CRLF 换行"
    fi
    # 常见密钥形态
    if grep -qE 'sk-[A-Za-z0-9_-]{20,}' "$f" 2>/dev/null; then
        PROBLEMS="$PROBLEMS\n  $f: 疑似 api key (sk-...)"
    fi
    if grep -qE 'sk-or-v1-[A-Za-z0-9]{20,}' "$f" 2>/dev/null; then
        PROBLEMS="$PROBLEMS\n  $f: 疑似 openrouter key"
    fi
    # 硬编码凭据：api_key = "至少8位"
    if grep -qiE '(api[_-]?key|app[_-]?secret|password|passwd)[[:space:]]*[:=][[:space:]]*"[A-Za-z0-9]{8,}"' "$f" 2>/dev/null; then
        PROBLEMS="$PROBLEMS\n  $f: 疑似硬编码凭据"
    fi
    # 本机路径
    if grep -qE '[A-Za-z]:\\Users\\|/home/[a-z]{3,}/' "$f" 2>/dev/null; then
        PROBLEMS="$PROBLEMS\n  $f: 含本机路径"
    fi
}

for f in $(find "$BUILD_DIR/root" -type f); do
    scan_file "$f"
done

# 自定义拦截串（逗号分隔），用于排除掉你自己知道不该进包的东西
if [ -n "$PC_PRIVACY_EXTRA" ]; then
    OLDIFS="$IFS"
    IFS=','
    for pat in $PC_PRIVACY_EXTRA; do
        [ -z "$pat" ] && continue
        if grep -rqF "$pat" "$BUILD_DIR/root" 2>/dev/null; then
            PROBLEMS="$PROBLEMS\n  命中自定义拦截串: ${pat}"
        fi
    done
    IFS="$OLDIFS"
fi

if [ -n "$PROBLEMS" ]; then
    echo "扫描发现问题，未生成任何包："
    echo -e "$PROBLEMS"
    exit 1
fi
echo "  扫描通过：无密钥、无 CRLF、无本机路径"

# ---------- 3. 生成 post-install ----------
cat > "$BUILD_DIR/post-install" <<'EOF'
#!/bin/sh
# 清理 LuCI 编译缓存，让新页面立即生效
rm -f /tmp/luci-indexcache* 2>/dev/null
rm -rf /tmp/luci-modulecache/* 2>/dev/null
exit 0
EOF
chmod 755 "$BUILD_DIR/post-install"

# ---------- 4. 打包 ----------
echo ""
echo "=== [3/4] apk mkpkg ==="
mkdir -p "$OUT_DIR"
OUT_APK="$OUT_DIR/${PKG_NAME}-${PC_VERSION}.apk"
rm -f "$OUT_APK"

# 注意：
#   * depends 用空格分隔一次给全（多次 -I depends: 是覆盖不是追加）
#   * 必须在 root 下跑，owner 才会是 root
apk mkpkg -F "$BUILD_DIR/root" \
    -I "name:${PKG_NAME}" \
    -I "version:${PC_VERSION}" \
    -I "description:LuCI support for PicoClaw AI gateway (jobs, MCP, skills, models)" \
    -I "arch:noarch" \
    -I "license:MIT" \
    -I "origin:${PKG_NAME}" \
    -I "maintainer:${PKG_MAINTAINER}" \
    -I "url:${PKG_URL}" \
    -I "depends:luci luci-lib-jsonc curl" \
    -s "post-install:$BUILD_DIR/post-install" \
    -o "$OUT_APK" \
    usr etc

echo ""
echo "=== [4/4] 校验 ==="
[ -f "$OUT_APK" ] || { echo "错误：没有生成包" >&2; exit 1; }
ls -la "$OUT_APK"
md5sum "$OUT_APK"

echo ""
echo "包信息："
apk adbdump "$OUT_APK" 2>/dev/null | sed -n '1,14p'

echo ""
echo "=== 完成 ==="
echo "产物: $OUT_APK"
echo ""
echo "安装（OpenWrt 25.x，apk 系统）："
echo "  scp $OUT_APK root@<路由器IP>:/tmp/"
echo "  ssh root@<路由器IP> 'apk add --allow-untrusted /tmp/${PKG_NAME}-${PC_VERSION}.apk'"
echo ""
echo "本包未签名（没有发布密钥），所以必须带 --allow-untrusted。"
