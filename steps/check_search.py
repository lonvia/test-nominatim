from lettuce import *
from nose.tools import *


@step('valid search xml is returned')
def search_validate_xml(step):
    world.call()
    assert world.results.nodeName == "searchresults", \
            "Unexpected element '%s'" % world.results.nodeName
    assert world.results.hasAttribute('attribution')
    assert world.results.hasAttribute('timestamp')
    assert world.results.hasAttribute('querystring')
    assert world.results.hasAttribute('more_url')
    for node in world.results.childNodes:
        if node.nodeType == 1:
            assert_equals("place", node.nodeName)

@step('valid search json is returned')
def search_validate_json(step):
    world.call()
    assert isinstance(world.results, list), "Result is not a list, it is %s" % type(world.results)
    

def compare(operator, op1, op2):
    if operator == 'less than':
        return op1 < op2
    elif operator == 'more than':
        return op1 > op2
    elif operator == 'exactly':
        return op1 == op2
    elif operator == 'at least':
        return op1 >= op2
    elif operator == 'at most':
        return op1 <= op2
    else:
        raise Exception("unknown operator '%s'" % operator)

@step('(less than|more than|exactly|at least|at most) (\d+) results? (?:is|are) returned')
def validate_result_number(step, operator, number):
    world.params['format'] = 'json'
    step.given('valid search json is returned')
    number = int(number)
    numres = len(world.results)
    assert compare(operator, numres, number), \
        "Bad number of results: expected %s %d, got %d." % (operator, number, numres)

@step('(less than|more than|exactly|at least|at most) (\d+) xml results? (?:is|are) returned')
def validate_result_number(step, operator, number):
    world.params['format'] = 'xml'
    step.given('valid search xml is returned')
    number = int(number)
    numres = len(world.results.getElementsByTagName('place'))
    assert compare(operator, numres, number), \
        "Bad number of results: expected %s %d, got %d." % (operator, number, numres)


@step('Then result (\d+) starts with "(.*)"')
def run_validate_display_name_start(step, resnum, result):
    step.given('at least %s results are returned' % resnum)
    assert world.results[int(resnum)-1]['display_name'].startswith(result), "Expected result to start with '%s', got '%s'." % (result, world.results[int(resnum)-1]['display_name'])


@step('there are( no)? duplicates')
def search_check_for_duplicates(step, nodups=None):
    step.given('at least 1 result is returned')
    resarr = []
    for res in world.results:
        resarr.append((res['osm_type'], res['class'],
                        res['type'], res['display_name']))

    if nodups is None:
        assert len(resarr) > len(set(resarr))
    else:
        assert_equal(len(resarr), len(set(resarr)))


@step('result (\d+) has attributes (\S+)')
def search_check_for_result_attribute(step, num, attrs):
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    for attr in attrs.split(','):
        assert attr in res, "Attribute %s missing" % attr

@step('result (\d+) has not attributes (\S+)')
def search_check_for_result_attribute(step, num, attrs):
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    for attr in attrs.split(','):
        assert attr not in res, "Unexpected attribute '%s'" % attr


@step('xml result (\d+) has attributes (\S+)')
def search_xml_check_for_result_attribute(step, num, attrs):
    step.given('at least %s xml results are returned' % num)
    res = world.results.getElementsByTagName('place')[int(num)-1]
    for attr in attrs.split(','):
        assert res.hasAttribute(attr), "Attribute %s missing" % attr


@step('xml result (\d+) has not attributes (\S+)')
def search_xml_check_for_result_attribute(step, num, attrs):
    step.given('at least %s xml results are returned' % num)
    res = world.results.getElementsByTagName('place')[int(num)-1]
    for attr in attrs.split(','):
        assert res.hasAttribute(attr), "Unexpected attribute '%s'" % attr


@step('result (\d+) has rank (\d+) to (\d+)')
def search_check_for_result_rank(step, num, low, hi):
    step.given('at least %s xml results are returned' % num)
    res = world.results.getElementsByTagName('place')[int(num)-1]
    assert res.hasAttribute('place_rank'), "Attribute place_rank missing"
    rank = int(res.getAttribute('place_rank'))
    assert_greater_equal(rank, int(low))
    assert_less_equal(rank, int(hi))


@step('result (\d+) has attribute (\S+) as "(.*)"')
def search_check_for_result_attribute(step, num, attr, value):
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    assert attr in res
    assert_equals(res[attr], value)


@step('result (\d+) is in "(.*)"')
def search_check_for_result_isin(step, num, location):
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    addressparts = [ x.strip() for x in res['display_name'].split(',') ]
    assert location in addressparts, "Unexpected address '%s'" % res['display_name']


@step('name of result (\d+) contains "(.*)"')
def search_check_for_result_isin(step, num, name):
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    namepart = res['display_name'].split(',', 1)[0].lower()
    assert name.lower() in namepart, "Unexpected address '%s'" % res['display_name']


@step('(xml )?result (\d+) has address details with(out)? "(.*)"')
def search_check_for_address_details(step, isxml, num, neg, name):
    if isxml:
        step.given('at least %s xml results are returned' % (num))
        res = world.results.getElementsByTagName('place')[int(num)-1]
        chld = res.firstChild
        while chld is not None:
            if chld.firstChild is not None:
                if chld.firstChild.nodeValue == name:
                    return
            chld = chld.nextSibling
        assert not "No such content in address."
    else:
        step.given('at least %s results are returned' % (num))
        res = world.results[int(num)-1]
        assert 'address' in res
        if neg:
            assert_not_in(name, res['address'].values())
        else:
            assert_in(name, res['address'].values())


@step('address (\d+) has details with(out)? type (.*)')
def search_check_for_address_detail_type(step, num, neg, name):
    world.params['addressdetails'] = 1
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    assert 'address' in res
    if neg:
        assert_not_in(name, res['address'])
    else:
        assert_in(name, res['address'])



@step('address (\d+) contains (\w+) "(.*)"')
def search_check_for_address_content(step, num, addrtype, addrname):
    world.params['addressdetails'] = 1
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    assert 'address' in res
    assert_in(addrtype, res['address'])
    assert_equals(addrname, res['address'][addrtype])


@step('address (\d+) contains the following:')
def search_check_for_address_contents(step, num):
    world.params['addressdetails'] = 1
    step.given('at least %s results are returned' % num)
    res = world.results[int(num)-1]
    assert 'address' in res
    for detail in step.hashes:
        assert_in(detail['type'], res['address'])
        assert_equals(detail['value'], res['address'][detail['type']])


@step('(xml )?result (\d+) has address details in order ([\w,]+)')
def search_check_address_detail_order(step, isxml, num, partstr):
    parts = [ x.strip() for x in partstr.split(',')]
    if isxml:
        step.given('at least %s xml results are returned' % num)
        res = world.results.getElementsByTagName('place')[int(num)-1]
        chld = res.firstChild
        returnedparts = []
        while chld is not None:
            if chld.firstChild is not None and chld.nodeName != 'geokml':
                returnedparts.append(chld.nodeName)
            chld = chld.nextSibling
    else:
        step.given('at least %s results are returned' % num)
        res = world.results[int(num)-1]
        assert 'address' in res
        returnedparts = res['address'].keys()
    assert_equals(parts, returnedparts)


@step('xml result (\d+) has no address details')
def search_xml_check_no_address_details(step, num):
    step.given('at least %s xml results are returned' % num)
    res = world.results.getElementsByTagName('place')[int(num)-1]
    chld = res.firstChild
    while chld is not None:
        assert chld.firstChild is None or chld.nodeName == 'geokml'
        chld = chld.nextSibling

