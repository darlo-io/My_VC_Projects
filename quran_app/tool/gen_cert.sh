#!/bin/bash
cd /f/My_VC_Projects/quran_app
openssl req -x509 -newkey rsa:2048 \
  -keyout tool/certs/server.key \
  -out tool/certs/server.crt \
  -days 365 -nodes \
  -config tool/certs/openssl.cnf 2>&1 | tail -2
echo "---"
openssl x509 -in tool/certs/server.crt -noout -text 2>/dev/null | grep -A6 'Subject Alt'
