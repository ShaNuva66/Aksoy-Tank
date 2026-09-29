"""Inspect the existing store listing without exposing review contact information."""
import json
from asc_testflight import api, APP_ID

def main():
    app = api(f'/v1/apps/{APP_ID}')['data']
    if app['attributes']['bundleId'] != 'com.atalay.aksoytanks':
        raise RuntimeError('Unexpected bundle identity')
    versions = api(f'/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=20')['data']
    for version in versions:
        attrs = version['attributes']
        print('VERSION', json.dumps({'id':version['id'], **{k:attrs.get(k) for k in ['versionString','appStoreState','releaseType','copyright']}}))
        localizations = api(f'/v1/appStoreVersions/{version["id"]}/appStoreVersionLocalizations')['data']
        for loc in localizations:
            a = loc['attributes']
            sets = api(f'/v1/appStoreVersionLocalizations/{loc["id"]}/appScreenshotSets')['data']
            print('LOCALIZATION', json.dumps({'id':loc['id'],'locale':a['locale'],'descriptionPresent':bool(a.get('description')),'supportUrl':a.get('supportUrl'),'screenshots':[(s['id'],s['attributes']['screenshotDisplayType']) for s in sets]}))
    builds = api(f'/v1/builds?filter[app]={APP_ID}&filter[version]=37&include=preReleaseVersion')['data']
    print('BUILDS', json.dumps([{'id':b['id'],'attributes':{k:b['attributes'].get(k) for k in ['version','processingState','expired','usesNonExemptEncryption']}} for b in builds]))
    submissions = api(f'/v1/apps/{APP_ID}/reviewSubmissions')['data']
    print('SUBMISSIONS', json.dumps([{'id':s['id'],'state':s['attributes'].get('state')} for s in submissions]))

if __name__ == '__main__':
    main()
