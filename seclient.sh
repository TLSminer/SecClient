#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

installPath=/opt/seclient
updatePath=${installPath}/update
serviceName=seclient
serverProg=seclient

check_os() {
    if [[ -f /etc/redhat-release ]]; then
        os="centos"
    elif [[ -f /etc/openwrt_release ]]; then
        os="openwrt"
    elif cat /etc/issue | grep -Eqi "debian"; then
        os="debian"
    elif cat /etc/issue | grep -Eqi "ubuntu"; then
        os="ubuntu"
    elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
        os="centos"
    elif cat /proc/version | grep -Eqi "debian"; then
        os="debian"
    elif cat /proc/version | grep -Eqi "ubuntu"; then
        os="ubuntu"
    elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
        os="centos"
    fi
}

create_service4comm() {
# Service
cat > /lib/systemd/system/${serviceName}.service << EOT
[Unit]
Description=${serviceName}
[Service]
Type=simple
WorkingDirectory=${installPath}
Environment=HOME=${installPath}
ExecStart=${installPath}/${serviceName}
SyslogIdentifier=${serviceName}
StandardOutput=null
Restart=always
RestartSec=3
TimeoutSec=300
LimitCORE=infinity
LimitNOFILE=655360
LimitNPROC=655360
[Install]
WantedBy=multi-user.target
EOT

cat > /etc/rsyslog.d/${serviceName}.conf << EOT
if \$programname == '${serviceName}' then /var/log/${serviceName}.log
& stop
EOT

systemctl restart rsyslog > /dev/null 2>&1 &
systemctl daemon-reload
systemctl enable ${serviceName}
}

create_service4openwrt() {
# Service
cat > /etc/init.d/${serviceName} << EOT
#!/bin/sh /etc/rc.common

START=90
USE_PROCD=1

PROG=${installPath}/${serviceName}

start_service() {
    procd_open_instance
    procd_set_param command \$PROG
    procd_set_param respawn
    procd_close_instance
}
EOT

chmod +x /etc/init.d/${serviceName}
/etc/init.d/${serviceName} enable
}

create_service() {
    check_os
    case $os in
        'openwrt')
            create_service4openwrt
            ;;
        *)
            create_service4comm
            ;;
    esac 
}

start_service4comm() {
    systemctl enable ${serviceName}
    systemctl restart  ${serviceName}

    if systemctl is-active ${serviceName} &>/dev/null ;then
        echo -e "[${green}成功${plain}] 安装成功！"
        echo -e "注意                    ：${yellow} 如果防火墙打开着，请关闭或添加端口访问权限 ${plain}"
    else
        echo -e "[${red}错误${plain}] ${SERVCIE_NAME} 启动失败"
    fi
}

start_service4openwrt() {
    /etc/init.d/${serviceName} start
    if /etc/init.d/${serviceName} running &>/dev/null ;then
        echo -e "[${green}成功${plain}] 安装成功！"
        echo -e "注意                    ：${yellow} 如果防火墙打开着，请关闭或添加端口访问权限 ${plain}"
    else
        echo -e "[${red}错误${plain}] ${SERVCIE_NAME} 启动失败"
    fi
}

start_service() {
    check_os
    case $os in
        'openwrt')
            start_service4openwrt
            ;;
        *)
            start_service4comm
            ;;
    esac 
}

install_tools() {
    check_os
    case $os in
        'ubuntu'|'debian')
            apt-get -y update
            apt-get -y install wget
            ;;
        'centos')
            yum install -y wget
            ;;
        'openwrt')
            opkg update
            opkg install wget
            ;;
    esac
}

install_depends() {
    if [ -e "${installPath}/certs" ] && [ -e "${installPath}/proxy_config.yaml1" ]; then
        return
    fi

    if [ -x ${updatePath} ]; then
        rm -rf ${updatePath}
    fi

    mkdir -p ${updatePath}

    cd ${updatePath}

    wget --no-check-certificate https://github.com/TLSminer/SecClient/raw/main/certs.tgz
    if [ $? -ne 0 ]; then
        exit -1;
    fi

    tar -xvzf certs.tgz
    if [ $? -ne 0 ]; then
        exit -1;
    fi

    wget --no-check-certificate https://raw.githubusercontent.com/TLSminer/SecClient/main/proxy_config.yaml1
    if [ $? -ne 0 ]; then
        exit -1;
    fi


    cd ${installPath}
    if [ ! -e certs ]; then
        mv "${updatePath}/certs" ./
    fi

    if [ ! -e proxy_config.yaml1 ]; then
        mv "${updatePath}/proxy_config.yaml1" ./
    fi
}

install_server() {
    install_depends

    if [ -x ${updatePath} ]; then
        rm -rf ${updatePath}
    fi
    mkdir -p ${updatePath}

    cd ${updatePath}
    wget --no-check-certificate https://github.com/TLSminer/SecClient/raw/main/seclient
    if [ $? -ne 0 ]; then
        exit -1;
    fi
    chmod +x seclient
    
    wget --no-check-certificate https://raw.githubusercontent.com/TLSminer/SecClient/main/version
        if [ $? -ne 0 ]; then
        exit -1;
    fi

    if [ -f "${installPath}/seclient.bak" ]; then
        rm -rf "${installPath}/seclient.bak"
        rm -rf "${installPath}/version.bak"
    fi
    if [ -f "${installPath}/seclient" ]; then
        mv "${installPath}/seclient" "${installPath}/seclient.bak"
        mv "${installPath}/version" "${installPath}/version.bak"
    fi
    
    mv "${updatePath}/seclient" "${installPath}/seclient"
    mv "${updatePath}/version" "${installPath}/version"

    create_service
}

update_server() {
    if [ -x ${updatePath} ]; then
        rm -rf ${updatePath}
    fi

    mkdir -p ${updatePath}

    cd ${updatePath}
       wget --no-check-certificate https://raw.githubusercontent.com/TLSminer/SecClient/main/version
    if [ $? -ne 0 ]; then
        exit -1;
    fi

    newVersion=$(cat ${updatePath}/version)
    oldVersion=$(cat ${installPath}/version)
    if [ "${newVersion}" == "${oldVersion}" ]; then
        echo -e "[${green}提示${plain}] 已经是最新版本了，不需要升级"
        exit 0
    fi

    install_server
}

uninstall_server4comm() {
    systemctl stop ${serviceName}
    systemctl disable ${serviceName}
    rm -rf /lib/systemd/system/${serviceName}.service
    rm -rf /etc/rsyslog.d/${serviceName}.conf
    rm -rf /usr/lib/systemd/system/${serviceName}.service
    systemctl restart rsyslog > /dev/null 2>&1 &
    systemctl daemon-reload
    rm -rf ${installPath}
}

uninstall_server4openwrt() {
    /etc/init.d/${serviceName} disable
    /etc/init.d/${serviceName} stop
    rm -rf /etc/init.d/${serviceName}
    rm -rf ${installPath}
}

uninstall_server() {
    check_os
    case $os in
        'openwrt')
            uninstall_server4openwrt
            ;;
        *)
            uninstall_server4comm
            ;;
    esac
}

check_server4comm() {
    if systemctl is-active ${serviceName} &>/dev/null ;then
        echo -e "[${green}提示${plain}] 服务运行中..."
    else
        echo -e "[${red}错误${plain}] 服务已停止"
    fi
}

check_server4openwrt() {
    if [[ ! -f /etc/init.d/${serviceName} ]]; then
        echo -e "[${red}错误${plain}] 没安装服务"

        return
    fi

    if /etc/init.d/${serviceName} running &>/dev/null ;then
        echo -e "[${green}提示${plain}] 服务运行中..."
    else
        echo -e "[${red}错误${plain}] 服务已停止"
    fi
}

check_server() {
    check_os
    case $os in
        'openwrt')
            check_server4openwrt
            ;;
        *)
            check_server4comm
            ;;
    esac
}



if [ "$EUID" -ne 0 ]; then
    echo -e "[${red}错误${plain}] 必需以root身份运行，请使用sudo命令"
    exit 1;
fi

install_tools

ops=( '安装或重新安装服务' '升级服务' '检测服务状态' '启动服务' '卸载服务' '退出' )
PS3="请输入操作的序号: "
select op in ${ops[@]}; do
    case ${op} in
    '安装或重新安装服务')
        install_server

        exit 0
    ;;
    '升级服务')
        update_server

        exit 0
    ;;
    '检测服务状态')
        check_server

        exit 0
    ;;
    '启动服务')
        start_service
        exit 0
    ;;
    '卸载服务')
        uninstall_server
        echo -e "[${green}提示${plain}] 服务已经卸载完毕"
        exit 0
    ;;
    '退出')
        exit 0
    ;;
    *)
        echo "请输入正确的序号"
   esac
done
