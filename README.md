# cgi-ubus
OpenWrt [UBUS](https://openwrt.org/docs/techref/ubus) as a CGI program to be used with Lighttpd, BusyBox httpd and Apache HTTPD.

The UBUS over http bridge is implemented as [a plugin for uhttpd](https://git.openwrt.org/?p=project/uhttpd.git;a=blob;f=ubus.c;hb=HEAD).
There is also [nginx-ubus-module](https://github.com/Ansuel/nginx-ubus-module).
For other web servers you may use this CGI adapter.

## BusyBox httpd
Put the script into `/ubus/cgi-bin/` folder:

    mkdir -p /www/ubus/cgi-bin/
    cp ubus.sh /www/ubus/cgi-bin/index.cgi
    chmod +x /www/ubus/cgi-bin/index.cgi

## Lighttpd
You must install mod_cgi:

    opkg lighttpd-mod-cgi

*TBD*
Then create a configuration `/etc/lighttpd/conf.d/99-ubus.conf`:

    cgi.assign := (".cgi" => "")
    url.rewrite = ("^/ubus/$" => "/ubus/cgi-bin/index.cgi")

## Apache HTTPD
*TBD*

   <Directory "/var/www/htdocs/cgit/">
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
