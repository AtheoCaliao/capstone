# Health AI Model Training

This directory contains scripts to train a custom TensorFlow Lite model for health data classification.

## Setup

1. Install Python dependencies:
```bash
pip install tensorflow numpy pandas scikit-learn
```

2. Generate and train the model:
```bash
python train_health_classifier.py
```

## Using Your Own Data

To train with your actual health records from Firebase:

1. Export your data from Firebase:
   - Go to Firebase Console → Firestore Database
   - Export the `checkup_records` collection
   - Save as `health_data.json`

2. Modify `train_health_classifier.py`:
```python
def load_real_data():
    with open('health_data.json', 'r') as f:
        firebase_data = json.load(f)
    
    data = []
    for record in firebase_data:
        data.append({
            'symptoms': record.get('symptoms', ''),
            'details': record.get('details', ''),
            'age': record.get('age', 0),
            'category': record.get('ai_category', 'Routine Checkup'),
            'severity': record.get('ai_severity', 'Low'),
        })
    
    return data

# Replace the synthetic data generation:
# data = create_synthetic_training_data(num_samples=2000)
data = load_real_data()
```

3. Run training again:
```bash
python train_health_classifier.py
```

## Model Architecture

- **Input**: 200 features (keywords, vital signs, age)
- **Hidden Layers**: 128 → 64 → 32 neurons with dropout
- **Outputs**:
  - Category classification (6 classes)
  - Severity assessment (4 levels)

## Categories

1. Communicable Disease
2. Non-Communicable Disease
3. Emergency
4. Routine Checkup
5. Prenatal Care
6. Pediatric Care

## Severity Levels

1. Low
2. Medium
3. High
4. Critical

## Model Performance

After training, you'll see:
- Training accuracy
- Validation accuracy
- Test set performance
- Model size (~50-100 KB)

## Integrating with Flutter

The model is automatically saved to:
```
../assets/models/health_classifier.tflite
```

Make sure your `pubspec.yaml` includes:
```yaml
flutter:
  assets:
    - assets/models/
```

## Continuous Improvement

As you collect more data:
1. Periodically retrain the model
2. Fine-tune hyperparameters
3. Add new categories/keywords
4. Improve feature engineering

## Troubleshooting

**Model not loading in Flutter?**
- Verify the file path in assets
- Check that tflite_flutter package is installed
- Review console logs for errors

**Poor accuracy?**
- Collect more training data (1000+ samples recommended)
- Balance classes (equal samples per category)
- Add domain-specific keywords
- Tune learning rate and epochs
