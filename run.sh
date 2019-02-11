#!/bin/bash
#
# MISP docker startup script
# Xavier Mertens <xavier@rootshell.be>
#
# 2017/05/17 - Created
# 2017/05/31 - Fixed small errors
#

set -e
# Start supervisord
service mysql start
mysql -u root --password=misp misp < /edit_apikey.sql

intial_login() { sleep 5; curl --header "Content-type: application/json" --header "Accept: application/json" --header "Authorization: testmispapikeytestmispapikeytestmispapik" -D- http://127.0.0.1/users/login --data-binary '{"User": {"username": "admin@admin.test", "password": "test"}}'
}

intial_login &

cd /
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
          
