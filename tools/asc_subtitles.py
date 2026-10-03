"""Update only subtitles on an already editable app info record."""
import json
from asc_testflight import api, APP_ID
from asc_store_release import resource, link

TARGETS = {'tr': 'Tank Sava\u015flar\u0131 ve Bosslar',
           'en-US': 'Arcade Battles & Boss Fights'}

def main():
    app = api(f'/v1/apps/{APP_ID}')['data']['attributes']
    if app['bundleId'] != 'com.atalay.aksoytanks':
        raise RuntimeError('Unexpected app')
    versions = api(f'/v1/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=20')['data']
    print('VERSION', json.dumps([(v['attributes']['versionString'], v['attributes']['appStoreState']) for v in versions]))
    infos = api(f'/v1/apps/{APP_ID}/appInfos')['data']
    editable = []
    for info in infos:
        state = info['attributes']['appStoreState']
        locales = api(f'/v1/appInfos/{info["id"]}/appInfoLocalizations')['data']
        print('LOCALIZATION', json.dumps({'state': state, 'locales': [{k: l['attributes'].get(k) for k in ['locale','name','subtitle']} for l in locales]}))
        if state in ('PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED'):
            editable.append((info, locales))
    if len(editable) != 1:
        print('RELEASE_SUBTITLE_BLOCKED: No unique editable app info. No review canceled and no new version created.')
        return
    info, locales = editable[0]
    by_locale = {l['attributes']['locale']: l for l in locales}
    source = by_locale.get(app['primaryLocale'])
    if not source:
        raise RuntimeError('Missing primary locale')
    for locale, subtitle in TARGETS.items():
        assert 0 < len(subtitle) <= 30
        existing = by_locale.get(locale)
        if existing:
            result = api(f'/v1/appInfoLocalizations/{existing["id"]}', 'PATCH', resource('appInfoLocalizations', {'subtitle': subtitle}, identifier=existing['id']))['data']
        else:
            attrs = {'locale': locale, 'name': source['attributes']['name'], 'subtitle': subtitle}
            for key in ('privacyPolicyUrl', 'privacyChoicesUrl', 'privacyPolicyText'):
                if source['attributes'].get(key):
                    attrs[key] = source['attributes'][key]
            result = api('/v1/appInfoLocalizations', 'POST', resource('appInfoLocalizations', attrs, {'appInfo': link('appInfos', info['id'])}))['data']
        saved = api(f'/v1/appInfoLocalizations/{result["id"]}')['data']['attributes']
        if saved.get('subtitle') != subtitle:
            raise RuntimeError('Subtitle readback mismatch')
        print('RELEASE_SUBTITLE_SAVED', json.dumps({'locale': locale, 'subtitle': subtitle}))

if __name__ == '__main__':
    main()
