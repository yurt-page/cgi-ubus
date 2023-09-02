# cgi-ubus
OpenWrt [UBUS](https://openwrt.org/docs/techref/ubus) as a CGI program to be used with Lighttpd, BusyBox httpd and Apache HTTPD.

The UBUS over http bridge is implemented as [a plugin for uhttpd](https://git.openwrt.org/?p=project/uhttpd.git;a=blob;f=ubus.c;hb=HEAD).
There is also [nginx-ubus-module](https://github.com/Ansuel/nginx-ubus-module).
For other web servers you may use this CGI adapter.

## Install
Upload to router:

    scp -O ubus.sh root@192.168.1.1:/www/cgi-bin/ubus.sh

Now enable the script as a UBUS path for Luci:

    chmod +x /www/cgi-bin/ubus.sh
    uci set luci.main.ubuspath='/cgi-bin/ubus.sh'
    uci commit
    reboot

Yes, the reboot is required to evict cache.

## BusyBox httpd

The BB httpd needs to be compiled with CGI support.
See BUSYBOX_CONFIG_FEATURE_HTTPD_CGI

## Lighttpd
You must install mod_cgi:

    opkg lighttpd-mod-cgi

*TBD*
Then create a configuration `/etc/lighttpd/conf.d/99-ubus.conf`:

    cgi.assign := (".sh" => "/bin/sh")

## Apache HTTPD
*TBD*

   <Directory "/var/www/htdocs/">
        AllowOverride None
        Options +ExecCGI
        Order allow,deny
        Allow from all
    </Directory>


## Author
Jo-Philipp Wich

See a discussion https://forum.openwrt.org/t/lighttpd-and-ubus-over-json-rpc/117582

## License
[0BDSD](https://opensource.org/licenses/0BSD) (similar to Public Domain)
