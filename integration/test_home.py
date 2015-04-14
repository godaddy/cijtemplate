from unittest import TestCase
import requests
from conf import settings


class TestHome(TestCase):

    def setUp(self):
        if getattr(self.__class__, 'session', None) is None:
            print('TestHome.setUp: CREATING SESSION')
            self.__class__.session = requests.Session()

    def test_000_home_loads(self):
        print('TestHome.test_000_home_loads: {}'.format(settings.URL))
        resp = self.__class__.session.get(settings.URL, allow_redirects=True)
        self.assertEqual(resp.status_code, 200)
        self.assertIn('Copyright', resp.content.decode('UTF-8'))
