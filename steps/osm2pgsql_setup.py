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
        if 'geometry' in node:
            lat, lon = node['geometry'].split(' ')
            node['lat'] = float(lat)
            node['lon'] = float(lon)
        else:
            node['lon'] = random.random()*360 - 180
            node['lat'] = random.random()*180 - 90
        if 'tags' in node:
            node['tags'] = world.make_hash(line['tags'])
        else:
            node['tags'] = None

        world.osm2pgsql.append(node)


@step(u'the osm ways:')
def osm2pgsql_import_ways(step):
    """ Define a list of OSM ways to be imported.
    """
    for line in step.hashes:
        way = { 'type' : 'W', 'version' : '1', 'timestamp': "2012-05-01T15:06:20Z",  
                 'changeset' : "11470653", 'uid' : "122294", 'user' : "foo"
               }
        way.update(line)

        way['id'] = int(way['id'])
        if 'tags' in way:
            way['tags'] = world.make_hash(line['tags'])
        else:
            way['tags'] = None
        way['nodes'] = way['nodes'].strip().split()

        world.osm2pgsql.append(way)

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
        fd.write('<way id="%(id)d" version="%(version)s" changeset="%(changeset)s" timestamp="%(timestamp)s" user="%(user)s" uid="%(uid)s">\n' % obj)
        for nd in obj['nodes']:
            fd.write('<nd ref="%s" />\n' % (nd,))
        if obj['tags'] is not None:
            for k,v in obj['tags'].iteritems():
                fd.write('  <tag k="%s" v="%s"/>\n' % (k, v))
        fd.write('</way>\n')
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
