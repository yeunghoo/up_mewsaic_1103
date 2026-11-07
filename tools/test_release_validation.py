import unittest
import json
from check_apple_upload import receipt_from_output
from check_privacy import validate


class PrivacyValidationTests(unittest.TestCase):
    def test_tracking_requires_real_hostname(self):
        for domains in ([], ['https://ads.inmobi.com'], ['ads.inmobi.com/sdk'], ['ads.inmobi.com/'], ['*.inmobi.com'], [42]):
            with self.subTest(domains=domains), self.assertRaises(ValueError):
                validate({'NSPrivacyTracking': True, 'NSPrivacyTrackingDomains': domains})
        validate({'NSPrivacyTracking': True, 'NSPrivacyTrackingDomains': ['ads.inmobi.com']})

    def test_no_tracking_and_vendor_omission(self):
        validate({})
        validate({'NSPrivacyTracking': False, 'NSPrivacyTrackingDomains': []})
        with self.assertRaises(ValueError):
            validate({'NSPrivacyTracking': False, 'NSPrivacyTrackingDomains': ['ads.inmobi.com']})

    def test_boolean_not_string_or_integer(self):
        for value in ('true', 1):
            with self.assertRaises(ValueError):
                validate({'NSPrivacyTracking': value})


class AppleUploadTests(unittest.TestCase):
    def test_requires_matching_successful_processing(self):
        receipt = {'build-status': 'VALID_BINARY', 'delivery-uuid': 'test-delivery', 'bundle-short-version-string': '1.1.1', 'bundle-version': '3'}
        log = 'UPLOAD SUCCEEDED\n' + json.dumps(receipt) + '\n{"success-message":"Uploaded"}'
        self.assertEqual(receipt_from_output(log, '1.1.1', '3'), receipt)
        for bad_log in ('UPLOAD SUCCEEDED', 'ERROR: Expected delivery ID argument is missing (21)', log.replace('VALID_BINARY', 'INVALID_BINARY'), log.replace('1.1.1', '1.1.0')):
            with self.subTest(log=bad_log), self.assertRaises(ValueError):
                receipt_from_output(bad_log, '1.1.1', '3')


if __name__ == '__main__':
    unittest.main()
