#!/bin/bash

######################################
#       Lancement de minikube        #
######################################

printf "\e[38;5;196mDeleting minikube cluster...\n\e[0m"
minikube delete 
printf "\e[38;5;196mChecking minikube update...\n\e[0m"
if [ `minikube update-check | sed -e '2d' | sed -e 's/CurrentVersion: //'` != `minikube update-check | sed -e '1d' | sed -e 's/LatestVersion: //'` ]
then
printf "\e[38;5;196mUpdating minikube...\n\e[0m"
sudo rm -rf /usr/local/bin/minikube
sudo curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 
sudo chmod +x minikube 
sudo cp minikube /usr/local/bin/
sudo rm minikube
else
printf "\e[38;5;196mMinikube is already up to date !\n\e[0m"
fi
# > /dev/null
printf "\e[38;5;196mCreating minikube cluster...\n\e[0m"
minikube start --memory=2000mb --vm-driver=docker
minikube addons enable ingress
minikube addons enable dashboard
minikube addons enable metrics-server

printf '\e[38;5;196mEnabled Addons...\n\e[0m'
minikube addons list | grep STATUS && minikube addons list | grep enabled

# > /dev/null
#minikube start --vm-driver=virtualbox

#        snap install minikube
#        brew install minikube

######################################
#  Assignation de l'ip de minikube   #
######################################

#export MINI=$(minikube ip)
export MINI=$(minikube ip | grep -oE "\b([0-9]{1,3}\.){3}\b")20

cp srcs/metallb/metallb-conf-copy.yaml srcs/metallb/metallb-conf.yaml
sed -i "s/MYIP/$MINI/g" ./srcs/metallb/metallb-conf.yaml

#cp srcs/mysql/srcs/wordpress-copy.sql srcs/mysql/srcs/wordpress.sql
#sed -i "s/MYIP/$MINI/g" ./srcs/mysql/srcs/wordpress.sql

cp srcs/nginx/nginx-copy.conf srcs/nginx/nginx.conf
sed -i "s/MYIP/$MINI/g" ./srcs/nginx/nginx.conf

cp srcs/ftps/vsftpd-copy.conf srcs/ftps/vsftpd.conf
sed -i "s/MYIP/$MINI/g" srcs/ftps/vsftpd.conf

cp srcs/nginx/index_nginx_copy.html srcs/nginx/index_nginx.html
sed -i "s/MYIP/$MINI/g" srcs/nginx/index_nginx.html

######################################
# Configure metallb as load-balancer #
######################################

printf "\e[93m[1/9] Building metallb...\e[0m\n"
minikube addons enable metallb > /dev/null

kubectl apply -f srcs/metallb/metallb-conf.yaml  > /dev/null

######################################
#            Docker Build            #
######################################
sleep 10
# let enough time to let the cluster start
eval $(minikube docker-env)

printf "\e[93m[2/9] Building Nginx...\e[0m\n"
docker build -t my_nginx srcs/nginx/ > /dev/null
printf "\e[93m[3/9] Building mySQL...\e[0m\n"
docker build -t my_mysql srcs/mysql/ > /dev/null
printf "\e[93m[4/9] Building WordPress...\e[0m\n"
docker build -t my_wordpress srcs/wordpress/ > /dev/null
printf "\e[93m[5/9] Building phpMyAdmin...\e[0m\n"
docker build -t my_phpmyadmin srcs/phpmyadmin/ > /dev/null
printf "\e[93m[6/9] Building Influxdb...\e[0m\n"
docker build -t my_influxdb srcs/influxdb/ > /dev/null
printf "\e[93m[7/9] Building Telegraf...\e[0m\n"
docker build -t my_telegraf srcs/telegraf/ > /dev/null
printf "\e[93m[8/9] Building Grafana...\e[0m\n"
docker build -t my_grafana srcs/grafana/ > /dev/null
printf "\e[93m[9/9] Building FTPs...\e[0m\n"
docker build -t my_ftps srcs/ftps/ > /dev/null

eval $(minikube docker-env --unset)

######################################
#          Config YAML               #
######################################

printf "\e[34m[1/8] Deployement NGINX...\e[0m\n"
kubectl apply -f srcs/nginx/nginx-deployment.yaml > /dev/null
printf "\e[34m[2/8] Deployement mySQL...\e[0m\n"
kubectl apply -f srcs/mysql/my_mysql.yaml > /dev/null
printf "\e[34m[3/8] Deployement WORDPRESS...\e[0m\n"
kubectl apply -f srcs/wordpress/my_wordpress.yaml > /dev/null
printf "\e[34m[4/8] Deployement PHPMYADMIN...\e[0m\n"
kubectl apply -f srcs/phpmyadmin/my_phpmyadmin.yaml > /dev/null
printf "\e[34m[5/8] Deployement INFLUXDB...\e[0m\n"
kubectl apply -f srcs/influxdb/influxdb_pod.yaml > /dev/null
printf "\e[34m[6/8] Deployement TELEGRAF...\e[0m\n"
kubectl apply -f srcs/telegraf/telegraf_pod.yaml > /dev/null
printf "\e[34m[7/8] Deployement GRAFANA...\e[0m\n"
kubectl apply -f srcs/grafana/grafana_pod.yaml > /dev/null
printf "\e[34m[8/8] Deployement FTPS...\e[0m\n"
kubectl apply -f srcs/ftps/ftps_pod.yaml > /dev/null

###
printf "\n\n
\e[38;5;196m███████╗████████╗     ███████╗███████╗██████╗ ██╗   ██╗██╗ ██████╗███████╗███████╗
\e[38;5;208m██╔════╝╚══██╔══╝     ██╔════╝██╔════╝██╔══██╗██║   ██║██║██╔════╝██╔════╝██╔════╝
\e[38;5;226m█████╗     ██║        ███████╗█████╗  ██████╔╝██║   ██║██║██║     █████╗  ███████╗
\e[38;5;118m██╔══╝     ██║        ╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██║██║     ██╔══╝  ╚════██║
\e[38;5;87m██║        ██║███████╗███████║███████╗██║  ██║ ╚████╔╝ ██║╚██████╗███████╗███████║
\e[38;5;164m╚═╝        ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚═╝ ╚═════╝╚══════╝╚══════╝\e[0m
                                                                                  \n\n"
######################################
#         Minikube Dashboard         #
######################################

xdg-open http://$MINI:80
minikube dashboard