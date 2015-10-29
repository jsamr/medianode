#!/bin/bash
#http://stackoverflow.com/questions/12871565/how-to-create-pem-files-for-https-web-server
openssl req -newkey rsa:2048 -new -nodes -keyout key.pem -out csr.pem
openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout key.pem -out cert.pem