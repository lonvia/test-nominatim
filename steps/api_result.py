""" Steps for checking the results of queries.
"""

from nose.tools import *
from lettuce import *
from tidylib import tidy_document
from collections import OrderedDict
import json
import logging
import re
from xml.dom.minidom import parseString

logger = logging.getLogger(__name__)

def _parse_xml():
    """ Puts the DOM structure into more convenient python
        with a similar structure as the json document, so
        that the same the semantics can be used. It does not
        check if the content is valid (or at least not more than
        necessary to transform it into a dict structure).
    """
    page = parseString(world.page).documentElement

    # header info
    world.result_heder = OrderedDict(page.attributes.items())
    world.results = []

    # results
    if page.nodeName == 'searchresults':
        for node in page.childNodes:
            assert node.nodeName == 'place'
            newresult = OrderedDict(node.attributes.items())
            assert_not_in('address', newresult)
            assert_not_in('geokml', newresult)
            address = OrderedDict()
            for sub in node.childNodes:
                if sub.nodeName == 'geokml':
                    newresult['geokml'] = sub.childNodes[0].toxml()
                else:
                    address[sub.nodeName] = sub.firstChild.nodeValue.strip()
            if address:
                newresult['address'] = address
            world.results.append(newresult)
    elif page.nodeName == 'reversegeocode':
        haserror = False
        address = {}
        for node in page.childNodes:
            if node.nodeName == 'result':
                assert_equals(len(world.results), 0)
                assert (not haserror)
                world.results.append(OrderedDict(node.attributes.items()))
                assert_not_in('display_name', world.results[0])
                assert_not_in('address', world.results[0])
                world.results[0]['display_name'] = node.firstChild.nodeValue.strip()
            elif node.nodeName == 'error':
                assert_equals(len(world.results), 0)
                haserror = True
            elif node.nodeName == 'addressparts':
                assert (not haserror)
                address = OrderedDict()
                for sub in node.childNodes:
                    address[sub.nodeName] = sub.firstChild.nodeValue.strip()
                world.results[0]['address'] = address
            elif node.nodeName == "#text":
                pass
            else:
                assert False, "Unknown content '%s' in XML" % node.nodeName
    else:
        assert False, "Unknown document node name %s in XML" % page.nodeName

    logger.debug("The following was parsed out of XML:")
    logger.debug(world.results)


@step(u'the result is valid( \w+)?')
def api_result_is_valid(step, fmt):
    assert_equals(world.returncode, 200)

    if world.response_format == 'html':
        document, errors = tidy_document(world.page, 
                             options={'char-encoding' : 'utf8'})
        assert(len(errors) == 0), "Errors found in HTML document:\n%s" % errors
        world.results = document
    elif world.response_format == 'xml':
        _parse_xml()
    elif world.response_format == 'json':
        world.results = json.JSONDecoder(object_pairs_hook=OrderedDict).decode(world.page)
    else:
        assert False, "Unknown page format: %s" % (world.response_format)

    if fmt:
        assert_equals (fmt.strip(), world.response_format)


@step(u'results contain$')
def api_result_contains(step):
    step.given('the result is valid')
    for line in step.hashes:
        curres = world.results[int(line['ID'])]
        for k,v in line.iteritems():
            if k != 'ID':
                assert_in(k, curres)
                m = re.match("%s$" % (v,), curres[k])
                assert_is_not_none(m, msg="field %s does not match: %s$ != %s." % (k, v, curres[k]))


@step(u'result addresses contain$')
def api_result_address_contains(step):
    step.given('the result is valid')
    for line in step.hashes:
        curres = world.results[int(line['ID'])]
        assert_in('address', curres)
        curres = curres['address']
        for k,v in line.iteritems():
            if k != 'ID':
                assert_in(k, curres)
                assert_equals(curres[k], v)
