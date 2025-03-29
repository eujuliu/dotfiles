function mkv_to_mov
    if test (count $argv) -lt 1
        echo "Usage: mkv_to_mov input.mkv"
        return 1
    end

    set input_file $argv[1]
    set output_file (string replace -r '\.mkv$' '.mov' $input_file)

    echo "Converting $input_file to $output_file..."
    ffmpeg -i "$input_file" -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p -c:a alac "$output_file"

    echo "Conversion complete: $output_file"
end