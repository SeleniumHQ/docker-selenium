#!/usr/bin/env bash
cd tests
pip install selenium===$VERSION \
            docker===2.2.1
python test.py $1 $2
