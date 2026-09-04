#!/usr/bin/bash

pgrep -f "foot --server" > /dev/null || foot --server
