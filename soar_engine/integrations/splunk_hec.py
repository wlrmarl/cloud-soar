import urllib.request
import json
import logging
import os
import ssl

logger = logging.getLogger()

SPLUNK_TOKEN = os.environ.get("SPLUNK_TOKEN")
SPLUNK_HEC_URL = os.environ.get("SPLUNK_HEC_URL")


def send_to_splunk(incident_report):
    if not SPLUNK_TOKEN or not SPLUNK_HEC_URL:
        logger.error("Splunk Token or URL environment variables are missing.")
        return

    logger.info("Forwarding Incident Report to Splunk SIEM...")
    
    payload = {
        "sourcetype": "_json",
        "event": incident_report
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(SPLUNK_HEC_URL, data=data)
    req.add_header('Authorization', f'Splunk {SPLUNK_TOKEN}')
    
    # Create an unverified SSL context to accept Splunk's self-signed cert
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    
    try:
        with urllib.request.urlopen(req, context=ctx) as response:
            res_body = response.read()
            logger.info(f"Splunk Response: {res_body.decode('utf-8')}")
            return True
    except Exception as e:
        logger.error(f"Failed to send to Splunk: {str(e)}")
        return False