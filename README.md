**openwrt_pangolin**是一个快速部署路由器透明代理（路由器翻墙）的配置集，适用已刷入[OpenWRT/LEDE](https://openwrt.org/)或其他衍生固件的便携和家用路由器。

1. [功能](#features)
2. [原理](#explanation)
    1. [DNS污染](#dns-pollution)
    2. [IP屏蔽/TCP阻断](#ip-blocking)
3. [安装](#installation)
4. [配置说明](#config)
    1. [DNS套件](#dns-related)
    1. [端口转发配置](#port-forwarding)
    1. [工作模式配置（针对便携路由器）](#work-mode)
5. [已测试设备](#tested-devices)
6. [参考](#refs)

<a name="features"></a>
功能
=====

本项目提供的所有功能均为可选配置，根据个人需要拷贝相关配置即可。具体的配置见“配置说明”一节。

* 透明代理：终端无需任何设置即可访问国际互联网。代理工具支持[shadowsocks-libev][ss-libev]和[v2ray][v2ray]。
* 智能分流：国外HTTP/HTTPS流量走代理，国内流量、BT流量直连。
* 多种方式抵御DNS污染。
* 支持家用路由与便携路由，行走各地畅通无阻。

<a name="explanation"></a>
原理
=====

<a name="dns-pollution"></a>
DNS污染
-------

目前GFW的DNS污染只针对使用UDP协议和53端口的服务器，因此对抗污染最简单的办法就是使用支持TCP协议或者非53端口的可信DNS服务器。
但这个方法比较脆弱，有两个原因：

1. 比较知名的公共DNS的大多处于UDP被污染，TCP被阻断的状态。你需要费时费力寻找幸存IP甚至自建DNS服务。
2. 即使解决了污染问题，紧接着就会发现国内多数网站并未对国外DNS做优化，导致访问国内站点比国外还慢的诡异现象。

针对问题1，我们让DNS请求通过代理查询即可解决。当然我们也可以使用`DNScrypt`这类工具提供安全DNS查询。
对于问题2，我们提供了两套方案：

1. 使用[ChinaDNS][chinadns]，它的原理是同时请求境内境外DNS服务器，并根据一个简单假设决定采用哪个结果。  
    优点是方便，速度快且防污染（无需通过代理）。  
    缺陷是境内DNS服务器会收到你的所有域名查询请求。
2. 使用`unbound`作为DNS服务器，通过维护一个国内常用域名列表分流DNS查询。  
    优点是配置灵活，支持自定义结果缓存策略，支持TCP、TLS等多种模式；  
    缺点是DNS解析速度受代理速度影响；而且如果想优化国内域名查询的话，还需要维护一个国内域名列表。听起来不难，毕竟常去的网站就那么几个不是吗？但如果亲自尝试过就知道，真正影响网速体验的其实是提供图片视频加速的海量CDN域名。

为了节省你宝贵的时间做更多有意义的事情，我们推荐使用**方案1**。如果你非常介意隐私，其实可以结合这两个方案：
让`ChinaDNS`作为`unbound`的上游DNS服务，并在`unbound`中维护一个境外域名列表，符合规则的域名查询直接请求境外可信DNS服务器即可。

<a name="ip-blocking"></a>
IP屏蔽/TCP阻断
--------------

对抗手段就是VPN或者应用层代理，把流量通过尚未被屏蔽的IP转发出去。本项目支持两个代理软件：

1. [shadowsocks-libev][ss-libev]：配置简单，体积小巧，功能强大。使用`shadowsocks`协议实现安全数据传输。
2. [v2ray][v2ray]：配置灵活，支持多种协议，并可以灵活搭配，实现协议伪装等需求。
    但配置文件略长，有一定学习门槛，并且软件体积较大（6~10MB），内存占用较多（>10MB）。

除此之外，我们使用`iptables`设置智能分流，只有到国外IP的HTTP/HTTPS流量经过代理。
IP规则用了精简过的国内IP段。如果需要自己生成，可以执行`gen_china_list.sh`生成`chiana.list`，自行精简后拷贝到`/root/config/`。

<a name="installation"></a>
安装
=====

1. 安装基础依赖，通过LuCI页面安装或者`ssh root@192.168.1.1`登录路由器执行命令（假定路由器IP`192.168.1.1`）：

    ``` shell
    opkg update
    opkg install ipset ca-certificates iptables-mod-tproxy unbound dnscrypt-proxy
    ```

    其中`unbound`和`dnscrypt-proxy`视需要选择安装（适用于DNS方案2）。

2. 下载安装代理工具：
    - [shadowsocks-libev][openwrt-ss]：根据路由器CPU架构下载对应的包，在路由器上执行`opkg install ./shadowsocks-libev_VERSION_ARCH.ipk`即可安装。
    - [v2ray][v2ray-release]：根据CPU架构下载对应的包到本地，解压后上传到`/root/v2ray`。如需精简体积，可尝试[自行编译][build-v2ray]。

3. 下载安装[ChinaDNS][chinadns-openwrt]（适用于DNS方案1），建议同时安装[LuCI配置](https://github.com/aa65535/openwrt-dist-luci)，安装方法不再赘述。

3. 配置代理工具：编辑`root/config/shadowsocks.json`或`root/config/v2ray.json`。不建议修改本地端口（默认 **1080**），否则`firewall.user`中也要做出相应修改。

4. 编辑`etc/firewall.user`， **将PROXY_SERVER_IP替换为代理服务器IP**，如有多个使用逗号分隔。

5. （建议）备份路由器配置。ssh登录路由器，备份`/etc`目录：

    ``` shell
    tar -czvf etc.tar.gz /etc
    ```

6. 拷贝需要的配置文件到OpenWRT路由器，注意要用`-p`参数保留文件权限。以下示例删除了便携路由配置，并拷贝其他所有配置到路由器：

    ``` shell
    rm -rf etc/config/network* etc/config/wireless* etc/dnsmasq.conf etc/rc.button root/bin
    scp -rp etc root root@192.168.1.1:/
    ```

7. ssh登录路由器，确保`firewall`, `unbound`, `shadowsocks` / `v2ray`在启动时自动运行：

    ``` shell
    /etc/init.d/firewall enable
    # shadowsocks和v2ray只能启用一个
    /etc/init.d/shadowsocks enable
    /etc/init.d/v2ray enable
    # 以下DNS服务按需启动
    /etc/init.d/chinadns enable
    /etc/init.d/unbound enable
    ```

8. 重启动路由器，可在LuCI页面控制或者登录路由器执行`reboot`。

<a name="config"></a>
配置说明
========

<a name="dns-related"></a>
DNS套件
-------

**<details><summary>方案1</summary>**

1. `etc/config/dhcp`: 设置`dnsmasq`将DNS查询转发到`ChinaDNS`的监听端口（2053）。主要改动如下：
    ``` conf
    option noresolv '1'
    list server '127.0.0.1#2053'
    list server '::1#2053'
    ```
2. `etc/config/chinadns`: `ChinaDNS`相关设置。国内IP段使用了精简IP列表`/root/config/china.list`，可以自行换回默认列表`/etc/chinadns_chnroute.txt`
</details>

**<details><summary>方案2</summary>**

1. `etc/config/dhcp`: 设置`dnsmasq`将DNS查询转发到`unbound`的监听端口（1053）。主要改动如下：
    ``` conf
    option noresolv '1'
    list server '127.0.0.1#1053'
    list server '::1#1053'
    ```
2. unbound相关配置，主要改动如下：
    - `etc/config/unbound`: unbound UCI config, 从LEDE 17.01和OpenWRT 18.06开始提供。
        ``` conf
        option listen_port '1053'   # 设置监听端口1053
        option manual_conf '1'      # 要求加载 /etc/unbound/unbound.conf
        ```

    - `etc/unbound/unbound.conf`: unbound标准配置，为了向后兼容重复了部分设置。
        ``` conf
        server:
            num-threads: 2      # unbound线程数，建议与路由器CPU核数一致
            so-reuseport: yes   # 线程数>1时开启
            port: 1053
            # tcp-upstream: yes   # 可选使用TCP请求
            # 向所有DNS服务器发送edns-client-subnet，优化解析结果
            send-client-subnet: 0.0.0.0/0  # 需要unbound >= 1.6.7

        # 读取china-dns配置，对国内音视频网站使用DNSPod解析
        include: "/etc/unbound/china-dns.conf"

        # 其他域名使用DNScrypt和境外DNS
        forward-zone:
              name: "."
              # DNScrypt upstream
              forward-addr: 127.0.0.1@5353
              # Public DNS servers
              forward-addr: 8.8.8.8
        ```

    - `etc/unbound/china-dns.conf`: 可以自行添加国内域名解析规则。
        ``` conf
        forward-zone:
            name: "qq.com."
            forward-addr: 119.29.29.29
        ```
3. `etc/firewall.user` 需要取消对UDP转发配置的注释。
4. `etc/config/dnscrypt-proxy`: DNScrypt配置，默认监听5353和5454两个端口。如果不使用需要删除`unbound.conf`中的对应转发目的地。
</details>

<a name="port-forwarding"></a>
端口转发配置
------------

1.  `etc/firewall.user`和`root/config/china.list`：设定`iptables`转发规则，做了一点微小的工作：
    1. 创建一个名为"BREAKWALL"的nat和mangle规则，分别用于TCP和UDP转发；
    2. 忽略目的地址为代理服务器的IP数据包；
    3. 创建`ipset`表，设置忽略内网地址和来自`china.list`的国内IP段；
    4. 其他路由到此规则的流量统统转发到**1080**端口
    5. 将该规则应用到所有目标端口为TCP 80和443的局域网流量（HTTP和HTTPS流量），以及目标端口为UDP 53的局域网和路由器自身流量（DNS查询）。

    **注意：** 如果你的转发规则没有生效，检查`/etc/config/firewall`，确保包含如下配置：
    ``` conf
    config include
        option path '/etc/firewall.user' 
    ```
    同时执行`/etc/init.d/firewall restart`查看有没有报错。
2.  `etc/init.d/`包含了代理服务自启动配置；代理配置文件在`root/config/`下。

**Tips:** 如果你需要添加其他DNS，可以在墙外节点用下面的命令测试是否支持TCP查询：
``` shell
dig @8.8.8.8 +tcp twitter.com
```

<a name="work-mode"></a>
工作模式配置（针对便携路由器）
-----------

可以设置三种工作模式，轻触`reset`切换模式：
+ AP模式：用网线接到上级路由出口，比较适合在酒店使用。
+ client模式：使用无线连接到上级路由，适合没有网线不适宜使用AP模式的场合。网速会比AP模式稍慢。
+ router模式：适合需要拨号上网的情况，比如家庭路由器。

子网段设置为`10.10.10.0/24`，不太容易跟上级路由冲突。配置方法如下。

1. `etc/config/network.router`：**填入你从ISP获得的拨号账号与密码**

2. `etc/config/wireless.{ap,router,client}`：更改WIFI SSID和密码，加密模式可以参考[OpenWRT Wiki][wpaencryption]。
    默认为 **穿山甲@[模式]**，密码均为 **88888888**。可以把不同模式下的SSID都设成一样，但是这样会不太方便区分路由器运行在什么模式下。

3. `etc/dnsmasq.conf`：设置DHCP的IP分配范围，从`10.10.10.100`到`10.10.10.150`。

4. `etc/rc.button/reset`：设置`reset`按钮，通过调用`/root/bin/toggle_ap.sh`切换工作模式。

5. `root/bin/`：`toggle_ap.sh`负责切换工作模式；`auto_toggle.sh`可以设置为开启启动脚本，如果当前工作模式为client但扫描不到名为“XXXclient”的无线网时，自动切换工作模式，这样可以确保路由器能够启用无线网络。

<a name="tested-devices"></a>
已测试设备
==========

欢迎提交issue补充更多设备支持信息。

**便携路由**：

OpenWRT 15.05 on:

[Nexx WT3020](https://wiki.openwrt.org/toh/nexx/wt3020), [TP-Link TL-WR703N](https://wiki.openwrt.org/zh-cn/toh/tp-link/tl-wr703n), [Kingston MLWG2](https://wiki.openwrt.org/toh/kingston/mlwg2)

**家用路由**：

OpenWRT 17.01, 18.06 on:

[Linksys WRT1900ACS](https://openwrt.org/toh/linksys/wrt_ac_series#wrt1900acs)

<a name="refs"></a>
参考
====

- [使用iptables透明代理TCP与UDP by 依云's Blog][transparent-proxy]
- [内核透明代理模块TPROXY](https://www.kernel.org/doc/Documentation/networking/tproxy.txt)
- [shadowsocks-libev透明代理设置][ss-tproxy]
- [unbound中不同forward-addr的选择策略][unbound-forward]


[ss-libev]: https://github.com/shadowsocks/shadowsocks-libev
[v2ray]: https://www.v2ray.com/
[v2ray-release]: https://github.com/v2ray/v2ray-core/releases
[build-v2ray]: https://steemit.com/cn/@v2ray/meemg-v2ray
[china-list-gist]: https://gist.github.com/zts1993/dca7c062a520396d3091
[openwrt-ss]: https://github.com/shadowsocks/openwrt-shadowsocks/releases
[ss-tproxy]: https://github.com/shadowsocks/shadowsocks-libev#transparent-proxy
[wpaencryption]: https://openwrt.org/docs/guide-user/network/wifi/basic#wpa_modes<Paste>
[openwrt-netfilter]: https://openwrt.org/docs/guide-user/firewall/netfilter-iptables/netfilter
[unbound-forward]: https://nlnetlabs.nl/pipermail/unbound-users/2018-January/005054.html
[chinadns]: https://github.com/shadowsocks/ChinaDNS
[chinadns-openwrt]: https://github.com/aa65535/openwrt-chinadns
[transparent-proxy]: https://blog.lilydjwg.me/2018/7/16/transparent-proxy-for-tcp-and-udp-with-iptables.213139.html
