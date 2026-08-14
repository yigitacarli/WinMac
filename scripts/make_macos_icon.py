import math
from PIL import Image, ImageDraw, ImageFilter, ImageOps

def create_macos_icon(input_path, output_path):
    # Load original image
    src = Image.open(input_path).convert("RGBA")
    
    # 1024x1024 canvas
    canvas_size = 1024
    
    # Apple icon grid: icon body is 824x824 (or 860x860) centered
    icon_size = 856
    padding = (canvas_size - icon_size) // 2 # 84px on each side
    radius = 185 # Apple standard squircle corner radius at 1024 scale
    
    # Resize artwork to 856x856 (centered crop from src)
    artwork = ImageOps.fit(src, (icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Create smooth squircle mask (superellipse) at 4x resolution for pristine anti-aliasing
    scale = 4
    mask_size = icon_size * scale
    mask_radius = radius * scale
    
    mask = Image.new("L", (mask_size, mask_size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (mask_size, mask_size)], radius=mask_radius, fill=255)
    mask = mask.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Apply mask to artwork
    masked_artwork = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 0))
    masked_artwork.paste(artwork, (0, 0), mask)
    
    # Create subtle macOS drop shadow
    shadow_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_mask = Image.new("L", (icon_size, icon_size), 0)
    shadow_draw = ImageDraw.Draw(shadow_mask)
    shadow_draw.rounded_rectangle([(0, 0), (icon_size, icon_size)], radius=radius, fill=110)
    
    shadow_layer = Image.new("RGBA", (icon_size, icon_size), (0, 0, 0, 110))
    shadow_layer.putalpha(shadow_mask)
    
    # Paste shadow with blur and slight Y offset
    shadow_canvas.paste(shadow_layer, (padding, padding + 16))
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(radius=18))
    
    # Composite artwork over shadow on transparent 1024x1024 canvas
    final_icon = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    final_icon = Image.alpha_composite(final_icon, shadow_canvas)
    final_icon.paste(masked_artwork, (padding, padding), masked_artwork)
    
    final_icon.save(output_path, "PNG")
    print(f"✅ Generated Apple-standard squircle icon at: {output_path}")

if __name__ == "__main__":
    import sys
    src_file = sys.argv[1] if len(sys.argv) > 1 else "src.png"
    out_file = sys.argv[2] if len(sys.argv) > 2 else "AppIcon_1024.png"
    create_macos_icon(src_file, out_file)
