import os
import json
import joblib
import pandas as pd
import numpy as np
import math
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# 1. CORS Setup (Allows Flutter Web to talk to the API)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. FILE PATH LOGIC (The "Anti-Error" Fix)
# This finds the exact folder where main.py lives, even on a cloud server
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
model_path = os.path.join(BASE_DIR, "model.pkl")
columns_path = os.path.join(BASE_DIR, "columns.json")

# 3. LOAD THE BRAIN AND THE MANUAL
# We do this at the top so the app crashes early if files are missing
try:
    with open(columns_path, "r") as f:
        trained_columns = json.load(f)
    model = joblib.load(model_path)
    print("✅ Model and Columns loaded successfully!")
except Exception as e:
    print(f"❌ Error loading files: {e}")

# 4. LONDON CONSTANTS
CENTRE_LAT, CENTRE_LON = 51.5074, -0.1278
BOROUGH_COORDS = {
    "Westminster": (51.4975, -0.1357), "Hackney": (51.5450, -0.0553),
    "Camden": (51.5290, -0.1255), "Southwark": (51.4834, -0.0821),
    "Tower Hamlets": (51.5099, -0.0059), "Islington": (51.5416, -0.1022),
    "Lambeth": (51.4607, -0.1163), "Kensington and Chelsea": (51.5020, -0.1947),
    "Wandsworth": (51.4567, -0.1910), "Brent": (51.5588, -0.2817),
    "Lewisham": (51.4452, -0.0209), "Haringey": (51.6000, -0.1119),
    "Newham": (51.5077, 0.0469), "Ealing": (51.5130, -0.3089),
    "Barnet": (51.6252, -0.1517), "Greenwich": (51.4892, 0.0648),
    "Hammersmith and Fulham": (51.4927, -0.2339), "Waltham Forest": (51.5907, -0.0134),
    "Croydon": (51.3714, -0.0977), "Hounslow": (51.4746, -0.3680),
    "Enfield": (51.6562, -0.0876), "Hillingdon": (51.5441, -0.4760),
    "Redbridge": (51.5590, 0.0741), "Bromley": (51.4039, 0.0198),
    "Merton": (51.4014, -0.2158), "Richmond upon Thames": (51.4479, -0.3260),
    "Harrow": (51.5898, -0.3346), "Barking and Dagenham": (51.5607, 0.1557),
    "Havering": (51.5812, 0.1837), "Kingston upon Thames": (51.4123, -0.3007),
    "Sutton": (51.3618, -0.1945), "Bexley": (51.4549, 0.1505),
    "City of London": (51.5123, -0.0909)
}

def calculate_distance(lat, lon):
    p = math.pi / 180
    a = 0.5 - math.cos((lat - CENTRE_LAT) * p)/2 + math.cos(CENTRE_LAT * p) * \
        math.cos(lat * p) * (1 - math.cos((lon - CENTRE_LON) * p)) / 2
    return 12742 * math.asin(math.sqrt(a))

# 5. INPUT SCHEMA
class PredictionInput(BaseModel):
    neighbourhood: str
    room_type: str
    minimum_nights: int
    availability_365: int
    host_listings_count: int

# 6. THE PREDICTION ENDPOINT
@app.post("/predict")
async def predict(data: PredictionInput):
    # Step A: Initialize all columns from columns.json to 0
    input_data = {col: 0 for col in trained_columns}
    
    # Step B: Fill with User data (if the columns exist in the model)
    if 'minimum_nights' in input_data: input_data['minimum_nights'] = data.minimum_nights
    if 'availability_365' in input_data: input_data['availability_365'] = data.availability_365
    
    # Defaults for new listings
    if 'has_no_reviews' in input_data: input_data['has_no_reviews'] = 1
    if 'host_tier' in input_data: input_data['host_tier'] = 1
    if 'competition_count' in input_data: input_data['competition_count'] = 10 
    
    # Step C: Distance calculation
    lat, lon = BOROUGH_COORDS.get(data.neighbourhood, (CENTRE_LAT, CENTRE_LON))
    if 'distance_to_center' in input_data:
        input_data['distance_to_center'] = calculate_distance(lat, lon)

    # Step D: One-Hot Encoding (Dynamic Matching)
    room_col = f"room_type_{data.room_type}"
    if room_col in input_data:
        input_data[room_col] = 1
        
    borough_col = f"neighbourhood_{data.neighbourhood}"
    if borough_col in input_data:
        input_data[borough_col] = 1

    # Step E: Convert to DataFrame using the EXACT Colab Column Order
    df = pd.DataFrame([input_data])[trained_columns]
    
    # Step F: Debug Print (Perfect for copying to Colab)
    print("\n--- COPY THIS DICTIONARY TO COLAB ---")
    print(json.dumps(input_data, indent=2))
    print("--------------------------------------")
    
    # Step G: Prediction and Reversing Log Price
    log_prediction = model.predict(df)[0]
    final_price = np.expm1(log_prediction)
    
    return {
        "predicted_price": round(float(final_price), 2),
        "is_90_day_warning": (data.room_type == "Entire home/apt" and data.availability_365 > 90)
    }