# -*- coding: utf-8 -*-

from os.path import join
from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_options/'


def test_no_file():
    script = '__foobarbaz__.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(res, "error: no such file `%s'\n" % script)


def test_warn_error():
    script = ldir+'warn_error.lua'
    msg = concat([(script, 2, 1, Blank_line_at_end_of_file.format())])

    # 警告 (オプションなし)
    env = TestFileEnvironment()
    res = run(env, script)
    assert_(res, msg)

    # エラー
    res = run(env, script, warn_error=[Blank_line_at_end_of_file.tag()], expect_error=True)
    assert_error(res, msg)


def test_warn_error_all():
    script = ldir+'warn_error.lua'
    msg = concat([(script, 2, 1, Blank_line_at_end_of_file.format())])

    env = TestFileEnvironment()
    res = run(env, script, warn_error_all=True, expect_error=True)
    assert_error(res, msg)


def test_lua_version_common():
    script = ldir+'lua_common.lua'
    env = TestFileEnvironment()
    res = run(env, script)
    assert_(res, '')


def test_lua_version_5_1():
    script = ldir+'lua_5_1.lua'
    env = TestFileEnvironment()
    res = run(env, script, lua_version='5.1', expect_error=True)
    assert_error(res,
            concat([(script, 9, 5, Unassigned_var.format(['_ENV']))]))


def test_lua_version_5_1_label():
    script = ldir+'lua_5_1_label.lua'
    env = TestFileEnvironment()
    res = run(env, script, lua_version='5.1', expect_error=True)
    fmt1 = ["`::' is supported by Lua 5.2 or later"]
    assert_error(res,
                 concat([(script, 1, 1, Syntax_error.format(fmt1))]))


def test_lua_version_5_1_goto():
    script = ldir+'lua_5_1_goto.lua'
    env = TestFileEnvironment()
    res = run(env, script, lua_version='5.1', expect_error=True)
    assert_error(res,
            concat([(script, 1, 1, Unassigned_var.format(['goto']))]))


def test_lua_version_5_2():
    script = ldir+'lua_5_2.lua'
    env = TestFileEnvironment()
    res = run(env, script, lua_version='5.2', expect_error=True)
    assert_error(res,
            concat([(script, 4, 5, Unassigned_var.format(['module'])),
                    (script, 5, 5, Unassigned_var.format(['setfenv'])),
                    (script, 6, 5, Unassigned_var.format(['getfenv'])),
                    (script, 7, 5, Unassigned_var.format(['loadstring'])),
                    (script, 8, 5, Unassigned_var.format(['unpack']))]))


def test_spell_check():
    script = ldir+'spell_check.lua'
    var = 'foobarbar'

    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(res, concat([
        (script, 2, 7,
         Unassigned_var_with_suggestion.format([var, 'foobarbaz']))]))

    env = TestFileEnvironment()
    res = run(env, script, no_spell_check=True, expect_error=True)
    assert_error(res, concat([
        (script, 2, 7, Unassigned_var.format([var]))]))


def test_project_config():
    confs = ['Lulifile']
    script = ldir+'projconf.lua'
    try:
        for conf in confs:
            if os.path.exists(conf):
                os.remove(conf)
            env = TestFileEnvironment()
            res = run(env, script, expect_error=True)
            assert_error(res, concat([(script, 1, 7, Unused_var.format(['foo']))]))

            f = open(conf, 'w')
            f.write("[luli]\n")
            f.write("ignore=E\n")
            f.close()
            env = TestFileEnvironment()
            res = run(env, script)
            os.remove(conf)
            assert_(res, '')
    except:
        for conf in confs:
            if os.path.exists(conf):
                os.remove(conf)
        raise


def test_load_path():
    # -I
    script = ldir+'load_path.lua'
    env = TestFileEnvironment()
    res = run(env, script, L=[join(ldir, 'lib1'), join(ldir, 'lib2')],
              l=['foo', 'bar'])
    assert_(res, '')


def test_load_path_expand():
    script = ldir+'load_path.lua'
    env = TestFileEnvironment()
    lpath = os.path.normpath(join(env.base_path, ldir)).replace(os.getenv('HOME'), '~')
    print lpath
    res = run(env, script, L=[join(lpath, 'lib1'), join(lpath, 'lib2')],
              l=['foo', 'bar'])
    assert_(res, '')


def test_load_with_home_rel_path():
    script = ldir+'load_path.lua'
    env = TestFileEnvironment()
    lpath = os.path.normpath(join(env.base_path, ldir)).replace(os.getenv('HOME'), '~')
    res = run(env, script,
              l=[join(lpath, 'lib1', 'foo'), join(lpath, 'lib2', 'bar')])
    assert_(res, '')


def test_autoload_1():
    script = ldir+'autoload1.lua'
    env = TestFileEnvironment()
    res = run(env, script, L=[ldir])
    assert_(res, '')

    env = TestFileEnvironment()
    res = run(env, script, no_autoload=True, no_spell_check=True, L=[ldir], expect_error=True)
    assert_error(res, concat([(script, 2, 1, Unassigned_var.format(['foo']))]))


def test_autoload_2():
    script = ldir+'autoload2.lua'
    env = TestFileEnvironment()
    res = run(env, script, L=[ldir])
    assert_(res, '')

    env = TestFileEnvironment()
    res = run(env, script, no_autoload=True, no_spell_check=True, L=[ldir], expect_error=True)
    assert_error(res, concat([(script, 2, 1, Unassigned_var.format(['foo']))]))


def test_autoload_3():
    script = ldir+'autoload3.lua'
    env = TestFileEnvironment()
    res = run(env, script, L=[ldir])
    assert_(res, '')

    env = TestFileEnvironment()
    res = run(env, script, no_autoload=True, no_spell_check=True, L=[ldir], expect_error=True)
    assert_error(res, concat([(script, 2, 1, Unassigned_var.format(['foo']))]))


def test_init():
    env = TestFileEnvironment()
    res = run(env, init=True)
    assert_create_file(res, "# creating Lulifile\n", ['Lulifile'])


def test_first():
    script = ldir+'first.lua'
    env = TestFileEnvironment()
    res = run(env, script, first=True, expect_error=True)
    assert_error(res, concat([(script, 1, 1, Unassigned_var.format(['foo1'])),
                         (script, 4, 16, Unused_var.format(['foo2'])),
                         (script, 10, 1, Global_var_def.format(['foo3']))]))
