# Homebrew Tap for Topic2Crossword

This is a Homebrew tap for the Topic2Crossword tool, which converts any topic into a 30-word crossword puzzle using AI.

## Installation

```bash
# Add the tap
brew tap domino-data-systems/topic2crossword

# Install the tool
brew install topic2crossword
```

## Usage

```bash
# Generate a crossword puzzle about a topic
topic2crossword "your topic here"

# Example
topic2crossword "space exploration"
```

## Requirements

- Ollama with llama3.2:3b model
- Python 3.9+

## Setup

After installation, you need to set up Ollama:

```bash
# Install Ollama
brew install --cask ollama

# Pull the required model
ollama pull llama3.2:3b

# Start Ollama
ollama serve
```

## What it does

1. Uses Ollama with llama3.2:3b to generate 30 questions about your topic
2. Converts the output into a structured format
3. Generates a crossword puzzle using the genxword library
4. Outputs a PDF file with the crossword

## Examples

```bash
topic2crossword "space exploration"
topic2crossword "cooking techniques"
topic2crossword "ancient civilizations"
```

## Troubleshooting

- Make sure Ollama is running: `ollama serve`
- Check if the model is available: `ollama list`
- Pull the model if missing: `ollama pull llama3.2:3b`

## License

[Add your license information here]
