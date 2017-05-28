from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_blank_lines/'


def test_eof():
    script = ldir+'eof.lua'
    env = TestFileEnvironment()
    res = run(env, script)
    assert_(
        res,
        concat([(script, 4, 1, Blank_line_at_end_of_file.format([]))]))


def test_eof_comment():
    script = ldir+'eof_comment.lua'
    env = TestFileEnvironment()
    res = run(env, script)
    assert_(res, '')
