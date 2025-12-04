# PDF to DOCX Converter

A lightweight command-line utility written in Python that converts PDF documents into editable Microsoft Word (`.docx`) files.

## Features

- **Simple CLI**: One command to convert a file.
- **Auto-naming**: Automatically saves the output file with the same name as the input (e.g., `report.pdf` becomes `report.docx`).
- **Layout Preservation**: Uses the `pdf2docx` library to extract text, tables, and images while maintaining the original layout.

## Prerequisites

- Python 3.6 or higher
- `pip` (Python package manager)

## Installation

1. **Install the required Python library:**

   ```bash
   pip install pdf2docx
   ```
