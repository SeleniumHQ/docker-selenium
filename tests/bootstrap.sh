#!/usr/bin/env bash
cd tests
pip install selenium===3.13.0 \
            docker===3.1.1 \
            | grep -v 'Requirement already satisfied'

python test.py $1 $2
