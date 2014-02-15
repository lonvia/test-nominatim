from nose.tools import *
import urllib
import urllib2
import urlparse
from lettuce import *
from tidylib import tidy_document
import json
from xml.dom.minidom import parseString


@step('a HTTP (\d+) is returned')
def send_and_check_for_error_code(step, http_code='200'):
    data = urllib.urlencode(world.params)
    req = urllib2.Request(url="%s/%s?%s" % (world.config.base_url, world.requesttype, data),
                          headers=world.header)
    if http_code == '200':
        fd = urllib2.urlopen(req)
        page = fd.read()
    else:
        with assert_raises_regexp(urllib2.HTTPError, http_code):
            urllib2.urlopen(req)


@step('a valid response is returned')
def validate_general_result(step):
    """ Most general of result checks. Will only send the request to the API
        and make sure a 200 is returned and the formatting is valid.
    """
    world.call()


###### XML format in general ################################

@step('xml header does not contain attribute (\w+)')
def check_xml_header_has_not_attribute(step, attr):
    world.call()
    assert_false(world.result.hasAttribute(attr))


@step('xml header contains attribute (\w+) as "(.*)"')
def check_xml_header_has_attribute(step, attr, value):
    world.call()
    assert_true(world.results.hasAttribute(attr))
    assert_equals(world.results.getAttribute(attr), value)


@step('xml more url consists of')
def check_xml_more_url_contains(step):
    world.call()
    assert_true(world.results.hasAttribute('more_url'))
    moreurl = urlparse.urlparse(world.results.getAttribute('more_url'))
    params = urlparse.parse_qs(moreurl.query)
    for line in step.hashes:
        assert_true(line['param'] in params, "Missing parameter %s" % line['param'])
        paramvals = params[line['param']]
        assert_equal(len(paramvals), 1)
        assert_equal(paramvals[0], line['value'])
        del params[line['param']]
    assert_false(params)


@step(r'xml contains a viewbox of ([-\d.]+),([-\d.]+),([-\d.]+),([-\d.]+)')
def check_xml_viewbox(step, *attr):
    world.call()
    assert_true(world.results.hasAttribute('viewbox'))
    parts = world.results.getAttribute('viewbox').split(',')
    assert_equal(len(parts), 4)
    for i in range(4):
        assert_almost_equal(float(parts[i]), float(attr[i]))

