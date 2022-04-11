import time
from cryptography.hazmat.backends import default_backend
import jwt
import os
import requests
import logging

github_app_id = os.environ.get('GITHUB_APP_ID')
github_installation_id = os.environ.get('GITHUB_INSTALLATION_ID')
private_key = os.environ.get('GITHUB_APP_PEM')
private_key = private_key.replace("\\n", "\n")


time_since_epoch_in_seconds = int(time.time())
    
payload = {
  # issued at time
  'iat': time_since_epoch_in_seconds,
  # JWT expiration time (10 minute maximum)
  'exp': time_since_epoch_in_seconds + (10 * 60),
  # GitHub App's identifier
  'iss': github_app_id
}

actual_jwt = jwt.encode(payload, private_key, algorithm='RS256')

headers = {"Authorization": "Bearer " + actual_jwt,
           "Accept": "application/vnd.github.v3+json"}

resp = requests.post('https://api.github.com/app/installations/' + github_installation_id + '/access_tokens', headers=headers)

print(resp.json()['token'])
