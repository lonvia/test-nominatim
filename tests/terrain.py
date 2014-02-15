from lettuce import world
import os
import subprocess

class NominatimConfig:

    def __init__(self):
        self.base_url = os.environ.get('NOMINATIM_SERVER', 'http://localhost/nominatim')
        self.source_dir = os.path.abspath(os.environ.get('NOMINATIM_DIR', '../Nominatim'))
        self.template_db = os.environ.get('TEMPLATE_DB', 'test_template_nominatim')
        self.test_db = os.environ.get('TEST_DB', 'test_nominatim')
        self.local_settings_file = os.environ.get('NOMINATIM_SETTINGS', '/tmp/nominatim_settings.php')
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
    world.write_nominatim_config(world.config.template_db)
    cmd = [os.path.join(world.config.source_dir, 'utils', '%s.php' % script)]
    cmd.extend(['--%s' % x for x in args])
    proc = subprocess.Popen(cmd)
    proc.wait() # XXX should become communicate
    assert (proc.returncode == 0)

@world.absorb
def make_hash(inp):
    return eval('{' + inp + '}')
