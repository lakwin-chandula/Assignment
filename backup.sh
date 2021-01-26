#!/bin/bash
web_content="/var/www/html"
#server_log="/var/log"
custom_logs="/var/www/custom_logs/check.log"
date=$(date '+%Y%m%d')
path="/var/www/scripts"

zip -r $path/backup_$date.zip $web_content $custom_logs


#upload to s3 bucket
accessKey="AKIAI7JDMIP4EY3F3IOA"
secretKey="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"
bucket="alinuxbucket1"
region="us-east-2"
filePath="${path}/backup_${date}.zip"
targetPath="custom_script_logs/"
acl="public-read"
mime="application/zip"
md5=`openssl md5 -binary ${filePath} | openssl base64`
date=`date -u +%Y%m%dT%H%M%SZ`
expdate=`if ! date -v+1d +%Y-%m-%d 2>/dev/null; then date -d tomorrow +%Y-%m-%d; fi`
expdate_s=`printf $expdate | sed s/-//g
service='s3'
p=$(cat << POLICY | openssl base64
	{ "expiration": "${expdate}T12:00:00.000Z",
		"conditions": [
			{"acl": "${acl}"},
			{"bucket": "${bucket}"},
			["starts-with", "\${key}", ""],
			["starts-with", "\${content-type}", ""],
			["content-length-range", 1, `ls -l -H "${filePath}" | awk '{print $5}' | head -1`],
			{"content-md5": "${md5}"},
			{"x-amz-date": "${date}"},
			{"x-amz-credential": "${accessKey}/${expdate_s}/${region}/${service}/aws4_request"},
			{"x-amz-algorithm": "AWS4-HMAC-SHA256"}
		]
	}
	POLICY
	)
# AWS4-HMAC-SHA256 signature
s=`printf "${expdate_s}"	| openssl sha256 -hmac "AWS4${secretKey}"        -hex | sed 's/(stdin)= //'`
s=`printf "${region}"		| openssl sha256 -mac HMAC -macopt hexkey:"${s}" -hex | sed 's/(stdin)= //'`
s=`printf "${service}"		| openssl sha256 -mac HMAC -macopt hexkey:"${s}" -hex | sed 's/(stdin)= //'`
s=`printf "aws4_request"	| openssl sha256 -mac HMAC -macopt hexkey:"${s}" -hex | sed 's/(stdin)= //'`
s=`printf "${p}"		| openssl sha256 -mac HMAC -macopt hexkey:"${s}" -hex | sed 's/(stdin)= //'`

key_and_sig_args="-F X-Amz-Credential=${accessKey}/${expdate_s}/${region}/${service}/aws4_request -F X-Amz-Algorithm=AWS4-HMAC-SHA256 -F X-Amz-Signature=${s} -F X-Amz-Date=${date}"

curl					\
	-# -k				\
	-F key=${targetPath}		\
	-F acl=${acl}			\
	${key_and_sig_args}		\
	-F "Policy=${p}"		\
	-F "Content-MD5=${md5}"		\
	-F "Content-Type=${mime}"	\
	-F "file=@${filePath}"		\
	https://${bucket}.s3.amazonaws.com/
