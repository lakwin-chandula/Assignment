#!/bin/bash

logfile="/var/www/custom_logs/check.log"

STATUS="$(systemctl is-active httpd.service)"
if [ "${STATUS}" != "active" ];
then
	echo "Service is not running and restarted! time-stamp: $(date)" >> $logfile
	mail -s "ALERT!" lakwinc@gmail.com <<< 'Apache server is down. Service re-started at: $(date).'
	service httpd.service start
else
	echo "Service is running! time-stamp: $(date)" >> $logfile
	#mail -s "This is the subject" lakwinc@gmail.com <<< 'This is the message'
	if curl --max-time 10 -I "3.140.25.135" 2>&1 | grep -w "200\|301";
	then
		echo "3.140.25.135 is available! time-stamp: $(date)" >> $logfile
	else
		echo "3.140.25.135 content is not loading! time-stamp: $(date)" >> $logfile
	fi
fi

objectName="custom_script_logs"
file="/var/www/custom_logs/check.log"
bucketName="alinuxbucket1"
region="us-east-2"
accessKey="AKIAI7JDMIP4EY3F3IOA"
secreteKey="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"
contentType="text/plain"
date=$(date '+%Y%m%dT%H%M%SZ')
stringToSign="${accessKey}/${date}/${region}/s3/PUT"
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${secreteKey} -binary | base64`
curl -v -i -X PUT -T "${file}" \
          -H "host: ${bucketName}.s3.amazonaws.com" \
          -H "date: ${date}" \
          -H "content-type: ${contentType}" \
          -H "authorization: AWS4-HMAC-SHA256 ${accessKey}:${signature}" \
          https://${bucketName}.s3.amazonaws.com/${objectName}

