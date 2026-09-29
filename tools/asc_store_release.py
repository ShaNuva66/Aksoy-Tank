"""Inspect the existing store listing without exposing review contact information."""
import json
import os
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

def resource(kind, attributes=None, relationships=None, identifier=None):
    value = {'type':kind}
    if attributes is not None:
        value['attributes'] = attributes
    if relationships is not None:
        value['relationships'] = relationships
    if identifier:
        value['id'] = identifier
    return {'data':value}

def link(kind, identifier):
    return {'data':{'type':kind,'id':identifier}}

def release(submit=False):
    app = api(f'/v1/apps/{APP_ID}')['data']
    if app['attributes']['bundleId'] != 'com.atalay.aksoytanks':
        raise RuntimeError('Unexpected application')
    response = api(f'/v1/builds?filter[app]={APP_ID}&filter[version]=37&include=preReleaseVersion')
    versions = {v['id']:v['attributes']['version'] for v in response.get('included',[]) if v['type']=='preReleaseVersions'}
    builds = [b for b in response['data'] if versions.get(b['relationships']['preReleaseVersion']['data']['id'])=='2.0.7' and b['attributes']['processingState']=='VALID' and not b['attributes']['expired']]
    if len(builds) != 1 or builds[0]['id'] != '126b18e6-7771-4d5a-afd0-5213e163ea8e':
        raise RuntimeError('Tested build identity not confirmed')
    build = builds[0]
    store_versions = api(f'/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=20')['data']
    targets = [v for v in store_versions if v['attributes']['versionString']=='2.0.7']
    previous = next(v for v in store_versions if v['id']=='70df253b-8070-492e-ad3c-734fdb7bad30')
    if not targets:
        target = api('/v1/appStoreVersions','POST',resource('appStoreVersions',{'platform':'IOS','versionString':'2.0.7','releaseType':'AFTER_APPROVAL','copyright':previous['attributes']['copyright']},{'app':link('apps',APP_ID),'build':link('builds',build['id'])}))['data']
    elif len(targets)==1:
        target = targets[0]
    else:
        raise RuntimeError('Ambiguous version')
    vid = target['id']
    state = target['attributes']['appStoreState']
    print('RELEASE_VERSION',vid,state,flush=True)
    if state in ['WAITING_FOR_REVIEW','IN_REVIEW','READY_FOR_SALE','PENDING_APPLE_RELEASE']:
        attached = api(f'/v1/appStoreVersions/{vid}/build')['data']
        if attached['id'] != build['id']:
            raise RuntimeError('Submitted build differs from tested build')
        print('RELEASE_CONFIRMED',state,flush=True)
        return
    if state not in ['PREPARE_FOR_SUBMISSION','READY_FOR_REVIEW']:
        raise RuntimeError('Version needs manual inspection: '+state)
    api(f'/v1/appStoreVersions/{vid}','PATCH',resource('appStoreVersions',{'releaseType':'AFTER_APPROVAL'},{'build':link('builds',build['id'])},vid))
    notes = ('Bu g\u00fcncellemede:\n'
             '- Hik\u00e2ye b\u00f6l\u00fcmleri aras\u0131nda otomatik ge\u00e7i\u015f ve ilerleme kayd\u0131 d\u00fczeltildi.\n'
             '- Y\u00f6n tu\u015flar\u0131 b\u00fcy\u00fct\u00fcld\u00fc; analog ve buton kontrolleri iyile\u015ftirildi.\n'
             '- Duraklatma ve kontrol se\u00e7imi sorunlar\u0131 giderildi.\n'
             '- Ayarlar ve b\u00f6l\u00fcm yaz\u0131lar\u0131 daha okunabilir hale getirildi.\n'
             '- Online oda, co-op ve VS deneyiminde iyile\u015ftirmeler yap\u0131ld\u0131.')
    locales = api(f'/v1/appStoreVersions/{vid}/appStoreVersionLocalizations')['data']
    if not locales or any(l['attributes']['locale'] != 'tr' for l in locales):
        raise RuntimeError('Localization needs inspection')
    for loc in locales:
        api(f'/v1/appStoreVersionLocalizations/{loc["id"]}','PATCH',resource('appStoreVersionLocalizations',{'whatsNew':notes},identifier=loc['id']))
        sets = api(f'/v1/appStoreVersionLocalizations/{loc["id"]}/appScreenshotSets')['data']
        screenshot_count = 0
        for screenshot_set in sets:
            screenshots = api(f'/v1/appScreenshotSets/{screenshot_set["id"]}/appScreenshots')['data']
            screenshot_count += len(screenshots)
        if screenshot_count == 0:
            raise RuntimeError('Screenshots not inherited; do not submit incomplete listing')
        print('RELEASE_METADATA',loc['attributes']['locale'],'screenshots',screenshot_count,flush=True)
    review = api(f'/v1/appStoreVersions/{vid}/appStoreReviewDetail')['data']
    if not review or not all(review['attributes'].get(k) for k in ['contactFirstName','contactLastName','contactEmail','contactPhone']):
        raise RuntimeError('Review contact information missing; not inventing personal details')
    print('RELEASE_PREPARED 2.0.7 (37)',flush=True)
    if not submit:
        return
    submissions = api(f'/v1/apps/{APP_ID}/reviewSubmissions')['data']
    pending = [s for s in submissions if s['attributes'].get('state') != 'COMPLETE' and s['attributes'].get('platform')=='IOS']
    if pending:
        if len(pending) != 1 or pending[0]['attributes']['state'] != 'READY_FOR_REVIEW':
            raise RuntimeError('Existing review submission requires inspection')
        submission = pending[0]
        items = api(f'/v1/reviewSubmissions/{submission["id"]}/items')['data']
        if any(i.get('relationships',{}).get('appStoreVersion',{}).get('data',{}).get('id') != vid for i in items):
            raise RuntimeError('Unrelated items in submission; refusing to alter')
    else:
        submission = api('/v1/reviewSubmissions','POST',resource('reviewSubmissions',{'platform':'IOS'},{'app':link('apps',APP_ID)}))['data']
        items = []
    sid = submission['id']
    if not items:
        api('/v1/reviewSubmissionItems','POST',resource('reviewSubmissionItems',relationships={'reviewSubmission':link('reviewSubmissions',sid),'appStoreVersion':link('appStoreVersions',vid)}))
    api(f'/v1/reviewSubmissions/{sid}','PATCH',resource('reviewSubmissions',{'submitted':True},identifier=sid))
    confirmed = api(f'/v1/reviewSubmissions/{sid}')['data']
    version = api(f'/v1/appStoreVersions/{vid}')['data']
    print('RELEASE_SUBMITTED',json.dumps({'version':'2.0.7','build':'37','submission':sid,'submissionState':confirmed['attributes']['state'],'versionState':version['attributes']['appStoreState'],'releaseType':version['attributes']['releaseType']}),flush=True)

if __name__ == '__main__':
    action = os.environ.get('RELEASE_ACTION','audit')
    if action == 'audit':
        main()
    elif action in ['prepare','submit']:
        release(action == 'submit')
    else:
        raise RuntimeError('Unknown release action')
