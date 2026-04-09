from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pickle
import pandas as pd
import numpy as np
import math

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

with open("model.pkl", "rb") as f:
    model = pickle.load(f)

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

class PredictionInput(BaseModel):
    neighbourhood: str
    room_type: str
    minimum_nights: int
    availability_365: int
    host_listings_count: int

@app.post("/predict")
async def predict(data: PredictionInput):
    columns = [
        'minimum_nights', 'number_of_reviews', 'reviews_per_month', 
        'availability_365', 'number_of_reviews_ltm', 'days_since_last_review',
        'room_type_Hotel room', 'room_type_Private room', 'room_type_Shared room',
        'neighbourhood_Barnet', 'neighbourhood_Bexley', 'neighbourhood_Brent', 
        'neighbourhood_Bromley', 'neighbourhood_Camden', 'neighbourhood_City of London', 
        'neighbourhood_Croydon', 'neighbourhood_Ealing', 'neighbourhood_Enfield', 
        'neighbourhood_Greenwich', 'neighbourhood_Hackney', 
        'neighbourhood_Hammersmith and Fulham', 'neighbourhood_Haringey', 
        'neighbourhood_Harrow', 'neighbourhood_Havering', 'neighbourhood_Hillingdon', 
        'neighbourhood_Hounslow', 'neighbourhood_Islington', 'neighbourhood_Kensington and Chelsea', 
        'neighbourhood_Kingston upon Thames', 'neighbourhood_Lambeth', 'neighbourhood_Lewisham', 
        'neighbourhood_Merton', 'neighbourhood_Newham', 'neighbourhood_Redbridge', 
        'neighbourhood_Richmond upon Thames', 'neighbourhood_Southwark', 'neighbourhood_Sutton', 
        'neighbourhood_Tower Hamlets', 'neighbourhood_Waltham Forest', 'neighbourhood_Wandsworth', 
        'neighbourhood_Westminster', 'has_no_reviews', 'distance_to_center', 
        'host_tier', 'competition_count'
    ]
    
    input_data = {col: 0 for col in columns}
    input_data['minimum_nights'] = data.minimum_nights
    input_data['availability_365'] = data.availability_365
    input_data['has_no_reviews'] = 1
    input_data['host_tier'] = 1
    input_data['competition_count'] = 10 
    
    lat, lon = BOROUGH_COORDS.get(data.neighbourhood, (CENTRE_LAT, CENTRE_LON))
    input_data['distance_to_center'] = calculate_distance(lat, lon)

    if f"room_type_{data.room_type}" in input_data:
        input_data[f"room_type_{data.room_type}"] = 1
    if f"neighbourhood_{data.neighbourhood}" in input_data:
        input_data[f"neighbourhood_{data.neighbourhood}"] = 1

    df = pd.DataFrame([input_data])[columns]
    
    # DEBUG: This will print the exact row sent to the model in your VS Code terminal
    print("\n--- Model Input Row ---")
    print(df.to_string())
    
    log_prediction = model.predict(df)[0]
    final_price = np.expm1(log_prediction)
    
    return {
        "predicted_price": round(float(final_price), 2),
        "is_90_day_warning": (data.room_type == "Entire home/apt" and data.availability_365 > 90)
    }