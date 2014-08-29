""" Steps for setting up a test database for osm2pgsql import.

    Note that osm2pgsql features need a database and therefore need
    to be tagged with @DB.
"""

from nose.tools import *
from lettuce import *

import logging
import random
import tempfile
import os
import subprocess

logger = logging.getLogger(__name__)

@before.each_scenario
def osm2pgsql_setup_test(scenario):
    world.osm2pgsql = []

@step(u'the osm nodes:')
def osm2pgsql_import_nodes(step):
    """ Define a list of OSM nodes to be imported, given as a table.
        Each line describes one node with all its attributes.
        'id' is mendatory, all other fields are filled with random values
        when not given. If 'tags' is missing an empty tag list is assumed.
        For updates, a mandatory 'action' column needs to contain 'A' (add),
        'M' (modify), 'D' (delete).
    """
    for line in step.hashes:
        node = { 'type' : 'N', 'version' : '1', 'timestamp': "2012-05-01T15:06:20Z",  
                 'changeset' : "11470653", 'uid' : "122294", 'user' : "foo"
               }
        node.update(line)
        node['id'] = int(node['id'])
        if not 'lon' in node:
            node['lon'] = random.random()*360 - 180
        if not 'lat' in node:
            node['lat'] = random.random()*180 - 90
        if 'tags' in node:
            node['tags'] = world.make_hash(line['tags'])
        else:
            node['tags'] = None

        world.osm2pgsql.append(node)

def _sort_xml_entries(x, y):
    if x['type'] == y['type']:
        return cmp(x['id'], y['id'])
    else:
        return cmp('NWR'.find(x['type']), 'NWR'.find(y['type']))

def write_osm_obj(fd, obj):
    if obj['type'] == 'N':
        fd.write('<node id="%(id)d" lat="%(lat).8f" lon="%(lon).8f" version="%(version)s" timestamp="%(timestamp)%" changeset="%(changeset)s" uid="%(uid)s" user="%(user)s"'% obj)
        if obj['tags'] is None:
            fd.write('/>\n')
        else:
            fd.write('>\n')
            for k,v in obj['tags'].iteritems():
                fd.write('  <tag k="%s" v="%s"/>\n' % (k, v))
            fd.write('</node>\n')
    elif obj['type'] == 'W':
        pass
    elif obj['type'] == 'R':
        pass

@step(u'loading osm data')
def osm2pgsql_load_place(step):
    """Imports the previously defined OSM data into a fresh copy of a
       Nominatim test database.
    """

    world.osm2pgsql.sort(cmp=_sort_xml_entries)

    # create a OSM file in /tmp
    with tempfile.NamedTemporaryFile(dir='/tmp', delete=False) as fd:
        fname = fd.name
        fd.write("<?xml version='1.0' encoding='UTF-8'?>\n")
        fd.write('<osm version="0.6" generator="test-nominatim" timestamp="2014-08-26T20:22:02Z">\n')
        fd.write('\t<bounds minlat="43.72335" minlon="7.409205" maxlat="43.75169" maxlon="7.448637"/>\n')
        
        for obj in world.osm2pgsql:
            write_osm_obj(fd, obj)

        fd.write('</osm>\n')

    logger.debug( "Filename: %s" % fname)

    cmd = [os.path.join(world.config.source_dir, 'utils', 'setup.php')]
    cmd.extend(['--osm-file', fname, '--import-data'])
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (outp, outerr) = proc.communicate()
    assert (proc.returncode == 0), "OSM data import failed:\n%s\n%s\n" % (outp, outerr)
        
    os.remove(fname)
