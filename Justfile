_default:
    @just --list --groups

config := absolute_path('config')
build := absolute_path('.build')
out := absolute_path('firmware')
draw := absolute_path('draw')
draw_keymap := 'splitkb_aurora_sweep'
draw_keyboard := 'ferris/sweep'

# Import recipes from /just-recipes
import 'just-recipes/build.just'
import 'just-recipes/flash.just'

# clear build cache and artifacts
[group('env-maintenance')]
[confirm]
clean:
    rm -rf {{ build }} {{ out }}

# clear all automatically generated files
[group('env-maintenance')]
[confirm]
clean-all: clean
    rm -rf .west zmk

# clear nix cache
[group('env-maintenance')]
clean-nix:
    nix-collect-garbage --delete-old

# initialize west
[group('env-maintenance')]
init:
    west init -l config
    west update
    west zephyr-export

# update west
[group('env-maintenance')]
update:
    west update

# upgrade zephyr-sdk and python dependencies
[group('env-maintenance')]
upgrade-sdk:
    nix flake update --flake .

# list build targets
[group('ZMK')]
list:
    @just _parse_targets all | sed 's/,$//' | sort | column

# parse & plot keymap
[group('ZMK')]
draw:
    #!/usr/bin/env bash
    set -euo pipefail
    keymap -c "{{ draw }}/config.yaml" parse -z "{{ config }}/{{ draw_keymap }}.keymap" >"{{ draw }}/{{ draw_keymap }}.yaml"
    keymap -c "{{ draw }}/config.yaml" draw "{{ draw }}/{{ draw_keymap }}.yaml" -k {{ draw_keyboard }} >"{{ draw }}/{{ draw_keymap }}.svg"

#run tests
[group('ZMK')]
test:
    cp config/splitkb_aurora_sweep.keymap tests/splitkb_aurora_sweep_formatted.keymap
    python -m unittest tests/test_format_keymap.py
