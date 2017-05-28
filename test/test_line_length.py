from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_line_length/'


def test_basic():
    script = ldir+'basic.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 80, Line_too_long.format([84, 79]))]))
