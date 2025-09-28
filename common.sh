#!/usr/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m" 
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
START_TIME=$(date +%s)
SCRIPT_DIR=$PWD # for absolute path
MONGODB_HOST=mongodb.devaws.store
MYSQL_HOST=mysql.devaws.store


mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

check_root()
{
    if [ $USERID -ne 0 ]; then
        echo "ERROR:: Please run this script with root privelege"
        exit 1 # failure is other than 0
    fi
}


VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}
                                                                # from 3-catalogue.sh  from shell-roboshop
nodejs_setup(){
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling NodeJS"
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enable NodeJS 20"
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing NodeJS"
    
    npm install &>>$LOG_FILE
    VALIDATE $? "Install Dependencies"
}

app_setup(){
    #idempotency
    id roboshop &>>$LOG_FILE 
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE   
        VALIDATE $? "Create System User"
    else
        echo -e "User already Exists ... $Y SKIPPING $N"
    fi
    mkdir -p /app
    VALIDATE $? "Creating App Directory"

    curl -o /tmp/$app_name.zip https://roboshop-artifacts.s3.amazonaws.com/$app_name-v3.zip &>>$LOG_FILE
    VALIDATE $? "Downloading $app_name Application"

    cd /app
    VALIDATE $? "Changing to app Directory"

    rm -rf /app/*
    VALIDATE $? "Remove Existing Code"

    unzip /tmp/$app_name.zip &>>$LOG_FILE
    VALIDATE $? "Unzip $app_name"
}
                                                                                # from 9-shipping.sh
java_setup(){
    dnf install maven -y &>>$LOG_FILE
    VALIDATE $? "Installing Maven application" 
    mvn clean package &>>$LOG_FILE
    VALIDATE $? "Packing the application"
    mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
    VALIDATE $? "Rename the Artifact"
}

python_setup(){
    dnf install python3 gcc python3-devel &>>$LOG_FILE
    VALIDATE $? "Install Python 3"
    pip3 install -r requirements.txt &>>$LOG_FILE
    VALIDATE $? "Install Dependencies"
}


systemd_setup(){
    cp $SCRIPT_DIR/$app_name.service /etc/systemd/system/$app_name.service
    VALIDATE $? "Copy systemctl service"

    systemctl daemon-reload
    systemctl enable $app_name &>>$LOG_FILE
    VALIDATE $? "Enable $app_name"
}

app_restart(){
    systemctl restart $app_name
    VALIDATE $? "Restarted $app_name"   
}

print_total_time(){
    END_TIME=$(date +%s)
    TOTAL_TIME=$(( $END_TIME - $START_TIME ))
    echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
}
