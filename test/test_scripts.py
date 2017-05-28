import os.path
import utils

SCRIPT_DIRS = [
    'test_whitespace',
    'test_indent/do',
    'test_indent/numfor',
    'test_indent/genfor',
    'test_indent/while',
    'test_indent/repeat',
    'test_indent/if',
    'test_indent/paren',
    'test_indent/table',
    'test_indent/anonfunc',
    'test_comment',
    'test_var',
    'test_string',
    'test_redundant_paren',
    'test_module',
    'test_option_select',
]


def test_scripts():
    for path in SCRIPT_DIRS:
        path = os.path.join('test', path)
        for dpath, fname in utils.get_scripts(path):
            yield utils.run_from_file, dpath, fname
