# Raspberry Pi Touch App

This project is a touch screen application designed for Raspberry Pi using Python and Tkinter. The application allows users to browse and view recipes stored in a JSON format.

## Project Structure

```
raspberrypi-touch-app
├── src
│   ├── main.py          # Entry point of the application
│   ├── ui               # Contains UI components
│   │   └── __init__.py
│   ├── recipes          # Contains recipe data in JSON format
│   │   └── sample_recipes.json
│   └── utils            # Contains utility functions
│       └── __init__.py
├── requirements.txt     # Lists required Python libraries
├── README.md            # Project documentation
└── .vscode              # Development environment settings
    └── settings.json
```

## Setup Instructions

1. **Clone the repository**:
   ```
   git clone <repository-url>
   cd raspberrypi-touch-app
   ```

2. **Install dependencies**:
   Make sure you have Python installed on your Raspberry Pi. Then, install the required libraries by running:
   ```
   pip install -r requirements.txt
   ```

3. **Run the application**:
   You can start the application by executing:
   ```
   python src/main.py
   ```

## Usage

- The application will display a touch screen interface where users can navigate through the recipes.
- Recipes are loaded from the `src/recipes/sample_recipes.json` file.

## Contributing

Feel free to submit issues or pull requests if you have suggestions or improvements for the project.