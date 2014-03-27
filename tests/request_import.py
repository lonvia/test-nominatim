""" Steps for setting up imports and update
"""

from nose.tools import *
from lettuce import *
import psycopg2
import psycopg2.extensions
import psycopg2.extras
import os
import subprocess
import random
import base64

psycopg2.extensions.register_type(psycopg2.extensions.UNICODE)

@before.each_scenario
def setup_test_database(scenario):
    if scenario.feature.tags is not None and 'DB' in scenario.feature.tags:
        world.db_template_setup()
        world.write_nominatim_config(world.config.test_db)
        conn = psycopg2.connect(database=world.config.template_db)
        conn.set_isolation_level(0)
        cur = conn.cursor()
        cur.execute('DROP DATABASE IF EXISTS %s' % (world.config.test_db, ))
        cur.execute('CREATE DATABASE %s TEMPLATE = %s' % (world.config.test_db, world.config.template_db))
        conn.close()
        world.conn = psycopg2.connect(database=world.config.test_db)
        psycopg2.extras.register_hstore(world.conn, globally=False, unicode=True)


@after.each_scenario
def tear_down_test_database(scenario):
    if hasattr(world, 'conn'):
        world.conn.close()
    if scenario.feature.tags is not None and 'DB' in scenario.feature.tags:
        conn = psycopg2.connect(database=world.config.template_db)
        conn.set_isolation_level(0)
        cur = conn.cursor()
        cur.execute('DROP DATABASE %s' % (world.config.test_db,))
        conn.close()

def _insert_place_table_nodes(places, force_name):
    cur = world.conn.cursor()
    for line in places:
        cols = dict(line)
        cols['osm_type'] = 'N'
        if 'name' in cols:
            cols['name'] = world.make_hash(cols['name'])
        elif force_name:
            cols['name'] = { 'name' : base64.urlsafe_b64encode(os.urandom(int(random.random()*30))) }
        if 'extratags' in cols:
            cols['extratags'] = world.make_hash(cols['extratags'])
        if 'geometry' in cols:
            coords = tuple([float(x) for x in cols['geometry'].split(',')])
            del(cols['geometry'])
        else:
            coords = (random.random()*360 - 180, random.random()*180 - 90)

        query = 'INSERT INTO place (%s, geometry) values(%s, %s)' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              "ST_SetSRID(ST_Point(%f, %f), 4326)" % coords
             )
        cur.execute(query, cols.values())
    world.conn.commit()


def _insert_place_table_ways(places, force_name):
    cur = world.conn.cursor()
    for line in places:
        cols = dict(line)
        cols['osm_type'] = 'W'
        if 'name' in cols:
            cols['name'] = world.make_hash(cols['name'])
        elif force_name:
            cols['name'] = { 'name' : base64.urlsafe_b64encode(os.urandom(int(random.random()*30))) }
        if 'extratags' in cols:
            cols['extratags'] = world.make_hash(cols['extratags'])
        coords = cols['geometry']
        del(cols['geometry'])

        query = 'INSERT INTO place (%s, geometry) values(%s, %s)' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              "ST_SetSRID('LINESTRING(%s)'::geometry, 4326)" % (coords,)
             )
        cur.execute(query, cols.values())
    world.conn.commit()

def _insert_place_table_areas(places, force_name):
    cur = world.conn.cursor()
    for line in places:
        cols = dict(line)
        if 'name' in cols:
            cols['name'] = world.make_hash(cols['name'])
        elif force_name:
            cols['name'] = { 'name' : base64.urlsafe_b64encode(os.urandom(int(random.random()*30))) }
        if 'extratags' in cols:
            cols['extratags'] = world.make_hash(cols['extratags'])
        coords = cols['geometry']
        del(cols['geometry'])

        query = 'INSERT INTO place (%s, geometry) values(%s, %s)' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              "ST_SetSRID('POLYGON((%s))'::geometry, 4326)" % (coords,)
             )
        cur.execute(query, cols.values())
    world.conn.commit()


@step(u'the (named )?place (node|way|area)s')
def import_place_table_nodes(step, named, osmtype):
    """Insert a list of nodes into the placex table.
       Expects a table where columns are named in the same way as placex.
    """
    cur = world.conn.cursor()
    cur.execute('ALTER TABLE place DISABLE TRIGGER place_before_insert')
    if osmtype == 'node':
        _insert_place_table_nodes(step.hashes, named is None)
    elif osmtype == 'way' :
        _insert_place_table_ways(step.hashes, named is None)
    elif osmtype == 'area' :
        _insert_place_table_areas(step.hashes, named is None)
    cur.execute('ALTER TABLE place ENABLE TRIGGER place_before_insert')
    cur.close()
    world.conn.commit()



@step(u'updating place (node|way|area)s')
def update_place_table_nodes(step, osmtype):
    world.run_nominatim_script('setup', 'create-functions', 'enable-diff-updates')
    if osmtype == 'node':
        _insert_place_table_nodes(step.hashes)
    elif osmtype == 'way':
        _insert_place_table_ways(step.hashes)
    elif osmtype == 'area':
        _insert_place_table_areas(step.hashes)
    world.run_nominatim_script('update', 'index')

@step(u'importing')
def import_database(step):
    cur = world.conn.cursor()
    cur.execute("""insert into placex (osm_type, osm_id, class, type, name, admin_level,
			       housenumber, street, addr_place, isin, postcode, country_code, extratags,
			       geometry) select * from place""")
    world.conn.commit()
    world.run_nominatim_script('setup', 'index', 'index-noanalyse')

