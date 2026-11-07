#!/usr/bin/env python3
"""Require an explicit successful Apple processing response, not just exit code 0."""
import json
import os
from pathlib import Path
import re
import sys


def receipt_from_output(output, version, build):
    if re.search(r'\bERROR\b|"product-errors"\s*:', output):
        raise ValueError('Apple upload output contains an error; inspect the upload log.')
    decoder = json.JSONDecoder()
    responses = []
    position = 0
    while position < len(output):
        start = output.find('{', position)
        if start < 0:
            break
        try:
            value, length = decoder.raw_decode(output[start:])
            if isinstance(value, dict) and 'build-status' in value:
                responses.append(value)
            position = start + length
        except ValueError:
            position = start + 1
    if not responses:
        raise ValueError('No Apple processing status received; upload success alone is insufficient.')
    receipt = responses[-1]
    if receipt.get('build-status') not in {'VALID_BINARY', 'BETA_INTERNAL_TESTING', 'BETA_EXTERNAL_TESTING', 'READY_FOR_SALE'}:
        raise ValueError('Apple processing is not successful: ' + str(receipt.get('build-status')))
    if (receipt.get('bundle-short-version-string'), receipt.get('bundle-version')) != (version, build):
        raise ValueError('Apple response version/build does not match this release.')
    if not receipt.get('delivery-uuid'):
        raise ValueError('Missing Apple delivery UUID.')
    return {k: receipt[k] for k in ('build-status', 'delivery-uuid', 'bundle-short-version-string', 'bundle-version')}


if __name__ == '__main__':
    try:
        receipt = receipt_from_output(Path(sys.argv[1]).read_text(), os.environ['MARKETING_VERSION'], os.environ['BUILD_NUMBER'])
    except ValueError as error:
        sys.exit(str(error))
    Path('artifacts/apple-upload-receipt.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt, indent=2))
