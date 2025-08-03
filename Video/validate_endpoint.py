#!/usr/bin/env python3

import sys
import os
import base64
from datetime import datetime
from datetime import timezone
import requests


def get_timestamp():
    """Get formatted timestamp based on SE_LOG_TIMESTAMP_FORMAT."""
    ts_format = os.environ.get('SE_LOG_TIMESTAMP_FORMAT', '%Y-%m-%d %H:%M:%S,%f')
    # Convert bash format to Python format
    if '%3N' in ts_format:
        # Replace %3N (bash milliseconds) with %f (Python microseconds) and trim later
        ts_format_python = ts_format.replace('%3N', '%f')
        timestamp = datetime.now(timezone.utc).strftime(ts_format_python)
        # Convert microseconds to milliseconds (trim last 3 digits)
        if '%f' in ts_format_python:
            # Find the microseconds part and trim to milliseconds
            parts = timestamp.rsplit(',', 1)
            if len(parts) == 2 and len(parts[1]) == 6:
                timestamp = parts[0] + ',' + parts[1][:3]
    else:
        timestamp = datetime.now(timezone.utc).strftime(ts_format)
    return timestamp


def create_session():
    """Create requests session with timeout configuration."""
    session = requests.Session()
    return session


def get_basic_auth():
    """Get basic authentication header if credentials are provided."""
    username = os.environ.get('SE_ROUTER_USERNAME')
    password = os.environ.get('SE_ROUTER_PASSWORD')

    if username and password:
        credentials = f"{username}:{password}"
        encoded_credentials = base64.b64encode(credentials.encode()).decode()
        return {"Authorization": f"Basic {encoded_credentials}"}

    return {}


def validate_endpoint(endpoint, graphql_endpoint=False, connection_timeout=5, read_timeout=5):
    """
    Validate an endpoint by making HTTP request and checking status code.

    Args:
        endpoint (str): The endpoint URL to validate
        graphql_endpoint (bool): Whether this is a GraphQL endpoint
        connection_timeout (int): Connection timeout in seconds
        read_timeout (int): Read timeout in seconds
    """
    process_name = "endpoint.checks"
    session = create_session()

    # Set up headers
    headers = {}
    headers.update(get_basic_auth())

    try:
        if graphql_endpoint:
            # GraphQL endpoint check
            headers['Content-Type'] = 'application/json'
            data = {"query": "{ grid { sessionCount } }"}

            response = session.post(
                endpoint,
                headers=headers,
                json=data,
                timeout=(connection_timeout, read_timeout),
                verify=False  # Equivalent to curl's -k flag
            )
        else:
            # Regular endpoint check
            response = session.get(
                endpoint,
                headers=headers,
                timeout=(connection_timeout, read_timeout),
                verify=False  # Equivalent to curl's -k flag
            )

        status_code = response.status_code

    except requests.exceptions.Timeout:
        print(
            f"{get_timestamp()} [{process_name}] - Endpoint {endpoint} timed out (connection: {connection_timeout}s, read: {read_timeout}s)")
        return False
    except requests.exceptions.ConnectionError:
        print(f"{get_timestamp()} [{process_name}] - Failed to connect to endpoint {endpoint}")
        return False
    except requests.exceptions.RequestException as e:
        print(f"{get_timestamp()} [{process_name}] - Error connecting to endpoint {endpoint}: {str(e)}")
        return False

    # Handle different status codes
    if status_code == 404:
        print(f"{get_timestamp()} [{process_name}] - Endpoint {endpoint} is not found - status code: {status_code}")
        return False
    elif status_code == 401:
        print(
            f"{get_timestamp()} [{process_name}] - Endpoint {endpoint} requires authentication - status code: {status_code}. Please provide valid credentials via SE_ROUTER_USERNAME and SE_ROUTER_PASSWORD environment variables.")
        return False
    elif status_code != 200:
        print(f"{get_timestamp()} [{process_name}] - Endpoint {endpoint} is not available - status code: {status_code}")
        return False

    print(f"{get_timestamp()} [{process_name}] - Endpoint {endpoint} is reachable - status code: {status_code}")
    return True


def main():
    """Main function to handle command line arguments and execute validation."""
    if len(sys.argv) < 2:
        print("Usage: python3 validate_endpoint.py <endpoint> [graphql_endpoint]")
        print("  endpoint: The URL endpoint to validate")
        print("  graphql_endpoint: 'true' if this is a GraphQL endpoint (default: false)")
        sys.exit(1)

    endpoint = sys.argv[1]
    graphql_endpoint = len(sys.argv) > 2 and sys.argv[2].lower() == 'true'
    max_time = int(os.environ.get('SE_ENDPOINT_CHECK_TIMEOUT', 5))

    # Validate the endpoint
    success = validate_endpoint(endpoint, graphql_endpoint, max_time, max_time)

    # Exit with appropriate code
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
