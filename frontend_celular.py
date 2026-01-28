from flask import Flask, render_template, request, jsonify
import paho.mqtt.client as mqtt
import json
import time
import threading

app = Flask(__name__)

# Variable global para guardar la última respuesta recibida
ultima_prediccion = None

# Configuración MQTT del Frontend
def on_message(client, userdata, msg):
    global ultima_prediccion
    data = json.loads(msg.payload.decode())
    ultima_prediccion = data['score']

client = mqtt.Client()
client.on_message = on_message
client.connect("localhost", 1883, 60)
client.subscribe("escuela/predict/response")
client.loop_start() # Hilo separado para escuchar mensajes

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/predecir', methods=['POST'])
def predecir():
    global ultima_prediccion
    ultima_prediccion = None # Resetear
    
    data = request.json
    # Enviar al Backend
    client.publish("escuela/predict/request", json.dumps(data))
    
    # Esperar respuesta (Polling simple para demo)
    for _ in range(50): # Esperar max 5 segundos
        if ultima_prediccion is not None:
            return jsonify({"score": ultima_prediccion})
        time.sleep(0.1)
        
    return jsonify({"error": "Tiempo de espera agotado"}), 500

if __name__ == '__main__':
    # Ejecutar en modo móvil accesible desde red local si quieres
    app.run(host='0.0.0.0', port=5000, debug=True)