功能
======

* 路由器有三种工作模式：

    + AP模式下用网线接到上级路由出口，比较适合在酒店使用。
    + client模式下无线连接到上级路由，适合没有网线不适宜使用AP模式的场合。网速会比AP模式稍差。
    + router适合需要拨号上网的情况，比较适合在家使用。

* 三种工作模式用轻触reset切换。
* 三种工作模式下均可以自动科学上网。
* 子网段为`10.10.10.0/24`，不太容易跟上级路由冲突。
* **针对TL-WR703N所定制**，原理适用于其他任何兼容openwrt的路由器，原则上只要各个interface的名字在配置文件中没有对应错误，即可同样使用。

原理
========

这里记录了我在`TL-WR703N`上用部署无痛自动翻墙路由的配置。对于GFW的两种屏蔽方式分别做了如下处理：

**DNS污染**：由于目前GFW的DNS污染完全是针对UDP，所以只需要用pdnsd去查询一个境外未被污染的支持TCP查询的DNS即可。
默认使用南韩电信DNS。因为dnsmaq可以对DNS查询进行缓存，所以我并没有对于国内国外IP分别用不同的DNS，速度上影响不大，
但是配置可以简单很多。

如果你需要换用其他的DNS，请用下面的命令测试是否支持TCP查询：

    dig @8.8.8.8 +tcp twitter.com

**IP屏蔽**：对于IP屏蔽，一般的做法是用VPN或者代理。因为shadowsocks最简单，所以这里用shadowsocks。用iptables对于国内IP
和国外IP分别处理，用了[精简过的瓷器国IP列表][1]。*如果需要自己生成IP列表，可以用`gen_china_list.sh`，并拷贝到/etc*。

安装
========

1. 安装pdnsd、ipset和shadowsocks，pdns/ipset可以直接用`opkg install pdnsd ipset`安装，但是shadowsocks请自行[下载][2]

2. 编辑`etc/shadowsocks.json`，**填入你的shadowsocks的服务器相关信息**，注意如果你更改了本地端口，
那么在`firewall.user`中也要做出相应修改，一般说来你不需要修改本地端口。

3. 编辑`etc/firewall.user`，**填入你的shadowsocksd的服务器IP**

4. （可选）编辑`etc/config/network.router`，**填入你从ISP获得的拨号账号与密码**

5. （可选）编辑`etc/config/wireless.client`，**填入你上级无线路由账号与密码**，加密模式可以参考[这里][3]。

6. （可选）编辑`etc/config/wireless.ap`和`etc/config/wireless.router`，更改WIFI SSID和密码；默认在router模式下SSID为
“**穿山甲**”，在AP模式下为“**游走的穿山甲**”，在client模式下为“**穿山甲_C**”，密码均为**88888888**。你可以把两个SSID都设成一样，但是这样会不太方便区分路由器运行在
什么模式下

7. 拷贝文件到你的openwrt路由器，注意要用`-p`保留文件权限

        scp -rp etc root root@OPENWRT_ADDRESS:/

8. 确保`firewall`,`pdnsd`,`shadowsocks`在启动时自动运行

        /etc/init.d/firewall enable
        /etc/init.d/pdnsd enable
        /etc/init.d/shadowsocks enable

9. 重启动路由器，可以拔电源或者登陆后运行`reboot`。


[1]: https://gist.github.com/zts1993/dca7c062a520396d3091
[2]: http://sourceforge.net/projects/openwrt-dist/files/shadowsocks-libev/
[3]: http://wiki.openwrt.org/doc/uci/wireless#wpaencryption
