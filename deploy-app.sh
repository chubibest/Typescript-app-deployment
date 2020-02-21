#!/bin/bash

setup-firewall () {
	echo "SETTING UP FIRE WALL"
	sudo ufw allow ssh
	sudo ufw --force enable 
	sudo ufw allow ssh
	sudo ufw allow http
	sudo ufw allow https
	sudo ufw status
	echo "FIREWALL SETUP"
}
install-dependencies () {
	echo "PERFORMING UPDATE"
	sudo apt-get update
	echo "PERFORMED APT UPDATE"


	echo "INSTALLING NODEJS"
	curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
	sudo apt install nodejs -y
	echo "INSTALLED NODEJS"


	echo "INSTALLING MONGODB"
	wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
	echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
	sudo apt update
	sudo apt-get install -y mongodb-org
	echo "INSTALLED MONGO"
	
	
	echo "STARTING UP MONGODB SERVER"
	sudo systemctl daemon-reload
	sudo systemctl start mongod
	sudo systemctl enable mongod
	sudo service mongod start
       	echo "STARTED MONGOD SERVICE"


	echo "INSTALLED DEPENDENCIES"
}

clone-repo () {
	 if [[ -d ./TypeScript-Node-Starter ]]; then
		echo "REMOVING EXISTING REPO"
		 rm -rf TypeScript-Node-Starter
	 fi
	 echo "CLONING REPO"
	 git clone --depth=1 https://github.com/Microsoft/TypeScript-Node-Starter.git
}

setup-env-and-build-app () {
	cd TypeScript-Node-Starter
	export NODE_ENV=production
	mv ./.env.example ./.env
	sed -i  's#.*MONGODB_URI=.*#MONGODB_URI=mongodb://localhost:27017/productiondb#g' ./.env
	echo 'NPM INSTALL'
	sudo npm install
	echo 'NPM RUN BUILD'
	npm run build
	sudo npm install pm2 -g	
	touch output.txt error.txt
	echo '****pm2 start****'
	pm2 start -o output.txt -e error.txt dist/server.js
	echo '****pm2 startup****'
	pm2 startup
	sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp ~
}
setup-nginx () {
	echo "INSTALLING NGINX"
	sudo apt install nginx -y
	sudo rm -rf /etc/nginx/sites-enabled/default

	  if [[ -d /etc/nginx/sites-enabled/app  ]]; then
	      printf "=================================== Removing existing configuration for nginx ======================================"
	      sudo rm -rf /etc/nginx/sites-available/app
	      sudo rm -rf /etc/nginx/sites-enabled/app
	  fi
	  sudo bash -c 'cat > /etc/nginx/sites-available/app <<EOF
	   server {
	           listen 80 default_server;
		   server_name _;
	           location / {
	                   proxy_pass 'http://127.0.0.1:3000';
	           }
	   }
	   '
	   sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
	   sudo service nginx restart
}
setupSSLCertificate() {
  printf '====================================== Setting up SSL certificate ======================================= \n'
  sudo  add-apt-repository ppa:certbot/certbot
  sudo apt-get update
  sudo apt-get install python-certbot-nginx -y
  sudo certbot --nginx -d $domain
}
setup-firewall 
install-dependencies 
clone-repo 
setup-nginx
setup-env-and-build-app 


curl localhost:80
curl http://localhost:80
curl localhost
pm2 logs
