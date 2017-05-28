from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_deadcode/'


def test_if_cond_pass():
    script = ldir+'if_cond_pass.lua'
    env = TestFileEnvironment()
    res = run(env, script)
    assert_(res, '')


def test_if_cond_true():
    script = ldir+'if_cond_true.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True, ignore=[Redundant_paren.tag()])
    assert_error(res, concat([(script, 1, 4, Meaningless_condition.format([])),
                         (script, 3, 4, Meaningless_condition.format([])),
                         (script, 5, 4, Meaningless_condition.format([])),
                         (script, 7, 4, Meaningless_condition.format([])),
                         (script, 9, 4, Meaningless_condition.format([])),
                         (script, 11, 4, Meaningless_condition.format([])),
                         (script, 13, 4, Meaningless_condition.format([])),
                         (script, 15, 4, Meaningless_condition.format([]))]))


def test_if_cond_false():
    script = ldir+'if_cond_false.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(res, concat([(script, 1, 4, Dead_block.format([])),
                         (script, 3, 4, Dead_block.format([]))]))


def test_elseif_cond_pass():
    script = ldir+'elseif_cond_pass.lua'
    env = TestFileEnvironment()
    res = run(env, script)
    assert_(res, '')


def test_elseif_cond_true():
    script = ldir+'elseif_cond_true.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True, ignore=[Redundant_paren.tag()])
    assert_error(res, concat([(script, 3, 8, Meaningless_condition.format([])),
                         (script, 4, 8, Meaningless_condition.format([])),
                         (script, 5, 8, Meaningless_condition.format([])),
                         (script, 6, 8, Meaningless_condition.format([])),
                         (script, 7, 8, Meaningless_condition.format([])),
                         (script, 8, 8, Meaningless_condition.format([])),
                         (script, 9, 8, Meaningless_condition.format([])),
                         (script, 10, 8, Meaningless_condition.format([]))]))


def test_elseif_cond_false():
    script = ldir+'elseif_cond_false.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(res, concat([(script, 3, 8, Dead_block.format([])),
                         (script, 4, 8, Dead_block.format([]))]))
