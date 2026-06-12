import tkinter as tk
import json
import os

def load_recipes(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def create_main_window():
    window = tk.Tk()
    window.title("Raspberry Pi Touch App")
    window.geometry("800x480")  # Set the window size for the touchscreen

    return window

def main():
    recipes_file_path = os.path.join(os.path.dirname(__file__), 'recipes', 'sample_recipes.json')
    recipes = load_recipes(recipes_file_path)

    window = create_main_window()

    # Here you can add code to display recipes in the GUI

    window.mainloop()

if __name__ == "__main__":
    main()