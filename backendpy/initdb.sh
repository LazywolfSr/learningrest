sudo -u postgres psql <<EOF
CREATE USER yealink WITH PASSWORD 'yealink';
CREATE DATABASE senatdb OWNER yealink;
EOF
