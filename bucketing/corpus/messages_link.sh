#!/bin/bash
# This corpus can be used for testing. Requires 'jq' package to extract messages from json into plain text
# The resulting messages.txt will contain 2664797 lines
wget https://huggingface.co/datasets/declip/Minecraft-Server-Chat/resolve/main/clean.json

jq -r '.[].content' clean.json > messages.txt
