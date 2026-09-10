import os
import sys

def rename_images(directory='.'):
    # Supported image extensions
    valid_extensions = ('.png', '.jpg', '.jpeg')
    
    # Get the name of this script to ensure it is excluded
    script_name = os.path.basename(__file__)
    
    # Gather files that match extensions and are not this script
    files = [
        f for f in os.listdir(directory) 
        if f.lower().endswith(valid_extensions) and f != script_name
    ]
    
    # Sort files alphabetically to ensure consistent numbering
    files.sort()
    
    if not files:
        print("No matching image files found.")
        return

    print(f"Found {len(files)} images. Starting rename...")

    # First pass: Rename to temporary names to avoid collisions 
    # (e.g., if '1.png' already exists but should be '10.png')
    temp_renames = []
    for i, filename in enumerate(files, 1):
        ext = os.path.splitext(filename)[1].lower()
        temp_name = f"__temp_{i}{ext}"
        old_path = os.path.join(directory, filename)
        new_path = os.path.join(directory, temp_name)
        
        os.rename(old_path, new_path)
        temp_renames.append((new_path, f"{i}{ext}"))

    # Second pass: Rename from temporary names to final numbered names
    for temp_path, final_name in temp_renames:
        final_path = os.path.join(directory, final_name)
        os.rename(temp_path, final_path)
        print(f"Renamed to: {final_name}")

    print("Renaming complete.")

if __name__ == "__main__":
    # Use current directory or one provided as an argument
    target_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    rename_images(target_dir)
