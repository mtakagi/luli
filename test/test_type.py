from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_type/'


def test_empty_string_concat():
    script = ldir+'empty_string_concat.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(res, concat([(script, 2, 14, Concat_to_cast.format()),
                         (script, 3, 7, Concat_to_cast.format()),
                         (script, 4, 7, Concat_to_cast.format())]))
