#!/usr/bin/env python

def read_require_directives(filename):
    import re
    r = re.compile(r"//\s*@require\s+\"([^\"]*)\"")
    required_files = []
    with open(filename) as f:
        for line in f:
            match = r.search(line)
            if match:
                required_files.append(match.group(1))
    return required_files


def build_required_file_list(filename):
    """Returns list of files needed to deploy `filename`"""
    import os
    if not os.path.isfile(filename):
        raise IOError(filename)
    filename = os.path.abspath(filename)
    dirname = os.path.dirname(filename)
    required_file_list = [filename]
    for directive in read_require_directives(filename):
        directive = os.path.abspath(os.path.join(dirname, directive))
        if directive in required_file_list:
            continue
        for nested_file in build_required_file_list(directive):
            if nested_file not in required_file_list:
                required_file_list.append(nested_file)
    required_file_list.append(required_file_list.pop(0))
    return required_file_list


def main():
    import optparse
    p = optparse.OptionParser()
    p.add_option('--make', '-m', action="store_const", const="makedep", dest="format", help="output in Makefile dependency format")
    p.add_option('--json', '-j', action="store_const", const="json", dest="format", help="output in JSON format")
    (opts, args) = p.parse_args()

    if len(args) < 1:
        return

    required_file_list = build_required_file_list(args[0])
    import os
    required_file_list = [os.path.relpath(x) for x in required_file_list]
    if opts.format == "makedep":
        print " ".join(required_file_list)
    elif opts.format == "json":
        import json
        print json.dumps(required_file_list)


if __name__ == '__main__':
    main()
