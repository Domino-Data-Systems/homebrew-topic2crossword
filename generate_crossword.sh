#!/bin/bash

# Progress bar function
show_progress() {
    local message="$1"
    echo -n "$message"
    for i in {1..3}; do
        sleep 0.5
        echo -n "."
    done
    echo ""
}

# Check if a topic is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <topic>"
    exit 1
fi

TOPIC=$1
QUESTIONS_FILE="questions.json"

# Show progress message
show_progress "🤖 Generating questions about '$TOPIC' using AI"

# Call the LLM to generate questions (suppress output)
ollama run llama3.2:3b "Generate 30 questions about $TOPIC. Each question should have a one-word answer (at least 3 characters long). Format as CSV with question,answer on each line. Example: What is the capital of France?,Paris" > raw_output.txt 2>/dev/null

# Show completion message
echo "✅ Questions generated successfully!"

# Parse the CSV output to extract questions and answers
awk -F, '{
    # Extract question and answer from CSV fields
    question = $1;
    answer = $2;
    
    # Clean up
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", question);  # Trim whitespace
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", answer);    # Trim whitespace
    
    # Remove quotes from question and answer
    gsub(/^"|"$/, "", question);  # Remove leading/trailing quotes
    gsub(/^"|"$/, "", answer);    # Remove leading/trailing quotes
    
    # Clean answer to only letters and spaces
    gsub(/[^A-Za-z ]/, "", answer);                     # Keep only letters and spaces
    answer = toupper(answer);                           # Convert to uppercase
    
    # Only output if answer is at least 3 characters and contains only letters and spaces
    if (length(answer) >= 3 && answer ~ /^[A-Z ]+$/ && question != "") {
        # Properly escape quotes in question for JSON
        gsub(/"/, "\\\"", question);
        print "{\"question\": \"" question "\", \"answer\": \"" answer "\"},"
    }
}' raw_output.txt > questions_cleaned.txt

# Combine into a JSON array
echo "[" > $QUESTIONS_FILE
cat questions_cleaned.txt | sed '$ s/,$//' >> $QUESTIONS_FILE  # Remove the last comma
echo "]" >> $QUESTIONS_FILE

# Show progress message for crossword generation
show_progress "🧩 Generating crossword puzzle"

# Run the Python script to generate the crossword (suppress ASCII output)
PYTHONPATH=/usr/local/Cellar/topic2crossword/1.0.0/libexec/python_packages /usr/local/opt/python@3.9/bin/python3.9 generate_crossword.py $QUESTIONS_FILE "$TOPIC" 2>/dev/null | grep -E "(Calculating|files have been saved|out of [0-9]+)" || true

# Clean up temporary files
rm raw_output.txt questions_cleaned.txt

# Show final success message
echo "🎉 Crossword puzzle generated successfully!"
echo "📄 Check the generated PDF files in your current directory."