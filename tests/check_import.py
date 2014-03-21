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
from collections import OrderedDict


@step(u'table placex contains for (N|R|W)(\d+)')
def check_placex(step, osmtyp, osmid):
    cur = world.conn.cursor(cursor_factory=psycopg2.extras.DictCursor)
    cur.execute('SELECT * FROM placex where osm_type = %s and osm_id =%s', (osmtyp, int(osmid)))
    res = {}
    for line in cur:
        res['%s|%s' % (line['class'], line['type'])] = line
    for line in step.hashes:
        hid = '%s|%s' % (line['class'], line['type'])
        assert_in (hid, res)
        dbobj = res[hid]
        for k,v in line.iteritems():
            assert k in dbobj
            if type(dbobj[k]) is dict:
                val = world.make_hash(v)
            else:
                val = v
            assert_equals(val, dbobj[k])
        del(res[hid])
    assert_equal(len(res), 0)

@step(u'table placex has no entry for (N|R|W)(\d+)')
def check_placex_missing(step, osmtyp, osmid):
    cur = world.conn.cursor()
    cur.execute('SELECT count(*) FROM placex where osm_type = %s and osm_id =%s', (osmtyp, int(osmid)))
    assert_equals (cur.fetchone()[0], 0)



@world.absorb
def query_cmd(query):
    cmd = [os.path.join(world.config.source_dir, 'utils', 'query.php'),
           '--search', query]
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (outp, err) = proc.communicate()
    assert (proc.returncode == 0), "query.php failed with message: %s" % err
    world.results = json.JSONDecoder(object_pairs_hook=OrderedDict).decode(outp)
    
    


@step(u'query "([^"]*)" returns (N|R|W)(\d+)')
def check_simple_query(step, query, osmtype, osmid):
    world.query_cmd(query)
    assert_equals(len(world.results), 1)

    res = world.results[0]
    assert_equals(res['osm_type'], osmtype)
    assert_equals(res['osm_id'], osmid)