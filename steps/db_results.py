""" Steps for checking the DB after import and update tests.

    There are two groups of test here. The first group tests
    the contents of db tables directly, the second checks
    query results by using the command line query tool.
"""

from nose.tools import *
from lettuce import *
import psycopg2
import psycopg2.extensions
import psycopg2.extras
import os
import subprocess
import random
import json
import re
from collections import OrderedDict


@step(u'table placex contains as names for (N|R|W)(\d+)')
def check_placex_names(step, osmtyp, osmid):
    """ Check for the exact content of the name hstaore in placex.
    """
    cur = world.conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    cur.execute('SELECT name FROM placex where osm_type = %s and osm_id =%s', (osmtyp, int(osmid)))
    for line in cur:
        names = dict(line['name'])
        for name in step.hashes:
            assert_in(name['k'], names)
            assert_equals(names[name['k']], name['v'])
            del names[name['k']]
        assert_equals(len(names), 0)


@step(u'table placex contains$')
def check_place_content(step):
    cur = world.conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    for line in step.hashes:
        osmtype, osmid, cls = world.split_id(line['object'])
        if cls is None:
            q = 'SELECT * FROM placex where osm_type = %s and osm_id = %s'
            params = (osmtype, osmid)
        else:
            q = 'SELECT * FROM placex where osm_type = %s and osm_id = %s and class = %s'
            params = (osmtype, osmid, cls)
        cur.execute(q, params)
        assert(cur.rowcount > 0)
        for res in cur:
            for k,v in line.iteritems():
                if not k == 'object':
                    assert_in(k, res)
                    if type(res[k]) is dict:
                        val = world.make_hash(v)
                        assert_equals(res[k], val)
                    elif k in ('parent_place_id', 'linked_place_id'):
                        pid = world.get_placeid(v)
                        assert_equals(pid, res[k], "Results for column '%s' differ: '%s' != '%s'" % (k, pid, res[k]))
                    else:
                        assert_equals(str(res[k]), v, "Results for column '%s' differ: '%s' != '%s'" % (k, str(res[k]), v))

@step(u'table placex has no entry for (N|R|W)(\d+)')
def check_placex_missing(step, osmtyp, osmid):
    cur = world.conn.cursor()
    cur.execute('SELECT count(*) FROM placex where osm_type = %s and osm_id =%s', (osmtyp, int(osmid)))
    numres = cur.fetchone()[0]
    assert_equals (numres, 0)

