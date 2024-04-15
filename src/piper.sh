#!/bin/bash
# text, .onyx, .json
echo "../piper/voices/$2.onyx"
echo "$1" | ../piper/piper --model "../piper/voices/$2.onnx" --config "../piper/voices/$2.json" --output-raw |   aplay -r 22050 -f S16_LE -t raw -
#echo "$1" | ../piper/piper --model ../piper/en_US-libritts_r-medium.onnx --config ../piper/en_en_US_libritts_r_medium_en_US-libritts_r-medium.onnx.json --output_file temp.wav
