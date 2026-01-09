@echo off
python test_librivox.py > output.txt 2>&1
type output.txt
