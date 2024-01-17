from PIL import Image, ImageDraw, ImageFont

A4_WIDTH = int(8.27 * 300)  # A4 width in pixels at 300 DPI
A4_HEIGHT = int(11.69 * 300)  # A4 height in pixels at 300 DPI

def text_to_handwritten(text):
    font_path = "C:\\Users\\idmak\\Documents\\python\\Assignment\\font.ttf"
    font_size = 40
    line_height = 30

    image = Image.new("RGB", (A4_WIDTH, A4_HEIGHT), "white")
    draw = ImageDraw.Draw(image)

    font = ImageFont.truetype(font_path, font_size)

    position = (50, 50)
    current_width = 0
    current_line = 0
    current_page = 1

    lines = text.split('\n')

    for line in lines:
        words = line.split()
        for word in words:
            word_bbox = draw.textbbox(position, word, font=font)
            word_width = word_bbox[2] - word_bbox[0]
            word_height = word_bbox[3] - word_bbox[1]

            if current_width + word_width > A4_WIDTH - 100:
                position = (50, position[1] + 100)
                current_width = 0
                current_line += 1

                if position[1] > A4_HEIGHT - 100:
                    image.save(f"C:\\Users\\idmak\\Documents\\python\\Assignment\\handwritten_text_page_{current_page}.png")
                    current_page += 1
                    image = Image.new("RGB", (A4_WIDTH, A4_HEIGHT), "white")
                    draw = ImageDraw.Draw(image)
                    position = (50, 50)

            draw.text(position, word, fill="black", font=font)
            word_width_with_space = word_width + 20  # Adjust the value for word spacing
            position = (position[0] + word_width_with_space, position[1])
            current_width += word_width_with_space

        position = (50, position[1] + 100)
        current_line += 1
        current_width = 0

    # Save the final image
    image.save(f"C:\\Users\\idmak\\Documents\\python\\Assignment\\handwritten_text_page_{current_page}.png")
    return f"C:\\Users\\idmak\\Documents\\python\\Assignment\\handwritten_text_page_{current_page}.png"

# Example usage
text_to_handwritten("Your input text goes here.")
