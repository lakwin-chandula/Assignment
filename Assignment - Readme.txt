Lakwin Chandula
Assignment – Associate Application Support Engineer (Capital Markets)

Part 1

1)	Create a new server

Requirement – Create a publicly accessible server on a cloud/ virtual environment.
Environment used – Amazon Elastic Compute Cloud (EC2) virtual computing environment.
Assumption – Need to have a verified AWS account (Free Tier).

Steps to follow:
	1.	Sign in to the AWS Management Console and open Amazon EC2 console.
	2.	Choose EC2 dashboard and then select Launch instance.
	3.	Choose an Amazon Machine Image (AMI) that contains the software configuration (OS, application server and applications) – Select Amazon Linux 2 AMI (64-bit x86).
	4.	Choose an Instance Type (Resource Configuration) – Default configuration that eligible in Free Tier is preferred. Then select Next.
	5.	Configure instance details – Default configuration is preferred (Important – make sure that Public IP is enabled). Create a new IAM role (for future use) with full access to S3 bucket and choose it as the IAM role. Then select Next.
	6.	Add storage (Choose storage device settings) – Default configuration is preferred. Then select Next.
	7.	Add tags (key-value pair) – Add a Name Tag for the instance (Ex: Key - Name, Value - linux_server). Then select Next.
	8.	Configure security group (firewall rules to control the traffic) – Add following inbound TCP rules (Let the rest of the settings as in their default configuration).
			i.	Type: SSH (Default) -> Protocol: TCP (Default) -> Port Range: (Default Value) -> Source: My IP -> Add a Description (Ex: SSH Admin Connect)
			ii.	Type: HTTP (Default) -> Protocol: TCP (Default) -> Port Range: (Default Value) -> Source: Anywhere -> Add a Description (Ex: HTTP Port)
			iii.Type: HTTPS (Default) -> Protocol: TCP (Default) -> Port Range: (Default Value) -> Source: Anywhere -> Add a Description (Ex: HTTPS Port)
	9.	Choose Review and Launch. Then verify the settings and choose Launch.
	10.	Select an existing key pair or create a new key pair – preferred the following steps.
			i.	Choose Create a new key pair
			ii.	Set Key pair name (Ex: linux_server_key).
			iii.Choose Download Key Pair and save it to local machine (this key pair file is used to connect to the EC2 instance).
	11.	Then choose Launch Instances.
	12.	Choose View Instances and find the created instance. Wait until the Instance Status reads as Running before continuing.
		(Note – An Elastic IP address can be allocated from Network & Security - > Elastic IPs -> Allocate Elastic IP address. And then associate the allocated Elastic IP to the instance we created. Purpose of associating an Elastic IP to an instance is because the public IP address of an instance can be changed when the instance is stopped or due to a failure of the instance. Elastic IPs are static and it is allocated to the instance once associated until release it.)



2)	Run a web server

Requirement – Run a freely available web server (purpose is to serve some deployed content).
Web Server used – Apache Web Server
Assumption –Ubuntu based local computer is used and following command executed on an opened terminal window in the local computer. Followings are other assumptions,
	•	Key pair name (downloaded) => linux_server_key
	•	Instance user name => ec2-user

Steps to follow:
	1.	Connect to the above created instance (linux_server) through SSH.
			ssh -i /path/key-pair-name.pem instance-user-name@instance-public-ip
			(note – for Amazon Linux 2/ Amazon Linux AMI, the instance user name is ec2-user.)
	2.	After connected to the remote server, to get latest bug fixes and security updates, update software on the instances using following command (Optional).
			sudo yum update -y
	3.	Install the Apache web server.
			sudo yum install -y httpd
	4.	Start the Apache web server after installation.
			sudo systemctl start httpd
	5.	Configure the web server to start with each system boot.
			sudo systemctl enable httpd
	6.	To set file permission for Apache web server, add the group to the instance.
			sudo groupadd www
	7.	Add the ec2-user user to the www group.
			sudo usermod -a -G www ec2-user
	8.	Log out to refresh and include the new www group.
			exit
	9.	Log back in again and verify that www group exist with the groups command.
			groups
			Output should look like:
			ec2-user adm wheel systemd-journal www
	10.	Change group ownership of /var/www directory and its contents to www group.
		sudo chgrp -R www /var/www
	11.	Change directory permissions of /var/www and its subdirectories to add group write permission and set group ID on subdirectories created in the future.
		sudo chmod 2775 /var/www
		find /var/www -type d -exec sudo chmod 2775 {} +
	12.	Recursively change permission for files in /var/www directory and its subdirectories to add group write permissions.
		find /var/www -type f -exec sudo chmod 0664 {} +
	13.	Create sample index page with a sample content “Hello World!”.
			echo “Hello World!” > /var/www/html/index.html
	14.	Check if the page is loading using public IP address of the instance created (linux_server).



3)	A script to run periodically that checks the status of web server and its content

Requirement – Create a script to check the status of Apache web server and start if it is stopped. And check if the server is serving expected content. Run this script periodically and save results then notify the support team via an email.
Scripting language used – Bash
Assumption – Local computer is already connected to the remote instance (linux_server) using public IP address and the key pair downloaded (linux_server_key) as mentioned in above. And following assumptions were also made.
	•	Bash script were created in the local computer using Vim editor and saved as “check.sh” that contains the code checking web server status and content. After completing the code, it transferred to the remote server (check.sh script file is attached).
		vim /path/check.sh
	•	Two new directories created in the remote server to transfer the script file and to save logs generated by scripts.
			/var/www/custom_logs/
			/var/www/scripts/

Steps to follow:
	1.	Transfer the script file created to the remote server by using following command.
			scp -i /path/key-pair-name.pem /path/check.sh instance-user-name@\[ instance-public-IP-address\]:/var/www/scripts/
			note – path on remote is the path where the script file is to be placed in the remote server.
	2.	Create an Amazon S3 bucket
			I.	Log in to AWS Management Console. Then type S3 in the search bar and select S3 to open S3 console.
			II.	Click on Create Bucket.
			III.Enter a valid bucket name (Ex - alinuxbucket1).
			IV.	Select a region (default settings preferred).
			V.	Choose bucket versioning (disabled in default).
			VI.	Add tags (optional).
			VII.Server-side encryption (disabled in default).
			VIII.Click on Create bucket. And then create a new folder custom_script_logs in the bucket.
			IX.	After creating the S3 bucket, need to generate an Access Key to access the bucket. To generate that, click on the username on top right corner.
			X.	Choose Access keys.
			XI.	Click on Create New Access Key.
			XII.Copy the Access Key ID and Secret Key. Then download and save. (This access key ID and secret key used in the check.sh script to put check.log file in alinuxbucket1 S3 bucket).
	3.	Create a Cron Job to schedule the process of executing check.sh periodically (Ex: in every 1 hour).
			I.	Open crontab configuration file for current user.
					crontab -e
			II.	Press ESC and then press i to begin editing the file.
			III.Enter/ paste following command to schedule executing check.sh once an hour.
					0 * * * * /var/www/scripts/check.sh > /dev/null 2>&1
					(/dev/null 2>&1 used to discard the output)
			IV.	Press ESC to exit editing mode. Then type :wq or :x to save and quit.
					(Now the crontab is saved and check.sh will run and execute once an hour.)



4)	A script to collect and compress log files and web server content and upload to S3 bucket daily

Requirement – Create a script to collect log files and content of the web server and to create a compressed file daily. Then to upload the compressed file to S3 bucket.
Scripting language used – Bash
Assumption – the collected log files and content of the web server compressed using .zip file format. Also, following assumptions were made.
	•	Bash script were created in the local computer using Vim editor and saved as “backup.sh” after the completion of the code. And then it was transferred to the remote server and placed in /var/www/scripts/ path.
			vim /path/backup.sh

Steps to follow:
	1.	Transfer the script file created to the remote server by using following command.
			scp -i /path/key-pair-name.pem /path/backup.sh instance-user-name@\[ instance-public-IP-address\]:/var/www/scripts/
			(note – path on remote is the path where the script file is to be placed in the remote server.)
	2.	Create new folder backups in the S3 bucket (alinuxbucket1). 
	3.	Create a Cron Job to schedule the periodical execution of backup.sh.
			I.	Open crontab configurations.
			II.	Press ESC and then press i to begin editing the file.
			III.Add new cron job to schedule the execution of backup.sh once a day.
					0 0 * * * /var/www/scripts/check.sh > /dev/null 2>&1
			IV.	Press ESC to exit editing mod and type :wq or :x then hit enter to save and quit.
