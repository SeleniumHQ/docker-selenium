#!/usr/bin/env python3
import os

def get_grid_url():
    max_time = 3
    se_sub_path = os.getenv('SE_SUB_PATH', '')

    # If SE_SUB_PATH is "/", set it to empty string
    if se_sub_path == "/":
        se_sub_path = ""

    # Start with default grid URL
    grid_url = os.getenv('SE_NODE_GRID_URL', '')

    # Check for hub/router configuration
    se_hub_host = os.getenv('SE_HUB_HOST') or os.getenv('SE_ROUTER_HOST')
    se_hub_port = os.getenv('SE_HUB_PORT') or os.getenv('SE_ROUTER_PORT')

    if se_hub_host and se_hub_port:
        grid_url = f"{os.getenv('SE_SERVER_PROTOCOL', 'http')}://{se_hub_host}:{se_hub_port}{se_sub_path}"
    # Check for standalone mode
    elif (os.getenv('DISPLAY_CONTAINER_NAME') and
          os.getenv('SE_VIDEO_RECORD_STANDALONE') == 'true'):
        display_container = os.getenv('DISPLAY_CONTAINER_NAME')
        node_port = os.getenv('SE_NODE_PORT', '4444')
        grid_url = f"{os.getenv('SE_SERVER_PROTOCOL', 'http')}://{display_container}:{node_port}{se_sub_path}"

    # Remove trailing slash if present
    grid_url = grid_url.rstrip('/')

    return grid_url

if __name__ == "__main__":
    print(get_grid_url())
