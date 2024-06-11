#!/bin/bash
read -rp "Enter the full path to the video file to transcribe: " videopath
basename=$(basename "${videopath}" | sed 's/\.[^.]*$//')
videodir=$(dirname "${videopath}")
whisperdir="/Users/${USER}/Developer/source/whisper.cpp"
ffmpeg -i "${videopath}" -vn -acodec pcm_s16le -ar 16000 -ac 2 "${videodir}"/"${basename}".wav
# model="ggml-base.en.bin"
# model="ggml-large-v3-q5_0.bin"
model="ggml-small.en-tdrz.bin"
# model="ggml-small.en.bin"
# model="ggml-medium.en.bin"
echo "Transcribing audio with Whisper using model ${model}..."
echo "Whisper options: t = 10 for 16 threads, p = 1 for 1 process, otxt = output text, of = output file, l = language, bs = beam size, bo = beam offset, m = model, f = audio file"
"${whisperdir}"/main -t 10 -p 1 -otxt -of "${videodir}/${basename}" -l en -bs 5 -bo 5 -m "${whisperdir}"/models/"${model}" -f "${videodir}"/"${basename}".wav -pp -pc -tdrz
rm "${videodir}"/"${basename}".wav
bat "${videodir}"/"${basename}".txt
