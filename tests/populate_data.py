import requests
import concurrent.futures
import random
import time
import argparse

def create_user(i, base_url):
    user = {
        "name": f"User {i}",
        "email": f"user{i}@example.com",
        "phone": f"555-01{i:02d}"
    }
    try:
        resp = requests.post(f"{base_url}/users", json=user)
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception as e:
        print(f"Failed to create user {i}: {e}")
        return None

def create_product(i, base_url):
    product = {
        "name": f"Product {i}",
        "description": f"Description for product {i}",
        "price": round(random.uniform(10.0, 500.0), 2),
        "stock": random.randint(10, 1000)
    }
    try:
        resp = requests.post(f"{base_url}/products", json=product)
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception as e:
        print(f"Failed to create product {i}: {e}")
        return None

def create_order(i, base_url, user_ids, product_ids):
    if not user_ids or not product_ids:
        return None
        
    order = {
        "userId": random.choice(user_ids),
        "productId": random.choice(product_ids),
        "quantity": random.randint(1, 5)
    }
    try:
        resp = requests.post(f"{base_url}/orders", json=order)
        resp.raise_for_status()
        return resp.json().get("id")
    except Exception as e:
        print(f"Failed to create order {i}: {e}")
        return None

def run_batch(func, count, concurrency, *args):
    ids = []
    start_time = time.time()
    print(f"Starting to create {count} items...")
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as executor:
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
    parser = argparse.ArgumentParser(description="Populate microservices with test data.")
    parser.add_argument("--url", default="http://localhost:9090", help="Gateway URL")
    parser.add_argument("--users", type=int, default=1000, help="Number of users")
    parser.add_argument("--products", type=int, default=10000, help="Number of products")
    parser.add_argument("--orders", type=int, default=50000, help="Number of orders")
    parser.add_argument("--concurrency", type=int, default=20, help="Concurrency level")
    
    args = parser.parse_args()
    
    print(f"Starting data population script with: URL={args.url}, Users={args.users}, Products={args.products}, Orders={args.orders}, Concurrency={args.concurrency}")
    
    # 1. Create Users
    print("\n--- Creating Users ---")
    user_ids = run_batch(create_user, args.users, args.concurrency, args.url)
    if not user_ids:
        print("No users created. Exiting.")
        return

    # 2. Create Products
    print("\n--- Creating Products ---")
    product_ids = run_batch(create_product, args.products, args.concurrency, args.url)
    if not product_ids:
        print("No products created. Exiting.")
        return

    # 3. Create Orders
    print("\n--- Creating Orders ---")
    run_batch(create_order, args.orders, args.concurrency, args.url, user_ids, product_ids)
    
    print("\nData population complete!")

if __name__ == "__main__":
    main()
