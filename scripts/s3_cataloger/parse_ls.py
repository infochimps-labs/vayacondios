#!/usr/bin/env python

import logging
import sys

# crank this down to info for progress messages. can also use
# "filename=" for that kind of thing. The only reason this is stderr
# is to allow for output redirection.
logging.basicConfig(stream=sys.stderr, level=logging.ERROR)

#-------------------------------------------------------------------------------

def calculate_sizes(parsedHierarchies):
    """
    @param parsedHierarchies dictionary mapping filenames to
                             parsedHierarchies. This is in the same
                             format as the 'subdirs' component of a
                             parsedHierarchy.
    """
    
    from operator import add
    return reduce(
        add,
        (
            calculate_size(parsedHierarchies[name])
            for name in parsedHierarchies.keys()))
        

def calculate_size(parsedHierarchy):
    """
    @param  parsedHierarchy dictionary in the same format as the one
                            operated on by insert_line
    """

    if 'subdirs' in parsedHierarchy:
        parsedHierarchy['tree_size'] = calculate_sizes(parsedHierarchy['subdirs'])
    elif parsedHierarchy['type'] == 'd':
            parsedHierarchy['tree_size'] = 0

    if 'tree_size' in parsedHierarchy:
        return parsedHierarchy['tree_size']
    else:
        return parsedHierarchy['file_size']

#-------------------------------------------------------------------------------

from sys import stdout
def write_listing_in_json(listing, writer = stdout):
    writer.write('{"basename":"%s"' % listing['basename'])

    from operator import add
    writer.write(reduce(add, (',"%s":%s' % (key,
                                             '"%s"' % listing[key]
                                             if isinstance(listing[key],str)
                                             else listing[key])
                              for key in listing.keys() if key != 'subdirs')))

    writer.write('}\n')
                 
#-------------------------------------------------------------------------------

def each_listing_in_hierarchy(parsedHierarchy):
    """
    @param parsedHierarchy dictionary mapping filenames to
                             parsedHierarchies. This is in the same
                             format as the 'subdirs' component of a
                             parsedHierarchy.

    @return one record for every file listing. Every parsedHierarchy
            will have its 'subdirs' key deleted and will consequently be flat.
    """

    if 'subdirs' in parsedHierarchy:
        subdirs = parsedHierarchy['subdirs']
        del parsedHierarchy['subdirs']
        return [parsedHierarchy] + each_listing_in_subdirs(subdirs)
    else:
        return [parsedHierarchy]

def each_listing_in_subdirs(parsedHierarchies):
    keys = parsedHierarchies.keys()
    keys.sort()
    from operator import add
    
    return reduce(add,
                  [each_listing_in_hierarchy(parsedHierarchies[f])
                   for f in keys])

#-------------------------------------------------------------------------------

def insert_line(parsedLine,
                parsedHierarchy,
                bucket_name,
                prefix='/',
                s3hdfs = False):
    """
    @param  parsedHierarchy A parsed hierarchy is a dictionary that
                            contains the size, date, type, path, and
                            subdirs of a file. It has two special
                            properties: the basename contains no /
                            characters, and the "subdirs" points to a
                            dictionary that maps names to
                            parsedHierarchies underneath this one.
    """

    def insert_subdir(parsedHierarchy, subdir, bucket_name, prefix):
        if 'subdirs' not in parsedHierarchy:
            parsedHierarchy['subdirs'] = {}
        if subdir not in parsedHierarchy['subdirs']:
            parsedHierarchy['subdirs'][subdir] = {}
            parsedHierarchy['subdirs'][subdir]['basename'] = subdir
            parsedHierarchy['subdirs'][subdir]['file_size'] = 0
            parsedHierarchy['subdirs'][subdir]['type'] = 'd'

            prot = 's3' if s3hdfs else 's3n'

            parent_url = (parsedHierarchy['_id'] if '_id' in parsedHierarchy
                          else '%s://%s/' % (prot, bucket_name))

            parsedHierarchy['subdirs'][subdir]['parent_id'] = parent_url
                                                         

            url = '%s://%s%s%s' % (prot, bucket_name, prefix, subdir)
            parsedHierarchy['subdirs'][subdir]['_id'] = url

            import hashlib
            sha1hasher = hashlib.new('sha1')
            sha1hasher.update(url)

            parsedHierarchy['subdirs'][subdir]['uuid'] = (
                sha1hasher.hexdigest().lower())

    path = parsedLine['path']
    # recursively insert rest of path after /
    if path.find('/') != -1:
        base,rest = path.split('/',1)

        insert_subdir(parsedHierarchy, base, bucket_name, prefix)

        parsedLine['path'] = rest
        insert_line(parsedLine,
                    parsedHierarchy['subdirs'][base],
                    bucket_name,
                    prefix + base + '/')

    # insert one file or directory into "subdirs"
    else:
        insert_subdir(parsedHierarchy, path, bucket_name, prefix)

        # This will also overwrite the default 'type':'d' from insert_subdir
        for k in parsedLine.keys():
            parsedHierarchy['subdirs'][path][k] = parsedLine[k]

        parsedHierarchy['subdirs'][path]['basename'] = \
            parsedHierarchy['subdirs'][path]['path']
        del parsedHierarchy['subdirs'][path]['path']

#-------------------------------------------------------------------------------

def json2ls(json, writer, prefix='/'):
    """
    sanity check. writes json back out to the command line in ls form
    """

    from datetime import datetime
    d =(datetime.fromtimestamp(json['datetime']).strftime("%Y-%m-%d %H:%M")
         if 'datetime' in json else '1970-01-01 00:00')
    
    writer.write("%s %9d   %s\n" % (
        d,
        json['file_size'],
        json['_id'].replace('s3n', 's3')))

#-------------------------------------------------------------------------------

def hdfs_parse_line(bucket_name):

    import re

    def line_parser(line):

        components = re.compile(r"""

            ^
            (                                       
                [d\-]                               # directory bit
            )
                (?:[r\-][w\-][xs\-]){2}
                [r\-][w\-][x\-]
            
            [ \t]*
            
            (?:-|[0-9]+)                            # number of links. ignore.
            
            [ \t]*
            
            ([0-9]+)                                # size
            
            [ \t]*
            
            (\d\d\d\d-\d\d-\d\d[ ]\d\d:\d\d)         
            
            [ \t]*
            
            (                                       # path
                [^ \t]
                [^\n]*
            )
            
            .*
            
            $
            
            """, re.VERBOSE)

        m = components.match(line)
        if not m:
            import sys
            sys.stderr.write("couldn't parse line: %s\n" % (line))
            return None

        typ, fsize, datetime, path = m.groups()

        if typ == '-': typ =  'f'
        if path.startswith('/'): path = path[1:]

        return datetime, fsize, bucket_name, path, typ

    return line_parser

#-------------------------------------------------------------------------------

def s3_parse_line(line):

    import re
    components = re.compile(r"""

        ^
        (\d\d\d\d-\d\d-\d\d[ ]\d\d:\d\d)         
        
        [ \t]*
        
        ([0-9]+)                               
        
        [ \t]*
        
        (?:                                    
            (?:s3://)                          
            ([^/]*)                            
            /
            ([^\n]*)                           
        )
        
        .*
        
        $
        
        """, re.VERBOSE)

    m = components.match(line)
    if not m:
        import sys
        sys.stderr.write("couldn't parse line: %s\n" % (line))
        return None

    datetime, fsize, bucket_name, parsed_line = m.groups()
    typ = 'f'

    return datetime, fsize, bucket_name, parsed_line, typ

#-------------------------------------------------------------------------------

def ls2json_subdirs(lines, line_parser):

    parsedHierarchy = None

    count = 0
    for line in lines:
        count = count + 1
        if count % 1000 == 0:
            logging.info("inserting line %d" % (count))
        
        line_tuple = line_parser(line)

        if not line_tuple:
            continue

        parsedLine = {}

        (
            
            parsedLine['datetime'],
            parsedLine['file_size'],
            bucket_name,
            parsedLine['path'],
            parsedLine['type']
            
            ) = line_tuple

        if not parsedHierarchy:
            url = "s3n://%s" % (bucket_name)
            import hashlib
            sha1hasher = hashlib.new('sha1')
            sha1hasher.update(url)

            parsedHierarchy = {
                bucket_name : {
                    "subdirs" : {},
                    "basename" : bucket_name,
                    "_id" : url,
                    "type" : "d",
                    "file_size" : 0,
                    "uuid" : sha1hasher.hexdigest(),
                    }
                }

        parsedLine['file_size'] = int(parsedLine['file_size'])

        if parsedLine['datetime'] == '1970-01-01 00:00':
            del parsedLine['datetime']
        else:
            from datetime import datetime
            parsedLine['datetime'] = int(datetime.strptime(
                parsedLine['datetime'],
                "%Y-%m-%d %H:%M").strftime("%s"))
                
            parsedLine['file_size'] = int(parsedLine['file_size'])

        if parsedLine['path'].endswith('/'):
            parsedLine['path'] = parsedLine['path'][:-1]
            parsedLine['type'] = 'd'

        insert_line(parsedLine,
                    parsedHierarchy[bucket_name],
                    bucket_name)

    if not parsedHierarchy: return []

    logging.info("calculating sizes")
    calculate_sizes(parsedHierarchy)

    logging.info("converting hierarchies")
    return each_listing_in_subdirs(parsedHierarchy)

#-------------------------------------------------------------------------------

if __name__ == '__main__':
    
    from optparse import OptionParser
    parser = OptionParser(usage = "usage: %prog [options] [s3hdfs bucket name]")
    parser.add_option("-i", "--input", dest="infile", default = None,
                      help="input file..")
    parser.add_option("-o", "--output", dest="outfile", default = None,
                      help="output file.")
    parser.add_option("-t", "--test", dest="test", default = False,
                      action="store_true",
                      help="reoutput in ls format. for debugging")
    
    (options, args) = parser.parse_args()

    import sys
    if len(args) > 1:
        parser.print_usage()
        sys.exit(0)

    if args:
        bucket, = args
        ls_converter = lambda istream: ls2json_subdirs(istream.readlines(),
                                                       hdfs_parse_line(bucket))
    else:
        ls_converter = lambda istream: ls2json_subdirs(istream.readlines(),
                                                       s3_parse_line)

    def open_or_die(fname, flags="r"):
        try:
            return open(fname, flags)
        except IOError as (errno, strerr):
            sys.stderr.write("Couldn't open %s: %s\n" % (fname, strerr))
            sys.exit(0)

    from sys import stdin, stdout
    instream = open_or_die(options.infile) if options.infile else stdin
    outstream = open_or_die(options.outfile, 'w') if options.outfile else stdout

    if options.test:
        for listing in ls_converter(instream):
            json2ls(listing, outstream)
    else:
        for listing in ls_converter(instream):
            write_listing_in_json(listing, outstream)

