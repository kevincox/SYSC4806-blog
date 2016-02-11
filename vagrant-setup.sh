#!/bin/bash

set -e

#The following parameters are to configure PostgreSQL. 
# Edit the following to change the name of the database user that will be created:
APP_DB_USER=blog
APP_DB_PASS=dbpass

# Edit the following to change the name of the databases that are created (defaults to dev_ [theuser name] and test_ [the username])
APP_DB_NAME1=dev_$APP_DB_USER
APP_DB_NAME2=test_$APP_DB_USER

# Edit the following to change the version of PostgreSQL that is installed: we'll stick to 9.3 because this version is available from the standard Ubuntu repositories.
PG_VERSION=9.3

export DEBIAN_FRONTEND=noninteractive #this will suppress interaction with the user, along with the -y flag of apt-get (see below)

to_install=(
	build-essential
	git-core
	libgmp-dev
	libpq-dev
	"postgresql-$PG_VERSION"
	"postgresql-contrib-$PG_VERSION"
)

apt-get update
apt-get -y upgrade
apt-get -y install "${to_install[@]}"

# Ruby Stuff
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable --ruby
usermod -aG rvm vagrant
. /etc/profile.d/rvm.sh
rvm install ruby-2.2.2
gem install bundler

wget -O- https://toolbelt.heroku.com/install-ubuntu.sh | sh

PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

sed -ie "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"
echo "client_encoding = utf8" >> "$PG_CONF"

cat <<-EOF > "$PG_HBA"
	# TYPE  DATABASE USER      ADDRESS      METHOD
	local   all      postgres  peer
	local   all      all       md5
	host    all      all       127.0.0.1/32 md5
	host    all      all       ::1/128      md5
	host    all      all       all          md5
EOF

service postgresql restart

sudo -u postgres psql <<-EOF
	-- Create the database user:
	CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';
	
	-- Create the database:
	CREATE DATABASE $APP_DB_NAME1
	WITH
		OWNER=$APP_DB_USER
		LC_COLLATE='en_US.utf8'
		LC_CTYPE='en_US.utf8'
		ENCODING='UTF8'
		TEMPLATE=template0;
	
	CREATE DATABASE $APP_DB_NAME2
	WITH
		OWNER=$APP_DB_USER
		LC_COLLATE='en_US.utf8'
		LC_CTYPE='en_US.utf8'
		ENCODING='UTF8'
		TEMPLATE=template0;
EOF


###########################################################
# This is the message you will get when the script finishes
cat <<-END
	Successfully created PostgreSQL dev virtual machine.
	
	Your PostgreSQL database has been setup and can be accessed on your local machine on the forwarded port (default: 15432)
	  Host: localhost
	  Port: 15432
	  Database: $APP_DB_NAME1
	  Username: $APP_DB_USER
	  Password: $APP_DB_PASS
	
	  Database: $APP_DB_NAME2
	  Username: $APP_DB_USER
	  Password: $APP_DB_PASS
	
	Admin access to postgres user via VM:
	  vagrant ssh
	  sudo su - postgres
	
	psql access to app database user via VM:
	  vagrant ssh
	  sudo su - postgres
	  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME1
	  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost $APP_DB_NAME2
	
	Env variable for application development:
	  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME1
	  DATABASE_URL=postgresql://$APP_DB_USER:$APP_DB_PASS@localhost:15432/$APP_DB_NAME2
	
	Local command to access the database via psql:
	  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME1
	  PGUSER=$APP_DB_USER PGPASSWORD=$APP_DB_PASS psql -h localhost -p 15432 $APP_DB_NAME2
END
