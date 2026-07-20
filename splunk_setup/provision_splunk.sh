#!/bin/bash

# Load variables from the hidden .env file
if [ -f .env ]; then
    source .env
else
    echo "❌ Error: .env file not found! Please create one with SPLUNK_PASSWORD and SPLUNK_TOKEN."
    exit 1
fi

echo "Waiting for Splunk REST API to come online (this can take 60-90 seconds on a fresh boot)..."
until curl -k -s -o /dev/null -u "admin:${SPLUNK_PASSWORD}" https://localhost:8089/services/server/info; do
    printf "."
    sleep 5
done
echo -e "\nSplunk API is awake! Proceeding with configuration..."

# 1. Enable HTTP Event Collector globally
curl -k -u "admin:${SPLUNK_PASSWORD}" https://localhost:8089/servicesNS/admin/splunk_httpinput/data/inputs/http/http -d disabled=0

# 2. Create the SOAR HEC Token securely
curl -k -u "admin:${SPLUNK_PASSWORD}" https://localhost:8089/servicesNS/admin/splunk_httpinput/data/inputs/http \
  -d name="AWS-Soar-Engine" \
  -d token="${SPLUNK_TOKEN}" \
  -d index="main" \
  -d disabled=0

# 3. Inject the Dashboard XML directly into the Splunk Search App
echo "Creating dashboard directory inside Splunk container..."
sudo docker exec -u root splunk_soar mkdir -p /opt/splunk/etc/apps/search/local/data/ui/views/

echo "Copying XML payload..."
sudo docker cp dashboards/aws_cloud_soar_automated_response.xml splunk_soar:/opt/splunk/etc/apps/search/local/data/ui/views/aws_cloud_soar_automated_response.xml

echo "Applying correct permissions..."
sudo docker exec -u root splunk_soar chown -R splunk:splunk /opt/splunk/etc/apps/search/local/data/ui/views/

echo -e "\n✅ Splunk Provisioning Complete! Your dashboard is ready and HEC Token is configured."