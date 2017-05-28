# -*- coding: utf8 -*-

# 未実装 (ソースコード内で未使用) のエラーコードを検出する

import json
import os
import re

CONF = 'linterr_code.json'

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
        self.used = False

def run():
    s = open(CONF).read()
    conf = json.loads(s)
    codes = [Code(data) for data in conf]
    for dirpath, dirnames, filenames in os.walk('.'):
        for fname in filenames:
            if fname.endswith('.ml'):
                if fname == 'linterr_internal.ml':
                    continue
                s = open(fname).read()
                for code in codes:
                    if re.search(code.type_, s):
                        code.used = True
    for code in codes:
        if not code.used and code.category != u'unimplemented':
            print "%d %s" % (code.num, code.type_)

if __name__ == "__main__":
    run()
