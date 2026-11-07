#!/usr/bin/env python3
"""Local structural checks for TN3181; not a substitute for Apple's validation."""
import argparse
import plistlib
import re
import zipfile
from pathlib import Path


def validate(manifest):
    def require(condition, message):
        if not condition:
            raise ValueError(message)

    require(isinstance(manifest, dict), 'Privacy manifest must be a dictionary')
    tracking = manifest.get('NSPrivacyTracking', False)
    require(type(tracking) is bool, 'NSPrivacyTracking must be Boolean')
    domains = manifest.get('NSPrivacyTrackingDomains', [])
    require(isinstance(domains, list), 'NSPrivacyTrackingDomains must be an array')
    require(not tracking or bool(domains), 'NSPrivacyTracking=true requires nonempty tracking domains (TN3181)')
    require(tracking or not domains, 'Tracking domains require NSPrivacyTracking=true')
    hostname = re.compile(r'(?=.{1,253}$)(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,63}')
    for domain in domains:
        require(isinstance(domain, str) and hostname.fullmatch(domain), 'Invalid tracking hostname: ' + repr(domain))
    for key in ('NSPrivacyAccessedAPITypes', 'NSPrivacyCollectedDataTypes'):
        require(isinstance(manifest.get(key, []), list), key + ' must be an array')
    for entry in manifest.get('NSPrivacyAccessedAPITypes', []):
        require(isinstance(entry, dict), 'API entry must be a dictionary')
        require(isinstance(entry.get('NSPrivacyAccessedAPIType'), str) and bool(entry['NSPrivacyAccessedAPIType']), 'Missing API category')
        reasons = entry.get('NSPrivacyAccessedAPITypeReasons')
        require(isinstance(reasons, list) and bool(reasons), 'API reasons must be a nonempty array')
        require(all(isinstance(r, str) and re.fullmatch(r'[A-Z0-9]{4}\.[0-9]+', r) for r in reasons), 'Invalid API reason format')
    for entry in manifest.get('NSPrivacyCollectedDataTypes', []):
        require(isinstance(entry, dict), 'Collected-data entry must be a dictionary')
        require(isinstance(entry.get('NSPrivacyCollectedDataType'), str) and bool(entry['NSPrivacyCollectedDataType']), 'Missing collected-data type')
        for key in ('NSPrivacyCollectedDataTypeLinked', 'NSPrivacyCollectedDataTypeTracking'):
            require(type(entry.get(key)) is bool, key + ' must be Boolean')
        purposes = entry.get('NSPrivacyCollectedDataTypePurposes')
        require(isinstance(purposes, list) and bool(purposes), 'Data purposes must be a nonempty array')
        require(all(isinstance(p, str) and bool(p) for p in purposes), 'Data purposes must be strings')


def check(path):
    if path.suffix == '.ipa':
        with zipfile.ZipFile(path) as archive:
            entries = [(n, archive.read(n)) for n in archive.namelist() if n.endswith('/PrivacyInfo.xcprivacy')]
    else:
        entries = [(str(path), path.read_bytes())]
    if not entries:
        raise ValueError('No privacy manifests found: ' + str(path))
    for name, data in entries:
        try:
            validate(plistlib.loads(data))
        except (ValueError, plistlib.InvalidFileException) as error:
            raise ValueError(name + ': ' + str(error)) from error
        print('Privacy structure OK: ' + name)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', nargs='?', type=Path, default=Path('loop_miao/PrivacyInfo.xcprivacy'))
    try:
        check(parser.parse_args().path)
    except ValueError as error:
        parser.exit(1, str(error) + '\n')
