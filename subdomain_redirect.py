import json

# BUG(low) pull out strings

# This is an origin-request handler redirecting from subdomain to apex for S3 origin


def lambda_handler(event, context):
    request = event["Records"][0]["cf"]["request"]
    headers = request["headers"]
    host_header = "Host"
    host = headers.get(host_header.lower(), None)

    if host:
        if host[0]["value"] == 'www.jeremychase.io':
            # Redirect from www to apex
            # BUG(medium) This loses the request path
            response = {
                'status': '301',
                'statusDescription': 'Moved Permanently',
                'headers': {
                    'location': [{
                        'key': 'Location',
                        'value': 'https://jeremychase.io/'
                    }]
                }
            }

            # Return generated response rather than make request to origin
            return response

        elif host[0]["value"] == 'jeremychase.io':
            # On apex request; update host header to match signature expected by S3
            host[0]["value"] = 'www.jeremychase.io.s3.amazonaws.com'
            headers[host_header] = host

        else:
            # Error condition; do not continue
            response = {
                'status': '400',
                'statusDescription': 'Invalid Host header',
            }

            # Return generated response
            return response

    # Make request to origin
    return request
