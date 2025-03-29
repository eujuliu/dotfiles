function mov_to_mp4
    if test (count $argv) -lt 1
        echo "Usage: mov_to_mp4 input.mov"
        return 1
    end

    set input_file $argv[1]
    set output_file (string replace -r '\.mov$' '.mp4' $input_file)

    echo "Converting $input_file to $output_file..."
    ffmpeg -i "$input_file" -c:v libx264 -preset slow -crf 18 -c:a aac -b:a 320k "$output_file"

    echo "Conversion complete: $output_file"
end