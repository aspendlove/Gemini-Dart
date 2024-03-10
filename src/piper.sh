#!/bin/bash
echo "$1" | ../piper/piper --model ../piper/en_US-libritts_r-medium.onnx --config ../piper/en_en_US_libritts_r_medium_en_US-libritts_r-medium.onnx.json --output-raw |   aplay -r 22050 -f S16_LE -t raw -
