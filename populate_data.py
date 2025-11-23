import requests
import concurrent.futures
import random
import time

# Configuration
GATEWAY_URL = "http://localhost:9090"
USER_SERVICE_URL = f"{GATEWAY_URL}/users"
PRODUCT_SERVICE_URL = f"{GATEWAY_URL}/products"
ORDER_SERVICE_URL = f"{GATEWAY_URL}/orders"

NUM_USERS = 1000
NUM_PRODUCTS = 10000
NUM_ORDERS = 50000
CONCURRENCY = 20  # Adjust based on system limits

def create_user(i):
    user = {
        "name": f"User {i}",
        "email": f"user{i}@example.com",
        "phone": f"555-01{i:02d}"
    }
    try:
        resp = requests.post(USER_SERVICE_URL, json=user)
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception as e:
        print(f"Failed to create user {i}: {e}")
        return None

def create_product(i):
    product = {
        "name": f"Product {i}",
        "description": f"Description for product {i}",
        "price": round(random.uniform(10.0, 500.0), 2),
        "stock": random.randint(10, 1000)
    }
    try:
        resp = requests.post(PRODUCT_SERVICE_URL, json=product)
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception as e:
        print(f"Failed to create product {i}: {e}")
        return None

def create_order(i, user_ids, product_ids):
    if not user_ids or not product_ids:
        return None
        
    order = {
        "userId": random.choice(user_ids),
        "productId": random.choice(product_ids),
        "quantity": random.randint(1, 5)
    }
    try:
        resp = requests.post(ORDER_SERVICE_URL, json=order)
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception as e:
        # Don't print every error to avoid spamming if service is down
        if i % 100 == 0:
            print(f"Failed to create order {i}: {e}")
        return None

def run_batch(func, count, *args):
    ids = []
    start_time = time.time()
    print(f"Starting to create {count} items...")
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENCY) as executor:
        futures = [executor.submit(func, i, *args) for i in range(1, count + 1)]
        
        for i, future in enumerate(concurrent.futures.as_completed(futures)):
            result = future.result()
            if result:
                ids.append(result)
            
            if (i + 1) % (count // 10 if count >= 10 else 1) == 0:
                print(f"Progress: {i + 1}/{count} ({(i + 1)/count*100:.1f}%)")
                
    duration = time.time() - start_time
    print(f"Finished creating {len(ids)} items in {duration:.2f} seconds.")
    return ids

def main():
    print("Starting data population script...")
    
    # 1. Create Users
    print("\n--- Creating Users ---")
    user_ids = run_batch(create_user, NUM_USERS)
    if not user_ids:
        print("No users created. Exiting.")
        return

    # 2. Create Products
    print("\n--- Creating Products ---")
    product_ids = run_batch(create_product, NUM_PRODUCTS)
    if not product_ids:
        print("No products created. Exiting.")
        return

    # 3. Create Orders
    print("\n--- Creating Orders ---")
    # We pass the actual created IDs to ensure validity
    run_batch(create_order, NUM_ORDERS, user_ids, product_ids)
    
    print("\nData population complete!")

if __name__ == "__main__":
    main()
