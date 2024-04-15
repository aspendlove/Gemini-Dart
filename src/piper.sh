#!/bin/bash
# text, .onyx, .json
#echo "$1" | ../piper/piper --model "../piper/voices/$2.onnx" --config "../piper/voices/$2.json" --output-raw |   aplay -r 22050 -f S16_LE -t raw -
echo "$1" | ../piper/piper ../piper/piper --model "../piper/voices/$2.onnx" --config "../piper/voices/$2.json" --output_file temp.wav
