import pandas as pd
import requests
from io import StringIO
from datetime import datetime
from math import radians, sin, cos, sqrt, atan2

def haversine(lat1, lon1, lat2, lon2):
    # Функция для расчета расстояния между двумя точками на Земле (в метрах)
    R = 6371.0  # радиус Земли в км

    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    distance = R * c * 1000  # переводим в метры
    return distance

# Обработка данных такси
def process_taxi_data(filepath):
    taxi_df = pd.read_csv(filepath)

    # Рассчитываем время поездки в минутах
    pickup_time = pd.to_datetime(taxi_df['tpep_pickup_datetime'])
    dropoff_time = pd.to_datetime(taxi_df['tpep_dropoff_datetime'])
    taxi_df['trip_time_min'] = (dropoff_time - pickup_time).dt.total_seconds() / 60

    # Рассчитываем расстояние поездки в метрах (переводим из миль)
    taxi_df['trip_distance_m'] = taxi_df['trip_distance'] * 1609.34

    # Извлекаем час дня
    taxi_df['hour_of_day'] = pickup_time.dt.hour

    # Выбираем нужные столбцы
    taxi_df = taxi_df[['trip_time_min', 'trip_distance_m', 'hour_of_day']]
    taxi_df['type'] = 'taxi'

    return taxi_df

# Обработка данных велопроката
def process_bike_data(filepath):
    bike_df = pd.read_csv(filepath)

    # Уже есть время в минутах
    bike_df['trip_time_min'] = bike_df['Trip Duration'] / 60

    # Рассчитываем расстояние поездки в метрах
    bike_df['trip_distance_m'] = bike_df.apply(
        lambda row: haversine(
            row['Start Station Latitude'],
            row['Start Station Longitude'],
            row['End Station Latitude'],
            row['End Station Longitude']
        ),
        axis=1
    )

    # Извлекаем час дня
    pickup_time = pd.to_datetime(bike_df['Start Time'])
    bike_df['hour_of_day'] = pickup_time.dt.hour

    # Выбираем нужные столбцы
    bike_df = bike_df[['trip_time_min', 'trip_distance_m', 'hour_of_day']]
    bike_df['type'] = 'bike'

    return bike_df

# Основная функция
def main():
    # Загрузка и обработка данных
    taxi_data = process_taxi_data('yellow_tripdata_2015-01.csv')
    bike_data = process_bike_data('NYC-BikeShare-2015-2017-combined.csv')

    # Объединяем данные
    combined_data = pd.concat([taxi_data, bike_data], ignore_index=True)

    # Добавляем номер строки
    combined_data['№'] = combined_data.index + 1

    # Упорядочиваем столбцы
    result = combined_data[['№', 'trip_time_min', 'trip_distance_m', 'hour_of_day', 'type']]

    # Сохраняем результат
    result.to_csv('combined_trips_data.csv', index=False)
    print("Файл combined_trips_data.csv успешно создан.")

if __name__ == "__main__":
    main()
