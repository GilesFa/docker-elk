#!/bin/bash
#------------------------安裝交互自動工具----------------------------#
yum install tcl expect -y
#------------------------git clone elk repo-------------------------#
#偵測/root目錄下是否有docker-elk目錄，若沒有則進行git clone 下載
if [ -d "/root/docker-elk" ]; then
    # 目錄/root/docker-elk 存在
    echo "/root/docker-elk exists."
else
    # 目錄 /root/docker-elk 不存在
    echo "/root/docker-elk not exists."
    git clone https://github.com/GilesFa/docker-elk.git
fi
#------------------------環境設定-------------------------#
#停用swap
swapoff -a
sed -i '/swap/d' /etc/fstab #刪除swap
#調整kernel參數
echo "vm.swappiness=1" | tee -a /etc/sysctl.conf
echo "vm.max_map_count = 262144"| tee -a /etc/sysctl.conf
#套用Kernel參數
sysctl -p
#調整使用者檔案限制，檔案/etc/security/limits.conf
echo "* soft nofile 65535" | tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | tee -a /etc/security/limits.conf
echo "* soft memlock unlimited" | tee -a /etc/security/limits.conf
echo "* hard memlock unlimited" | tee -a /etc/security/limits.conf
echo "* soft nofile 65535" | tee -a /etc/security/limits.conf
#-----------------------啟動docker-compose-------------------------#
#取得.env檔案內的ELASTIC_PASSWORD變數
ELASTIC_PASSWORD=`cat /root/docker-elk/.env |grep ELASTIC | awk -F '=' '{print $2}'`
ELASTIC_PASSWORD=${ELASTIC_PASSWORD}
docker-compose -f /root/docker-elk/docker-compose-nossl.yml up -d
echo "watting 120 seconds for elasticsearch cluster ready..."
/usr/bin/sleep 120
echo "check elasticsearch cluster status..."
curl http://elastic:${ELASTIC_PASSWORD}@127.0.0.1:9200
curl http://elastic:${ELASTIC_PASSWORD}@127.0.0.1:9200/_cat/nodes
#------------------------設定cluster認證-------------------------#
#產生elastic-stack-ca.p12
#docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-certutil ca
#這邊會出現互動式程序，直接按兩次enter
/usr/bin/expect <<EOF
    spawn docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-certutil ca
    expect {
            "Please*" { send "\r"; exp_continue }
            "Enter*" { send "\r" }
    }
    expect eof
EOF

/usr/bin/sleep 3

#利用elastic-stack-ca.p12產生ssl憑證elastic-certificates.p12
#docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-certutil cert -ca /usr/share/elasticsearch/elastic-stack-ca.p12
#這邊會出現互動式程序，直接按3次enter
# Enter password for CA (/usr/share/elasticsearch/elastic-stack-ca.p12) : 
# Please enter the desired output file [elastic-certificates.p12]: 
# Enter password for elastic-certificates.p12 : 
/usr/bin/expect <<EOF
    spawn docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-certutil cert -ca /usr/share/elasticsearch/elastic-stack-ca.p12
    expect {
            "Enter*" { send "\r"; exp_continue }
            "Please*" { send "\r"; exp_continue}
            "Enter*" { send "\r"}            
    }
    expect eof
EOF

/usr/bin/sleep 3

#將ca憑證複製到本地
docker cp es01:usr/share/elasticsearch/elastic-certificates.p12 /root/docker-elk/

#複製ca到每個節點
docker cp /root/docker-elk/elastic-certificates.p12 es01:usr/share/elasticsearch/config/
docker cp /root/docker-elk/elastic-certificates.p12 es02:usr/share/elasticsearch/config/
docker cp /root/docker-elk/elastic-certificates.p12 es03:usr/share/elasticsearch/config/

#修改憑證與keystore權限
docker exec -it es01 chown elasticsearch:root /usr/share/elasticsearch/config/elastic-certificates.p12
docker exec -it es01 chmod 660 /usr/share/elasticsearch/config/elastic-certificates.p12
docker exec -it es01 chown elasticsearch:root /usr/share/elasticsearch/config/elasticsearch.keystore

docker exec -it es02 chown elasticsearch:root /usr/share/elasticsearch/config/elastic-certificates.p12
docker exec -it es02 chmod 660 /usr/share/elasticsearch/config/elastic-certificates.p12
docker exec -it es02 chown elasticsearch:root /usr/share/elasticsearch/config/elasticsearch.keystore

docker exec -it es03 chown elasticsearch:root /usr/share/elasticsearch/config/elastic-certificates.p12
docker exec -it es03 chmod 660 /usr/share/elasticsearch/config/elastic-certificates.p12
docker exec -it es03 chown elasticsearch:root /usr/share/elasticsearch/config/elasticsearch.keystore

/usr/bin/sleep 10

#------------------------設定cluster密碼-------------------------#
#docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

#這邊會出現互動式程序，按一次y，然後輸入12次密碼
#Please confirm that you would like to continue [y/N]
# Enter password for [elastic]: 
# Reenter password for [elastic]: 
# Enter password for [apm_system]: 
# Reenter password for [apm_system]: 
# Enter password for [kibana_system]: 
# Reenter password for [kibana_system]: 
# Enter password for [logstash_system]: 
# Reenter password for [logstash_system]: 
# Enter password for [beats_system]: 
# Reenter password for [beats_system]: 
# Enter password for [remote_monitoring_user]: 
# Reenter password for [remote_monitoring_user]:
/usr/bin/expect <<EOF
    spawn docker exec -it es01 /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive
    expect {
            "Please*" { send "y\r"; exp_continue }
            "Enter*" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Reenter*]:" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Enter*" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Reenter*]:" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Enter*" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Reenter*]:" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Enter*" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Reenter*]:" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Enter*" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Reenter*]:" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Enter*" { send "${ELASTIC_PASSWORD}\r"; exp_continue}
            "Reenter*]:" { send "${ELASTIC_PASSWORD}\r"}
    }
    expect eof
EOF

#------------------------再次檢查叢集狀態-------------------------#
echo "watting for 5 seconds..."
/usr/bin/sleep 5
curl http://elastic:${ELASTIC_PASSWORD}@127.0.0.1:9200
curl http://elastic:${ELASTIC_PASSWORD}@127.0.0.1:9200/_cat/nodes

#-----------------------啟動有ssl設定的docker-compose-------------------------
docker-compose -f  /root/docker-elk/docker-compose-nossl.yml down
docker-compose -f /root/docker-elk/docker-compose-ssl.yml up -d
echo "watting 90 seconds for elasticsearch cluster ready..."
/usr/bin/sleep 90
#------------------------再次檢查叢集狀態-------------------------#
curl http://elastic:${ELASTIC_PASSWORD}@127.0.0.1:9200
curl http://elastic:${ELASTIC_PASSWORD}@127.0.0.1:9200/_cat/nodes
