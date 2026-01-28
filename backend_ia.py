from flask import Flask, request, jsonify
import pandas as pd
from sklearn.linear_model import LinearRegression
import psycopg2
from datetime import datetime
import time

app = Flask(__name__)

print("🧠 Iniciando Servidor IA (Modo HTTP)...")

# --- 1. ENTRENAMIENTO IA (Igual que antes) ---
try:
    df = pd.read_csv('Exam_Score_Prediction.csv')
    df.columns = [c.lower() for c in df.columns]
    X = df[['study_hours', 'class_attendance', 'sleep_hours']]
    y = df['exam_score']
    model = LinearRegression()
    model.fit(X, y)
    print("✅ Modelo Entrenado.")
except Exception as e:
    print(f"❌ Error CSV: {e}")
    exit()

# --- 2. BASE DE DATOS (Igual que antes) ---
def get_db_connection():
    return psycopg2.connect(
        host="localhost", port="5435", 
        database="escuela_db", user="admin", password="admin"
    )

def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS predicciones (
                id SERIAL PRIMARY KEY,
                study_hours FLOAT,
                attendance FLOAT,
                sleep_hours FLOAT,
                nota_predicha FLOAT,
                fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        conn.commit()
        conn.close()
        print("✅ Base de Datos Conectada.")
    except Exception as e:
        print(f"⚠️ Error DB inicial: {e}")

# --- 3. RUTAS DEL SERVIDOR (Endpoints) ---

# Endpoint para PREDECIR (POST)
@app.route('/predict', methods=['POST'])
def predict():
    try:
        data = request.json
        study = float(data['study'])
        attend = float(data['attendance'])
        sleep = float(data['sleep'])
        
        # Predecir
        pred_raw = model.predict([[study, attend, sleep]])[0]
        prediction = float(round(pred_raw, 2))
        
        # Guardar en BD
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO predicciones (study_hours, attendance, sleep_hours, nota_predicha) VALUES (%s, %s, %s, %s)",
            (study, attend, sleep, prediction)
        )
        conn.commit()
        conn.close()
        
        # Responder al cliente
        return jsonify({'score': prediction})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Endpoint para HISTORIAL (GET)
@app.route('/history', methods=['GET'])
def history():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT study_hours, attendance, sleep_hours, nota_predicha, fecha FROM predicciones ORDER BY id DESC LIMIT 10")
        rows = cur.fetchall()
        conn.close()
        
        historial = []
        for r in rows:
            historial.append({
                "study": r[0],
                "attendance": r[1],
                "sleep": r[2],
                "score": r[3],
                "date": r[4].strftime("%Y-%m-%d %H:%M")
            })
        return jsonify(historial)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    init_db()
    # '0.0.0.0' permite que te conectes desde otro dispositivo (celular)
    app.run(host='0.0.0.0', port=5000, debug=True)