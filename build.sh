#!/usr/bin/env bash

julia --project=. --compile=min -O0 generator.jl
