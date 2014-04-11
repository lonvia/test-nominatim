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


def _format_placex_cols(cols, geomtype, force_name):
    if 'name' in cols:
        cols['name'] = world.make_hash(cols['name'])
    elif force_name:
        cols['name'] = { 'name' : base64.urlsafe_b64encode(os.urandom(int(random.random()*30))) }
    if 'extratags' in cols:
        cols['extratags'] = world.make_hash(cols['extratags'])
    if 'admin_level' not in cols:
        cols['admin_level'] = 100
    if 'geometry' in cols:
        coords = world.get_scenario_geometry(cols['geometry'])
        if coords is None:
            coords = "'%s(%s)'::geometry" % (geomtype, cols['geometry'])
        else:
            coords = "'%s'::geometry" % coords.wkt
        cols['geometry'] = coords


def _insert_place_table_nodes(places, force_name):
    cur = world.conn.cursor()
    for line in places:
        cols = dict(line)
        cols['osm_type'] = 'N'
        _format_placex_cols(cols, 'ST_POINT', force_name)
        if 'geometry' in cols:
            coords = cols.pop('geometry')
        else:
            coords = "ST_Point(%f, %f)" % (random.random()*360 - 180, random.random()*180 - 90)

        query = 'INSERT INTO place (%s,geometry) values(%s, ST_SetSRID(%s, 4326))' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              coords
             )
        cur.execute(query, cols.values())
    world.conn.commit()


def _insert_place_table_ways(places, force_name):
    cur = world.conn.cursor()
    for line in places:
        cols = dict(line)
        cols['osm_type'] = 'W'
        _format_placex_cols(cols, 'LINESTRING', force_name)
        coords = cols.pop('geometry')

        query = 'INSERT INTO place (%s, geometry) values(%s, ST_SetSRID(%s, 4326))' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              coords
             )
        cur.execute(query, cols.values())
    world.conn.commit()

def _insert_place_table_areas(places, force_name):
    cur = world.conn.cursor()
    for line in places:
        cols = dict(line)
        _format_placex_cols(cols, 'POLYGON', force_name)
        coords = cols.pop('geometry')

        query = 'INSERT INTO place (%s, geometry) values(%s, ST_SetSRID(%s, 4326))' % (
              ','.join(cols.iterkeys()),
              ','.join(['%s' for x in range(len(cols))]),
              coords
             )
        cur.execute(query, cols.values())
    world.conn.commit()

@step(u'the scenario (.*)')
def import_set_scenario(step, scenario):
    world.load_scenario(scenario)

@step(u'the (named )?place (node|way|area)s')
def import_place_table_nodes(step, named, osmtype):
    """Insert a list of nodes into the placex table.
       Expects a table where columns are named in the same way as placex.
    """
    cur = world.conn.cursor()
    cur.execute('ALTER TABLE place DISABLE TRIGGER place_before_insert')
    if osmtype == 'node':
        _insert_place_table_nodes(step.hashes, named is not None)
    elif osmtype == 'way' :
        _insert_place_table_ways(step.hashes, named is not None)
    elif osmtype == 'area' :
        _insert_place_table_areas(step.hashes, named is not None)
    cur.execute('ALTER TABLE place ENABLE TRIGGER place_before_insert')
    cur.close()
    world.conn.commit()



@step(u'updating place (node|way|area)s')
def update_place_table_nodes(step, osmtype):
    world.run_nominatim_script('setup', 'create-functions', 'create-partition-functions', 'enable-diff-updates')
    if osmtype == 'node':
        _insert_place_table_nodes(step.hashes, False)
    elif osmtype == 'way':
        _insert_place_table_ways(step.hashes, False)
    elif osmtype == 'area':
        _insert_place_table_areas(step.hashes, False)
    world.run_nominatim_script('update', 'index')


@step(u'importing')
def import_database(step):
    world.run_nominatim_script('setup', 'create-functions', 'create-partition-functions')
    cur = world.conn.cursor()
    cur.execute("""insert into placex (osm_type, osm_id, class, type, name, admin_level,
			       housenumber, street, addr_place, isin, postcode, country_code, extratags,
			       geometry) select * from place""")
    world.conn.commit()
    world.run_nominatim_script('setup', 'index', 'index-noanalyse')
    #world.db_dump_table('placex')

@step(u'marking for delete (.*)')
def update_delete_places(step, places):
    world.run_nominatim_script('setup', 'create-functions', 'create-partition-functions', 'enable-diff-updates')
    cur = world.conn.cursor()
    for place in places.split(','):
        osmtype, osmid, cls = world.split_id(place)
        if cls is None:
            q = "delete from place where osm_type = %s and osm_id = %s"
            params = (osmtype, osmid)
        else:
            q = "delete from place where osm_type = %s and osm_id = %s and class = %s"
            params = (osmtype, osmid, cls)
        cur.execute(q, params)
    world.conn.commit()
    #world.db_dump_table('placex')
    world.run_nominatim_script('update', 'index')

