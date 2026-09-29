"""Wait for this upload and enable it only for the existing internal test group."""
import base64
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec, utils

APP_ID = '6804423770'

def token():
    def encode(value):
        return base64.urlsafe_b64encode(value).rstrip(b'=').decode('ascii')
    now = int(time.time())
    header = encode(json.dumps({'alg':'ES256','kid':os.environ['APP_STORE_CONNECT_KEY_ID'],'typ':'JWT'}).encode())
    payload = encode(json.dumps({'iss':os.environ['APP_STORE_CONNECT_ISSUER_ID'],'iat':now,'exp':now+600,'aud':'appstoreconnect-v1'}).encode())
    message = f'{header}.{payload}'.encode()
    key = serialization.load_pem_private_key(Path(os.environ['ASC_KEY_PATH']).read_bytes(), password=None)
    r, s = utils.decode_dss_signature(key.sign(message, ec.ECDSA(hashes.SHA256())))
    return f'{header}.{payload}.{encode(r.to_bytes(32,"big")+s.to_bytes(32,"big"))}'

def api(path, method='GET', body=None):
    request = urllib.request.Request('https://api.appstoreconnect.apple.com'+path,
        headers={'Authorization':'Bearer '+token(),'Content-Type':'application/json'},
        data=json.dumps(body).encode() if body is not None else None, method=method)
    try:
        with urllib.request.urlopen(request, timeout=45) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as error:
        detail = json.loads(error.read()).get('errors', [])
        raise RuntimeError(f'Apple HTTP {error.code}: '+', '.join(item.get('code','UNKNOWN') for item in detail)) from None

def main():
    app = api(f'/v1/apps/{APP_ID}')['data']['attributes']
    if app['bundleId'] != 'com.atalay.aksoytanks':
        raise RuntimeError('Unexpected application identity')
    query = urllib.parse.urlencode({'filter[app]':APP_ID,'filter[version]':os.environ['IOS_BUILD_NUMBER'],'include':'preReleaseVersion','limit':20})
    build = None
    for _ in range(40):
        response = api('/v1/builds?'+query)
        versions = {item['id']: item['attributes']['version'] for item in response.get('included',[]) if item['type']=='preReleaseVersions'}
        for item in response['data']:
            version_id = item['relationships']['preReleaseVersion']['data']['id']
            if versions.get(version_id) != '2.0.7':
                continue
            state = item['attributes']['processingState']
            print('Apple processing:',state,flush=True)
            if state in ('FAILED','INVALID'):
                raise RuntimeError('Apple rejected build processing: '+state)
            if state == 'VALID':
                build = item
                break
        if build:
            break
        time.sleep(30)
    if not build:
        raise RuntimeError('Upload completed but Apple processing was not confirmed within 20 minutes. Do not re-upload blindly.')
    groups = api(f'/v1/apps/{APP_ID}/betaGroups?limit=200')['data']
    groups = [group for group in groups if group['attributes'].get('isInternalGroup')]
    if len(groups) != 1:
        raise RuntimeError('Build processed; select an internal test group manually. No tester access changed.')
    group = groups[0]
    existing = api(f'/v1/betaGroups/{group["id"]}/relationships/builds?limit=200')['data']
    if not any(item['id']==build['id'] for item in existing):
        api(f'/v1/betaGroups/{group["id"]}/relationships/builds', 'POST', {'data':[{'type':'builds','id':build['id']}]})
    confirmed = api(f'/v1/betaGroups/{group["id"]}/relationships/builds?limit=200')['data']
    if not any(item['id']==build['id'] for item in confirmed):
        raise RuntimeError('Internal build assignment was not confirmed')
    print('TESTFLIGHT_READY: 2.0.7 ('+os.environ['IOS_BUILD_NUMBER']+')',flush=True)
    print('Minimum iOS reported by Apple:',build['attributes'].get('minOsVersion'),flush=True)
    print('No public App Store release or external tester invitation was made.',flush=True)

if __name__ == '__main__':
    main()
