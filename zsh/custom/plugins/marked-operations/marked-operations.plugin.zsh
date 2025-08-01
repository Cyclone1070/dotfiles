# script for seperate lines copy paste

# Initialize arrays to store paths of files to copy and move
M_COPY_FILES=()
M_MOVE_FILES=()

# Function to mark files for copying
function mcp {
    for file in "$@"; do
        if [ -e "$file" ]; then
            M_COPY_FILES+=("$(realpath "$file")")
            echo "Marked $file for copying"
        else
            echo "File $file does not exist"
        fi
    done
}

# Function to mark files for moving
function mmv {
    for file in "$@"; do
        if [ -e "$file" ]; then
            M_MOVE_FILES+=("$(realpath "$file")")
            echo "Marked $file for moving"
        else
            echo "File $file does not exist"
        fi
    done
}

# Function to paste the marked files to the specified directories (or current directory if not specified)
function mp {
    local dest_dirs=("$@")  # Get all specified directories

    # Default to current directory if no directories are provided
    if [ ${#dest_dirs[@]} -eq 0 ]; then
        dest_dirs=(".")
    fi

    # Check if each destination directory exists
    for dest_dir in "${dest_dirs[@]}"; do
        if [ ! -d "$dest_dir" ]; then
            echo "Destination directory $dest_dir does not exist"
            return 1
        fi
    done

    local files_moved=false
    local files_copied=false

    # Move files to each specified directory
    if [ ${#M_MOVE_FILES[@]} -gt 0 ]; then
        for file in "${M_MOVE_FILES[@]}"; do
            for dest_dir in "${dest_dirs[@]}"; do
                mv "$file" "$dest_dir"
                echo "Moved $file to $dest_dir"
            done
        done
        # Clear the array after moving files
        M_MOVE_FILES=()
        files_moved=true
    fi
    
    # Copy files to each specified directory
    if [ ${#M_COPY_FILES[@]} -gt 0 ]; then
        for file in "${M_COPY_FILES[@]}"; do
            for dest_dir in "${dest_dirs[@]}"; do
                cp -r "$file" "$dest_dir"
                echo "Copied $file to $dest_dir"
            done
        done
        # Clear the array after copying files
        M_COPY_FILES=()
        files_copied=true
    fi

    if ! $files_moved && ! $files_copied; then
        echo "No file marked for copying or moving"
    fi
}

# mark reset to reest the marked files
function mr {
    M_COPY_FILES=()
    M_MOVE_FILES=()
    echo "Reset marked files"
}
# marked list to list the marked files
function mls {
    local files_listed=false
    if [ ${#M_MOVE_FILES[@]} -gt 0 ]; then
        echo "Files marked for moving:"
        for file in "${M_MOVE_FILES[@]}"; do
            echo "$file"
        done
        files_listed=true
    fi

    if [ ${#M_COPY_FILES[@]} -gt 0 ]; then
        echo "Files marked for copying:"
        for file in "${M_COPY_FILES[@]}"; do
            echo "$file"
        done
        files_listed=true
    fi

    if ! $files_listed; then
        echo "No file marked for copying or moving"
    fi
}
