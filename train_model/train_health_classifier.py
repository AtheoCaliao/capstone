#!/usr/bin/env python3
"""
Health Data Classification Model Training Script
Trains a TensorFlow Lite model for classifying health records into categories

Requirements:
    pip install tensorflow numpy pandas scikit-learn
"""

import tensorflow as tf
import numpy as np
import json
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import os

# Configuration
CATEGORIES = [
    'Communicable Disease',
    'Non-Communicable Disease',
    'Emergency',
    'Routine Checkup',
    'Prenatal Care',
    'Pediatric Care',
]

SEVERITY_LEVELS = ['Low', 'Medium', 'High', 'Critical']

# Medical keywords for feature engineering
KEYWORDS = {
    'communicable': ['fever', 'cough', 'flu', 'cold', 'infection', 'tuberculosis', 
                     'dengue', 'covid', 'measles', 'chickenpox', 'pneumonia'],
    'emergency': ['chest pain', 'difficulty breathing', 'severe bleeding', 
                  'unconscious', 'seizure', 'stroke', 'heart attack'],
    'non_communicable': ['diabetes', 'hypertension', 'asthma', 'arthritis', 
                         'cancer', 'thyroid', 'cholesterol', 'obesity'],
    'prenatal': ['pregnant', 'pregnancy', 'prenatal', 'antenatal', 'maternal'],
    'pediatric': ['infant', 'child', 'baby', 'newborn', 'toddler'],
}


def create_synthetic_training_data(num_samples=1000):
    """
    Generate synthetic training data for demonstration
    In production, use your actual health records from Firebase
    Data is based on keywords from communicable, emergency, non_communicable, prenatal, and pediatric categories
    """
    print(f"Generating {num_samples} synthetic training samples...")
    
    data = []
    
    for _ in range(num_samples):
        # Random category
        category = np.random.choice(CATEGORIES)
        
        # Generate symptoms based on category keywords
        if category == 'Communicable Disease':
            # Use keywords from communicable category
            selected_keywords = np.random.choice(KEYWORDS['communicable'], size=np.random.randint(1, 3), replace=False)
            symptoms = ', '.join(selected_keywords)
            severity = np.random.choice(['Low', 'Medium', 'High'], p=[0.5, 0.3, 0.2])
            age = np.random.randint(5, 85)
            
        elif category == 'Emergency':
            # Use keywords from emergency category
            selected_keywords = np.random.choice(KEYWORDS['emergency'], size=np.random.randint(1, 2), replace=False)
            symptoms = ', '.join(selected_keywords)
            severity = np.random.choice(['High', 'Critical'], p=[0.3, 0.7])
            age = np.random.randint(20, 80)
            
        elif category == 'Non-Communicable Disease':
            # Use keywords from non_communicable category
            selected_keywords = np.random.choice(KEYWORDS['non_communicable'], size=np.random.randint(1, 3), replace=False)
            symptoms = ', '.join(selected_keywords)
            severity = np.random.choice(['Low', 'Medium', 'High'], p=[0.4, 0.4, 0.2])
            age = np.random.randint(30, 90)
            
        elif category == 'Prenatal Care':
            # Use keywords from prenatal category
            selected_keywords = np.random.choice(KEYWORDS['prenatal'], size=np.random.randint(1, 2), replace=False)
            symptoms = ', '.join(selected_keywords)
            severity = np.random.choice(['Low', 'Medium'], p=[0.7, 0.3])
            age = np.random.randint(18, 50)
            
        elif category == 'Pediatric Care':
            # Use keywords from pediatric category
            selected_keywords = np.random.choice(KEYWORDS['pediatric'], size=np.random.randint(1, 2), replace=False)
            symptoms = ', '.join(selected_keywords)
            severity = np.random.choice(['Low', 'Medium'], p=[0.7, 0.3])
            age = np.random.randint(1, 18)
            
        else:  # Routine Checkup
            symptoms = 'general checkup'
            severity = 'Low'
            age = np.random.randint(1, 90)
        
        # Generate vital signs based on age and category
        if age < 10:
            bp_systolic = np.random.randint(90, 120)
            bp_diastolic = np.random.randint(60, 85)
        elif age < 18:
            bp_systolic = np.random.randint(100, 130)
            bp_diastolic = np.random.randint(65, 90)
        else:
            bp_systolic = np.random.randint(90, 180)
            bp_diastolic = np.random.randint(60, 120)
        
        temp = np.random.uniform(36.0, 40.0)
        hr = np.random.randint(50, 120)
        
        details = f"Age: {age}, BP: {bp_systolic}/{bp_diastolic}, Temp: {temp:.1f}, HR: {hr}"
        
        data.append({
            'symptoms': symptoms,
            'details': details,
            'age': age,
            'category': category,
            'severity': severity,
        })
    
    return data


def extract_features(record):
    """Extract numerical features from health record"""
    features = np.zeros(200)
    
    symptoms = record['symptoms'].lower()
    details = record['details'].lower()
    combined_text = f"{symptoms} {details}"
    
    # Feature 0: Normalized age
    features[0] = record['age'] / 100.0
    
    # Features 1-50: Keyword presence
    idx = 1
    for keyword_list in KEYWORDS.values():
        for keyword in keyword_list[:10]:
            if idx >= 51:
                break
            features[idx] = 1.0 if keyword in combined_text else 0.0
            idx += 1
    
    # Features 51-53: Vital signs
    import re
    bp_match = re.search(r'BP:\s*(\d+)/(\d+)', details)
    if bp_match:
        features[51] = int(bp_match.group(1)) / 200.0
        features[52] = int(bp_match.group(2)) / 150.0
    
    temp_match = re.search(r'Temp:\s*(\d+\.?\d*)', details)
    if temp_match:
        features[53] = float(temp_match.group(1)) / 42.0
    
    hr_match = re.search(r'HR:\s*(\d+)', details)
    if hr_match:
        features[54] = int(hr_match.group(1)) / 200.0
    
    return features


def build_model(input_shape, num_categories, num_severity_levels):
    """Build multi-output neural network"""
    print("\nBuilding model architecture...")
    
    inputs = tf.keras.Input(shape=(input_shape,), name='input_features')
    
    # Shared layers
    x = tf.keras.layers.Dense(128, activation='relu', name='dense_1')(inputs)
    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(64, activation='relu', name='dense_2')(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    x = tf.keras.layers.Dense(32, activation='relu', name='dense_3')(x)
    
    # Category output
    category_output = tf.keras.layers.Dense(
        num_categories,
        activation='softmax',
        name='category_output'
    )(x)
    
    # Severity output
    severity_output = tf.keras.layers.Dense(
        num_severity_levels,
        activation='softmax',
        name='severity_output'
    )(x)
    
    model = tf.keras.Model(
        inputs=inputs,
        outputs=[category_output, severity_output],
        name='health_classifier'
    )
    
    model.compile(
        optimizer='adam',
        loss={
            'category_output': 'sparse_categorical_crossentropy',
            'severity_output': 'sparse_categorical_crossentropy',
        },
        metrics=['accuracy']
    )
    
    return model


def train_model():
    """Main training function"""
    print("=" * 60)
    print("Health Classification Model Training")
    print("=" * 60)
    
    # Generate training data
    data = create_synthetic_training_data(num_samples=2000)
    
    # Extract features and labels
    print("\nExtracting features...")
    X = np.array([extract_features(record) for record in data])
    
    # Encode labels
    category_encoder = LabelEncoder()
    severity_encoder = LabelEncoder()
    
    y_category = category_encoder.fit_transform([r['category'] for r in data])
    y_severity = severity_encoder.fit_transform([r['severity'] for r in data])
    
    # Split data
    X_train, X_test, y_cat_train, y_cat_test, y_sev_train, y_sev_test = train_test_split(
        X, y_category, y_severity, test_size=0.2, random_state=42
    )
    
    print(f"\nTraining set size: {len(X_train)}")
    print(f"Test set size: {len(X_test)}")
    
    # Build model
    model = build_model(
        input_shape=X.shape[1],
        num_categories=len(CATEGORIES),
        num_severity_levels=len(SEVERITY_LEVELS)
    )
    
    print("\nModel Summary:")
    model.summary()
    
    # Train model
    print("\nTraining model...")
    history = model.fit(
        X_train,
        {'category_output': y_cat_train, 'severity_output': y_sev_train},
        validation_data=(
            X_test,
            {'category_output': y_cat_test, 'severity_output': y_sev_test}
        ),
        epochs=50,
        batch_size=32,
        verbose=1
    )
    
    # Evaluate
    print("\nEvaluating model...")
    results = model.evaluate(
        X_test,
        {'category_output': y_cat_test, 'severity_output': y_sev_test}
    )
    print(f"\nTest Results: {dict(zip(model.metrics_names, results))}")
    
    # Convert to TensorFlow Lite
    print("\nConverting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    # Save model
    os.makedirs('../assets/models', exist_ok=True)
    model_path = '../assets/models/health_classifier.tflite'
    
    with open(model_path, 'wb') as f:
        f.write(tflite_model)
    
    print(f"\n✅ Model saved to: {model_path}")
    print(f"Model size: {len(tflite_model) / 1024:.2f} KB")
    
    # Save encoders
    encoders = {
        'categories': category_encoder.classes_.tolist(),
        'severity_levels': severity_encoder.classes_.tolist(),
    }
    
    with open('../assets/models/encoders.json', 'w') as f:
        json.dump(encoders, f, indent=2)
    
    print("\n✅ Encoders saved to: ../assets/models/encoders.json")
    
    return model, history


def test_model():
    """Test the trained model with sample inputs"""
    print("\n" + "=" * 60)
    print("Testing Model with Sample Inputs")
    print("=" * 60)
    
    # Load model
    interpreter = tf.lite.Interpreter(model_path='../assets/models/health_classifier.tflite')
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Test samples
    test_samples = [
        {'symptoms': 'severe chest pain', 'details': 'Age: 55, BP: 180/120', 'age': 55},
        {'symptoms': 'fever and cough', 'details': 'Age: 30, Temp: 38.5', 'age': 30},
        {'symptoms': 'diabetes checkup', 'details': 'Age: 60, BP: 140/90', 'age': 60},
    ]
    
    for i, sample in enumerate(test_samples):
        print(f"\n--- Test Sample {i+1} ---")
        print(f"Symptoms: {sample['symptoms']}")
        print(f"Details: {sample['details']}")
        
        features = extract_features(sample).reshape(1, -1).astype(np.float32)
        
        interpreter.set_tensor(input_details[0]['index'], features)
        interpreter.invoke()
        
        category_probs = interpreter.get_tensor(output_details[0]['index'])[0]
        severity_probs = interpreter.get_tensor(output_details[1]['index'])[0]
        
        category_idx = np.argmax(category_probs)
        severity_idx = np.argmax(severity_probs)
        
        print(f"Predicted Category: {CATEGORIES[category_idx]} ({category_probs[category_idx]*100:.1f}%)")
        print(f"Predicted Severity: {SEVERITY_LEVELS[severity_idx]} ({severity_probs[severity_idx]*100:.1f}%)")


if __name__ == '__main__':
    # Train the model
    model, history = train_model()
    
    # Test the model
    test_model()
    
    print("\n" + "=" * 60)
    print("Training Complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Copy assets/models/health_classifier.tflite to your Flutter assets")
    print("2. Update pubspec.yaml to include the model in assets")
    print("3. The AI classifier will automatically use the model")
    print("=" * 60)
