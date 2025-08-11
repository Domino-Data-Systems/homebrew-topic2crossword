class Topic2crossword < Formula
  desc "Convert any topic into a 30-word crossword puzzle using AI"
  homepage "https://github.com/Domino-Data-Systems/Topic2CrosswordPuzzle"
  version "1.0.0"
  
  # For GitHub repository
  url "https://github.com/Domino-Data-Systems/Topic2CrosswordPuzzle.git", branch: "main"
  # You'll need to update this SHA256 after the first commit
  # sha256 "your_sha256_here"
  
  depends_on "python@3.9"
  depends_on "pkg-config"
  depends_on "cairo"
  # Note: Ollama is installed as a cask, so we don't declare it as a dependency
  # Users need to install it manually: brew install --cask ollama
  
  def install
    # Install Python dependencies
    system "pip3", "install", "-r", "requirements.txt"
    
    # Install the Python script
    libexec.install "generate_crossword.py"
    
    # Install the main bash script and make it executable
    bin.install "generate_crossword.sh" => "topic2crossword"
    chmod 0755, bin/"topic2crossword"
    
    # Update the script to use the correct path for the Python script
    inreplace bin/"topic2crossword", "python3 generate_crossword.py", "python3 #{libexec}/generate_crossword.py"
  end
  
  def caveats
    <<~EOS
      Topic2Crossword requires Ollama to be running with the llama3.2:3b model.
      
      To set up:
      1. Install Ollama: brew install --cask ollama
      2. Pull the model: ollama pull llama3.2:3b
      3. Start Ollama: ollama serve
      
      Usage:
        topic2crossword "your topic here"
        
      Example:
        topic2crossword "space exploration"
    EOS
  end
  
  test do
    # Test that the script exists and is executable
    assert_predicate bin/"topic2crossword", :exist?
    assert_predicate bin/"topic2crossword", :executable?
  end
end
