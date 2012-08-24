#!/usr/bin/env python

import unittest
from mako.template import Template

class TestTemplate(unittest.TestCase):

    def test_template(self):
        mytemplate = Template(filename='appserver/event_renderers/tweets_with_image.html')
