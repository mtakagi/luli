from scripttest import TestFileEnvironment
from utils import *
from errorcode import *

ldir = '../test_stat/'


def test_multi_stats():
    script = ldir+'multi_stats.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 12, Stats_on_line.format()),
                (script, 1, 23, Stats_on_line.format())]))


def test_multi_stats_semi():
    script = ldir+'multi_stats_semi.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 11, Stats_on_line_by_semi_colon.format()),
                (script, 1, 23, Stats_on_line_by_semi_colon.format())]))


def test_stat_semi():
    script = ldir+'stat_semi.lua'
    env = TestFileEnvironment()
    res = run(env, script, expect_error=True)
    assert_error(
        res,
        concat([(script, 1, 13, Stat_ends_with_semi_colon.format()),
                (script, 3, 13, Stat_ends_with_semi_colon.format()),
                (script, 3, 14, Trailing_whitespace.format())]))
