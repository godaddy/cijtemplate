from django.test import TestCase
from cijtemplate.views import home
from unittest.mock import patch, MagicMock



# Create your tests here.
class HomeTests(TestCase):

    @patch('cijtemplate.views.render')
    def test_home(self, render):
        request = MagicMock()
        home(request)
        render.assert_called_once_with(request, 'home.html', {})
