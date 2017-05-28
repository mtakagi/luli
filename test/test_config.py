from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_config/'

nosec_msg = "%s: warning: section `luli' is not found\n"


def test_empty_file():
    conf = ldir+'empty.ini'
    script = ldir+'empty.lua'
    env = TestFileEnvironment()
    res = run(env, script, config=conf)
    assert_(res, nosec_msg % conf)


def test_empty_lines():
    conf = ldir+'empty_lines.ini'
    script = ldir+'empty.lua'
    env = TestFileEnvironment()
    res = run(env, script, config=conf)
    assert_(res, nosec_msg % conf)


def test_loadlib():
    conf = ldir+'loadlib.ini'
    script = ldir+'loadlib.lua'
    env = TestFileEnvironment()
    res = run(env, script, config=conf)
    assert_(res, '')


def test_load_path():
    conf = ldir+'load_path.ini'
    script = '../test_options/load_path.lua'
    env = TestFileEnvironment()
    res = run(env, script, config=conf)
    assert_(res, '')


def test_load_path_proj_conf():
    script = ldir+'loadlib.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True,
              l=['test_config/loadlib-lib1', 'test_config/loadlib-lib2'])
    assert_error(res, "error: library not found - test_config/loadlib-lib1\n")

    conf = 'test/Lulifile'
    f = open(conf, 'w')
    f.write("[luli]\n")
    f.write("l = test_config/loadlib-lib1, test_config/loadlib-lib2\n")
    f.close()
    env = TestFileEnvironment()
    res = run(env, script)
    os.remove(conf)
    assert_(res, '')
