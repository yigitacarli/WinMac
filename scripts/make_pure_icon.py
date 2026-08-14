from PIL import Image, ImageDraw, ImageFilter, ImageOps
import numpy as np

def process_pure_icon(input_path, output_png):
    img = Image.open(input_path).convert("RGBA")
    w, h = img.size
    
    # Crop the central dark squircle tile from the gray surround
    # Let's find the bounding box of the dark area (where R,G,B < 150)
    img_gray = img.convert("L")
    arr = np.array(img_gray)
    
    # Threshold dark tile vs gray background (the background is ~210 gray, tile is ~35-50 dark)
    dark_mask = arr < 120
    
    y_indices, x_indices = np.where(dark_mask)
    if len(y_indices) > 0 and len(x_indices) > 0:
        min_y, max_y = y_indices.min(), y_indices.max()
        min_x, max_x = x_indices.min(), x_indices.max()
        print(f"Detected tile box: ({min_x}, {min_y}) to ({max_x}, {max_y})")
        cropped_tile = img.crop((min_x, min_y, max_x, max_y))
    else:
        # Fallback crop center
        cropped_tile = img.crop((w * 0.18, h * 0.18, w * 0.82, h * 0.82))
    
    canvas_size = 1024
    icon_size = 856
    padding = (canvas_size - icon_size) // 2
    radius = 185
    
    # Resize the tile to 856x856
    tile_856 = ImageOps.fit(cropped_tile, (icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Smooth Apple Squircle mask at 4x
    scale = 4
    mask_size = icon_size * scale
    mask_radius = radius * scale
    mask = Image.new("L", (mask_size, mask_size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (mask_size, mask_size)], radius=mask_radius, fill=255)
    mask = mask.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    masked_tile = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
    masked_tile.paste(tile_856, (0, 0), mask)
    
    # Drop shadow
    shadow_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_mask = Image.new("L", (icon_size, icon_size), 0)
    shadow_draw = ImageDraw.Draw(shadow_mask)
    shadow_draw.rounded_rectangle([(0, 0), (icon_size, icon_size)], radius=radius, fill=120)
    
    shadow_layer = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 120))
    shadow_layer.putalpha(shadow_mask)
    
    shadow_canvas.paste(shadow_layer, (padding, padding + 18))
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(radius=20))
    
    # Final composite
    final_icon = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    final_icon = Image.alpha_composite(final_icon, shadow_canvas)
    final_icon.paste(masked_tile, (padding, padding), masked_tile)
    
    final_icon.save(output_png, "PNG")
    print(f"✅ Created pristine pure icon at: {output_png}")

if __name__ == "__main__":
    process_pure_icon(
        "/Users/yigitacarli/.gemini/antigravity/brain/1c1b2786-892f-4497-bc81-d904b1878510/winmac_pure_icon_1786715557395.jpg",
        "Resources/AppIcon_1024.png"
    )
