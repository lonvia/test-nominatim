from lettuce import *
import os
import subprocess
import psycopg2

class NominatimConfig:

    def __init__(self):
        self.base_url = os.environ.get('NOMINATIM_SERVER', 'http://localhost/nominatim')
        self.source_dir = os.path.abspath(os.environ.get('NOMINATIM_DIR', '../Nominatim'))
        self.template_db = os.environ.get('TEMPLATE_DB', 'test_template_nominatim')
        self.test_db = os.environ.get('TEST_DB', 'test_nominatim')
        self.local_settings_file = os.environ.get('NOMINATIM_SETTINGS', '/tmp/nominatim_settings.php')
        self.reuse_template = 'NOMINATIM_REUSE_TEMPLATE' in os.environ
        os.environ['NOMINATIM_SETTINGS'] = '/tmp/nominatim_settings.php'


    def __str__(self):
        return 'Server URL: %s\nSource dir: %s\n' % (self.base_url, self.source_dir)

world.config = NominatimConfig()

@world.absorb
def write_nominatim_config(dbname):
    f = open(world.config.local_settings_file, 'w')
    f.write("<?php\n  @define('CONST_Database_DSN', 'pgsql://@/%s');\n" % dbname)
    f.close()


@world.absorb
def run_nominatim_script(script, *args):
    cmd = [os.path.join(world.config.source_dir, 'utils', '%s.php' % script)]
    cmd.extend(['--%s' % x for x in args])
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (outp, outerr) = proc.communicate()
    assert (proc.returncode == 0), "Script '%s' failed:\n%s\n%s\n" % (script, outp, outerr)

@world.absorb
def make_hash(inp):
    return eval('{' + inp + '}')


@world.absorb
def db_drop_database(name):
    conn = psycopg2.connect(database='postgres')
    conn.set_isolation_level(0)
    cur = conn.cursor()
    cur.execute('DROP DATABASE IF EXISTS %s' % (name, ))
    conn.close()


world.is_template_set_up = False

@world.absorb
def db_template_setup():
    """ Set up a template database, containing all tables
        but not yet any functions.
    """
    if world.is_template_set_up:
        return

    world.is_template_set_up = True
    world.write_nominatim_config(world.config.template_db)
    if world.config.reuse_template:
        # check that the template is there
        conn = psycopg2.connect(database='postgres')
        cur = conn.cursor()
        cur.execute('select count(*) from pg_database where datname = %s', 
                     (world.config.template_db,))
        if cur.fetchone()[0] == 1:
            return
    else:
        # just in case... make sure a previous table has been dropped
        world.db_drop_database(world.config.template_db)
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
    world.run_nominatim_script('setup', 'create-functions', 'create-tables', 'create-partition-tables', 'create-partition-functions', 'load-data', 'create-search-indices')



@after.all
def db_template_teardown(total):
    """ Set up a template database, containing all tables
        but not yet any functions.
    """
    if world.is_template_set_up:
        # remove template DB
        if not world.config.reuse_template:
            world.db_drop_database(world.config.template_db)
        try:
            os.remove(world.config.local_settings_file)
        except OSError:
            pass # ignore missing file
