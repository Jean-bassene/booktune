#!/usr/bin/env python3
"""
Generate a simple launcher icon for BookTune app
Creates a purple square with a white book and 'B' letter
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon():
    # Create assets/images directory if it doesn't exist
    os.makedirs("assets/images", exist_ok=True)

    # Try to load existing app_icon.png, otherwise create a default one
    input_path = "assets/images/app_icon.png"
    if os.path.exists(input_path):
        # Load existing icon
        img = Image.open(input_path)
        print(f"✅ Using existing icon: {input_path}")
        print(f"   Original size: {img.size[0]}x{img.size[1]} pixels")

        # Auto-crop to focus on the main content (zoom effect)
        # This removes transparent/white borders and focuses on the logo
        if img.mode == 'RGBA':
            # For PNG with transparency, crop to content
            bbox = img.getbbox()
            if bbox:
                img = img.crop(bbox)
                print(f"✅ Auto-cropped to content: {img.size[0]}x{img.size[1]} pixels")
        else:
            # For other formats, try to crop white/transparent borders
            # Convert to ensure we have alpha channel for processing
            img_rgba = img.convert('RGBA')
            bbox = img_rgba.getbbox()
            if bbox:
                img = img_rgba.crop(bbox)
                print(f"✅ Auto-cropped to content: {img.size[0]}x{img.size[1]} pixels")

    else:
        # Create default icon if none exists
        print(f"⚠️  No existing icon found, creating default icon")
        size = 512
        img = Image.new('RGB', (size, size), color=(103, 0, 186))  # Purple background
        draw = ImageDraw.Draw(img)

        # Draw a white book rectangle
        book_width = 272
        book_height = 352
        book_x = (size - book_width) // 2
        book_y = (size - book_height) // 2

        # Book pages (white)
        draw.rectangle(
            [book_x + 40, book_y, book_x + book_width, book_y + book_height],
            fill=(255, 255, 255)
        )

        # Book spine (darker purple)
        draw.rectangle(
            [book_x, book_y, book_x + 40, book_y + book_height],
            fill=(80, 0, 150)
        )

        # Try to draw 'B' letter
        try:
            # Try to use a system font
            font = ImageFont.truetype("arial.ttf", 200)
        except:
            try:
                font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", 200)
            except:
                # Use default font
                font = ImageFont.load_default()

        # Draw 'B' text
        text = "B"
        # Get text size using getbbox (newer PIL)
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]

        text_x = book_x + 40 + (book_width - 40 - text_width) // 2
        text_y = book_y + (book_height - text_height) // 2

        draw.text((text_x, text_y), text, fill=(103, 0, 186), font=font)

        print(f"✅ Default icon created")

    # Ensure the base icon is 512x512 for consistency
    if img.size != (512, 512):
        # Use thumbnail to maintain aspect ratio and fit within 512x512
        img.thumbnail((512, 512), Image.Resampling.LANCZOS)

        # Create a new 512x512 image and paste the resized icon centered
        final_img = Image.new('RGBA', (512, 512), (0, 0, 0, 0))  # Transparent background
        x = (512 - img.size[0]) // 2
        y = (512 - img.size[1]) // 2
        final_img.paste(img, (x, y), img if img.mode == 'RGBA' else None)

        img = final_img
        print(f"✅ Icon processed to: 512x512 pixels (centered)")

    # Create Android icons
    android_sizes = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": 48,
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": 72,
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": 96,
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": 144,
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": 192,
    }

    for path, sz in android_sizes.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = img.resize((sz, sz), Image.Resampling.LANCZOS)
        resized.save(path, 'PNG')
        print(f"✅ Android icon: {path} ({sz}x{sz})")

    # Also create a smaller version for web (192x192)
    img_web = img.resize((192, 192), Image.Resampling.LANCZOS)
    img_web.save("web/icons/Icon-192.png", 'PNG')
    img_web.save("web/icons/Icon-512.png", 'PNG')
    print(f"✅ Web icons updated: web/icons/Icon-192.png, Icon-512.png")

if __name__ == "__main__":
    create_icon()
