from PIL import Image
import os

def pad_image(input_path, output_path, scale_factor=0.65):
    try:
        img = Image.open(input_path).convert("RGBA")
        
        # Calculate new size based on scale factor
        # We want the content to be scale_factor * original_size, centered
        # Actually simplest way:
        # Create a new blank image of original size
        # Resize original image to scale_factor size
        # Paste centered
        
        width, height = img.size
        new_width = int(width * scale_factor)
        new_height = int(height * scale_factor)
        
        resized_img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
        
        # Create canvas
        canvas = Image.new("RGBA", (width, height), (255, 255, 255, 0)) # Transparent
        
        # Calculate position to center
        x = (width - new_width) // 2
        y = (height - new_height) // 2
        
        canvas.paste(resized_img, (x, y), resized_img)
        
        canvas.save(output_path)
        print(f"Successfully created padded image: {output_path}")
        
    except Exception as e:
        print(f"Error padding image: {e}")

if __name__ == "__main__":
    input_file = "c:\\Users\\polat\\taksibu-backend\\taksibusonlogo.png"
    output_file = "c:\\Users\\polat\\taksibu-backend\\taksibu_padded.png"
    pad_image(input_file, output_file)
