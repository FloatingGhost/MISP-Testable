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

cd /
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
          
