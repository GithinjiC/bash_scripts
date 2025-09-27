import boto3

def get_all_hosted_zones():
    """Retrieve all hosted zones in Route 53."""
    client = boto3.client('route53')
    hosted_zones = []
    paginator = client.get_paginator('list_hosted_zones')
    for page in paginator.paginate():
        hosted_zones.extend(page['HostedZones'])
    return hosted_zones

def get_all_dns_records(hosted_zone_id):
    """Retrieve all DNS records for a given hosted zone."""
    client = boto3.client('route53')
    records = []
    paginator = client.get_paginator('list_resource_record_sets')
    for page in paginator.paginate(HostedZoneId=hosted_zone_id):
        records.extend(page['ResourceRecordSets'])
    return records

def find_cloudfront_distribution_in_route53(distribution_name):
    """Check if the CloudFront distribution name is mapped in Route 53 records."""
    hosted_zones = get_all_hosted_zones()
    matches = []
    
    for zone in hosted_zones:
        zone_id = zone['Id']
        dns_records = get_all_dns_records(zone_id)
        
        for record in dns_records:
            if 'AliasTarget' in record and 'DNSName' in record['AliasTarget']:
                if distribution_name in record['AliasTarget']['DNSName']:
                    matches.append({'hosted_zone': zone['Name'], 'record_name': record['Name']})
    
    return matches

if __name__ == "__main__":
    distribution_name = input("Enter CloudFront distribution name (e.g., d123example.cloudfront.net): ").strip()
    results = find_cloudfront_distribution_in_route53(distribution_name)
    
    if results:
        print("CloudFront distribution is mapped to the following Route 53 records:")
        for result in results:
            print(f"- Hosted Zone: {result['hosted_zone']}, Record Name: {result['record_name']}")
    else:
        print("No Route 53 records found for the given CloudFront distribution.")
