#!/bin/sh
/bin/bind_exporter --bind.stats-url=http://10.10.10.1:8053 --web.listen-address=:9121 --bind.stats-groups=server,view,tasks &
/bin/bind_exporter --bind.stats-url=http://10.10.10.2:8053 --web.listen-address=:9122 --bind.stats-groups=server,view,tasks &
