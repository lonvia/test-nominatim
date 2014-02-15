""" Steps for import checks.
"""

from nose.tools import *
from lettuce import *
import psycopg2
import psycopg2.extensions
import psycopg2.extras
import os
import subprocess
import random

psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)

@before.each_scenario
def setup_test_database(scenario):
    if 'DB' in scenario.feature.tags:
        conn = psycopg2.connect(database=world.config.template_db)
        conn.set_isolation_level(0)
        cur = conn.cursor()
        cur.execute('DROP DATABASE IF EXISTS %s' % (world.config.test_db, ))
        cur.execute('CREATE DATABASE %s TEMPLATE = %s' % (world.config.test_db, world.config.template_db))
        conn.close()
        world.conn = psycopg2.connect(database=world.config.test_db)
        psycopg2.extras.register_hstore(world.conn, globally=False, unicode=True)


#@after.each_scenario
def tear_down_test_database(scenario):
    if 'DB' in scenario.feature.tags:
        conn = psycopg2.connect(database=world.config.template_db)
        conn.set_isolation_level(0)
        cur = conn.cursor()
        cur.execute('DROP DATABASE %s' % (world.config.test_db,))
        conn.close()


@step(u'the place nodes')
def fill_place_table_nodes(step):
    cur = world.conn.cursor()
    cur.execute('ALTER TABLE place DISABLE TRIGGER place_before_insert')
    for line in step.hashes:
        cols = dict(line)
        cols['osm_type'] = 'N'
        if 'name' in cols:
            cols['name'] = world.make_hash(cols['name'])
        if 'extratags' in cols:
            cols['extratags'] = world.make_hash(cols['extratags'])
        if 'geometry' in cols:
            coords = [float(x) for x in cols['geometry'].split(',')]
            del(cols['geometry'])
        else:
            coords = (random.random()*360 - 180, random.random()*180 - 90)

        query = 'INSERT INTO place (%s, geometry) values(%s, %s)' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              "ST_SetSRID(ST_Point(%f, %f), 4326)" % coords
             )
        cur.execute(query, cols.values())
    cur.execute('ALTER TABLE place ENABLE TRIGGER place_before_insert')
    world.conn.commit()

@step(u'importing')
def import_database(step):
    cur = world.conn.cursor()
    cur.execute("""insert into placex (osm_type, osm_id, class, type, name, admin_level,
			       housenumber, street, addr_place, isin, postcode, country_code, extratags,
			       geometry) select * from place""")
    world.conn.commit()


@step(U'placex contains for (N|R|W)(\d+)')
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
    world.conn.commit()
