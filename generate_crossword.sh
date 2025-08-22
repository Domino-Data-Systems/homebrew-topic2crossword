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

# Function to generate questions using Ollama
generate_questions() {
    local topic="$1"
    local attempt="$2"
    
    if [ "$attempt" -gt 1 ]; then
        echo "🔄 Attempt $attempt: Regenerating questions for '$topic'"
        echo "💡 Trying with more specific instructions..."
    else
        show_progress "🤖 Generating questions about '$topic' using AI"
    fi
    
    # Enhanced prompt for better question generation
    local prompt="Generate exactly 30 questions about $topic. Each question must be a complete sentence ending with a question mark and have a one-word answer (3-12 characters long). Avoid yes/no questions. Use specific nouns, names, or terms as answers. Do not include any instructions or explanations. Format as CSV with question,answer on each line. Example: What is the capital of France?,Paris"
    
    # Call the LLM to generate questions (suppress output)
    ollama run llama3.2:3b "$prompt" > raw_output.txt 2>/dev/null
    
    if [ "$attempt" -eq 1 ]; then
        echo "✅ Questions generated successfully!"
    else
        echo "✅ Questions regenerated successfully!"
    fi
}

# Function to process questions and create JSON
process_questions() {
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
        
        # Filter out problematic entries
        # Skip if question is too short or answer is too long
        if (length(question) < 8 || length(answer) > 15) {
            next
        }
        
        # Skip if answer contains spaces (multiple words)
        if (answer ~ / /) {
            next
        }
        
        # Skip if question is too short (likely not a proper question)
        if (length(question) < 12) {
            next
        }
        
        # Skip yes/no questions (answers like YES, NO, TRUE, FALSE)
        if (answer ~ /^(YES|NO|TRUE|FALSE)$/) {
            next
        }
        
        # Only output if answer is at least 3 characters and contains only letters
        if (length(answer) >= 3 && answer ~ /^[A-Z]+$/ && question != "") {
            # Properly escape quotes in question for JSON
            gsub(/"/, "\\\"", question);
            print "{\"question\": \"" question "\", \"answer\": \"" answer "\"},"
        }
    }' raw_output.txt > questions_cleaned.txt

    # Combine into a JSON array
    echo "[" > $QUESTIONS_FILE
    cat questions_cleaned.txt | sed '$ s/,$//' >> $QUESTIONS_FILE  # Remove the last comma
    echo "]" >> $QUESTIONS_FILE
}

# Function to generate crossword with retry logic
generate_crossword() {
    local topic="$1"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # Generate questions
        generate_questions "$topic" $attempt
        
        # Process questions into JSON
        process_questions
        
        # Show progress message for crossword generation
        if [ $attempt -eq 1 ]; then
            show_progress "🧩 Generating crossword puzzle"
        else
            echo "🧩 Attempting crossword generation (attempt $attempt/$max_attempts)"
        fi
        
        # Run the Python script to generate the crossword
        PYTHONPATH=/usr/local/Cellar/topic2crossword/1.0.0/libexec/python_packages /usr/local/opt/python@3.9/bin/python3.9 generate_crossword.py $QUESTIONS_FILE "$topic" 2>&1 | grep -E "(❌|✅|📊|📝|Calculating|files have been saved|out of [0-9]+|Renamed|Crossword puzzle generated|Loaded|Added word|Valid questions processed)" || true
        
        # Check the exit code
        local exit_code=$?
        
        case $exit_code in
            0)
                echo "🎉 Crossword puzzle generated successfully!"
                echo "📄 Check the generated PDF files in your current directory."
                return 0
                ;;
            2)
                echo "⚠️  Insufficient questions generated. Retrying..."
                ;;
            3)
                echo "⚠️  Grid calculation error. Retrying..."
                ;;
            4)
                echo "⚠️  Crossword generation error. Retrying..."
                ;;
            5)
                echo "⚠️  Crossword validation failed - insufficient words placed. Retrying..."
                ;;
            *)
                echo "⚠️  Unexpected error (code $exit_code). Retrying..."
                ;;
        esac
        
        # Clean up for retry
        rm -f raw_output.txt questions_cleaned.txt $QUESTIONS_FILE
        
        # Increment attempt counter
        attempt=$((attempt + 1))
        
        # Add a small delay between attempts
        if [ $attempt -le $max_attempts ]; then
            echo "⏳ Waiting 2 seconds before retry..."
            sleep 2
        fi
    done
    
    # If we get here, all attempts failed
    echo "❌ Failed to generate crossword puzzle after $max_attempts attempts."
    echo "💡 Try using a different topic or check your internet connection."
    return 1
}

# Check if a topic is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <topic>"
    exit 1
fi

TOPIC=$1
QUESTIONS_FILE="questions.json"

# Generate crossword with retry logic
generate_crossword "$TOPIC"

# Clean up temporary files
rm -f raw_output.txt questions_cleaned.txt