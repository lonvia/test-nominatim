""" Steps for checking results of reverse requests.
"""

from lettuce import *
from nose.tools import *


@step('valid reverse json is returned')
def validate_reverse_hasresult(step):
    world.call()
    assert 'address' in world.results


@step('valid reverse xml is returned')
def validate_reverse_hasresult(step):
    world.call()
    # XXX check parameters


@step('the location address contains (.*) "(.*)"')
def validate_reverse_address(step, addresstype, addressvalue):
    world.params['format'] = 'json'
    step.given('valid reverse json is returned')
    assert addresstype in world.results['address'], "Expected address to contain '%s'. Got %s." % (addresstype, world.results['address'])
    assert world.results['address'][addresstype] == addressvalue, "Expected address '%s' to be '%s'. Got %s." % (addresstype, addressvalue, world.results['address'][addresstype])

