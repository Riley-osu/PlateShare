from PIL import Image, ImageOps
import io

#to see the image at runtime use the load_image function and then use .show()
class imageHandler:
    def load_image(filePathOrBytes):
        """Loads an image and fixes rotation issues, accepts file path or raw bytes"""

        img = Image.open(filePathOrBytes)
        img = ImageOps.exif_transpose(img)
        return img

    def resize_keep_ratio(img, maxWidth, maxHeight):
        """Shrinks an image to fit within the box without squishing it"""
        resizedImg = img.copy()
        resizedImg.thumbnail((maxWidth, maxHeight), Image.Resampling.LANCZOS)
        return resizedImg

    def crop_to_ratio(img, targetWidth, targetHeight):
        """Forces a new size ratio by cropping the center of the image"""
        return ImageOps.fit(img, (targetWidth, targetHeight), Image.Resampling.LANCZOS)

    def get_image_bytes(img, format="JPEG", quality=85):
        """Converts the image object back into raw bytes."""
        byte_stream = io.BytesIO()

        if img.mode in ("RGBA", "P") and format == "JPEG":
            img = img.convert("RGB")

        img.save(byte_stream, format=format, quality=quality)
        return byte_stream.getvalue()

    