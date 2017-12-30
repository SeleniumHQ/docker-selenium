#!/usr/bin/env bash
cd tests
pip install selenium===3.8.0 \
            docker===2.5.1 \
            | grep -v 'Requirement already satisfied'

python test.py $1 $2
