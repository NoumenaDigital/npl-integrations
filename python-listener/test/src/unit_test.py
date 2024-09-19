import unittest
from nose.tools import assert_is_not_none, assert_is_none, assert_equals

from src.auth import AuthService

class TestStringMethods(unittest.TestCase):

    def test_login(self):
        my_username = 'my_username'
        my_password = 'my_password'
        auth_service = AuthService()

        access_token = auth_service.auth(
            my_username,
            my_password
        )
        assert_is_not_none(access_token)

    def test_upper(self):
        self.assertEqual('foo'.upper(), 'FOO')

    def test_isupper(self):
        self.assertTrue('FOO'.isupper())
        self.assertFalse('Foo'.isupper())

    def test_split(self):
        s = 'hello world'
        self.assertEqual(s.split(), ['hello', 'world'])
        # check that s.split fails when the separator is not a string
        with self.assertRaises(TypeError):
            s.split(2)

if __name__ == '__main__':
    unittest.main()
