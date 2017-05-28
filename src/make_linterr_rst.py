# -*- coding: utf-8 -*-

import json
from StringIO import StringIO
import subprocess
import datetime

CONF = 'linterr_code.json'
RST = 'errorcode.rst'

today = datetime.date.today()
date = "%d/%d/%d" % (today.year, today.month, today.day)
revision = subprocess.Popen(["git", "show", "--format=%h", "-s"],
        stdout=subprocess.PIPE).communicate()[0].strip()

HEADER = u"""
================
エラーコード
================

""" % {"date": date, "revision": revision}

FOOTER = """
"""

CATEGORY = {
    'style': u'コーディングスタイル',
    'analysis': u'ソースコードの解析',
    'unimplemented': u'未実装'
}

LOGLV = {'Error': u'エラー', 'Warn': u'警告'}

class Code(object):

    def __init__(self, data):
        self.category = data['category']
        self.num = data['num']
        self.loglv = data.get('loglv', 'Error')
        self.type_ = data['type']
        self.param_types = data.get('param_types')
        self.message = data['message']
        self.doc = data.get('doc')
        self.param_doc = data.get('param_doc')
        self.status = data.get('status')

    def tag(self):
        return self.loglv[0]

    def tagnum(self):
        return "%s%d" % (self.tag(), self.num)

    def header(self):
        return "%s: %s" % (self.tagnum(), escape(self.message))

def escape(s):
    s = s.replace('*', '\*')
    s = s.replace('`', '\`')
    return s

def run():
    s = open(CONF).read()
    conf = json.loads(s)
    codes = [Code(data) for data in conf]
    make_rst(codes)

def make_rst(codes):
    f = StringIO()
    f.write(HEADER)
    cats = ['style', 'analysis', 'unimplemented']
    for cat in cats:
        write_contents_category(f, codes, cat)
    for cat in cats:
        write_category(f, codes, cat)
    f.write(FOOTER)
    open(RST, 'w').write(f.getvalue().encode('utf8'))

def filter_codes(codes, cat):
    return filter(lambda code: code.category == cat, codes)

def write_contents_category(f, codes, cat):
    codes = filter_codes(codes, cat)
    if not codes:
        return
    f.write(u"- `" + CATEGORY[cat] + "`_\n\n")
    for code in codes:
        f.write(u"  - `" + code.header() + "`_\n")
    f.write("\n")

def write_category(f, codes, cat):
    codes = filter_codes(codes, cat)
    if not codes:
        return
    header = CATEGORY[cat]
    f.write(header + "\n")
    f.write(len(header) * 2 * "=" + "\n\n")
    for code in codes:
        if code.category == cat:
            write_doc(f, code)

def write_doc(f, code):
    f.write(code.header() + "\n")
    f.write("-" * (len(code.message) + 10) + "\n\n")
    f.write(u":エラーコード: %s\n" % code.tagnum())
    f.write(u":エラーレベル: %s\n" % LOGLV[code.loglv])
    if code.param_doc:
        for i in range(len(code.param_doc)):
            f.write(u":$%d: %s\n" % (i+1, escape(code.param_doc[i])))
    f.write(u"\n%s\n" % escape(code.doc))
    f.write("\n")

if __name__ == "__main__":
    run()
