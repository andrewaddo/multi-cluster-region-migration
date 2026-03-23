import requests
import time
import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description="Test Multi-Cluster Gateway failover.")
    parser.add_argument("url", help="The Gateway URL (e.g., http://<gateway-ip>/status)")
    parser.add_argument("--interval", type=float, default=0.5, help="Interval between requests in seconds")
    
    args = parser.parse_args()
    
    print(f"Starting load test against {args.url}")
    print("Press Ctrl+C to stop.\n")
    
    success_count = 0
    error_count = 0
    cluster_counts = {}
    
    try:
        while True:
            try:
                # Disable keep-alive to simulate fresh client connections and force load balancing
                headers = {'Connection': 'close'}
                response = requests.get(args.url, timeout=2.0, headers=headers)
                
                if response.status_code == 200:
                    data = response.json()
                    cluster = data.get("cluster", "unknown")
                    region = data.get("region", "unknown")
                    
                    cluster_counts[cluster] = cluster_counts.get(cluster, 0) + 1
                    success_count += 1
                    
                    sys.stdout.write(f"\r[Success: {success_count} | Errors: {error_count}] Latest response from: {cluster} ({region})    ")
                    sys.stdout.flush()
                else:
                    error_count += 1
                    print(f"\nError: HTTP {response.status_code}")
                    
            except requests.exceptions.RequestException as e:
                error_count += 1
                print(f"\nRequest failed: {e}")
                
            time.sleep(args.interval)
            
    except KeyboardInterrupt:
        print("\n\nTest stopped by user.")
        print("-" * 30)
        print("Final Results:")
        print(f"Total Requests: {success_count + error_count}")
        print(f"Successful:   {success_count}")
        print(f"Errors:       {error_count}")
        print("\nTraffic Distribution:")
        for cluster, count in cluster_counts.items():
            percentage = (count / success_count) * 100 if success_count > 0 else 0
            print(f"  - {cluster}: {count} ({percentage:.1f}%)")

if __name__ == "__main__":
    main()
