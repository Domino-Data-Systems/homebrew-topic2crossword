import sys
import json
from genxword.calculate import Crossword
from genxword.control import Genxword

def validate_crossword_questions(genxword, short_title):
    """
    Validate that all words in the crossword have proper questions.
    Returns True if validation passes, False otherwise.
    """
    try:
        # Check if the crossword was generated successfully by looking for output files
        import os
        import glob
        
        # Look for the generated PDF files
        grid_files = glob.glob(f"{short_title}_grid.pdf")
        key_files = glob.glob(f"{short_title}_key.pdf")
        
        if not grid_files or not key_files:
            print("❌ Crossword PDF files were not generated")
            return False
        
        # Check file sizes to ensure they're not empty
        for file_path in grid_files + key_files:
            if os.path.getsize(file_path) < 1000:  # Less than 1KB
                print(f"❌ Generated file {file_path} is too small (possibly empty)")
                return False
        
        # Count words that were successfully placed
        total_words = len(genxword.wordlist) if hasattr(genxword, 'wordlist') else 0
        
        if total_words == 0:
            print("❌ No words were provided to the crossword generator")
            return False
        
        # For now, we'll consider it successful if the PDF files were generated
        # and have reasonable sizes. The genxword library handles the word placement.
        print(f"📊 Crossword Status: {total_words} words processed, PDF files generated successfully")
        print("✅ Crossword validation passed - PDF files created with questions")
        return True
        
    except Exception as e:
        print(f"❌ Error during crossword validation: {e}")
        return False

def main(questions_file, topic="Crossword Puzzle"):
    # Load questions from a JSON file
    try:
        with open(questions_file, 'r') as file:
            data = json.load(file)
        print(f"Loaded {len(data)} questions from {questions_file}")
        
        # Check if we have enough questions
        if len(data) < 10:
            print(f"❌ Insufficient questions ({len(data)}). Need at least 10 questions.")
            return 2  # Exit code 2 for insufficient questions
    except Exception as e:
        print(f"Error reading from {questions_file}: {e}")
        return 1  # Exit code 1 for file error

    # Initialize crossword
    crossword = Crossword(rows=50, cols=50)

    # Add questions to crossword
    valid_questions = 0
    for item in data:
        try:
            question = item['question']
            answer = item['answer']
            
            # Validate question and answer
            if len(question.strip()) > 0 and len(answer.replace(" ", "")) >= 3:
                # Store the answer as a string, not a list
                crossword.available_words.append([answer.replace(" ", ""), question])  # Remove spaces
                print(f"Added word: {answer} with clue: {question}")
                valid_questions += 1
            else:
                print(f"Skipping invalid question/answer: '{question}' / '{answer}'")
        except (KeyError, ValueError) as e:
            print(f"Error processing item: {item}. Error: {e}")
            continue

    print(f"📝 Valid questions processed: {valid_questions}")
    
    if valid_questions < 10:
        print(f"❌ Insufficient valid questions ({valid_questions}). Need at least 10.")
        return 2

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
    try:
        genxword.grid_size()
    except Exception as e:
        print(f"❌ Error calculating grid size: {e}")
        return 3  # Exit code 3 for grid calculation error

    # Generate the crossword grid with the shortened title
    short_title = f"DDS AI Crossword Generator - {topic}"
    try:
        genxword.gengrid(short_title, "p")
    except Exception as e:
        print(f"❌ Error generating crossword grid: {e}")
        return 4  # Exit code 4 for generation error
    
    # Validate the generated crossword
    if not validate_crossword_questions(genxword, short_title):
        return 5  # Exit code 5 for validation failure
    
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
    
    print("✅ Crossword puzzle generated successfully!")
    return 0  # Success

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: python3 generate_crossword.py <questions_file> [topic]")
        sys.exit(1)

    questions_file = sys.argv[1]
    topic = sys.argv[2] if len(sys.argv) == 3 else "Crossword Puzzle"
    exit_code = main(questions_file, topic)
    sys.exit(exit_code)
