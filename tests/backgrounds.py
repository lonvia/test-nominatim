import psycopg2
import os
import subprocess
from lettuce import *

def _drop_database(name):
    conn = psycopg2.connect(database='postgres')
    conn.set_isolation_level(0)
    cur = conn.cursor()
    cur.execute('DROP DATABASE IF EXISTS %s' % (name, ))
    conn.close()

@before.all
def background_template_setup():
    """ Set up a template database, containing all tables
        but not yet any functions.
    """
    # just in case... make sure a previous table has been dropped
    _drop_database(world.config.template_db)
    # call the first part of database setup
    world.run_nominatim_script('setup', 'create-db', 'setup-db')
    # remove external data to speed up indexing for tests
    conn = psycopg2.connect(database=world.config.template_db)
    psycopg2.extras.register_hstore(conn, globally=False, unicode=True)
    cur = conn.cursor()
    for table in ('gb_postcode', 'us_postcode', 'us_state', 'us_statecounty'):
        cur.execute('TRUNCATE TABLE %s' % (table,))
    conn.commit()
    conn.close()
    # execute osm2pgsql on an empty file to get the right tables
    osm2pgsql = os.path.join(world.config.source_dir, 'osm2pgsql', 'osm2pgsql')
    proc = subprocess.Popen([osm2pgsql, '-lsc', '-O', 'gazetteer', '-d', world.config.template_db, '-'],
    stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    [outstr, errstr] = proc.communicate(input='<osm version="0.6"></osm>')
    world.run_nominatim_script('setup', 'create-functions', 'create-tables', 'create-partition-tables', 'create-partition-functions')



@after.all
def background_template_teardown(total):
    """ Set up a template database, containing all tables
        but not yet any functions.
    """
    # remove template DB
    _drop_database(world.config.template_db)
    os.remove(world.config.local_settings_file)
