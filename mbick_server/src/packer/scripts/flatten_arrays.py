#!/usr/bin/env python3
import json
import sys
import argparse


parser = argparse.ArgumentParser(description='Flatten JSON arrays for Packer')
parser.add_argument(
        '-o',
        '--output-file',
        type=argparse.FileType('w'),
        default=sys.stdout
    )
parser.add_argument(
        'file',
        metavar='FILENAME',
        type=argparse.FileType('r'),
        default=sys.stdin
    )


def flatten_arrays(data):
    if isinstance(data, dict):
        for key in data:
            data[key] = flatten_arrays(data[key])
    elif isinstance(data, list):
        try:
            new_data = str(data.pop(0))
        except IndexError:
            return data

        for item in data:
            # new_data += ",{}".format(flatten_arrays(item))
            # This is a hack for my use case until the relevant packer issue is
            # fixed: https://github.com/hashicorp/packer/issues/7716
            # TODO: revert back when Packer fixes this upstream
            new_data += str(flatten_arrays(item))
        return new_data

    return data


def main():
    args = parser.parse_args()

    data = json.load(args.file)

    # Try to flatten the variables section only, if it exists
    try:
        data['variables'] = flatten_arrays(data['variables'])
    except KeyError:
        pass

    json.dump(data, args.output_file, sort_keys=True, indent=2)


if __name__ == "__main__":
    main()
