from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_func/'


def test_anon_args():
    script = ldir+'anon_args.lua'
    env = TestFileEnvironment()
    res = run(env, script, anon_args=True, expect_error=True)
    assert_error(res, concat([(script, 1, 28, Unused_var.format(['z']))]))


def test_local_anon_func():
    script = ldir+'local_anon_func.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(res,
            concat([(script, 1, 18,
                     Init_assign_to_anon_func_with_name.format(['foo'])),
                    (script, 1, 35,
                     Init_assign_to_anon_func_with_name.format(['bar'])),
                    (script, 1, 52, Init_assign_to_anon_func.format())]))
