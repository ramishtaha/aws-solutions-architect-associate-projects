# Sample Image Instructions

## Creating sample-image.jpg

Since this repository contains text files, here are instructions to create a simple test image:

### Option 1: Use the provided SVG file
The `sample-image.svg` file in this directory can be used directly for testing S3 Cross-Region Replication. Simply rename it to `sample-image.jpg` or use it as-is.

### Option 2: Create your own simple image
1. Open any image editing software (Paint, GIMP, Photoshop, etc.)
2. Create a new image with dimensions 200x200 pixels
3. Add some simple text like "AWS DR Test Image"
4. Add the current date/time to make it unique
5. Save as "sample-image.jpg"

### Option 3: Download a small test image
1. Search for "test image" on any royalty-free image website
2. Download a small image (under 1MB)
3. Rename it to "sample-image.jpg"

### Requirements for the test:
- File should be small (under 5MB to stay within Free Tier limits)
- Should be a common format (JPG, PNG, GIF)
- Content doesn't matter - it's just for testing replication

The key is to have a file that you can easily identify when checking if S3 Cross-Region Replication is working correctly.
