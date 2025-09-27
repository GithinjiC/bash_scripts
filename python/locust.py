from locust import HttpUser, TaskSet, task, between
import random

class UserBehavior(TaskSet):
    @task
    def home_page(self):
        # Simulate accessing the home page
        with self.client.get("/", catch_response=True) as response:
            if response.status_code != 200:
                response.failure("Failed to load home page")
            else:
                response.success()
    
    @task
    def login(self):
        # Simulate a login POST request
        response = self.client.post("/login", json={"username": "testuser", "password": "testpass"})

        if response.status_code == 200:
            # Save token/cookies for authenticated requests
            self.token = response.json().get("token")
        else:
            print(f"Login failed with status code {response.status_code}")

    @task
    def browse_products(self):
        # Simulate browsing a products page
        product_id = random.randint(1, 100)  # Simulate product IDs 1-100
        self.client.get(f"/api/products/{product_id}")
    
    @task
    def checkout(self):
        # Simulate accessing the checkout page
        self.client.get("/checkout")

class WebsiteUser(HttpUser):
    tasks = [UserBehavior]
    wait_time = between(1, 5)  # Users will wait 1 to 5 seconds between tasks
