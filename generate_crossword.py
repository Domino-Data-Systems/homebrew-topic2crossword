import sys
import json
from genxword.calculate import Crossword
from genxword.control import Genxword

def main(questions_file, topic="Crossword Puzzle"):
    # Load questions from a JSON file
    try:
        with open(questions_file, 'r') as file:
            data = json.load(file)
        print(f"Loaded {len(data)} questions from {questions_file}")
    except Exception as e:
        print(f"Error reading from {questions_file}: {e}")
        sys.exit(1)

    # Initialize crossword
    crossword = Crossword(rows=50, cols=50)

    # Add questions to crossword
    for item in data:
        try:
            question = item['question']
            answer = item['answer']
            # Store the answer as a string, not a list
            crossword.available_words.append([answer.replace(" ", ""), question])  # Remove spaces
            print(f"Added word: {answer} with clue: {question}")
        except (KeyError, ValueError) as e:
            print(f"Error processing item: {item}. Error: {e}")
            continue

    # Prepare the word list in the expected format for Genxword
    formatted_wordlist = []
    for word_entry in crossword.available_words:
        word = word_entry[0]  # Keep the word as a string
        clue = word_entry[1]
        formatted_wordlist.append([word, clue])  # Store as list of strings

    # Initialize Genxword with necessary attributes
    genxword = Genxword(auto=True)
    genxword.nrow = crossword.rows
    genxword.ncol = crossword.cols
    genxword.wordlist = formatted_wordlist  # Ensure wordlist is a list of lists

    # Calculate the grid size before generating
    genxword.grid_size()

    # Generate the crossword grid with the shortened title
    short_title = f"DDS AI Crossword Generator - {topic}"
    genxword.gengrid(short_title, "p")
    
    # Create filename-safe topic (replace spaces with underscores, remove special chars)
    safe_topic = topic.replace(" ", "_").replace("-", "_")
    safe_topic = ''.join(c for c in safe_topic if c.isalnum() or c == '_')
    
    # Rename the generated files to the desired format
    import os
    import glob
    
    # Find the generated files and rename them
    for old_file in glob.glob(f"{short_title}_grid.pdf"):
        new_file = f"DDS-AICWG-{safe_topic}_grid.pdf"
        if os.path.exists(old_file):
            os.rename(old_file, new_file)
            print(f"Renamed {old_file} to {new_file}")
    
    for old_file in glob.glob(f"{short_title}_key.pdf"):
        new_file = f"DDS-AICWG-{safe_topic}_key.pdf"
        if os.path.exists(old_file):
            os.rename(old_file, new_file)
            print(f"Renamed {old_file} to {new_file}")

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python3 generate_crossword.py <questions_file> [topic]")
        sys.exit(1)

    questions_file = sys.argv[1]
    topic = sys.argv[2] if len(sys.argv) == 3 else "Crossword Puzzle"
    main(questions_file, topic)
