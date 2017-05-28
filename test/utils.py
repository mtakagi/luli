# -*- coding: utf-8 -*-

import os
import re
from scripttest import TestFileEnvironment
import errorcode

CONF_FNAME = 'Lulifile'


def cmd():
    return os.getenv('LULI')


def simple_run(path=None, **opts):
    env = TestFileEnvironment()
    return run(env, path, **opts)


def run(env, path=None, **opts):
    def add(key, optname=None):
        if optname is None:
            optname = '-' + key.replace('_', '-')
        v = opts.get(key)
        if v:
            opts.pop(key)
            t = type(v)
            if t == list:
                if key in ['l', 'L']:
                    for e in v:
                        args.append(optname)
                        args.append(e)
                else:
                    args.append(optname)
                    args.append(','.join(v))
            elif t == bool:
                if v:
                    args.append(optname)
            else:
                args.append(optname)
                args.append(v)
    args = [cmd()]
    keys = ['no_autoload', 'cocos', 'config', 'lua_version', 'ignore', 'L',
            'init', 'l', 'no_spell_check', 'warn_error', 'warn_error_all',
            'first', 'anon_args']
    for key in keys:
        add(key)
    if path:
        args.append(path)
    return env.run(*args, **opts)


def get_scripts(dirpath):
    if not os.path.exists(dirpath):
        raise StandardError("%s: no such directory in %s" % (dirpath, os.getcwd()))
    l = []
    for (dpath, dnames, fnames) in os.walk(dirpath):
        print fnames
        for fname in fnames:
            if not fname.startswith('.') and fname.endswith('.lua'):
                l.append((dpath, fname))
    return l


def escape_arg(s, info):
    # エラーコードの引数の置換
    # $file -> ファイル名 (E1211 などのメッセージにファイル名が含まれるテストに使う)
    # $colon -> ":"
    s = s.replace('$file', info['file'])
    s = s.replace('$colon', ':')
    return s

def run_from_file(dpath, fname):
    opts = {'expect_error': True}
    conf = os.path.join(dpath, CONF_FNAME)
    if os.path.exists(conf):
        opts['config'] = os.path.join('..', '..', conf)
    fpath = os.path.join(dpath, fname)
    rel_fpath = os.path.join('..', '..', dpath, fname)
    env = TestFileEnvironment()
    res = run(env, rel_fpath, **opts)

    if '-' not in fname:
        return
    elif fname.startswith('OK-'):
        assert_(res, '')
    else:
        elems = os.path.splitext(fname)[0].split('-')
        tag = elems.pop(0)
        lnum = int(elems.pop(0))
        bol = int(elems.pop(0))
        code = getattr(errorcode, tag)
        info = {'file': rel_fpath}
        elems = [escape_arg(e, info) for e in elems]
        try:
            expected = concat([(rel_fpath, lnum, bol, code.format(elems))])
        except KeyError:
            assert False, "%s: specify parameters for '%s'" % (fpath, code.message)
        assert_error(res, expected)


def concat(descs):
    msgs = []
    for desc in descs:
        path, line, bol, msg = desc
        msgs.append("%s:%d:%d: %s\n" % (path, line, bol, msg))
    return ''.join(msgs)


def assert_eq(title, ex, ac):
    if ex != ac:
        print("assert %s failed:" % title)
        print("    expected: %s" % ex)
        print("    actual:   %s" % ac)
        assert ex == ac


def assert_(res, stdout, returncode=0):
    assert_eq('stdout', stdout, res.stdout)
    assert_eq('return', returncode, res.returncode)
    assert not res.files_created
    assert not res.files_deleted
    assert not res.files_updated
    assert not res.stderr


def assert_error(res, stdout):
    assert_(res, stdout, 255)


def assert_create_file(res, stdout, fnames, returncode=0):
    assert_eq('stdout', stdout, res.stdout)
    assert_eq('return', returncode, res.returncode)
    for fname in fnames:
        assert fname in res.files_created
    assert not res.files_deleted
    assert not res.files_updated
    assert not res.stderr
