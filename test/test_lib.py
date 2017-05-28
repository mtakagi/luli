from scripttest import TestFileEnvironment
from utils import *
from errorcode import *
import os.path

curdir = os.path.dirname(os.path.abspath(__file__))
ldir = '../test_lib/'


def test_full_path():
    lib = os.path.join(curdir, 'test_lib', 'full_path_lib.lua')
    script = ldir+'full_path.lua'
    env = TestFileEnvironment()
    res = run(env, script, l=[lib])
    assert_(res, '')


def test_import_lvar():
    script = ldir+'import_lvar.lua'
    env = TestFileEnvironment()
    res = run(env, script, l=[ldir+'baselib'], expect_error=True)
    assert_error(res,
            concat([(script, 1, 7, Unassigned_var.format(['lvar____']))]))


def test_import_gvar():
    script = ldir+'import_gvar.lua'
    env = TestFileEnvironment()
    res = run(env, script, l=[ldir+'baselib'])
    assert_(res, '')


def test_import_lfunc():
    script = ldir+'import_lfunc.lua'
    env = TestFileEnvironment()
    res = run(env, script, l=[ldir+'baselib'], expect_error=True)
    assert_error(res,
            concat([(script, 1, 1, Unassigned_var.format(['lfunc____']))]))


def test_import_gfunc():
    script = ldir+'import_gfunc.lua'
    env = TestFileEnvironment()
    res = run(env, script, l=[ldir+'baselib'])
    assert_(res, '')
