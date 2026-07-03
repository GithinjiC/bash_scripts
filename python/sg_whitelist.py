# =============================================================================
# sg_whitelist.py — self-service AWS security-group whitelister
# =============================================================================
#
# A tiny Flask service. When someone hits it in a browser, it reads their
# public IP and adds <ip>/32 as an inbound rule on a target security group,
# with IpProtocol="-1" (ALL traffic, ALL ports).
#
# -----------------------------------------------------------------------------
# 1. INSTALL DEPENDENCIES
# -----------------------------------------------------------------------------
#   pip install -r requirements.txt
#   (Flask and boto3 are already pinned in the repo's requirements.txt)
#
# -----------------------------------------------------------------------------
# 2. CONFIGURE AWS CREDENTIALS
# -----------------------------------------------------------------------------
# boto3 picks up credentials from the standard chain (env vars, ~/.aws/,
# instance/task role). The principal needs at minimum:
#
#   {
#     "Effect": "Allow",
#     "Action": "ec2:AuthorizeSecurityGroupIngress",
#     "Resource": "arn:aws:ec2:<region>:<account>:security-group/sg-..."
#   }
#
# -----------------------------------------------------------------------------
# 3. SET ENVIRONMENT VARIABLES
# -----------------------------------------------------------------------------
#   SG_ID              (required) e.g. sg-0123456789abcdef0
#   AWS_REGION         (optional, default us-east-1)
#   SHARED_SECRET      (optional but STRONGLY recommended) gate via ?token=
#   DESCRIPTION_PREFIX (optional, default "self-whitelist") tags the rule
#   PORT               (optional, default 8080) port Flask binds to
#
# Example:
#   export SG_ID=sg-0123456789abcdef0
#   export AWS_REGION=us-east-1
#   export SHARED_SECRET=$(openssl rand -hex 32)
#
# -----------------------------------------------------------------------------
# 4. RUN
# -----------------------------------------------------------------------------
#   python python/sg_whitelist.py
#
# Then from a browser:
#   http://<host>:8080/?token=<SHARED_SECRET>
#
# Response is a small HTML page confirming the add (or that the IP was
# already present).
#
# -----------------------------------------------------------------------------
# 5. SECURITY NOTES — READ BEFORE DEPLOYING
# -----------------------------------------------------------------------------
# * The endpoint grants ALL-traffic ingress. Anyone who reaches it (and knows
#   the token, if set) gets full network access to whatever this SG protects.
#   Always set SHARED_SECRET in any non-trivial deployment.
# * X-Forwarded-For is trusted so the real client IP is captured when this
#   runs behind an ALB / CloudFront / nginx. If you expose Flask directly to
#   the public internet, a client can spoof that header — either keep it
#   behind a trusted proxy, or strip the XFF branch in client_ip().
# * Rules accumulate. There's no auto-cleanup of stale /32 entries — prune
#   the SG periodically or extend this script to do so.
# =============================================================================

import os
import ipaddress

import boto3
from botocore.exceptions import ClientError
from flask import Flask, request

app = Flask(__name__)

SG_ID = os.environ["SG_ID"]
REGION = os.environ.get("AWS_REGION", "us-east-1")
SHARED_SECRET = os.environ.get("SHARED_SECRET")
DESCRIPTION_PREFIX = os.environ.get("DESCRIPTION_PREFIX", "self-whitelist")

ec2 = boto3.client("ec2", region_name=REGION)


def client_ip():
    xff = request.headers.get("X-Forwarded-For")
    raw = xff.split(",")[0].strip() if xff else request.remote_addr
    try:
        ip = ipaddress.ip_address(raw)
    except ValueError:
        return None
    if not isinstance(ip, ipaddress.IPv4Address):
        return None
    return str(ip)


@app.route("/")
def whitelist():
    if SHARED_SECRET and request.args.get("token") != SHARED_SECRET:
        return "Forbidden", 403

    ip = client_ip()
    if ip is None:
        return "Could not determine a valid IPv4 client address", 400

    cidr = f"{ip}/32"
    try:
        ec2.authorize_security_group_ingress(
            GroupId=SG_ID,
            IpPermissions=[{
                "IpProtocol": "-1",
                "IpRanges": [{
                    "CidrIp": cidr,
                    "Description": f"{DESCRIPTION_PREFIX} {ip}",
                }],
            }],
        )
        return f"<h1>Added {cidr} to {SG_ID}</h1>", 200
    except ClientError as e:
        if e.response["Error"]["Code"] == "InvalidPermission.Duplicate":
            return f"<h1>{cidr} already present in {SG_ID}</h1>", 200
        return f"<pre>AWS error: {e}</pre>", 500


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
