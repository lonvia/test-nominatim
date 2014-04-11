""" Steps for checking results of import and update tests.

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
        osmobj = re.match('(N|R|W)(\d+)', line['object'])
        cur.execute('SELECT * FROM placex where osm_type = %s and osm_id =%s', (osmobj.group(1), int(osmobj.group(2))))
        assert(cur.rowcount > 0)
        for res in cur:
            for k,v in line.iteritems():
                if not k == 'object':
                    assert_in(k, res)
                    if type(res[k]) is dict:
                        val = world.make_hash(v)
                        assert_equals(res[k], val)
                    else:
                        assert_equals(str(res[k]), v)

@step(u'table placex has no entry for (N|R|W)(\d+)')
def check_placex_missing(step, osmtyp, osmid):
    cur = world.conn.cursor()
    cur.execute('SELECT count(*) FROM placex where osm_type = %s and osm_id =%s', (osmtyp, int(osmid)))
    numres = cur.fetchone()[0]
    assert_equals (numres, 0)

@world.absorb
def query_cmd(query):
    cmd = [os.path.join(world.config.source_dir, 'utils', 'query.php'),
           '--search', query]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (outp, err) = proc.communicate()
    assert (proc.returncode == 0), "query.php failed with message: %s" % err
    world.results = json.JSONDecoder(object_pairs_hook=OrderedDict).decode(outp)
    
    
@step(u'query "([^"]*)" returns nothing')
def check_simple_query(step, query):
    world.query_cmd(query)
    assert_equals(len(world.results), 0)


@step(u'query "([^"]*)" returns (N|R|W)(\d+)')
def check_simple_query(step, query, osmtype, osmid):
    world.query_cmd(query)
    assert_equals(len(world.results), 1)

    res = world.results[0]
    assert_equals(res['osm_type'], osmtype)
    assert_equals(res['osm_id'], osmid)

@step(u'parent of (N|R|W)(\d+) is (N|R|W)(\d+)')
def check_parent_placex(step, childtype, childid, parenttype, parentid):
    cur = world.conn.cursor()
    cur.execute("""SELECT p.osm_type, p.osm_id
                   FROM placex p, placex c
                   WHERE c.osm_type = %s AND c.osm_id = %s
                    AND  p.place_id = c.parent_place_id""", (childtype, int(childid)))
    res = cur.fetchone()
    assert (res is not None), "Object not found or has no parent"
    assert_equals(res[0], parenttype)
    assert_equals(res[1], int(parentid))
    world.conn.commit()
