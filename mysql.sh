#!/bin/bash

source ./common.sh

check_root

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MYSQL server"

systemctl enable mysqld &>>$LOG_FILE
systemctl start mysqld 
VALIDATE $? "Enable and Start MySQL Server"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Set Root Password for MYSQL server"

print_total_time