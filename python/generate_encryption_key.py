import secrets
import base64

def generate_encryption_key(key_length=32):
    """
    Generate a globally unique encryption key.
    The default key length is 32 bytes (256 bits).
    Args:
    - key_length: The length of the encryption key in bytes (default is 32).
    Returns:
    - The generated encryption key as a base64 encoded string for easy use.
    """
    # Generate a random key using secrets module
    key = secrets.token_bytes(key_length)

    # Optionally, you can base64 encode the key to make it easy to store and use
    encoded_key = base64.urlsafe_b64encode(key).decode('utf-8')

    return encoded_key

# Example usage
encryption_key = generate_encryption_key()
print(f"{encryption_key}")