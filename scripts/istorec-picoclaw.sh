#!/bin/sh
# iStore 通用钩子：luci-app-picoclaw 提供的应用操作入口。
# PicoClaw 服务由 OpenWrt 的 /etc/init.d/picoclaw 托管，这里只做转发。
ACTION=${1:-status}

case "${ACTION}" in
  install|upgrade)
    /etc/init.d/picoclaw enable >/dev/null 2>&1
    ;;
  start)
    /etc/init.d/picoclaw start
    ;;
  stop)
    /etc/init.d/picoclaw stop
    ;;
  restart)
    /etc/init.d/picoclaw restart
    ;;
  status)
    /etc/init.d/picoclaw status
    ;;
  port)
    echo 18790
    ;;
  rm)
    /etc/init.d/picoclaw stop >/dev/null 2>&1
    /etc/init.d/picoclaw disable >/dev/null 2>&1
    ;;
  *)
    echo "usage: $0 install|upgrade|start|stop|restart|status|port|rm"
    exit 1
    ;;
esac
