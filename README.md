# 🎓 Sistema de Predicción de Notas con IA (Exam Score AI)

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)

Este proyecto es una aplicación completa de **Arquitectura Cliente-Servidor** diseñada para predecir el rendimiento académico de estudiantes basándose en sus hábitos de estudio. Utiliza un modelo de Inteligencia Artificial (Regresión Lineal) entrenado con datos históricos.

## 🚀 Características Principales

* **Arquitectura Cliente-Servidor RESTful:** Comunicación vía HTTP entre la App móvil y el Backend.
* **Inteligencia Artificial:** Modelo de Machine Learning (`scikit-learn`) que predice la nota final.
* **Base de Datos Persistente:** Almacenamiento histórico de todas las predicciones en **PostgreSQL** (Dockerizado).
* **Interfaz Móvil Moderna:** App desarrollada en **Flutter** con dos módulos:
    1.  **Predicción:** Formulario interactivo para enviar datos al servidor.
    2.  **Historial:** Visualización en tiempo real de las últimas predicciones almacenadas.

---

## 🏗️ Arquitectura del Sistema

El sistema sigue un flujo de datos desacoplado:

```mermaid
graph LR
    A[📱 Flutter App (Cliente)] -- HTTP POST --> B(🐍 Python Flask API)
    B -- Procesa IA --> B
    B -- SQL Insert --> C[(🐘 PostgreSQL Docker)]
    B -- JSON Response --> A
    A -- HTTP GET (Historial) --> B
    B -- SQL Select --> C
