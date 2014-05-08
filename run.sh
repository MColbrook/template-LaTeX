#!/bin/bash

### I should have made a make file :(

# Create arguments:
CURRENTPATH=${PWD}
CURRENTDIR=${PWD##*/}
SCRIPTNAME=$0
QUIET=0
while test $# -gt 0; do
    case "$1" in
        -h)
            printf -- "${SCRIPTNAME} v0.01\n"
            printf -- "This script compiles the .tex file located in your \"./src\" directory\n"
            printf -- "The compiled PDF will be located in the current directory.\n"
            printf -- "USAGE:\n"
            printf -- "${SCRIPTNAME} [options] [arguments]\n\n"
            printf -- "Options:\n"
            printf -- "-h\t\tShow this help and exit\n"
            printf -- "-o [FILE]\tSpecify the filename to save to. i.e.: -o file.pdf\n"
            printf -- "\t\tThe file will be saved in the directory where the script was run\n"
            printf -- "-q\t\tQuiet mode\n"
            exit 0
            ;;
        -o)
            FILENAME=${CURRENTPATH}/${2##/}
            shift 2
            ;;
        -q) QUIET=1
            shift 1
            ;;
        *)
            printf -- "Parameter ${1} unknown... \nExiting...\n"
            exit 0
            ;;
        esac
done

# If filename not specified:
if [ -z ${FILENAME} ]; then
    FILENAME=${CURRENTPATH}/${CURRENTDIR}.pdf
    if [ ${QUIET} == 0 ]; then
        printf -- "Setting the output filename to ${FILENAME}\n"
    fi
fi

# Check if top.tex exists:
if [ ! -f "./src/top.tex" ]; then
    if [ ${QUIET} == 0 ]; then
        echo "You need ./src/top.tex as your root file for LaTeX. Fix it, please..."
    fi
    # echo "Exiting now!"
    exit 1
fi

# Check is build directory is there
if [ ! -d "build" ]; then
    if [ ${QUIET} == 0 ]; then
        echo "No build directory, creating one :)"
    fi
    mkdir build
fi

# Check if support directories are there
if [ ! -d "codes" -o ! -d "img" -o ! -d "include" ]; then
    if [ ${QUIET} == 0 ]; then
        printf -- "\n\n*WARNING* One or more directories missing, which might cause problems"
        printf -- "The standard directories are:\n"
        printf -- "*\tcodes \n*\timg \n*\tinclude\n\n"
        read -p "Press <ENTER> to continue or <CTRL+C> to abort"
    fi
fi

# change to build directory (all your logs would be here)
cd build

# Clear old logs
if [ ${QUIET} == 0 ]; then
    echo "Clearing old logs..."
fi
rm -rf ./*.log

# Create soft links to custom packages.
# This is done for portability, so that if a package is not installed on another
# machine, it would still work
if [ -d "../include/packages" ]; then
    echo "Packages directory found"
    echo "Creating soft links..."
    # Find all the packages:
    MYPACKS=(`find ../include/packages/ -type d -print`);
    # strip the current name:
    
    # iterate through the directories:
    for PACK in ${MYPACKS[@]:1}
    do
    	PACKNAME="`basename $PACK`.sty";
        echo "Linking $PACK/$PACKNAME";
        ln -sf $PACK/$PACKNAME ./
    done
fi


# and run the pdf latex
# This is weird, but for references to work properly need to precompile :(
# I could have used the *mk script, but some people might not have it by default
if [ ${QUIET} == 0 ]; then
    printf -- "**********************\n"
    printf -- "Running precompilation...\n"
fi
pdflatex -interaction=nonstopmode -interaction=batchmode ../src/top.tex >/dev/null # precompile the document

if [ ${QUIET} == 0 ]; then
    printf -- "**********************\n"
    printf -- "Generating bibliography...\n"
fi
bibtex ./top >/dev/null # compile the bibliography (can be used with MS Word), it is in the build directory

if [ ${QUIET} == 0 ]; then
    printf -- "**********************\n"
    printf -- "Running compilation...\n"
fi
pdflatex -interaction=nonstopmode -interaction=batchmode ../src/top.tex >/dev/null # regenerate the document with the references.

if [ ${QUIET} == 0 ]; then
    printf -- "**********************\n"
    printf -- "Just in case, run again to make sure formatting is fine:\n"
    pdflatex ../src/top.tex # Last pass
else
    pdflatex -interaction=nonstopmode -interaction=batchmode ../src/top.tex >/dev/null  # Last pass
fi

# In reality, you might want to use "latex" instead of the pdflatex, but this works so far
# If you decide to use latex, you also need to convert the DVI to PDF using:
# 	dvips top.dvi
# 	ps2pdf top.ps
# or
#	dvipdf top.dvi

# If -output-directory doesn't work:
if [ ${QUIET} == 0 ]; then
    mv -f top.pdf ${FILENAME}
else
    mv -f top.pdf ${FILENAME} >/dev/null
fi

cd ..


