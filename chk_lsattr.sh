#!/bin/bash
(/usr/bin/lsattr $1 | awk '{print $1}' | grep "\bi\b" &> /dev/null && echo 0) || echo 1
