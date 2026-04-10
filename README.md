# London Airbnb Price Predictor

A full-stack machine learning application that predicts nightly rental prices for Airbnb listings in London using a Random Forest regression model.
Live Application Link: https://riyabishwakarma11.github.io/airbnb-london-app/
Technical Specifications
Machine Learning
Model: Random Forest Regressor (Scikit-Learn).
Data Processing: Pandas and NumPy for data cleaning and manipulation.
Feature Engineering:
Haversine formula for coordinate-based distance calculation.
One-Hot Encoding for categorical variables (Boroughs, Room Types).
Log Transformation (np.log1p) for target variable normalization.
Serialization: Model compression and persistence via Joblib.
Backend API
Framework: FastAPI (Python).
Server: Uvicorn (ASGI).
Data Validation: Pydantic models for request/response schema enforcement.
Middleware: Cross-Origin Resource Sharing (CORS) configuration for frontend-backend communication.
Hosting: Render (Cloud PAAS).
Frontend
Framework: Flutter Web (Dart).
State Management: StatefulWidget for dynamic UI updates.
Asynchronous Operations: Dart Futures and Async/Await for non-blocking API calls.
Responsiveness: Media Queries and BoxConstraints for cross-device compatibility.
Hosting: GitHub Pages.
Implementation Details
Data Pipeline
The model was trained on historical London Airbnb data. Preprocessing included outlier detection, removal of missing values, and feature scaling. The final model uses 45 features, including spatial data (distance to central London) and categorical encoding.
System Architecture
Request: The Flutter frontend sends a POST request containing user-defined parameters (Borough, Room Type, Nights, Availability, Host Listings).
Preprocessing: The FastAPI backend receives the 5 user inputs and dynamically pads them into a 45-feature vector compatible with the model's training schema.
Inference: The model calculates the predicted price in log-scale.
Post-processing: The backend applies an exponential transformation (np.expm1) to return the final price in GBP (£).
Deployment
Backend
The Python environment is managed via a virtual environment and requirements.txt. The API is deployed to Render, utilizing an absolute path logic to locate serialized artifacts (model.pkl and columns.json).
Frontend
The Flutter web build is compiled with a specific base-href for GitHub Pages compatibility and deployed via the gh-pages branch.
Installation and Local Development
Prerequisites
Python 3.10+
Flutter SDK
Git
Backend Setup
code
Bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: .\venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload
Frontend Setup
code
Bash
cd frontend
flutter pub get
flutter run -d chrome
Author
Riya Bishwakarma
