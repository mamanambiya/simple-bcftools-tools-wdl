#!/bin/bash

# Script to validate the bcftools stats WDL workflow

echo "Validating bcftools_stats.wdl workflow..."

# Check if womtool is available
if command -v womtool &> /dev/null; then
    echo "Using womtool for validation..."
    womtool validate bcftools_stats.wdl
    if [ $? -eq 0 ]; then
        echo "✓ Workflow validation successful with womtool!"
        
        # Generate inputs template
        echo -e "\nGenerating inputs template..."
        womtool inputs bcftools_stats.wdl > inputs_template.json
        echo "✓ Inputs template saved to inputs_template.json"
    else
        echo "✗ Workflow validation failed with womtool"
        exit 1
    fi
    
# Check if miniwdl is available
elif command -v miniwdl &> /dev/null; then
    echo "Using miniwdl for validation..."
    miniwdl check bcftools_stats.wdl
    if [ $? -eq 0 ]; then
        echo "✓ Workflow validation successful with miniwdl!"
    else
        echo "✗ Workflow validation failed with miniwdl"
        exit 1
    fi
    
# Check if Cromwell is available
elif [ -f "cromwell.jar" ]; then
    echo "Using Cromwell for validation..."
    java -jar cromwell.jar validate bcftools_stats.wdl
    if [ $? -eq 0 ]; then
        echo "✓ Workflow validation successful with Cromwell!"
    else
        echo "✗ Workflow validation failed with Cromwell"
        exit 1
    fi
else
    echo "✗ No WDL validation tool found!"
    echo "Please install one of the following:"
    echo "  - womtool: https://github.com/broadinstitute/cromwell/releases"
    echo "  - miniwdl: pip install miniwdl"
    echo "  - Cromwell: Download cromwell.jar from https://github.com/broadinstitute/cromwell/releases"
    exit 1
fi

echo -e "\n✓ Workflow is ready to use!"
echo "Next steps:"
echo "1. Edit inputs.json with your file paths"
echo "2. Run the workflow using your preferred WDL runner"
