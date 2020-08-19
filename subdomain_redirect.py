import json

# BUG(high) fix


def lambda_handler(event, context):
    response = event["Records"][0]["cf"]["response"]
    headers = response["headers"]

    request = event["Records"][0]["cf"]["request"]
    request_headers = request["headers"]

    print(f"request_headers: {request_headers}")

    headerNameSrc = "X-Amz-Meta-Last-Modified"
    headerNameDst = "Last-Modified"

    if headers.get(headerNameSrc.lower(), None):
        headers[headerNameDst.lower()] = [headers[headerNameSrc.lower()][0]]
        print(
            f"Response header {headerNameDst.lower()} was set to {headers[headerNameSrc.lower()][0]}")

    return response
