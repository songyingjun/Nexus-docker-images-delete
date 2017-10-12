#!/bin/bash
if [ $# -ne 1 ]
then
    echo "usage: $0 service_name"
    echo "------------------------------------------"
    echo "example: bash $0 api-gateway"
    echo "------------------------------------------"
    exit 0
fi
registry_address="https://xxx.xx.x"
##登录到docker镜像仓库，请替换下面的用户名和密码为可用的用户名密码
docker login $registry_address -u yingjun.song -p "xxxxxxxx" > /dev/null 2>&1
if [ "$?" == "0" ];then
        echo "login docker registry successful"
else
        echo "login docker registry failed"
        exit 1
fi

service=$1

##查询非prod镜像并保存到文件中
docker search --limit 100 ${registry_address}/hapzhishi/${service}|grep -v DESCRIPTION|awk '{print $1}'|awk -F : '{print $NF}'|egrep 'stage.|test.|test2.|dev.|dev2.|content.' > manifest

##调用删除接口，对如上查出来的镜像进行删除,请修改-u后面的用户名密码为可用的用户名密码
cat manifest|while read line
do
    curl -v -u 'yingjun.song:xxxxxxxx' -H 'Accept:application/vnd.docker.distribution.manifest.v2+json' ${registry_address}/v2/hapzhishi/${service}/manifests/$line  > response 2>&1
    digest=`cat response|grep Docker-Content-Digest|awk '{print $NF}'`
    url="${registry_address}/v2/hapzhishi/${service}/manifests/${digest}"
    curl -v -X DELETE -u 'yingjun.song:xxxxxxxx' ${url%$'\r'} > /dev/null 2>&1
    if [ "$?" == "0" ];then
        echo "delete $service/$line successful"
    else
        echo "delete $service/$line failed"
        exit 1
    fi


done
