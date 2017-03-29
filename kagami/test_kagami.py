from __future__ import absolute_import
from unittest import TestCase
from kagami import Kagami


class TestKagami(TestCase):
    def test_start_app(self):
        k = Kagami()
        k.start_app()
        self.assertEqual(k.run_application, 1)

    def test_stop_app(self):
        k = Kagami()
        k.stop_app()
        self.assertEqual(k.run_application, 0)

    def test_check_config(self):
        k = Kagami()
        self.assertRaises(Exception, k.check_config(k.cfg_dir))
        self.assertEqual(k.check_config(k.cfg_dir), False)

    def test_load_config(self):
        k = Kagami()
        self.assertEqual(k.load_config(), True)

    def test_syntax_config(self):
        k = Kagami()
        self.assertEqual(k.syntax_config(), False)
