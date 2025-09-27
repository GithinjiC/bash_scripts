import boto3

def get_alb_dns_name(alb_name):
    """Get the DNS name of an ALB by its name."""
    elb_client = boto3.client('elbv2')
    response = elb_client.describe_load_balancers(Names=[alb_name])
    return response['LoadBalancers'][0]['DNSName']


def check_cloudfront_origin(alb_dns_name):
    """Check if the ALB DNS name is used as an origin in any CloudFront distribution."""
    cloudfront_client = boto3.client('cloudfront')
    distributions = cloudfront_client.list_distributions()

    if 'DistributionList' in distributions and distributions['DistributionList']['Items']:
        for dist in distributions['DistributionList']['Items']:
            for origin in dist['Origins']['Items']:
                if alb_dns_name in origin['DomainName']:
                    print(f"✅ ALB is an origin for CloudFront distribution: {dist['Id']}")
                    return
    print("❌ ALB is not used as an origin for any CloudFront distribution.")


def check_route53_record(alb_dns_name):
    """Check if the ALB DNS name is used in any Route 53 records."""
    route53_client = boto3.client('route53')
    hosted_zones = route53_client.list_hosted_zones()['HostedZones']

    for zone in hosted_zones:
        zone_id = zone['Id'].split('/')[-1]
        records = route53_client.list_resource_record_sets(HostedZoneId=zone_id)['ResourceRecordSets']

        for record in records:
            if 'AliasTarget' in record and alb_dns_name in record['AliasTarget']['DNSName']:
                print(f"✅ ALB is targeted by Route 53 record: {record['Name']}")
                return
            elif 'ResourceRecords' in record:
                for rr in record['ResourceRecords']:
                    if alb_dns_name in rr['Value']:
                        print(f"✅ ALB is targeted by Route 53 record: {record['Name']}")
                        return
    print("❌ ALB is not targeted by any Route 53 record.")


def main():
    alb_name = input("Enter the name of your ALB: ")

    try:
        alb_dns_name = get_alb_dns_name(alb_name)
        print(f"ALB DNS Name: {alb_dns_name}")
    except Exception as e:
        print(f"Error fetching ALB DNS name: {e}")
        return

    print("\nChecking CloudFront distributions...")
    check_cloudfront_origin(alb_dns_name)

    print("\nChecking Route 53 records...")
    check_route53_record(alb_dns_name)


if __name__ == "__main__":
    main()
