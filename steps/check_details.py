""" Tests for details page.
"""

from lettuce import *
from nose.tools import *


@step('a details page is returned')
def details_validate_html(step):
    """ Check for a valid details page.
        Currently only tests that correct html is returned.
    """
    world.call()

