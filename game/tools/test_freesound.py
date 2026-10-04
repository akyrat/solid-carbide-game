"""Tests for freesound.py: everything that does not call Freesound.

Run from the repo root:  python -m unittest discover -s game/tools -p "test_*.py"
"""

import json
import os
import shutil
import sys
import tempfile
import unittest
import urllib.parse

sys.dont_write_bytecode = True
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import freesound as fs  # noqa: E402


SOUND = {
    "id": 123456,
    "name": "Car Engine Idle (V8).wav",
    "username": "someone",
    "url": "https://freesound.org/people/someone/sounds/123456/",
    "license": "http://creativecommons.org/licenses/by/4.0/",
    "type": "wav",
    "filesize": 1000,
    "duration": 4.2,
}


class EnvTests(unittest.TestCase):
    def test_parse_env_handles_comments_quotes_and_blank_lines(self):
        env = fs.parse_env(
            "# comment\n\nA=1\nB = \"two words\"\nC='x'  \nD=val   # trailing\nexport E=5\r\nF=\n")
        self.assertEqual(env, {"A": "1", "B": "two words", "C": "x", "D": "val", "E": "5", "F": ""})

    def test_load_credentials_missing_values_raises(self):
        d = tempfile.mkdtemp()
        try:
            path = os.path.join(d, ".env")
            with open(path, "w") as f:
                f.write("FREESOUND_CLIENT_ID=\nFREESOUND_API_KEY=\n")
            saved = {k: os.environ.pop(k, None) for k in ("FREESOUND_CLIENT_ID", "FREESOUND_API_KEY")}
            try:
                with self.assertRaises(fs.SystemExit_) as ctx:
                    fs.load_credentials(path)
                self.assertEqual(ctx.exception.code, 2)
            finally:
                for k, v in saved.items():
                    if v is not None:
                        os.environ[k] = v
        finally:
            shutil.rmtree(d)


class AuthUrlTests(unittest.TestCase):
    def test_authorize_url_has_only_client_id_and_response_type(self):
        url = fs.build_authorize_url("abc123")
        base, query = url.split("?", 1)
        self.assertEqual(base, "https://freesound.org/apiv2/oauth2/authorize/")
        self.assertEqual(urllib.parse.parse_qs(query), {"client_id": ["abc123"], "response_type": ["code"]})


class TokenTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.path = os.path.join(self.dir, ".secrets", "freesound_token.json")

    def tearDown(self):
        shutil.rmtree(self.dir)

    def test_token_record_computes_expiry(self):
        rec = fs.token_record_from_response(
            {"access_token": "a", "refresh_token": "r", "expires_in": 86399, "scope": "read write"}, 1000)
        self.assertEqual(rec["expires_at"], 1000 + 86399)
        self.assertEqual(rec["refresh_token"], "r")

    def test_token_record_without_access_token_fails(self):
        with self.assertRaises(fs.ApiError):
            fs.token_record_from_response({"error": "invalid_grant"}, 0)

    def test_expiry_uses_margin(self):
        rec = {"expires_at": 1000}
        self.assertFalse(fs.token_is_expired(rec, 900))
        self.assertTrue(fs.token_is_expired(rec, 950))   # inside the 60 s margin
        self.assertTrue(fs.token_is_expired(rec, 2000))

    def test_valid_token_is_used_without_any_request(self):
        fs.save_token({"access_token": "A1", "refresh_token": "R1", "expires_at": 5000}, self.path)

        def post(*a, **k):
            raise AssertionError("must not call Freesound")
        self.assertEqual(fs.get_access_token("cid", "sec", self.path, post=post, now=100), "A1")

    def test_expired_token_is_refreshed_and_saved(self):
        fs.save_token({"access_token": "A1", "refresh_token": "R1", "expires_at": 100}, self.path)
        calls = []

        def post(method, url, data):
            calls.append(data)
            return {"access_token": "A2", "refresh_token": "R2", "expires_in": 86400}
        self.assertEqual(fs.get_access_token("cid", "sec", self.path, post=post, now=200), "A2")
        self.assertEqual(calls[0]["grant_type"], "refresh_token")
        self.assertEqual(calls[0]["refresh_token"], "R1")
        self.assertEqual(calls[0]["client_id"], "cid")
        saved = fs.load_token(self.path)
        self.assertEqual(saved["access_token"], "A2")
        self.assertEqual(saved["refresh_token"], "R2")
        self.assertEqual(saved["expires_at"], 200 + 86400)

    def test_refresh_keeps_old_refresh_token_if_none_returned(self):
        fs.save_token({"access_token": "A1", "refresh_token": "R1", "expires_at": 0}, self.path)
        fs.get_access_token("c", "s", self.path,
                            post=lambda *a: {"access_token": "A2", "expires_in": 10}, now=5)
        self.assertEqual(fs.load_token(self.path)["refresh_token"], "R1")

    def test_rejected_refresh_means_login_needed(self):
        fs.save_token({"access_token": "A1", "refresh_token": "R1", "expires_at": 0}, self.path)

        def post(*a):
            raise fs.ApiError("HTTP 400")
        with self.assertRaises(fs.LoginNeeded):
            fs.get_access_token("c", "s", self.path, post=post, now=10)

    def test_no_token_file_means_login_needed(self):
        with self.assertRaises(fs.LoginNeeded):
            fs.get_access_token("c", "s", self.path, now=0)

    def test_exchange_code_sends_no_redirect_uri(self):
        sent = {}

        def post(method, url, data):
            sent.update(data)
            return {"access_token": "A", "refresh_token": "R", "expires_in": 60}
        rec = fs.exchange_code(" CODE \n", "cid", "sec", post=post, now=0)
        self.assertEqual(sent, {"client_id": "cid", "client_secret": "sec",
                                "grant_type": "authorization_code", "code": "CODE"})
        self.assertEqual(rec["access_token"], "A")


class LicenseTests(unittest.TestCase):
    def test_license_names(self):
        cases = {
            "http://creativecommons.org/publicdomain/zero/1.0/": "CC0 1.0",
            "https://creativecommons.org/licenses/by/4.0/": "CC BY 4.0",
            "http://creativecommons.org/licenses/by/3.0/": "CC BY 3.0",
            "https://creativecommons.org/licenses/by-nc/4.0/": "CC BY-NC 4.0",
            "http://creativecommons.org/licenses/sampling+/1.0/": "CC Sampling+ 1.0",
        }
        for url, name in cases.items():
            self.assertEqual(fs.license_from_api(url)[0], name, url)

    def test_license_url_is_https(self):
        self.assertEqual(fs.license_from_api("http://creativecommons.org/licenses/by/4.0/")[1],
                         "https://creativecommons.org/licenses/by/4.0/")

    def test_plain_license_names(self):
        self.assertEqual(fs.license_from_api("Creative Commons 0")[0], "CC0 1.0")
        self.assertEqual(fs.license_from_api("Attribution NonCommercial")[0], "CC BY-NC 4.0")


class MetadataTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.dir)

    def test_base_name_is_id_and_slug(self):
        self.assertEqual(fs.file_base_name(SOUND), "123456_car-engine-idle-v8")
        self.assertEqual(fs.file_base_name({"id": 5, "name": "!!!"}), "5_sound")

    def test_id_from_page_url(self):
        self.assertEqual(fs.id_from_page_url(SOUND["url"]), 123456)
        self.assertIsNone(fs.id_from_page_url("https://freesound.org/people/x/"))

    def test_build_metadata_has_all_required_fields(self):
        meta = fs.build_metadata(SOUND, "car engine idle", "2026-10-04", "123456_x.wav")
        for key in fs.REQUIRED_METADATA_FIELDS:
            self.assertNotIn(meta[key], (None, ""), key)
        self.assertEqual(meta["license_name"], "CC BY 4.0")
        self.assertEqual(meta["freesound_id"], 123456)
        self.assertEqual(fs.validate_metadata(meta), [])

    def test_write_metadata_round_trip(self):
        meta = fs.build_metadata(SOUND, "q", "2026-10-04", "f.wav")
        path = os.path.join(self.dir, "123456_x.json")
        fs.write_metadata(path, meta)
        with open(path, encoding="utf-8") as f:
            self.assertEqual(json.load(f), meta)
        self.assertEqual(fs.existing_ids(self.dir), {123456})

    def test_write_metadata_rejects_empty_field(self):
        meta = fs.build_metadata(SOUND, "", "2026-10-04", "f.wav")
        with self.assertRaises(ValueError):
            fs.write_metadata(os.path.join(self.dir, "a.json"), meta)
        self.assertFalse(os.path.exists(os.path.join(self.dir, "a.json")))

    def test_validate_catches_id_url_mismatch(self):
        meta = fs.build_metadata(dict(SOUND, id=999), "q", "2026-10-04", "f.wav")
        self.assertIn("freesound_id does not match freesound_url", fs.validate_metadata(meta))


class PickTests(unittest.TestCase):
    def test_pick_skips_unimportable_types_and_existing_ids(self):
        results = [
            {"id": 1, "type": "flac"},
            {"id": 2, "type": "wav"},
            {"id": 3, "type": "mp3"},
            {"id": 4, "type": "aiff"},
            {"id": 5, "type": "ogg"},
            {"id": 6, "type": "wav"},
        ]
        self.assertEqual([s["id"] for s in fs.pick_sounds(results, 3, skip_ids={3})], [2, 5, 6])

    def test_search_filter(self):
        self.assertEqual(fs.search_filter(5000), "type:(wav OR ogg OR mp3) filesize:[* TO 5000]")
        self.assertEqual(fs.search_filter(0), "type:(wav OR ogg OR mp3)")


if __name__ == "__main__":
    unittest.main()
