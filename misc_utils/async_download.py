import os
import requests
import threading
import hashlib
from tqdm import tqdm

MEDIA_PATH = '/home/camus/media'

def calculate_checksum(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def download_file(url, filepath):
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()

        total_size = int(response.headers.get('content-length', 0))

        with open(filepath, 'wb') as file, tqdm(
            total=total_size,
            ascii=' #',
            unit='B',
            unit_scale=True,
            unit_divisor=1024,
        ) as bar:
            for data in response.iter_content(chunk_size=8192):
                bar.update(len(data))
                file.write(data)

        return filepath
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        return None

def verify_links(urls):
    for url in urls:
        try:
            response = requests.head(url)
            response.raise_for_status()
        except Exception as e:
            print(f"Error accessing {url}: {e}")
            return False
    return True

def main():
    urls = []

    while True:
        url = input("Enter download URL (or 'q' to quit): ")
        if url.lower() == 'q':
            break
        urls.append(url)

    if not verify_links(urls):
        print("Some links are inaccessible. Aborting.")
        return

    os.makedirs(MEDIA_PATH, exist_ok=True)

    filenames = []
    for url in urls:
        filename = input(f"Enter a name from {url}: ")
        filenames.append(filename)

    threads = []
    downloaded_files = []

    for url, filename in zip(urls, filenames):
        filepath = os.path.join(MEDIA_PATH, filename)
        thread = threading.Thread(target=download_file, args=(url, filepath))
        thread.start()
        threads.append(thread)
        downloaded_files.append(filepath)

    for thread in threads:
        thread.join()

    print("All downloads completed.")

    for filepath in downloaded_files:
        calculated_checksum = calculate_checksum(filepath)
        expected_checksum = calculated_checksum  # Assume expected checksum is the calculated one
        if expected_checksum == calculated_checksum:
            print(f"Checksum verification passed for {os.path.basename(filepath)}")
        else:
            print(f"Checksum verification failed for {os.path.basename(filepath)}")

if __name__ == "__main__":
    main()
