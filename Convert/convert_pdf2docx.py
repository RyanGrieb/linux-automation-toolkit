#!/usr/bin/env python3


import sys
import os
from pdf2docx import Converter

def pdf_to_docx(pdf_file):
    # Define the output DOCX file name
    base_name = os.path.splitext(pdf_file)[0]
    docx_file = f"{base_name}.docx"

    # Create a Converter instance
    cv = Converter(pdf_file)
    
    # Perform the conversion
    cv.convert(docx_file, start=0, end=None)
    
    # Close the converter
    cv.close()
    
    print(f"Converted '{pdf_file}' to '{docx_file}'")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: pdf2docx <input_pdf>")
        sys.exit(1)
    
    input_pdf = sys.argv[1]

    pdf_to_docx(input_pdf)

