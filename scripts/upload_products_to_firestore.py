import firebase_admin
from firebase_admin import credentials, firestore
import csv
import os
import re

# --- Configuration ---
# IMPORTANT: Replace 'path/to/your/serviceAccountKey.json' with the actual path to your Firebase service account key.
# You can download this from Firebase Console -> Project settings -> Service accounts.
SERVICE_ACCOUNT_KEY_PATH = 'scripts/serviceAccountKey.json' 
CSV_FILE_PATH = r"D:\SM products\smmarkets_pantry_full.csv" # Use raw string for Windows paths
FIRESTORE_COLLECTION_NAME = 'local_products_ph'

# --- Initialize Firebase ---
try:
    if not os.path.exists(SERVICE_ACCOUNT_KEY_PATH):
        raise FileNotFoundError(f"Service account key not found at: {SERVICE_ACCOUNT_KEY_PATH}")
    
    cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase initialized successfully.")
except Exception as e:
    print(f"Error initializing Firebase: {e}")
    exit()

# --- Delete Collection Function ---
def delete_collection(coll_ref, batch_size):
    docs = coll_ref.limit(batch_size).stream()
    deleted = 0

    for doc in docs:
        print(f"Deleting doc {doc.id} => {doc.to_dict()}")
        doc.reference.delete()
        deleted = deleted + 1

    if deleted >= batch_size:
        return delete_collection(coll_ref, batch_size)

# --- Upload CSV Data to Firestore ---
def upload_csv_to_firestore(csv_path, collection_name, clear_existing=False):
    if clear_existing:
        print(f"Clearing existing collection '{collection_name}'...")
        delete_collection(db.collection(collection_name), 100) # Use a smaller batch size for deletion
        print(f"Finished clearing collection '{collection_name}'.")

    print(f"Starting upload from {csv_path} to Firestore collection '{collection_name}'...")
    batch = db.batch()
    batch_size = 500 # Firestore batches have a limit of 500 operations

    try:
        with open(csv_path, mode='r', encoding='utf-8') as file:
            csv_reader = csv.DictReader(file)
            
            # Get header names and clean them (e.g., remove BOM if present)
            fieldnames = [field.strip().replace('\ufeff', '') for field in csv_reader.fieldnames]
            csv_reader.fieldnames = fieldnames

            for i, row in enumerate(csv_reader):
                # Ensure 'Name', 'Net weight', 'Price' columns exist
                if not all(key in row for key in ['Name', 'Net weight', 'Price']):
                    print(f"Skipping row {i+1} due to missing required columns (Name, Net weight, Price): {row}")
                    continue

                # Prepare data for Firestore
                product_name_raw = row['Name'].strip()
                net_weight_from_csv = row['Net weight'].strip()

                # Regex to find patterns like "155g", "350ml", "1kg"
                # It looks for a number followed by an optional space and then a unit (g, ml, kg, L)
                # It also handles cases like "| 155g" or "(155g)"
                weight_pattern = re.compile(r'[\s|\(]*(\d+)\s*(g|ml|kg|L)[\s\)]*', re.IGNORECASE)
                
                extracted_net_weight = net_weight_from_csv
                cleaned_product_name = product_name_raw

                match = weight_pattern.search(product_name_raw)
                if match:
                    value = match.group(1)
                    unit = match.group(2)
                    extracted_net_weight = f"{value}{unit.lower()}"
                    
                    # Remove the matched pattern from the product name
                    cleaned_product_name = weight_pattern.sub('', product_name_raw).strip()
                    # Clean up any remaining separators or extra spaces
                    cleaned_product_name = re.sub(r'[\s|(-]+$', '', cleaned_product_name).strip()
                    cleaned_product_name = re.sub(r'\s{2,}', ' ', cleaned_product_name).strip() # Remove multiple spaces

                product_data = {
                    'productName': cleaned_product_name,
                    'netWeight': extracted_net_weight,
                    'price': float(row['Price'].strip()), # Convert price to float
                    'locale': 'PH', # Add locale for Philippine products
                    'source': 'SM Supermarket' # Optional: track data source
                }
                
                # Use product name as part of the document ID for easier lookup,
                # or generate a unique ID. For now, let's use a unique ID.
                doc_ref = db.collection(collection_name).document() 
                batch.set(doc_ref, product_data)

                if (i + 1) % batch_size == 0:
                    batch.commit()
                    batch = db.batch()
                    print(f"Committed {i + 1} documents.")
            
            # Commit any remaining documents in the last batch
            if (i + 1) % batch_size != 0:
                batch.commit()
                print(f"Committed final {i + 1} documents.")
        
        print(f"Successfully uploaded all products from {csv_path} to Firestore collection '{collection_name}'.")

    except FileNotFoundError:
        print(f"Error: CSV file not found at {csv_path}")
    except KeyError as e:
        print(f"Error: Missing expected column in CSV: {e}. Please ensure 'Name', 'Net weight', 'Price' columns exist.")
    except ValueError as e:
        print(f"Error converting data type: {e}. Check 'Price' column for non-numeric values.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    # Set clear_existing to True to delete the collection before uploading
    # Be careful with this option as it will permanently delete all documents in the collection.
    CLEAR_EXISTING_COLLECTION = True 
    upload_csv_to_firestore(CSV_FILE_PATH, FIRESTORE_COLLECTION_NAME, clear_existing=CLEAR_EXISTING_COLLECTION)
