from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_directive/'


def test_noqa():
    script = ldir+'noqa.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 7, Unused_var.format(['a'])),
                (script, 4, 7, Unused_var.format(['b']))]))


def test_unknown1():
    script = ldir+'unknown1.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 10,
                 Directive_error.format(["unknown directive `foo'"]))]))


def test_unknown2():
    script = ldir+'unknown2.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 10,
                 Directive_error.format(["unknown directive `foo'"]))]))


def test_empty():
    script = ldir+'empty.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 10,
                 Directive_error.format(["empty directive"]))]))
