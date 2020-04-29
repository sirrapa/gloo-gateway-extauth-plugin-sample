#!/bin/bash

if ! make compare-deps; then
 cp go.mod plugin.mod
 status=$?
 for i in {1..200}; do
    make merge-deps
    mv suggestion.mod go.mod
    make compare-deps
    status=$?
    [ $status -ne 0 ] && echo "retry ${i} failed" || echo "retry ${i} passed"
    [ $status -eq 0 ] &&  break
 done
 exit $status
fi