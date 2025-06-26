# -*- coding: utf-8 -*-
"""import_metadata.py

Usage:
  import_metadata.py <data_hub> <tsv_input> <tsv_output> <json_directory>

Options:
  -h --help        Show this screen

"""
from __future__ import division
from __future__ import print_function

import os
import os.path
import json
import pprint
import sys
import argparse


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('data_hub')
    parser.add_argument('tsv_input')
    parser.add_argument('tsv_output')
    parser.add_argument('json_directory')
    arguments = parser.parse_args()

    data_hub = json.loads(read_file(arguments.data_hub))
    samples = parse_tsv(read_file(arguments.tsv_input).strip())
    tsv_output = arguments.tsv_output
    json_directory = arguments.json_directory

    # Check if samples are missing
    missing_samples = {}
    for i, sample in enumerate(samples):
        external_name = sample['External Name']
        if external_name not in data_hub['samples']:
            missing_samples[i] = True

    # Create directory
    
    #mkdir(json_directory)

    # Generate JSON files
    '''
     A.M. 
     - added artifact_id prefix to JSON filenames    
    '''    
    for i, sample in enumerate(samples):
        if i in missing_samples:
            sample['QC'] = 'Fail'
            continue
        sample['QC'] = 'Pass'
        
        filename = '{artifact_id}_{lims_id}_{sample_name}.json'.format(artifact_id=sample['Artifact ID'],lims_id=sample['LIMS ID'], sample_name=sample['Sample Name'])
        #filename = '{lims_id}_{sample_name}.json'.format(lims_id=sample['LIMS ID'], sample_name=sample['Sample Name'])
        #filepath = os.path.join(json_directory, filename)
        filepath=filename
        
        content = data_hub['samples'][sample['External Name']]
        content['id'] = sample['External Name']
        write_file(filepath, json.dumps(content))
        

    # Create output TSV
    '''
     A.M. 
     - added Artifact IDcolumn to output file    
    '''
    write_file(tsv_output, generate_tsv(['LIMS ID', 'Sample Name', 'External Name', 'Artifact ID', 'QC'], samples))

    print('done')


def generate_tsv(headers, records):
    rows = [[record[header] for header in headers] for record in records]
    return '\n'.join(['\t'.join(headers)] + ['\t'.join(row) for row in rows])

def parse_tsv(content):
    lines = content.split('\n')
    rows = [line.split('\t') for line in lines]
    headers = rows[0]
    rows = rows[1:]
    records = []
    for row in rows:
        record = {}
        for i, header in enumerate(headers):
            record[header] = row[i]
        records.append(record)
    return records


def read_file(filepath):
    with open(filepath) as f:
        return f.read()


def write_file(filepath, content):
    with open(filepath, 'w') as f:
        f.write(content)


def mkdir(path):
    if os.path.isdir(path):
        return
    if os.path.isfile(path):
        raise OSError("a file with the same name as the desired "
                      "dir, '%s', already exists." % path)
    head, tail = os.path.split(path)
    if head and not os.path.isdir(head):
        mkdir(head)
    if tail:
        os.mkdir(path)


def log(value):
    pprint.pprint(value, depth=6, width=180)


def red(string):
    return '\x1b[91m' + string + '\x1b[39m'


if __name__ == '__main__':
    main()
