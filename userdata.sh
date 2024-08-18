#!/bin/bash
# Update the system and install necessary packages
apt update -y
apt install -y apache2

# Start the Apache server
systemctl start apache2
systemctl enable apache2

# Fetch the Availability Zone information using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || echo "failed")
if [ "$TOKEN" != "failed" ]; then
  AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone || echo "unknown")
else
  AZ="unknown"
fi

# Create the index.html file
cat > /var/www/html/index.html <<EOF
<html>
<head>
    <title>Instance Availability Zone</title>
    <style>
        body {
            background-color: #6495ED; /* Cornflower Blue - a darker shade */
            color: white;
            font-size: 36px; /* Significantly larger text */
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            font-family: Arial, sans-serif;
        }
    </style>
</head>
<body>
    <div>This instance is located in Availability Zone: $AZ</div>
</body>
</html>
EOF